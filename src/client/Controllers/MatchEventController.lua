local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")

local Remotes      = require(ReplicatedStorage.Remotes)
local UIController = require(script.Parent.UIController)

local Player    = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- ── State ──────────────────────────────────────────────────────────────
local currentMatch: any = nil  -- latest MatchEventUpdate payload

-- Prediction state
local myPredictions = {
    MatchResult  = nil,   -- "teamA" | "teamB" | "draw"
    FinalScore   = nil,   -- "N-N"
    FirstScorer  = nil,   -- string
}
local predictionSubmitted = false

-- Score values for +/- buttons
local scoreA = 0
local scoreB = 0

local MatchEventController = {}

-- ── UI helpers ─────────────────────────────────────────────────────────

local function corner(p, r)
    Instance.new("UICorner", p).CornerRadius = UDim.new(0, r or 8)
end

local C = {
    bg      = Color3.fromRGB(14, 14, 24),
    panel   = Color3.fromRGB(22, 22, 38),
    section = Color3.fromRGB(18, 18, 32),
    white   = Color3.new(1, 1, 1),
    dim     = Color3.fromRGB(140, 140, 160),
    green   = Color3.fromRGB(20, 160, 70),
    blue    = Color3.fromRGB(50, 120, 220),
    gold    = Color3.fromRGB(220, 180, 20),
    red     = Color3.fromRGB(160, 20, 20),
    sel     = Color3.fromRGB(60, 140, 60),
}

-- ── Prediction ScreenGui ───────────────────────────────────────────────

local matchGui = Instance.new("ScreenGui")
matchGui.Name           = "MatchPredictionScreen"
matchGui.ResetOnSpawn   = false
matchGui.Enabled        = false
matchGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
matchGui.Parent         = PlayerGui

local overlay = Instance.new("Frame")
overlay.Size              = UDim2.fromScale(1, 1)
overlay.BackgroundColor3  = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 0.5
overlay.Parent            = matchGui

local panel = Instance.new("Frame")
panel.Name             = "Panel"
panel.Size             = UDim2.new(0, 540, 0, 580)
panel.Position         = UDim2.new(0.5, -270, 0.5, -290)
panel.BackgroundColor3 = C.bg
panel.BorderSizePixel  = 0
panel.Parent           = matchGui
corner(panel, 14)

-- Header
local headerFrame = Instance.new("Frame")
headerFrame.Size             = UDim2.new(1, 0, 0, 60)
headerFrame.BackgroundColor3 = Color3.fromRGB(0, 80, 30)
headerFrame.BorderSizePixel  = 0
headerFrame.Parent           = panel
corner(headerFrame, 14)

local headerLbl = Instance.new("TextLabel")
headerLbl.Name              = "MatchTitle"
headerLbl.Size              = UDim2.new(1, -50, 1, 0)
headerLbl.Position          = UDim2.new(0, 10, 0, 0)
headerLbl.BackgroundTransparency = 1
headerLbl.Text              = "⚽ Predicción de Partido"
headerLbl.TextColor3        = Color3.new(1, 1, 1)
headerLbl.TextScaled        = true
headerLbl.Font              = Enum.Font.GothamBold
headerLbl.TextXAlignment    = Enum.TextXAlignment.Left
headerLbl.Parent            = headerFrame

local closeBtn = Instance.new("TextButton")
closeBtn.Size             = UDim2.new(0, 38, 0, 38)
closeBtn.Position         = UDim2.new(1, -44, 0, 11)
closeBtn.BackgroundColor3 = C.red
closeBtn.BorderSizePixel  = 0
closeBtn.Text             = "✕"
closeBtn.TextColor3       = C.white
closeBtn.TextScaled       = true
closeBtn.Font             = Enum.Font.GothamBold
closeBtn.Parent           = panel
corner(closeBtn, 6)

-- ── Section: Winner ────────────────────────────────────────────────────

