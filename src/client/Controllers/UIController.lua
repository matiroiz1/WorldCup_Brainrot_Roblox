local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local Remotes = require(ReplicatedStorage.Remotes)

local Player    = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- ── Shared UI state ───────────────────────────────────────────────────
local UIController = {}

-- ── HUD ScreenGui ─────────────────────────────────────────────────────

local function makeLabel(parent, name, text, pos, size, bgColor, textColor, fontSize)
    local frame = Instance.new("Frame")
    frame.Name            = name .. "Frame"
    frame.Size            = size or UDim2.new(0, 160, 0, 44)
    frame.Position        = pos
    frame.BackgroundColor3 = bgColor or Color3.fromRGB(20, 20, 20)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Parent          = parent
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Name              = name
    lbl.Size              = UDim2.fromScale(1, 1)
    lbl.BackgroundTransparency = 1
    lbl.Text              = text
    lbl.TextColor3        = textColor or Color3.new(1, 1, 1)
    lbl.TextScaled        = true
    lbl.Font              = Enum.Font.GothamBold
    lbl.Parent            = frame
    return lbl, frame
end

local function makeButton(parent, name, text, pos, size, bgColor)
    local btn = Instance.new("TextButton")
    btn.Name              = name
    btn.Size              = size or UDim2.new(0, 130, 0, 44)
    btn.Position          = pos
    btn.BackgroundColor3  = bgColor or Color3.fromRGB(40, 100, 200)
    btn.BorderSizePixel   = 0
    btn.Text              = text
    btn.TextColor3        = Color3.new(1, 1, 1)
    btn.TextScaled        = true
    btn.Font              = Enum.Font.GothamBold
    btn.Parent            = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    return btn
end

-- Build HUD
local hud = Instance.new("ScreenGui")
hud.Name            = "WorldCupHUD"
hud.ResetOnSpawn    = false
hud.IgnoreGuiInset  = true
hud.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
hud.Parent          = PlayerGui

-- Coins
local coinsLabel, coinsFrame = makeLabel(
    hud, "CoinsLabel", "🪙 0",
    UDim2.new(0, 12, 0, 12),
    UDim2.new(0, 160, 0, 44),
    Color3.fromRGB(180, 130, 10),
    Color3.fromRGB(255, 240, 180)
)

-- Event tokens
local tokensLabel, tokensFrame = makeLabel(
    hud, "TokensLabel", "🎟 0",
    UDim2.new(0, 12, 0, 62),
    UDim2.new(0, 160, 0, 44),
    Color3.fromRGB(30, 60, 160),
    Color3.fromRGB(200, 220, 255)
)

-- Base level (top-left, below tokens)
local baseLevelLabel, _ = makeLabel(
    hud, "BaseLevelLabel", "🏠 Base Lv.1",
    UDim2.new(0, 12, 0, 112),
    UDim2.new(0, 160, 0, 36),
    Color3.fromRGB(30, 100, 30),
    Color3.fromRGB(200, 255, 200)
)

-- Capture prompt (center-bottom, hidden by default)
local captureFrame = Instance.new("Frame")
captureFrame.Name              = "CapturePromptFrame"
captureFrame.Size              = UDim2.new(0, 320, 0, 64)
captureFrame.Position          = UDim2.new(0.5, -160, 1, -120)
captureFrame.BackgroundColor3  = Color3.fromRGB(180, 20, 20)
captureFrame.BackgroundTransparency = 0.1
captureFrame.BorderSizePixel   = 0
captureFrame.Visible           = false
captureFrame.Parent            = hud
Instance.new("UICorner", captureFrame).CornerRadius = UDim.new(0, 10)

local captureLabel = Instance.new("TextLabel")
captureLabel.Name              = "CaptureLabel"
captureLabel.Size              = UDim2.fromScale(1, 0.6)
captureLabel.Position          = UDim2.fromScale(0, 0)
captureLabel.BackgroundTransparency = 1
captureLabel.Text              = "⚡ Presioná E para capturar"
captureLabel.TextColor3        = Color3.new(1, 1, 1)
captureLabel.TextScaled        = true
captureLabel.Font              = Enum.Font.GothamBold
captureLabel.Parent            = captureFrame

local captureBarBg = Instance.new("Frame")
captureBarBg.Name              = "CaptureBarBg"
captureBarBg.Size              = UDim2.new(0.9, 0, 0.25, 0)
captureBarBg.Position          = UDim2.new(0.05, 0, 0.72, 0)
captureBarBg.BackgroundColor3  = Color3.fromRGB(60, 0, 0)
captureBarBg.BorderSizePixel   = 0
captureBarBg.Visible           = false
captureBarBg.Parent            = captureFrame
Instance.new("UICorner", captureBarBg).CornerRadius = UDim.new(0.5, 0)

local captureBar = Instance.new("Frame")
captureBar.Name               = "CaptureBar"
captureBar.Size               = UDim2.fromScale(0, 1)
captureBar.BackgroundColor3   = Color3.fromRGB(255, 220, 0)
captureBar.BorderSizePixel    = 0
captureBar.Parent             = captureBarBg
Instance.new("UICorner", captureBar).CornerRadius = UDim.new(0.5, 0)

-- Inventory + Album buttons (bottom-right)
local inventoryBtn = makeButton(
    hud, "InventoryBtn", "🎴 Inventario",
    UDim2.new(1, -278, 1, -64),
    UDim2.new(0, 130, 0, 48),
    Color3.fromRGB(40, 100, 200)
)

local albumBtn = makeButton(
    hud, "AlbumBtn", "📋 Álbum",
    UDim2.new(1, -138, 1, -64),
    UDim2.new(0, 130, 0, 48),
    Color3.fromRGB(180, 100, 10)
)

