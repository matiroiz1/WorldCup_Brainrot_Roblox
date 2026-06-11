local Players        = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService     = game:GetService("RunService")

local Remotes = require(ReplicatedStorage.Remotes)

local Player    = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local REFRESH_HZ = 5  -- seconds between leaderboard refreshes

local LeaderboardController = {}

-- ── Colours ────────────────────────────────────────────────────────────
local C = {
    bg      = Color3.fromRGB(10, 10, 20),
    row     = Color3.fromRGB(22, 22, 38),
    rowAlt  = Color3.fromRGB(18, 18, 32),
    header  = Color3.fromRGB(30, 30, 55),
    gold    = Color3.fromRGB(255, 215, 0),
    silver  = Color3.fromRGB(192, 192, 192),
    bronze  = Color3.fromRGB(205, 127, 50),
    white   = Color3.new(1, 1, 1),
    dim     = Color3.fromRGB(130, 130, 150),
    green   = Color3.fromRGB(20, 160, 70),
    accent  = Color3.fromRGB(255, 220, 80),
}

local RANK_COLORS = { C.gold, C.silver, C.bronze }

-- ── UI setup ───────────────────────────────────────────────────────────

local lbGui = Instance.new("ScreenGui")
lbGui.Name           = "LeaderboardScreen"
lbGui.ResetOnSpawn   = false
lbGui.Enabled        = false
lbGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
lbGui.Parent         = PlayerGui

local overlay = Instance.new("Frame")
overlay.Size              = UDim2.fromScale(1, 1)
overlay.BackgroundColor3  = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 0.5
overlay.Parent            = lbGui

local panel = Instance.new("Frame")
panel.Name             = "Panel"
panel.Size             = UDim2.new(0, 520, 0, 540)
panel.Position         = UDim2.new(0.5, -260, 0.5, -270)
panel.BackgroundColor3 = C.bg
panel.BorderSizePixel  = 0
panel.Parent           = lbGui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Size             = UDim2.new(1, 0, 0, 54)
titleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
titleBar.BorderSizePixel  = 0
titleBar.Parent           = panel
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 14)

local titleLbl = Instance.new("TextLabel")
titleLbl.Size              = UDim2.new(1, -50, 1, 0)
titleLbl.Position          = UDim2.new(0, 14, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text              = "🏆  TABLA DE POSICIONES"
titleLbl.TextColor3        = C.accent
titleLbl.TextScaled        = true
titleLbl.Font              = Enum.Font.GothamBold
titleLbl.TextXAlignment    = Enum.TextXAlignment.Left
titleLbl.Parent            = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size             = UDim2.new(0, 38, 0, 38)
closeBtn.Position         = UDim2.new(1, -44, 0, 8)
closeBtn.BackgroundColor3 = Color3.fromRGB(140, 20, 20)
closeBtn.BorderSizePixel  = 0
closeBtn.Text             = "✕"
closeBtn.TextColor3       = C.white
closeBtn.TextScaled       = true
closeBtn.Font             = Enum.Font.GothamBold
closeBtn.Parent           = panel
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 7)

-- Column headers
local colHeader = Instance.new("Frame")
colHeader.Size             = UDim2.new(1, -16, 0, 30)
colHeader.Position         = UDim2.new(0, 8, 0, 58)
colHeader.BackgroundColor3 = C.header
colHeader.BorderSizePixel  = 0
colHeader.Parent           = panel
Instance.new("UICorner", colHeader).CornerRadius = UDim.new(0, 6)

local function colLbl(parent, text, xScale, xOff, width)
    local l = Instance.new("TextLabel")
    l.Size              = UDim2.new(width, 0, 1, 0)
    l.Position          = UDim2.new(xScale, xOff, 0, 0)
    l.BackgroundTransparency = 1
    l.Text              = text
    l.TextColor3        = C.dim
    l.TextScaled        = true
    l.Font              = Enum.Font.GothamBold
    l.TextXAlignment    = Enum.TextXAlignment.Left
    l.Parent            = parent
    return l
