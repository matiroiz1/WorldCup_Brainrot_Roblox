local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")

local Remotes   = require(ReplicatedStorage.Remotes)
local Brainrots = require(ReplicatedStorage.Config.Brainrots)
local Economy   = require(ReplicatedStorage.Config.Economy)

-- ── Constants ─────────────────────────────────────────────────────────

local FLEE_RANGE     = 20   -- studs: brainrot starts fleeing when player is this close
local WANDER_RADIUS  = 45   -- max studs from spawn point for wander movement
local AI_TICK        = 0.5  -- seconds between AI decisions

local RARITY_COLORS = {
    Common    = BrickColor.new("Medium stone grey"),
    Rare      = BrickColor.new("Bright blue"),
    Elite     = BrickColor.new("Royal purple"),
    Legendary = BrickColor.new("Bright yellow"),
    Chaotic   = BrickColor.new("Bright orange"),
}

local WALK_SPEEDS = {
    Common    = 10,
    Rare      = 14,
    Elite     = 18,
    Legendary = 22,
    Chaotic   = 16,
}

-- ── State ─────────────────────────────────────────────────────────────

-- ActiveBrainrots[instanceId] = { defId, model, spawnPos, beingCaptured, capturedBy }
local ActiveBrainrots: { [string]: any } = {}
-- AiTasks[instanceId] = thread (so we can cancel on despawn)
local AiTasks: { [string]: thread } = {}

local spawnPoints: { Vector3 } = {}

local BrainrotSpawnService = {}

-- ── Spawn point collection ────────────────────────────────────────────

local function collectSpawnPoints()
    local map = Workspace:FindFirstChild("Map")
    if not map then return end
    local folder = map:FindFirstChild("BrainrotSpawns")
    if not folder then return end
    for _, part in ipairs(folder:GetChildren()) do
        if part:IsA("BasePart") then
            table.insert(spawnPoints, part.Position + Vector3.new(0, 3, 0))
        end
    end
end

-- ── NPC model creation ────────────────────────────────────────────────
-- Placeholder model until real 3D assets are added.
-- When you have actual models: replace this function body,
-- keep the same signature and return a Model with PrimaryPart = HumanoidRootPart.

local function createNPCModel(def: any, position: Vector3): Model
    local assets = ReplicatedStorage:FindFirstChild("Assets")
    local mobsFolder = assets and assets:FindFirstChild("Mobs")
    local template = mobsFolder and mobsFolder:FindFirstChild(def.id)

    local model
    local hrp
    local humanoid

    if template then
        model = template:Clone()
        model.Name = "BrainrotNPC_" .. def.id
        
        hrp = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
        if not hrp then
            hrp = model:FindFirstChildOfClass("BasePart")
        end
        if hrp then
            hrp.CFrame = CFrame.new(position)
            model.PrimaryPart = hrp
        end
        
        humanoid = model:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = WALK_SPEEDS[def.brainrotType] or 12
            humanoid.JumpPower = 0
            humanoid.MaxHealth = 100
            humanoid.Health = 100
            humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        end
    else
        model = Instance.new("Model")
        model.Name  = "BrainrotNPC_" .. def.id

        -- Body
        hrp = Instance.new("Part")
        hrp.Name        = "HumanoidRootPart"
        hrp.Size        = Vector3.new(4, 5, 4)
        hrp.CFrame      = CFrame.new(position)
        hrp.BrickColor  = RARITY_COLORS[def.brainrotType] or BrickColor.new("Medium stone grey")
        hrp.Material    = Enum.Material.SmoothPlastic
        hrp.Anchored    = false
        hrp.CanCollide  = true
        hrp.Parent      = model

        -- Head (visual)
        local head = Instance.new("Part")
        head.Name       = "Head"
        head.Size       = Vector3.new(3.5, 3.5, 3.5)
        head.BrickColor = RARITY_COLORS[def.brainrotType] or BrickColor.new("Medium stone grey")
        head.Material   = Enum.Material.SmoothPlastic
        head.Anchored   = false
        head.CanCollide = false
        head.Parent     = model

        local weld = Instance.new("WeldConstraint")
        weld.Part0  = hrp
        weld.Part1  = head
        weld.Parent = hrp

        head.CFrame = hrp.CFrame * CFrame.new(0, 4.5, 0)

        -- Humanoid (required for MoveTo)
        humanoid = Instance.new("Humanoid")
        humanoid.WalkSpeed     = WALK_SPEEDS[def.brainrotType] or 12
        humanoid.JumpPower     = 0
        humanoid.MaxHealth     = 100
        humanoid.Health        = 100
        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        humanoid.Parent        = model

        model.PrimaryPart = hrp
    end

    -- Add billboard name tag (always useful for clear naming)
    if hrp then
        local bb = Instance.new("BillboardGui")
        bb.Size         = UDim2.new(0, 180, 0, 55)
        bb.StudsOffset  = Vector3.new(0, 5, 0)
        bb.AlwaysOnTop  = false
        bb.Parent       = hrp

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size                 = UDim2.fromScale(1, 0.6)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text                 = def.name
        nameLbl.TextColor3           = Color3.new(1, 1, 1)
        nameLbl.TextScaled           = true
        nameLbl.Font                 = Enum.Font.GothamBold
        nameLbl.TextStrokeTransparency = 0.3
        nameLbl.Parent               = bb

        local rarityLbl = Instance.new("TextLabel")
        rarityLbl.Size               = UDim2.new(1, 0, 0.4, 0)
        rarityLbl.Position           = UDim2.fromScale(0, 0.6)
        rarityLbl.BackgroundTransparency = 1
        rarityLbl.Text               = "[" .. def.brainrotType .. "]"
        rarityLbl.TextColor3         = (RARITY_COLORS[def.brainrotType] or BrickColor.new("White")).Color
        rarityLbl.TextScaled         = true
        rarityLbl.Font               = Enum.Font.Gotham
        rarityLbl.Parent             = bb
    end

    return model
