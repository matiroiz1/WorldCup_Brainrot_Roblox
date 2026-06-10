local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local Workspace         = game:GetService("Workspace")

local Remotes       = require(ReplicatedStorage.Remotes)
local UIController  = require(script.Parent.UIController)

local Player = Players.LocalPlayer

-- ── Constants ─────────────────────────────────────────────────────────
local CAPTURE_RANGE      = 15   -- studs: show prompt when this close
local PROXIMITY_CHECK_HZ = 0.25 -- seconds between proximity checks

-- ── State ─────────────────────────────────────────────────────────────
-- TrackedBrainrots[instanceId] = { name, defId, rarity }
local TrackedBrainrots: { [string]: any } = {}

-- Current nearest brainrot instanceId (nil = none in range)
local nearestInstanceId: string? = nil

local MapController = {}

-- ── Helpers ───────────────────────────────────────────────────────────

local function getPlayerHRP(): BasePart?
    local char = Player.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function getBrainrotHRP(instanceId: string): BasePart?
    local model = Workspace:FindFirstChild("BrainrotNPC_" .. instanceId)
    if not model then return nil end
    return (model :: Model):FindFirstChild("HumanoidRootPart") :: BasePart?
end

-- ── Proximity loop ────────────────────────────────────────────────────

local function proximityLoop()
    local elapsed = 0

    RunService.Heartbeat:Connect(function(dt)
        elapsed += dt
        if elapsed < PROXIMITY_CHECK_HZ then return end
        elapsed = 0

        local hrp = getPlayerHRP()
        if not hrp then
            if nearestInstanceId then
                nearestInstanceId = nil
                UIController.hideCapturePrompt()
            end
            return
        end

        local playerPos   = hrp.Position
        local bestDist    = CAPTURE_RANGE + 1
        local bestId: string? = nil
        local bestName          = ""

        for instanceId, info in pairs(TrackedBrainrots) do
            local npcHRP = getBrainrotHRP(instanceId)
            if npcHRP then
                local dist = (npcHRP.Position - playerPos).Magnitude
                if dist < bestDist then
                    bestDist = dist
                    bestId   = instanceId
                    bestName = info.name
                end
            else
                -- Model is gone (despawned), clean up tracking
                TrackedBrainrots[instanceId] = nil
            end
        end

        if bestId ~= nearestInstanceId then
            nearestInstanceId = bestId
            if bestId then
                UIController.showCapturePrompt(bestName)
            else
                UIController.hideCapturePrompt()
            end
        end
    end)
end

-- ── Input ─────────────────────────────────────────────────────────────

local captureCooldown = false

local function onKeyDown(input: InputObject, processed: boolean)
    if processed then return end
    if input.KeyCode ~= Enum.KeyCode.E then return end
    if not nearestInstanceId then return end
    if captureCooldown then return end

    captureCooldown = true
    Remotes.RequestCapture:FireServer(nearestInstanceId)

    -- Block re-fire for 3s (matches server cooldown)
    task.delay(3, function()
        captureCooldown = false
    end)
end

-- ── Init ──────────────────────────────────────────────────────────────

function MapController.OnStart()
    -- Track brainrots spawned while we're in the server
    Remotes.BrainrotSpawned:Connect(function(info)
        TrackedBrainrots[info.instanceId] = {
            name   = info.name,
            defId  = info.defId,
            rarity = info.rarity,
        }
    end)

    Remotes.BrainrotDespawned:Connect(function(info)
        TrackedBrainrots[info.instanceId] = nil
        if nearestInstanceId == info.instanceId then
            nearestInstanceId = nil
            UIController.hideCapturePrompt()
        end
    end)

    -- Key input
    UserInputService.InputBegan:Connect(onKeyDown)

    -- Start proximity polling
    proximityLoop()
end

return MapController