local winnerSection = Instance.new("Frame")
winnerSection.Size             = UDim2.new(1, -20, 0, 110)
winnerSection.Position         = UDim2.new(0, 10, 0, 70)
winnerSection.BackgroundColor3 = C.section
winnerSection.BorderSizePixel  = 0
winnerSection.Parent           = panel
corner(winnerSection, 10)

local winnerTitle = Instance.new("TextLabel")
winnerTitle.Size              = UDim2.new(1, -12, 0, 30)
winnerTitle.Position          = UDim2.new(0, 8, 0, 4)
winnerTitle.BackgroundTransparency = 1
winnerTitle.Text              = "¿Quién gana?"
winnerTitle.TextColor3        = C.gold
winnerTitle.TextScaled        = true
winnerTitle.Font              = Enum.Font.GothamBold
winnerTitle.TextXAlignment    = Enum.TextXAlignment.Left
winnerTitle.Parent            = winnerSection

-- TeamA, Draw, TeamB buttons
local teamABtn = Instance.new("TextButton")
teamABtn.Name            = "TeamABtn"
teamABtn.Size            = UDim2.new(0, 148, 0, 50)
teamABtn.Position        = UDim2.new(0, 8, 0, 48)
teamABtn.BackgroundColor3 = C.blue
teamABtn.BorderSizePixel = 0
teamABtn.Text            = "Team A"
teamABtn.TextColor3      = C.white
teamABtn.TextScaled      = true
teamABtn.Font            = Enum.Font.GothamBold
teamABtn.Parent          = winnerSection
corner(teamABtn, 8)

local drawBtn = Instance.new("TextButton")
drawBtn.Name             = "DrawBtn"
drawBtn.Size             = UDim2.new(0, 100, 0, 50)
drawBtn.Position         = UDim2.new(0.5, -50, 0, 48)
drawBtn.BackgroundColor3 = C.panel
drawBtn.BorderSizePixel  = 0
drawBtn.Text             = "Empate"
drawBtn.TextColor3       = C.white
drawBtn.TextScaled       = true
drawBtn.Font             = Enum.Font.GothamBold
drawBtn.Parent           = winnerSection
corner(drawBtn, 8)

local teamBBtn = Instance.new("TextButton")
teamBBtn.Name            = "TeamBBtn"
teamBBtn.Size            = UDim2.new(0, 148, 0, 50)
teamBBtn.Position        = UDim2.new(1, -156, 0, 48)
teamBBtn.BackgroundColor3 = C.blue
teamBBtn.BorderSizePixel = 0
teamBBtn.Text            = "Team B"
teamBBtn.TextColor3      = C.white
teamBBtn.TextScaled      = true
teamBBtn.Font            = Enum.Font.GothamBold
teamBBtn.Parent          = winnerSection
corner(teamBBtn, 8)

-- ── Section: Score ─────────────────────────────────────────────────────

local scoreSection = Instance.new("Frame")
scoreSection.Size             = UDim2.new(1, -20, 0, 100)
scoreSection.Position         = UDim2.new(0, 10, 0, 192)
scoreSection.BackgroundColor3 = C.section
scoreSection.BorderSizePixel  = 0
scoreSection.Parent           = panel
corner(scoreSection, 10)

local scoreTitle = Instance.new("TextLabel")
scoreTitle.Size              = UDim2.new(1, -12, 0, 28)
scoreTitle.Position          = UDim2.new(0, 8, 0, 4)
scoreTitle.BackgroundTransparency = 1
scoreTitle.Text              = "Marcador exacto (opcional)"
scoreTitle.TextColor3        = C.gold
scoreTitle.TextScaled        = true
scoreTitle.Font              = Enum.Font.GothamBold
scoreTitle.TextXAlignment    = Enum.TextXAlignment.Left
scoreTitle.Parent            = scoreSection

