local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")

local Remotes   = require(ReplicatedStorage.Remotes)
local Brainrots = require(ReplicatedStorage.Config.Brainrots)
local Economy   = require(ReplicatedStorage.Config.Economy)

-- ── Constants ─────────────────────────────────────────────────────────

local FLEE_RANGE      = 20
local WANDER_RADIUS   = 45
local AI_TICK         = 0.5
local MAX_TOTAL_NPCS  = 20
local DESPAWN_AFTER   = 300  -- seconds before an uncaptured NPC auto-despawns
local FALL_Y_LIMIT    = -50

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

        -- Desanclar todos los parts del template clonado
        for _, part in ipairs(model:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Anchored = false
            end
        end

        hrp = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
        if not hrp then
            hrp = model:FindFirstChildOfClass("BasePart")
        end
        if hrp then
            model.PrimaryPart = hrp
        end

        humanoid = model:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = WALK_SPEEDS[def.brainrotType] or 12
            humanoid.JumpPower = 0
            humanoid.MaxHealth = 100
            humanoid.Health = 100
            humanoid.HipHeight = humanoid.HipHeight > 0 and humanoid.HipHeight or 2
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
        humanoid.HipHeight     = 2
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
    -- Delay inicial aleatorio para que los NPCs no se muevan todos sincronizados
    task.wait(math.random() * 4)

    local nextMoveAt = os.clock() + math.random(2, 6)

    while true do
        task.wait(AI_TICK)

        local state = ActiveBrainrots[instanceId]
        if not state then break end
        if state.beingCaptured then continue end

        local model    = state.model
        if not model or not model.Parent then break end
        local hrp      = model:FindFirstChild("HumanoidRootPart")
        local humanoid = model:FindFirstChildOfClass("Humanoid")
        if not hrp or not humanoid or humanoid.Health <= 0 then break end

        local pos = hrp.Position

        -- Fall detection: si cayó del mapa, reposicionar en el spawn
        if pos.Y < FALL_Y_LIMIT then
            model:PivotTo(CFrame.new(spawnPos))
            nextMoveAt = os.clock() + math.random(1, 3)
            continue
        end

        local now = os.clock()

        -- Flee: huir del jugador más cercano, tiene prioridad sobre el wander
        if def.moveStyle == "Flee" then
            local nearPlayer, nearDist = getNearestPlayerDistance(pos)
            if nearPlayer and nearDist < FLEE_RANGE then
                local playerHrp = nearPlayer.Character and nearPlayer.Character:FindFirstChild("HumanoidRootPart")
                if playerHrp then
                    local dx = pos.X - playerHrp.Position.X
                    local dz = pos.Z - playerHrp.Position.Z
                    local len = math.sqrt(dx*dx + dz*dz)
                    if len > 0 then
                        local tx = math.clamp(pos.X + (dx/len) * 20, -280, 280)
                        local tz = math.clamp(pos.Z + (dz/len) * 20, -280, 280)
                        humanoid:MoveTo(Vector3.new(tx, pos.Y, tz))
                        nextMoveAt = now + 1.5
                    end
                end
                continue
            end
        end

        -- Wander: pick nuevo destino cuando toca
        if now >= nextMoveAt then
            local angle  = math.random() * math.pi * 2
            local radius = math.random(10, WANDER_RADIUS)
            local tx = math.clamp(spawnPos.X + math.cos(angle) * radius, -280, 280)
            local tz = math.clamp(spawnPos.Z + math.sin(angle) * radius, -280, 280)
            -- Y: usar la posición actual del suelo (pos.Y ya refleja dónde está parado)
            humanoid:MoveTo(Vector3.new(tx, pos.Y, tz))
            -- Próximo cambio de dirección aleatorio, independiente por NPC
            nextMoveAt = now + math.random(4, 10)
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
    model.Name       = "BrainrotNPC_" .. instanceId

    -- Primero parentear, luego PivotTo (así los constraints físicos están activos)
    model.Parent = Workspace
    if model.PrimaryPart then
        model:PivotTo(CFrame.new(position))
    end

    local state = {
        defId         = defId,
        model         = model,
        spawnPos      = position,
        beingCaptured = false,
        capturedBy    = nil,
        spawnedAt     = os.clock(),
    }
    ActiveBrainrots[instanceId] = state

    -- Start AI
    local thread = task.spawn(runAI, instanceId, def, position)
    AiTasks[instanceId]  = thread

    -- Auto-despawn timer
    task.delay(DESPAWN_AFTER, function()
        if ActiveBrainrots[instanceId] then
            BrainrotSpawnService.despawnBrainrot(instanceId)
        end
    end)

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

local function totalActive(): number
    local count = 0
    for _ in pairs(ActiveBrainrots) do count += 1 end
    return count
end

local function spawnLoop()
    task.wait(5)

    while true do
        task.wait(Economy.SpawnIntervalSeconds)

        if totalActive() >= MAX_TOTAL_NPCS then continue end

        local spawnable = Brainrots.getAllSpawnable()

        -- Spawn commons up to cap
        local commonCount = countActiveByType("Common")
        if commonCount < Economy.MaxCommonBrainrotsPerZone * 3 then
            local commons = {}
            for _, def in ipairs(spawnable) do
                if def.brainrotType == "Common" then
                    table.insert(commons, def)
                end
            end
            if #commons > 0 then
                BrainrotSpawnService.spawnBrainrot(commons[math.random(1, #commons)].id)
            end
        end

        -- 30% chance to spawn a Rare
        local rareCount = countActiveByType("Rare")
        if rareCount < Economy.MaxRareBrainrotsPerServer and math.random() < 0.3 then
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

        -- 10% chance to spawn an Elite
        if math.random() < 0.1 then
            local elites = {}
            for _, def in ipairs(spawnable) do
                if def.brainrotType == "Elite" then
                    table.insert(elites, def)
                end
            end
            if #elites > 0 then
                BrainrotSpawnService.spawnBrainrot(elites[math.random(1, #elites)].id)
            end
        end
    end
end

-- ── RequestDamage handler ─────────────────────────────────────────────

local WEAPON_DAMAGE = {
    Bate      = 34,
    Boomerang = 25,
    Pelota    = 20,
}
local MAX_HIT_DISTANCE = 25

local function onRequestDamage(player: Player, info: any)
    if typeof(info) ~= "table" then return end
    local instanceId = info.instanceId
    local weaponName = info.weaponName

    local state = ActiveBrainrots[instanceId]
    if not state then return end

    -- Server-side distance check
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local npcHrp = state.model and state.model:FindFirstChild("HumanoidRootPart")
    if not hrp or not npcHrp then return end
    if (hrp.Position - npcHrp.Position).Magnitude > MAX_HIT_DISTANCE then return end

    local humanoid = state.model:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end

    local damage = WEAPON_DAMAGE[weaponName] or 20
    humanoid.Health = math.max(0, humanoid.Health - damage)

    if humanoid.Health <= 0 then
        -- NPC killed — give reward via CardService
        local ok, CardService = pcall(require, script.Parent.CardService)
        local def = Brainrots.getById(state.defId)
        if ok and CardService and def and def.rewardsTable then
            CardService.giveRewardCard(player, def.rewardsTable)
        end

        local PDS = require(script.Parent.PlayerDataService)
        if def then
            local coins = Economy.CaptureCoins[def.brainrotType] or 15
            PDS.addCoins(player, coins)
            Remotes.Notification:FireClient(player, {
                type = "success",
                message = "⚽ +" .. coins .. " monedas — " .. def.name .. " eliminado!",
            })
        end

        BrainrotSpawnService.despawnBrainrot(instanceId)
    end
end

-- ── Init ──────────────────────────────────────────────────────────────

function BrainrotSpawnService.OnStart()
    collectSpawnPoints()

    Remotes.RequestDamage:Connect(onRequestDamage)

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