end

colLbl(colHeader, "#",           0,   6,  0.06)
colLbl(colHeader, "Jugador",     0.06, 0, 0.38)
colLbl(colHeader, "Esta semana", 0.44, 0, 0.26)
colLbl(colHeader, "Total",       0.70, 0, 0.18)
colLbl(colHeader, "Base",        0.88, 0, 0.12)

-- Rows container
local rowContainer = Instance.new("ScrollingFrame")
rowContainer.Name                 = "Rows"
rowContainer.Size                 = UDim2.new(1, -16, 1, -100)
rowContainer.Position             = UDim2.new(0, 8, 0, 92)
rowContainer.BackgroundTransparency = 1
rowContainer.BorderSizePixel      = 0
rowContainer.ScrollBarThickness   = 5
rowContainer.CanvasSize           = UDim2.new(0, 0, 0, 0)
rowContainer.AutomaticCanvasSize  = Enum.AutomaticSize.Y
rowContainer.Parent               = panel

local rowLayout = Instance.new("UIListLayout")
rowLayout.Padding   = UDim.new(0, 3)
rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
rowLayout.Parent    = rowContainer

-- ── Data helpers ───────────────────────────────────────────────────────

local function getLeaderstatValue(player: Player, statName: string): number
    local ls = player:FindFirstChild("leaderstats")
    if not ls then return 0 end
    local v = ls:FindFirstChild(statName)
    return v and v.Value or 0
end

local function collectRows(): { { player: Player, weekly: number, total: number, base: number } }
    local rows = {}
    for _, p in ipairs(Players:GetPlayers()) do
        table.insert(rows, {
            player = p,
            weekly = getLeaderstatValue(p, "SemanaCapturas"),
            total  = getLeaderstatValue(p, "Capturas"),
            base   = getLeaderstatValue(p, "BaseNivel"),
        })
    end
    -- Sort: weekly desc, total desc as tiebreaker
    table.sort(rows, function(a, b)
        if a.weekly ~= b.weekly then return a.weekly > b.weekly end
        return a.total > b.total
    end)
    return rows
end

-- ── Render ────────────────────────────────────────────────────────────

