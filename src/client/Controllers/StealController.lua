local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")

local Remotes   = require(ReplicatedStorage.Remotes)
local ZoneUtils = require(ReplicatedStorage.Modules.ZoneUtils)
local UIController = require(script.Parent.UIController)

local Player    = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- ── Constants ─────────────────────────────────────────────────────────
local STEAL_SHOW_RANGE = 10   -- studs: show steal prompt within this distance
local PROXIMITY_HZ     = 0.25 -- seconds between proximity checks

-- ── State ─────────────────────────────────────────────────────────────
local nearestTarget: Player? = nil
local stealInProgress = false
local stealCooldown   = false

local StealController = {}

-- ── Steal prompt UI ────────────────────────────────────────────────────

local stealFrame = Instance.new("Frame")
stealFrame.Name             = "StealPromptFrame"
stealFrame.Size             = UDim2.new(0, 320, 0, 64)
stealFrame.Position         = UDim2.new(0.5, -160, 1, -198)  -- above capture prompt
stealFrame.BackgroundColor3 = Color3.fromRGB(160, 80, 10)
stealFrame.BackgroundTransparency = 0.1
stealFrame.BorderSizePixel  = 0
stealFrame.Visible          = false
stealFrame.Parent           = PlayerGui:WaitForChild("WorldCupHUD", 10) or PlayerGui
Instance.new("UICorner", stealFrame).CornerRadius = UDim.new(0, 10)

local stealLabel = Instance.new("TextLabel")
stealLabel.Size              = UDim2.fromScale(1, 0.55)
stealLabel.BackgroundTransparency = 1
stealLabel.Text              = "🃏 G para robar"
stealLabel.TextColor3        = Color3.new(1, 1, 1)
stealLabel.TextScaled        = true
stealLabel.Font              = Enum.Font.GothamBold
stealLabel.Parent            = stealFrame

local stealBarBg = Instance.new("Frame")
stealBarBg.Name             = "StealBarBg"
stealBarBg.Size             = UDim2.new(0.9, 0, 0.25, 0)
stealBarBg.Position         = UDim2.new(0.05, 0, 0.72, 0)
stealBarBg.BackgroundColor3 = Color3.fromRGB(60, 30, 0)
stealBarBg.BorderSizePixel  = 0
stealBarBg.Visible          = false
stealBarBg.Parent           = stealFrame
Instance.new("UICorner", stealBarBg).CornerRadius = UDim.new(0.5, 0)

local stealBar = Instance.new("Frame")
stealBar.Name               = "StealBar"
stealBar.Size               = UDim2.fromScale(0, 1)
stealBar.BackgroundColor3   = Color3.fromRGB(255, 140, 0)
stealBar.BorderSizePixel    = 0
stealBar.Parent             = stealBarBg
Instance.new("UICorner", stealBar).CornerRadius = UDim.new(0.5, 0)

-- ── Victim warning UI ──────────────────────────────────────────────────

local victimGui = Instance.new("ScreenGui")
victimGui.Name           = "StealVictimWarning"
victimGui.ResetOnSpawn   = false
victimGui.Enabled        = false
victimGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
victimGui.Parent         = PlayerGui

local victimFrame = Instance.new("Frame")
victimFrame.Size             = UDim2.new(0, 440, 0, 80)
victimFrame.Position         = UDim2.new(0.5, -220, 0, 100)
victimFrame.BackgroundColor3 = Color3.fromRGB(160, 0, 0)
victimFrame.BackgroundTransparency = 0.1
victimFrame.BorderSizePixel  = 0
victimFrame.Parent           = victimGui
Instance.new("UICorner", victimFrame).CornerRadius = UDim.new(0, 12)

local victimLabel = Instance.new("TextLabel")
victimLabel.Size              = UDim2.fromScale(1, 0.55)
victimLabel.BackgroundTransparency = 1
victimLabel.Text              = "⚠ ¡Te están robando! ¡Corré a tu base!"
victimLabel.TextColor3        = Color3.new(1, 1, 1)
victimLabel.TextScaled        = true
victimLabel.Font              = Enum.Font.GothamBold
victimLabel.Parent            = victimFrame

local victimTimerLbl = Instance.new("TextLabel")
victimTimerLbl.Size              = UDim2.new(1, 0, 0.4, 0)
victimTimerLbl.Position          = UDim2.fromScale(0, 0.6)
victimTimerLbl.BackgroundTransparency = 1
victimTimerLbl.Text              = ""
victimTimerLbl.TextColor3        = Color3.fromRGB(255, 200, 100)
victimTimerLbl.TextScaled        = true
victimTimerLbl.Font              = Enum.Font.Gotham
victimTimerLbl.Parent            = victimFrame

-- ── Helpers ───────────────────────────────────────────────────────────

local function getHRP(p: Player): BasePart?
    local char = p.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function showStealPrompt(target: Player)
    stealLabel.Text    = "🃏 G para robar a " .. target.DisplayName
    stealBarBg.Visible = false
    stealBar.Size      = UDim2.fromScale(0, 1)
    stealFrame.Visible = true
end

local function hideStealPrompt()
    stealFrame.Visible = false
    stealBarBg.Visible = false
