local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local Remotes  = require(ReplicatedStorage.Remotes)
local Economy  = require(ReplicatedStorage.Config.Economy)
local Events   = require(ReplicatedStorage.Config.Events)

-- ── State ─────────────────────────────────────────────────────────────
-- Matches[matchId] = { matchId, teamA, teamB, status, createdAt, startedAt?, endedAt?, result? }
local Matches: { [string]: any } = {}

-- Predictions[matchId][userId][predType] = value
-- predType: "MatchResult" | "FinalScore" | "FirstScorer"
local Predictions: { [string]: { [number]: { [string]: any } } } = {}

local currentMatchId: string? = nil

local MatchEventService = {}

-- ── Helpers ───────────────────────────────────────────────────────────

local function getPDS()
    return require(script.Parent.PlayerDataService)
end

local function generateMatchId(): string
    return "match_" .. tostring(os.time()) .. "_" .. tostring(math.random(100, 999))
end

local function broadcastMatchUpdate(matchId: string)
    local match = Matches[matchId]
    if not match then return end
    Remotes.MatchEventUpdate:FireAllClients({
        matchId = match.matchId,
        teamA   = match.teamA,
        teamB   = match.teamB,
        status  = match.status,
        result  = match.result,
    })
end

-- ── Match lifecycle ────────────────────────────────────────────────────

-- Create a match (admin). Status starts as "pending".
function MatchEventService.createMatch(teamA: string, teamB: string, matchId: string?): string
    local id = matchId or generateMatchId()
    Matches[id] = {
        matchId   = id,
        teamA     = teamA,
        teamB     = teamB,
        status    = "pending",
        createdAt = os.time(),
    }
    Predictions[id] = {}
    return id
end

-- Start accepting predictions for a match.
function MatchEventService.startMatch(matchId: string): boolean
    local match = Matches[matchId]
    if not match or match.status ~= "pending" then return false end

    match.status    = "active"
    match.startedAt = os.time()
    currentMatchId  = matchId

    Remotes.Notification:FireAllClients({
        type    = "event",
        message = Events.Announcements.MatchStart .. " " .. match.teamA .. " vs " .. match.teamB,
    })

    broadcastMatchUpdate(matchId)
    return true
end

-- End a match and distribute rewards.
function MatchEventService.endMatch(
    matchId: string,
    winner: string,      -- "teamA" | "teamB" | "draw"
    scoreA: number,
    scoreB: number,
    firstGoalScorer: string?
): boolean
    local match = Matches[matchId]
    if not match or match.status ~= "active" then return false end

    match.status  = "ended"
    match.endedAt = os.time()
    match.result  = {
        winner          = winner,
        scoreA          = scoreA,
        scoreB          = scoreB,
        firstGoalScorer = firstGoalScorer,
    }

    if currentMatchId == matchId then
        currentMatchId = nil
    end

    broadcastMatchUpdate(matchId)

    -- Distribute prediction rewards
    local matchPreds = Predictions[matchId] or {}
    local PDS = getPDS()

    for userId, preds in pairs(matchPreds) do
        local player = nil
        for _, p in ipairs(Players:GetPlayers()) do
            if p.UserId == userId then player = p; break end
        end
        if not player then continue end

        local totalCoins  = 0
        local totalTokens = 0
        local correct: { string } = {}

        -- MatchResult: "teamA" | "teamB" | "draw"
        if preds.MatchResult == winner then
            local reward = Economy.PredictionRewards.CorrectResult
            totalCoins  += reward.coins
            totalTokens += reward.tokens
            table.insert(correct, "MatchResult")
        end

        -- FinalScore: stored as "N-N" string
        local expectedScore = tostring(scoreA) .. "-" .. tostring(scoreB)
        if preds.FinalScore == expectedScore then
            local reward = Economy.PredictionRewards.CorrectScore
            totalCoins  += reward.coins
            totalTokens += reward.tokens
            table.insert(correct, "FinalScore")
        end

        -- FirstScorer: case-insensitive string match
        if firstGoalScorer and preds.FirstScorer then
            local pred   = tostring(preds.FirstScorer):lower():gsub("%s+", "")
            local actual = tostring(firstGoalScorer):lower():gsub("%s+", "")
            if pred == actual then
                local reward = Economy.PredictionRewards.CorrectScorer
                totalCoins  += reward.coins
                totalTokens += reward.tokens
                table.insert(correct, "FirstScorer")
            end
        end

        if totalCoins > 0 then PDS.addCoins(player, totalCoins) end
        if totalTokens > 0 then PDS.addTokens(player, totalTokens) end

        Remotes.PredictionResult:FireClient(player, {
            matchId     = matchId,
            totalCoins  = totalCoins,
            totalTokens = totalTokens,
            correct     = correct,
        })
    end

    Remotes.Notification:FireAllClients({
        type    = "event",
        message = Events.Announcements.MatchEnd,
    })

    -- Clean up predictions after a delay
    task.delay(60, function()
        Predictions[matchId] = nil
    end)

    return true