local function renderRows()
    -- Clear existing rows
    for _, c in ipairs(rowContainer:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end

    local rows = collectRows()

    for i, entry in ipairs(rows) do
        local row = Instance.new("Frame")
        row.Name             = "Row_" .. i
        row.Size             = UDim2.new(1, 0, 0, 40)
        row.BackgroundColor3 = (i % 2 == 0) and C.rowAlt or C.row
        row.BorderSizePixel  = 0
        row.LayoutOrder      = i
        row.Parent           = rowContainer
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 7)

        -- Highlight local player
        if entry.player == Player then
            row.BackgroundColor3 = Color3.fromRGB(30, 50, 30)
        end

        -- Rank
        local rankLbl = Instance.new("TextLabel")
        rankLbl.Size              = UDim2.new(0.06, 0, 1, 0)
        rankLbl.Position          = UDim2.new(0, 6, 0, 0)
        rankLbl.BackgroundTransparency = 1
        rankLbl.Text              = tostring(i)
        rankLbl.TextColor3        = RANK_COLORS[i] or C.dim
        rankLbl.TextScaled        = true
        rankLbl.Font              = Enum.Font.GothamBold
        rankLbl.TextXAlignment    = Enum.TextXAlignment.Left
        rankLbl.Parent            = row

        -- Name
        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size              = UDim2.new(0.38, 0, 1, 0)
        nameLbl.Position          = UDim2.new(0.06, 0, 0, 0)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text              = entry.player.DisplayName
        nameLbl.TextColor3        = (entry.player == Player) and C.green or C.white
        nameLbl.TextScaled        = true
        nameLbl.Font              = Enum.Font.Gotham
        nameLbl.TextXAlignment    = Enum.TextXAlignment.Left
        nameLbl.Parent            = row

        -- Weekly score
        local weeklyLbl = Instance.new("TextLabel")
        weeklyLbl.Size              = UDim2.new(0.26, 0, 1, 0)
        weeklyLbl.Position          = UDim2.new(0.44, 0, 0, 0)
        weeklyLbl.BackgroundTransparency = 1
        weeklyLbl.Text              = tostring(entry.weekly)
        weeklyLbl.TextColor3        = C.accent
        weeklyLbl.TextScaled        = true
        weeklyLbl.Font              = Enum.Font.GothamBold
        weeklyLbl.TextXAlignment    = Enum.TextXAlignment.Left
        weeklyLbl.Parent            = row

        -- Total captures
        local totalLbl = Instance.new("TextLabel")
        totalLbl.Size              = UDim2.new(0.18, 0, 1, 0)
        totalLbl.Position          = UDim2.new(0.70, 0, 0, 0)
        totalLbl.BackgroundTransparency = 1
        totalLbl.Text              = tostring(entry.total)
        totalLbl.TextColor3        = C.white
        totalLbl.TextScaled        = true
        totalLbl.Font              = Enum.Font.Gotham
        totalLbl.TextXAlignment    = Enum.TextXAlignment.Left
        totalLbl.Parent            = row

        -- Base level
        local baseLbl = Instance.new("TextLabel")
        baseLbl.Size              = UDim2.new(0.12, 0, 1, 0)
        baseLbl.Position          = UDim2.new(0.88, 0, 0, 0)
        baseLbl.BackgroundTransparency = 1
        baseLbl.Text              = "Lv" .. entry.base
        baseLbl.TextColor3        = C.dim
        baseLbl.TextScaled        = true
        baseLbl.Font              = Enum.Font.Gotham
        baseLbl.TextXAlignment    = Enum.TextXAlignment.Left
        baseLbl.Parent            = row
    end
end

-- ── HUD button ─────────────────────────────────────────────────────────

local function addLeaderboardButton()
    local hud = PlayerGui:WaitForChild("WorldCupHUD", 10)
    if not hud then return end

    local lbBtn = Instance.new("TextButton")
    lbBtn.Name            = "LeaderboardBtn"
    lbBtn.Size            = UDim2.new(0, 50, 0, 48)
    lbBtn.Position        = UDim2.new(1, -480, 1, -64)
    lbBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 60)
    lbBtn.BorderSizePixel = 0
    lbBtn.Text            = "🏆"
    lbBtn.TextColor3      = C.accent
    lbBtn.TextScaled      = true
    lbBtn.Font            = Enum.Font.GothamBold
    lbBtn.Parent          = hud
    Instance.new("UICorner", lbBtn).CornerRadius = UDim.new(0, 8)

    lbBtn.MouseButton1Click:Connect(function()
        local open = not lbGui.Enabled
        lbGui.Enabled = open
        if open then renderRows() end
    end)
end

-- ── Init ──────────────────────────────────────────────────────────────

function LeaderboardController.OnStart()
    closeBtn.MouseButton1Click:Connect(function()
        lbGui.Enabled = false
    end)

    task.spawn(addLeaderboardButton)

    -- Auto-refresh while open
    local elapsed = 0
    RunService.Heartbeat:Connect(function(dt)
        if not lbGui.Enabled then return end
        elapsed += dt
        if elapsed >= REFRESH_HZ then
            elapsed = 0
            renderRows()
        end
    end)

    -- Update leaderstats sync: refresh when capture event fires for local player
    Remotes.CaptureResult:Connect(function(result)
        if result.success == true then
            -- Small delay to let server update leaderstats first
            task.delay(0.5, function()
                if lbGui.Enabled then renderRows() end
            end)
        end
    end)
end

return LeaderboardController
