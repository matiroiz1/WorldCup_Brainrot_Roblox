local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes             = require(ReplicatedStorage.Remotes)
local Brainrots           = require(ReplicatedStorage.Config.Brainrots)
local Economy             = require(ReplicatedStorage.Config.Economy)

-- ── Constants ─────────────────────────────────────────────────────────

local CAPTURE_START_RANGE = 15  -- studs: must be this close to start capture
local CAPTURE_HOLD_RANGE  = 20  -- studs: must stay within this to keep capturing
local CAPTURE_COOLDOWN    = 3   -- seconds between capture ATTEMPTS per player
local DIFFICULTY_MULT     = 1.5 -- captureTime = difficulty * DIFFICULTY_MULT seconds

-- ── State ─────────────────────────────────────────────────────────────

-- Per-player capture cooldown timestamps
local LastAttempt: { [number]: number } = {}

local ChaseService = {}

-- ── Private helpers ───────────────────────────────────────────────────

local function getBSS()
    return require(script.Parent.BrainrotSpawnService)
end

local function getCardService()
    return require(script.Parent.CardService)
end

local function getPDS()
    return require(script.Parent.PlayerDataService)
end

local function getPlayerHRP(player: Player): BasePart?
    local char = player.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function getBrainrotHRP(state: any): BasePart?
    local model = state.model
    if not model then return nil end
    return model:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function distanceBetween(p1: Vector3, p2: Vector3): number
    return (p1 - p2).Magnitude
end

-- ── Capture flow ──────────────────────────────────────────────────────

local function doCapture(player: Player, instanceId: string)
    local BSS   = getBSS()
    local state = BSS.getState(instanceId)
    if not state then return end

    local def = Brainrots.getById(state.defId)
    if not def then return end

    local captureTime = def.captureDifficulty * DIFFICULTY_MULT

    -- Lock NPC so other players can't capture simultaneously
    if not BSS.lockForCapture(instanceId, player.UserId) then
        Remotes.CaptureResult:FireClient(player, {
            success    = false,
            instanceId = instanceId,
            reason     = "already_captured",
        })
        return
    end

    -- Notify client: capture started
    Remotes.CaptureResult:FireClient(player, {
        success    = nil,  -- nil = "in progress"
        instanceId = instanceId,
        duration   = captureTime,
    })

    -- Hold check loop
    local elapsed = 0
    local tick    = 0.25

    while elapsed < captureTime do
        task.wait(tick)
        elapsed += tick

        -- Validate brainrot still exists
        local currentState = BSS.getState(instanceId)
        if not currentState then
            -- Someone else despawned it
            return
        end

        -- Validate player still in range
        local playerHRP    = getPlayerHRP(player)
        local brainrotHRP  = getBrainrotHRP(currentState)

        if not playerHRP or not brainrotHRP then
            BSS.unlockCapture(instanceId)
            Remotes.CaptureResult:FireClient(player, {
                success    = false,
                instanceId = instanceId,
                reason     = "out_of_range",
            })
            return
        end

        local dist = distanceBetween(playerHRP.Position, brainrotHRP.Position)
        if dist > CAPTURE_HOLD_RANGE then
            BSS.unlockCapture(instanceId)
            Remotes.CaptureResult:FireClient(player, {
                success    = false,
                instanceId = instanceId,
                reason     = "out_of_range",
            })
            return
        end

        -- Player disconnected mid-capture
        if not player:IsDescendantOf(Players) then
            BSS.unlockCapture(instanceId)
            return
        end
    end

    -- ── SUCCESS ──────────────────────────────────────────────────────

    -- Give rewards
    local CardService = getCardService()
    local PDS         = getPDS()

    local coinReward = Economy.CaptureCoins[def.brainrotType] or Economy.CaptureCoins.Common
    PDS.addCoins(player, coinReward)

    local cardId = CardService.giveRewardCard(player, def.rewardsTable)

    -- Update stats
    PDS.update(player, function(data)
        data.totalCaptures  = data.totalCaptures + 1
        data.weeklyScore    = data.weeklyScore + 1
        data.seasonScore    = data.seasonScore + 1
    end)

    -- Despawn the NPC
    BSS.despawnBrainrot(instanceId)

    -- Notify player
    Remotes.CaptureResult:FireClient(player, {
        success    = true,
        instanceId = instanceId,
        cardId     = cardId,
        coins      = coinReward,
    })
end

-- ── Remote handler ────────────────────────────────────────────────────

local function onRequestCapture(player: Player, instanceId: string)
    if type(instanceId) ~= "string" then return end

    -- Cooldown check
    local now      = os.clock()
    local lastTime = LastAttempt[player.UserId] or 0
    if now - lastTime < CAPTURE_COOLDOWN then
        Remotes.CaptureResult:FireClient(player, {
            success    = false,
            instanceId = instanceId,
            reason     = "cooldown",
        })
        return
    end
    LastAttempt[player.UserId] = now

    -- Check brainrot exists
    local BSS   = getBSS()
    local state = BSS.getState(instanceId)
    if not state then
        Remotes.CaptureResult:FireClient(player, {
            success    = false,
            instanceId = instanceId,
            reason     = "not_found",
        })
        return
    end

    if state.beingCaptured then
        Remotes.CaptureResult:FireClient(player, {
            success    = false,
            instanceId = instanceId,
            reason     = "already_captured",
        })
        return
    end

    -- Distance check
    local playerHRP   = getPlayerHRP(player)
    local brainrotHRP = getBrainrotHRP(state)

    if not playerHRP or not brainrotHRP then
        return
    end

    if distanceBetween(playerHRP.Position, brainrotHRP.Position) > CAPTURE_START_RANGE then
        Remotes.CaptureResult:FireClient(player, {
            success    = false,
            instanceId = instanceId,
            reason     = "too_far",
        })
        return
    end

    -- All checks passed — run capture in separate thread
    task.spawn(doCapture, player, instanceId)
end

-- ── Init ──────────────────────────────────────────────────────────────

function ChaseService.OnStart()
    Remotes.RequestCapture:Connect(onRequestCapture)

    Players.PlayerRemoving:Connect(function(player)
        LastAttempt[player.UserId] = nil
    end)
end

return ChaseService