end

-- ── RequestPrediction handler ──────────────────────────────────────────

local function onRequestPrediction(player: Player, matchId: string, predType: string, value: any)
    if type(matchId) ~= "string" or type(predType) ~= "string" then return end

    local match = Matches[matchId]
    if not match or match.status ~= "active" then
        Remotes.PredictionResult:FireClient(player, {
            matchId = matchId,
            error   = "match_not_active",
        })
        return
    end

    -- Validate predType
    local validType = false
    for _, t in ipairs(Events.PredictionTypes) do
        if t == predType then validType = true; break end
    end
    if not validType then return end

    -- Validate values
    if predType == "MatchResult" then
        if value ~= "teamA" and value ~= "teamB" and value ~= "draw" then return end
    elseif predType == "FinalScore" then
        if type(value) ~= "string" or not value:match("^%d+%-%d+$") then return end
    elseif predType == "FirstScorer" then
        if type(value) ~= "string" or #value < 2 or #value > 40 then return end
    end

    if not Predictions[matchId] then Predictions[matchId] = {} end
    if not Predictions[matchId][player.UserId] then Predictions[matchId][player.UserId] = {} end

    Predictions[matchId][player.UserId][predType] = value

    Remotes.Notification:FireClient(player, {
        type    = "success",
        message = "⚽ Predicción guardada: " .. predType,
    })
end

-- ── Public read API ───────────────────────────────────────────────────

function MatchEventService.getCurrentMatch(): any?
    if not currentMatchId then return nil end
    return Matches[currentMatchId]
end

function MatchEventService.getMatch(matchId: string): any?
    return Matches[matchId]
end

-- ── Studio test ───────────────────────────────────────────────────────

local function studioTest()
    if not RunService:IsStudio() then return end
    task.delay(15, function()
        print("[MatchEventService] Studio: starting test match Argentina vs Brasil")
        local id = MatchEventService.createMatch("Argentina", "Brasil", "test_match_001")
        MatchEventService.startMatch(id)
        -- End match after 60s in Studio for full flow test
        task.delay(60, function()
            print("[MatchEventService] Studio: ending test match 2-1, scorer=Messi")
            MatchEventService.endMatch(id, "teamA", 2, 1, "Messi")
        end)
    end)
end

-- ── Init ──────────────────────────────────────────────────────────────

function MatchEventService.OnStart()
    Remotes.RequestPrediction:Connect(onRequestPrediction)

    -- Send current match state to newly joined players
    Players.PlayerAdded:Connect(function(player)
        if currentMatchId then
            task.delay(4, function()
                if player:IsDescendantOf(Players) and currentMatchId then
                    broadcastMatchUpdate(currentMatchId)
                end
            end)
        end
    end)

    studioTest()
end

return MatchEventService