end

-- ── AI loop ───────────────────────────────────────────────────────────

local function getNearestPlayerDistance(position: Vector3): (Player?, number)
    local nearest: Player? = nil
    local nearestDist = math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        local char = player.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local dist = (hrp.Position - position).Magnitude
                if dist < nearestDist then
                    nearestDist = dist
                    nearest = player
                end
            end
        end
    end
    return nearest, nearestDist
end

local function runAI(instanceId: string, def: any, spawnPos: Vector3)
    local lastMoveTime = 0
    local moveCooldown = 4 -- seconds between wander decisions

    while true do
        task.wait(AI_TICK)

        local state = ActiveBrainrots[instanceId]
        if not state then break end -- despawned
        if state.beingCaptured then
            task.wait(0.5)
            continue
        end

        local model    = state.model
        local hrp      = model and model:FindFirstChild("HumanoidRootPart")
        local humanoid = model and model:FindFirstChild("Humanoid")
        if not hrp or not humanoid then break end

        local pos = hrp.Position
        local nearPlayer, nearDist = getNearestPlayerDistance(pos)

        if def.moveStyle == "Flee" or def.moveStyle == "Wander" then
            if def.moveStyle == "Flee" and nearPlayer and nearDist < FLEE_RANGE then
                -- Run away from nearest player
                local playerHrp = nearPlayer.Character and nearPlayer.Character:FindFirstChild("HumanoidRootPart")
                if playerHrp then
                    local awayDir = (pos - playerHrp.Position).Unit
                    local target  = pos + awayDir * 30
                    -- Keep within island bounds (rough clamp)
                    target = Vector3.new(
                        math.clamp(target.X, -320, 320),
                        pos.Y,
                        math.clamp(target.Z, -320, 320)
                    )
                    humanoid:MoveTo(target)
                    lastMoveTime = os.clock()
                end
            elseif os.clock() - lastMoveTime > moveCooldown then
                -- Wander: pick random nearby point
                local angle  = math.random() * math.pi * 2
                local radius = math.random(10, WANDER_RADIUS)
                local target = spawnPos + Vector3.new(
                    math.cos(angle) * radius,
                    0,
                    math.sin(angle) * radius
                )
                target = Vector3.new(
                    math.clamp(target.X, -320, 320),
                    pos.Y,
                    math.clamp(target.Z, -320, 320)
                )
                humanoid:MoveTo(target)
                lastMoveTime = os.clock()
                moveCooldown = math.random(3, 7)
            end
        end
    end
end

-- ── Spawn / Despawn ───────────────────────────────────────────────────

local function generateInstanceId(): string
    return tostring(os.clock()):gsub("%.", "") .. tostring(math.random(1000, 9999))
end