end

local function startStealBar(duration: number)
    stealLabel.Text    = "🃏 Robando..."
    stealBarBg.Visible = true
    stealBar.Size      = UDim2.fromScale(0, 1)
    TweenService:Create(stealBar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
        Size = UDim2.fromScale(1, 1)
    }):Play()
end

local function stopStealBar()
    stealBarBg.Visible = false
    stealBar.Size      = UDim2.fromScale(0, 1)
end

-- ── Proximity loop ─────────────────────────────────────────────────────

local function proximityLoop()
    local elapsed = 0
    RunService.Heartbeat:Connect(function(dt)
        elapsed += dt
        if elapsed < PROXIMITY_HZ then return end
        elapsed = 0

        if stealInProgress then return end

        local myHRP = getHRP(Player)
        if not myHRP then
            if nearestTarget then
                nearestTarget = nil
                hideStealPrompt()
            end
            return
        end

        -- Only show steal prompt if local player is in DangerZone
        if ZoneUtils.isPlayerSafe(Player) then
            if nearestTarget then
                nearestTarget = nil
                hideStealPrompt()
            end
            return
        end

        local myPos   = myHRP.Position
        local bestDist = STEAL_SHOW_RANGE + 1
        local best: Player? = nil

        for _, p in ipairs(Players:GetPlayers()) do
            if p == Player then continue end
            local hrp = getHRP(p)
            if not hrp then continue end
            local dist = (hrp.Position - myPos).Magnitude
            if dist < bestDist then
                -- Don't show prompt if target is in their own safe zone
                if not ZoneUtils.isPlayerSafe(p) then
                    bestDist = dist
                    best = p
                end
            end
        end

        if best ~= nearestTarget then
            nearestTarget = best
            if best then
                showStealPrompt(best)
            else
                hideStealPrompt()
            end
        end
    end)
end

-- ── Input ─────────────────────────────────────────────────────────────

local function onKeyDown(input: InputObject, processed: boolean)
    if processed then return end
    if input.KeyCode ~= Enum.KeyCode.G then return end
    if stealInProgress or stealCooldown then return end
    if not nearestTarget then return end

    stealInProgress = true
    hideStealPrompt()
    Remotes.RequestSteal:FireServer(nearestTarget.UserId)
end

-- ── Init ──────────────────────────────────────────────────────────────

function StealController.OnStart()
    proximityLoop()
    UserInputService.InputBegan:Connect(onKeyDown)

    -- StealResult: fired to both thief and victim with different payloads
    Remotes.StealResult:Connect(function(result)
        if result.success == nil then
            -- Steal started (we are the thief)
            startStealBar(result.duration or 5)

        elseif result.success == true then
            -- We successfully stole a card
            stealInProgress = false
            stealCooldown   = true
            stopStealBar()
            hideStealPrompt()
            local cardName = result.stolenCard and result.stolenCard.cardId or "carta"
            UIController.showNotification("success",
                "🃏 ¡Robaste " .. cardName .. " a " .. (result.victimName or "alguien") .. "!")
            task.delay(5, function() stealCooldown = false end)

        elseif result.success == false then
            stealInProgress = false
            stopStealBar()
            hideStealPrompt()

            if result.reason == "stolen" then
                -- We are the VICTIM — handled by StealAttemptNotify + Notification
                return
            end

            -- We are the thief and failed
            local msgs = {
                cooldown         = "⏳ Esperá antes de robar de nuevo.",
                too_far          = "Acercate más para robar.",
                thief_moved      = "Te alejaste demasiado.",
                victim_escaped   = "¡La víctima escapó a su base!",
                victim_safe_zone = "Esa persona está en zona segura.",
                thief_safe_zone  = "No podés robar desde zona segura.",
                victim_in_base   = "Esa persona está en su base.",
                no_cards         = "Esa persona no tiene cartas sin asegurar.",
                already_targeted = "Alguien ya está robando a esa persona.",
                victim_shielded  = "Esa persona tiene escudo activo.",
                target_not_found = "Jugador no encontrado.",
            }
            local msg = msgs[result.reason or ""] or ("Robo fallido: " .. (result.reason or ""))
            UIController.showNotification("warning", "❌ " .. msg)

            stealCooldown = true
            task.delay(3, function() stealCooldown = false end)
        end
    end)

    -- StealAttemptNotify: we are the VICTIM
    Remotes.StealAttemptNotify:Connect(function(info)
        victimGui.Enabled = true
        victimLabel.Text  = "⚠ ¡" .. (info.thiefName or "Alguien") .. " te está robando! ¡Corré a tu base!"

        -- Countdown timer for victim
        local timeLeft = info.duration or 5
        task.spawn(function()
            while timeLeft > 0 and victimGui.Enabled do
                victimTimerLbl.Text = "Tiempo: " .. math.ceil(timeLeft) .. "s"
                task.wait(0.25)
                timeLeft -= 0.25
            end
            victimGui.Enabled = false
            victimTimerLbl.Text = ""
        end)

        -- Auto-hide after duration + 1s buffer
        task.delay((info.duration or 5) + 1, function()
            victimGui.Enabled = false
        end)
    end)
end

return StealController