-- Notification toast (top-center)
local notifFrame = Instance.new("Frame")
notifFrame.Name              = "NotifFrame"
notifFrame.Size              = UDim2.new(0, 380, 0, 60)
notifFrame.Position          = UDim2.new(0.5, -190, 0, -70)
notifFrame.BackgroundColor3  = Color3.fromRGB(20, 20, 20)
notifFrame.BackgroundTransparency = 0.1
notifFrame.BorderSizePixel   = 0
notifFrame.ClipsDescendants  = true
notifFrame.Parent            = hud
Instance.new("UICorner", notifFrame).CornerRadius = UDim.new(0, 10)

local notifLabel = Instance.new("TextLabel")
notifLabel.Name              = "NotifLabel"
notifLabel.Size              = UDim2.fromScale(1, 1)
notifLabel.BackgroundTransparency = 1
notifLabel.Text              = ""
notifLabel.TextColor3        = Color3.new(1, 1, 1)
notifLabel.TextScaled        = true
notifLabel.Font              = Enum.Font.GothamBold
notifLabel.Parent            = notifFrame

local NOTIF_COLORS = {
    info    = Color3.fromRGB(30, 80, 180),
    success = Color3.fromRGB(20, 140, 60),
    warning = Color3.fromRGB(180, 120, 10),
    error   = Color3.fromRGB(160, 20, 20),
    event   = Color3.fromRGB(120, 20, 180),
}

-- ── Public API ────────────────────────────────────────────────────────

function UIController.updateCoins(amount: number)
    coinsLabel.Text = "🪙 " .. tostring(amount)
end

function UIController.updateTokens(amount: number)
    tokensLabel.Text = "🎟 " .. tostring(amount)
end

function UIController.updateBaseLevel(level: number)
    baseLevelLabel.Text = "🏠 Base Lv." .. tostring(level)
end

local notifQueue: { thread } = {}

function UIController.showNotification(notifType: string, message: string)
    -- Cancel previous slide-out if pending
    for _, t in ipairs(notifQueue) do
        task.cancel(t)
    end
    notifQueue = {}

    notifFrame.BackgroundColor3 = NOTIF_COLORS[notifType] or NOTIF_COLORS.info
    notifLabel.Text = message

    -- Slide in
    TweenService:Create(notifFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -190, 0, 12)
    }):Play()

    -- Auto slide out after 3s
    local t = task.delay(3, function()
        TweenService:Create(notifFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, -190, 0, -70)
        }):Play()
    end)
    table.insert(notifQueue, t)
end

function UIController.showCapturePrompt(brainrotName: string)
    captureLabel.Text = "⚡ E para capturar: " .. brainrotName
    captureBarBg.Visible = false
    captureFrame.Visible = true
end

function UIController.hideCapturePrompt()
    captureFrame.Visible = false
    captureBarBg.Visible = false
end

-- Shows animated progress bar during active capture hold
local captureBarThread: thread?
function UIController.startCaptureBar(duration: number)
    if captureBarThread then task.cancel(captureBarThread) end
    captureBarBg.Visible = true
    captureBar.Size      = UDim2.fromScale(0, 1)
    captureLabel.Text    = "⏳ Capturando..."
    TweenService:Create(captureBar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
        Size = UDim2.fromScale(1, 1)
    }):Play()
end

function UIController.stopCaptureBar()
    if captureBarThread then task.cancel(captureBarThread) end
    captureBarBg.Visible = false
    captureBar.Size      = UDim2.fromScale(0, 1)
end

-- Expose button references so InventoryController can wire them
UIController.InventoryButton = inventoryBtn
UIController.AlbumButton     = albumBtn

-- ── Remote listeners ──────────────────────────────────────────────────

function UIController.OnStart()
    Remotes.CoinsUpdated:Connect(function(amount: number)
        UIController.updateCoins(amount)
    end)

    Remotes.TokensUpdated:Connect(function(amount: number)
        UIController.updateTokens(amount)
    end)

    Remotes.PlayerDataLoaded:Connect(function(data)
        UIController.updateCoins(data.coins or 0)
        UIController.updateTokens(data.eventTokens or 0)
    end)

    Remotes.BaseAssigned:Connect(function(info)
        UIController.updateBaseLevel(info.baseLevel or 1)
    end)

    Remotes.BaseUpgraded:Connect(function(info)
        UIController.updateBaseLevel(info.baseLevel or 1)
        UIController.showNotification("success", "🏠 Base mejorada a nivel " .. info.baseLevel .. "!")
    end)

    Remotes.Notification:Connect(function(notif)
        UIController.showNotification(notif.type or "info", notif.message or "")
    end)

    -- Capture result feedback
    Remotes.CaptureResult:Connect(function(result)
        if result.success == true then
            UIController.stopCaptureBar()
            local msg = "✅ ¡Capturado!"
            if result.cardId then
                msg = msg .. " Carta: " .. result.cardId
            end
            if result.coins then
                msg = msg .. " +" .. result.coins .. " 🪙"
            end
            UIController.showNotification("success", msg)
        elseif result.success == false then
            UIController.stopCaptureBar()
            local reasons = {
                out_of_range   = "Te alejaste demasiado.",
                cooldown       = "Esperá un momento.",
                already_captured = "Ya fue capturado.",
                too_far        = "Muy lejos del brainrot.",
                not_found      = "El brainrot desapareció.",
            }
            UIController.showNotification("error", "❌ " .. (reasons[result.reason] or "Falló la captura."))
        elseif result.success == nil and result.duration then
            -- Capture started
            UIController.startCaptureBar(result.duration)
        end
    end)
end

return UIController