function BrainrotSpawnService.spawnBrainrot(defId: string, position: Vector3?): string?
    local def = Brainrots.getById(defId)
    if not def then
        warn("[BrainrotSpawnService] Unknown defId:", defId)
        return nil
    end

    -- Pick spawn point if position not provided
    if not position then
        if #spawnPoints == 0 then
            warn("[BrainrotSpawnService] No spawn points found")
            return nil
        end
        position = spawnPoints[math.random(1, #spawnPoints)]
    end

    local instanceId = generateInstanceId()
    local model      = createNPCModel(def, position)
    model.Name       = "BrainrotNPC_" .. instanceId  -- client finds model by this name
    model.Parent     = Workspace

    local state = {
        defId         = defId,
        model         = model,
        spawnPos      = position,
        beingCaptured = false,
        capturedBy    = nil,
    }
    ActiveBrainrots[instanceId] = state

    -- Start AI
    local thread = task.spawn(runAI, instanceId, def, position)
    AiTasks[instanceId]  = thread

    -- Notify all clients
    Remotes.BrainrotSpawned:FireAllClients({
        instanceId = instanceId,
        defId      = defId,
        position   = position,
        name       = def.name,
        rarity     = def.brainrotType,
    })

    return instanceId
end

function BrainrotSpawnService.despawnBrainrot(instanceId: string)
    local state = ActiveBrainrots[instanceId]
    if not state then return end

    -- Cancel AI task
    local thread = AiTasks[instanceId]
    if thread then
        task.cancel(thread)
        AiTasks[instanceId] = nil
    end

    -- Destroy model
    if state.model and state.model.Parent then
        state.model:Destroy()
    end

    ActiveBrainrots[instanceId] = nil

    Remotes.BrainrotDespawned:FireAllClients({ instanceId = instanceId })
end

function BrainrotSpawnService.getActive(): { [string]: any }
    return ActiveBrainrots
end

function BrainrotSpawnService.getState(instanceId: string): any?
    return ActiveBrainrots[instanceId]
end

-- Mark a brainrot as being captured (blocks AI fleeing during capture)
function BrainrotSpawnService.lockForCapture(instanceId: string, userId: number): boolean
    local state = ActiveBrainrots[instanceId]
    if not state then return false end
    if state.beingCaptured then return false end
    state.beingCaptured = true
    state.capturedBy    = userId
    return true
end

function BrainrotSpawnService.unlockCapture(instanceId: string)
    local state = ActiveBrainrots[instanceId]
    if state then
        state.beingCaptured = false
        state.capturedBy    = nil
    end
end

-- ── Spawn loop ────────────────────────────────────────────────────────

local function countActiveByType(brainrotType: string): number
    local count = 0
    for _, state in pairs(ActiveBrainrots) do
        local def = Brainrots.getById(state.defId)
        if def and def.brainrotType == brainrotType then
            count += 1
        end
    end
    return count
end

local function spawnLoop()
    -- Initial delay so world loads before first spawn
    task.wait(5)

    while true do
        task.wait(Economy.SpawnIntervalSeconds)

        -- Spawn commons up to cap
        local commonCount = countActiveByType("Common")
        if commonCount < Economy.MaxCommonBrainrotsPerZone * 3 then
            local spawnable = Brainrots.getAllSpawnable()
            -- Filter commons only for top-up
            local commons = {}
            for _, def in ipairs(spawnable) do
                if def.brainrotType == "Common" then
                    table.insert(commons, def)
                end
            end
            if #commons > 0 then
                local pick = commons[math.random(1, #commons)]
                BrainrotSpawnService.spawnBrainrot(pick.id)
            end
        end

        -- Occasionally spawn a rare
        local rareCount = countActiveByType("Rare")
        if rareCount < Economy.MaxRareBrainrotsPerServer and math.random() < 0.3 then
            local spawnable = Brainrots.getAllSpawnable()
            local rares = {}
            for _, def in ipairs(spawnable) do
                if def.brainrotType == "Rare" then
                    table.insert(rares, def)
                end
            end
            if #rares > 0 then
                BrainrotSpawnService.spawnBrainrot(rares[math.random(1, #rares)].id)
            end
        end
    end
end

-- ── Init ──────────────────────────────────────────────────────────────

function BrainrotSpawnService.OnStart()
    collectSpawnPoints()

    if #spawnPoints == 0 then
        warn("[BrainrotSpawnService] No BrainrotSpawn parts found in Workspace.Map.BrainrotSpawns")
        warn("  Run the map setup script in Studio first.")
        return
    end

    -- Spawn a few commons immediately on start
    local commons = {}
    for _, def in ipairs(Brainrots.getAllSpawnable()) do
        if def.brainrotType == "Common" then
            table.insert(commons, def)
        end
    end
    for _ = 1, math.min(4, #commons) do
        local def = commons[math.random(1, #commons)]
        BrainrotSpawnService.spawnBrainrot(def.id)
    end

    task.spawn(spawnLoop)
end

return BrainrotSpawnService
