local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local Remotes = require(ReplicatedStorage.Remotes)

local Player    = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- ── State ──────────────────────────────────────────────────────────────
local activeEvents: { [string]: boolean } = {}

local EventController = {}

-- ── Drop boost HUD badge ───────────────────────────────────────────────

local boostBadge: Frame? = nil

local function showBoostBadge()
    if boostBadge then return end

    local hud = PlayerGui:FindFirstChild("WorldCupHUD")
    if not hud then return end

    local badge = Instance.new("Frame")
    badge.Name             = "DropBoostBadge"
    badge.Size             = UDim2.new(0, 180, 0, 36)
    badge.Position         = UDim2.new(0, 12, 0, 158)
    badge.BackgroundColor3 = Color3.fromRGB(180, 70, 0)
    badge.BackgroundTransparency = 0.1
    badge.BorderSizePixel  = 0
    badge.Parent           = hud
    Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Size              = UDim2.fromScale(1, 1)
    lbl.BackgroundTransparency = 1
    lbl.Text              = "🔥 Drop Boost +50%"
    lbl.TextColor3        = Color3.fromRGB(255, 220, 120)
    lbl.TextScaled        = true
    lbl.Font              = Enum.Font.GothamBold
    lbl.Parent            = badge

    -- Pulse animation
    task.spawn(function()
        while badge and badge.Parent do
            TweenService:Create(badge, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                BackgroundTransparency = 0.35
            }):Play()
            task.wait(0.8)
            TweenService:Create(badge, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                BackgroundTransparency = 0.1
            }):Play()
            task.wait(0.8)
        end
    end)

    boostBadge = badge
end

local function hideBoostBadge()
    if boostBadge then
        boostBadge:Destroy()
        boostBadge = nil
    end
end

-- ── Active event banner ────────────────────────────────────────────────

local eventBannerGui: ScreenGui? = nil

local function showEventBanner(eventType: string, message: string, durationSeconds: number)
    -- Remove any existing banner
    if eventBannerGui then eventBannerGui:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name           = "EventBanner"
    gui.ResetOnSpawn   = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent         = PlayerGui
    eventBannerGui     = gui

    local banner = Instance.new("Frame")
    banner.Size             = UDim2.new(0, 560, 0, 72)
    banner.Position         = UDim2.new(0.5, -280, 0, -80)
    banner.BackgroundTransparency = 0.08
    banner.BorderSizePixel  = 0
    banner.Parent           = gui

    local bgColor = Color3.fromRGB(120, 30, 160)
    if eventType == "EliteSpawn" then
        bgColor = Color3.fromRGB(60, 20, 140)
    elseif eventType == "LegendarySpawn" then
        bgColor = Color3.fromRGB(160, 120, 0)
    elseif eventType == "DropBoost" then
        bgColor = Color3.fromRGB(160, 70, 0)
    end
    banner.BackgroundColor3 = bgColor
    Instance.new("UICorner", banner).CornerRadius = UDim.new(0, 12)

    local lbl = Instance.new("TextLabel")
    lbl.Size              = UDim2.fromScale(1, 1)
    lbl.BackgroundTransparency = 1
    lbl.Text              = message
    lbl.TextColor3        = Color3.new(1, 1, 1)
    lbl.TextScaled        = true
    lbl.Font              = Enum.Font.GothamBold
    lbl.Parent            = banner

    -- Slide in
    local slideIn = TweenService:Create(banner, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -280, 0, 16)
    })
    slideIn:Play()

    -- Auto slide out after 6s
    task.delay(6, function()
        if banner and banner.Parent then
            TweenService:Create(banner, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.new(0.5, -280, 0, -80)
            }):Play()
            task.delay(0.35, function()
                if gui and gui.Parent then gui:Destroy() end
                if eventBannerGui == gui then eventBannerGui = nil end
            end)
        end
    end)
end

-- ── Init ──────────────────────────────────────────────────────────────

function EventController.OnStart()
    Remotes.EventStarted:Connect(function(info)
        local eventType = info.eventType or "Unknown"
        activeEvents[eventType] = true

        showEventBanner(eventType, info.message or "", info.durationSeconds or 0)

        if eventType == "DropBoost" then
            showBoostBadge()
        end
    end)

    Remotes.EventEnded:Connect(function(info)
        local eventType = info.eventType or "Unknown"
        activeEvents[eventType] = nil

        if eventType == "DropBoost" then
            hideBoostBadge()
        end
    end)
end

return EventController