-- Score A control
local function makeScoreControl(parent, xPos, label, onGet, onSet)
    local f = Instance.new("Frame")
    f.Size             = UDim2.new(0, 130, 0, 52)
    f.Position         = UDim2.new(0, xPos, 0, 36)
    f.BackgroundTransparency = 1
    f.Parent           = parent

    local minusBtn = Instance.new("TextButton")
    minusBtn.Size             = UDim2.new(0, 38, 0, 38)
    minusBtn.Position         = UDim2.new(0, 0, 0.5, -19)
    minusBtn.BackgroundColor3 = C.panel
    minusBtn.BorderSizePixel  = 0
    minusBtn.Text             = "−"
    minusBtn.TextColor3       = C.white
    minusBtn.TextScaled       = true
    minusBtn.Font             = Enum.Font.GothamBold
    minusBtn.Parent           = f
    corner(minusBtn, 6)

    local valLbl = Instance.new("TextLabel")
    valLbl.Size              = UDim2.new(0, 40, 0, 38)
    valLbl.Position          = UDim2.new(0, 44, 0.5, -19)
    valLbl.BackgroundTransparency = 1
    valLbl.Text              = "0"
    valLbl.TextColor3        = C.white
    valLbl.TextScaled        = true
    valLbl.Font              = Enum.Font.GothamBold
    valLbl.TextXAlignment    = Enum.TextXAlignment.Center
    valLbl.Parent            = f

    local teamLbl = Instance.new("TextLabel")
    teamLbl.Size              = UDim2.new(1, 0, 0, 18)
    teamLbl.Position          = UDim2.new(0, 0, 0, 0)
    teamLbl.BackgroundTransparency = 1
    teamLbl.Text              = label
    teamLbl.TextColor3        = C.dim
    teamLbl.TextScaled        = true
    teamLbl.Font              = Enum.Font.Gotham
    teamLbl.TextXAlignment    = Enum.TextXAlignment.Center
    teamLbl.Parent            = f

    local plusBtn = Instance.new("TextButton")
    plusBtn.Size             = UDim2.new(0, 38, 0, 38)
    plusBtn.Position         = UDim2.new(0, 88, 0.5, -19)
    plusBtn.BackgroundColor3 = C.panel
    plusBtn.BorderSizePixel  = 0
    plusBtn.Text             = "+"
    plusBtn.TextColor3       = C.white
    plusBtn.TextScaled       = true
    plusBtn.Font             = Enum.Font.GothamBold
    plusBtn.Parent           = f
    corner(plusBtn, 6)

    minusBtn.MouseButton1Click:Connect(function()
        local v = math.max(0, onGet() - 1)
        onSet(v)
        valLbl.Text = tostring(v)
    end)
    plusBtn.MouseButton1Click:Connect(function()
        local v = math.min(20, onGet() + 1)
        onSet(v)
        valLbl.Text = tostring(v)
    end)

    return valLbl
end

local scoreALabel = makeScoreControl(scoreSection, 30,  "Local",
    function() return scoreA end,
    function(v) scoreA = v end)
local scoreBLabel = makeScoreControl(scoreSection, 330, "Visitante",
    function() return scoreB end,
    function(v) scoreB = v end)

local scoreDash = Instance.new("TextLabel")
scoreDash.Size              = UDim2.new(0, 30, 0, 38)
scoreDash.Position          = UDim2.new(0.5, -15, 0, 46)
scoreDash.BackgroundTransparency = 1
scoreDash.Text              = "−"
scoreDash.TextColor3        = C.white
scoreDash.TextScaled        = true
scoreDash.Font              = Enum.Font.GothamBold
scoreDash.TextXAlignment    = Enum.TextXAlignment.Center
scoreDash.Parent            = scoreSection

-- ── Section: First Scorer ──────────────────────────────────────────────

local scorerSection = Instance.new("Frame")
scorerSection.Size             = UDim2.new(1, -20, 0, 80)
scorerSection.Position         = UDim2.new(0, 10, 0, 304)
scorerSection.BackgroundColor3 = C.section
scorerSection.BorderSizePixel  = 0
scorerSection.Parent           = panel
corner(scorerSection, 10)

local scorerTitle = Instance.new("TextLabel")
scorerTitle.Size              = UDim2.new(1, -12, 0, 28)
scorerTitle.Position          = UDim2.new(0, 8, 0, 4)
scorerTitle.BackgroundTransparency = 1
scorerTitle.Text              = "Primer goleador (opcional)"
scorerTitle.TextColor3        = C.gold
scorerTitle.TextScaled        = true
scorerTitle.Font              = Enum.Font.GothamBold
scorerTitle.TextXAlignment    = Enum.TextXAlignment.Left
scorerTitle.Parent            = scorerSection

local scorerBox = Instance.new("TextBox")
scorerBox.Size              = UDim2.new(1, -16, 0, 36)
scorerBox.Position          = UDim2.new(0, 8, 0, 36)
scorerBox.BackgroundColor3  = C.panel
scorerBox.BorderSizePixel   = 0
scorerBox.Text              = ""
scorerBox.PlaceholderText   = "Ej: Messi, Mbappé..."
scorerBox.TextColor3        = C.white
scorerBox.PlaceholderColor3 = C.dim
scorerBox.TextScaled        = true
scorerBox.Font              = Enum.Font.Gotham
scorerBox.ClearTextOnFocus  = false
scorerBox.Parent            = scorerSection
corner(scorerBox, 7)

-- ── Status label ────────────────────────────────────────────────────────

local statusLbl = Instance.new("TextLabel")
statusLbl.Size              = UDim2.new(1, -20, 0, 28)
statusLbl.Position          = UDim2.new(0, 10, 0, 396)
statusLbl.BackgroundTransparency = 1
statusLbl.Text              = ""
statusLbl.TextColor3        = C.dim
statusLbl.TextScaled        = true
statusLbl.Font              = Enum.Font.Gotham
statusLbl.Parent            = panel

-- ── Confirm button ─────────────────────────────────────────────────────

local confirmBtn = Instance.new("TextButton")
confirmBtn.Name            = "ConfirmBtn"
confirmBtn.Size            = UDim2.new(1, -20, 0, 50)
confirmBtn.Position        = UDim2.new(0, 10, 0, 430)
confirmBtn.BackgroundColor3 = C.green
confirmBtn.BorderSizePixel = 0
confirmBtn.Text            = "✅ Confirmar predicción"
confirmBtn.TextColor3      = C.white
confirmBtn.TextScaled      = true
confirmBtn.Font            = Enum.Font.GothamBold
confirmBtn.Parent          = panel
corner(confirmBtn, 10)

-- ── Predict HUD button ─────────────────────────────────────────────────

local predictBtn: TextButton? = nil

local function addPredictButton()
    local hud = PlayerGui:WaitForChild("WorldCupHUD", 10)
    if not hud then return end

    local btn = Instance.new("TextButton")
    btn.Name            = "PredictBtn"
    btn.Size            = UDim2.new(0, 130, 0, 48)
    btn.Position        = UDim2.new(1, -570, 1, -64)
    btn.BackgroundColor3 = Color3.fromRGB(0, 100, 40)
    btn.BorderSizePixel = 0
    btn.Text            = "⚽ Predecir"
    btn.TextColor3      = Color3.new(1, 1, 1)
    btn.TextScaled      = true
    btn.Font            = Enum.Font.GothamBold
    btn.Visible         = false
    btn.Parent          = hud
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    btn.MouseButton1Click:Connect(function()
        if currentMatch and currentMatch.status == "active" then
            matchGui.Enabled = true
        end
    end)

    predictBtn = btn
    return btn
end

-- ── Winner button selection ────────────────────────────────────────────

local function refreshWinnerButtons()
    teamABtn.BackgroundColor3 = (myPredictions.MatchResult == "teamA") and C.sel or C.blue
    drawBtn.BackgroundColor3  = (myPredictions.MatchResult == "draw")  and C.sel or C.panel
    teamBBtn.BackgroundColor3 = (myPredictions.MatchResult == "teamB") and C.sel or C.blue
end

-- ── Populate match UI ──────────────────────────────────────────────────

local function populateMatchUI(match: any)
    if not match then return end
    headerLbl.Text   = "⚽ " .. match.teamA .. " vs " .. match.teamB
    teamABtn.Text    = match.teamA
    teamBBtn.Text    = match.teamB
    statusLbl.Text   = match.status == "active"
        and "Hacé tus predicciones antes de que empiece."
        or  "El partido ya terminó."
    confirmBtn.Active    = (match.status == "active") and not predictionSubmitted
    confirmBtn.BackgroundColor3 = (match.status == "active") and not predictionSubmitted
        and C.green or Color3.fromRGB(50, 50, 70)
    refreshWinnerButtons()
end

-- ── Wiring ─────────────────────────────────────────────────────────────

local function wireButtons()
    teamABtn.MouseButton1Click:Connect(function()
        if predictionSubmitted then return end
        myPredictions.MatchResult = "teamA"
        refreshWinnerButtons()
    end)

    drawBtn.MouseButton1Click:Connect(function()
        if predictionSubmitted then return end
        myPredictions.MatchResult = "draw"
        refreshWinnerButtons()
    end)

    teamBBtn.MouseButton1Click:Connect(function()
        if predictionSubmitted then return end
        myPredictions.MatchResult = "teamB"
        refreshWinnerButtons()
    end)

    closeBtn.MouseButton1Click:Connect(function()
        matchGui.Enabled = false
    end)

    confirmBtn.MouseButton1Click:Connect(function()
        if predictionSubmitted then return end
        if not currentMatch then return end
        local matchId = currentMatch.matchId

        -- Submit all filled predictions
        if myPredictions.MatchResult then
            Remotes.RequestPrediction:FireServer(matchId, "MatchResult", myPredictions.MatchResult)
        end

        local scoreStr = tostring(scoreA) .. "-" .. tostring(scoreB)
        Remotes.RequestPrediction:FireServer(matchId, "FinalScore", scoreStr)

        local scorerText = scorerBox.Text
        if #scorerText >= 2 then
            Remotes.RequestPrediction:FireServer(matchId, "FirstScorer", scorerText)
        end

        predictionSubmitted = true
        statusLbl.Text = "✅ ¡Predicciones enviadas! Esperá el resultado."
        confirmBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
        task.delay(2, function()
            matchGui.Enabled = false
        end)
    end)
end

-- ── Init ──────────────────────────────────────────────────────────────

function MatchEventController.OnStart()
    wireButtons()
    task.spawn(addPredictButton)

    Remotes.MatchEventUpdate:Connect(function(match)
        currentMatch = match

        if match.status == "active" then
            -- Reset predictions for new match
            myPredictions = { MatchResult = nil, FinalScore = nil, FirstScorer = nil }
            predictionSubmitted = false
            scoreA, scoreB = 0, 0
            scorerBox.Text = ""

            if predictBtn then predictBtn.Visible = true end
            populateMatchUI(match)

        elseif match.status == "ended" then
            if predictBtn then predictBtn.Visible = false end
            matchGui.Enabled = false

        elseif match.status == "pending" then
            if predictBtn then predictBtn.Visible = false end
        end
    end)

    Remotes.PredictionResult:Connect(function(result)
        if result.error then return end

        local msg = ""
        if result.totalCoins > 0 or result.totalTokens > 0 then
            msg = "⚽ ¡Predicción correcta! +" .. result.totalCoins .. " 🪙"
            if result.totalTokens > 0 then
                msg = msg .. " +" .. result.totalTokens .. " 🎟"
            end
            local c = result.correct or {}
            if #c > 0 then
                msg = msg .. " (" .. table.concat(c, ", ") .. ")"
            end
            UIController.showNotification("success", msg)
        else
            UIController.showNotification("info", "⚽ Resultado: ninguna predicción correcta.")
        end
    end)
end

return MatchEventController
