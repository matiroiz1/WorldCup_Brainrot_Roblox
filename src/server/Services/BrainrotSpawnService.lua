local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")

local Remotes   = require(ReplicatedStorage.Remotes)
local Brainrots = require(ReplicatedStorage.Config.Brainrots)
local Economy   = require(ReplicatedStorage.Config.Economy)

-- ── Constants ─────────────────────────────────────────────────────────────

local MAX_TOTAL_NPCS  = 15
local DESPAWN_AFTER   = 300
local WANDER_RADIUS   = 35
local FLEE_RANGE      = 18
local FALL_Y          = -40

-- Roblox R6 standard animation IDs
local ANIM_WALK = "rbxassetid://180426354"
local ANIM_IDLE = "rbxassetid://180435571"

local RARITY_COLORS = {
    Common    = Color3.fromRGB(180, 180, 180),
    Rare      = Color3.fromRGB(60, 120, 220),
    Elite     = Color3.fromRGB(150, 40, 210),
    Legendary = Color3.fromRGB(230, 170, 10),
    Chaotic   = Color3.fromRGB(220, 80, 20),
}

local RARITY_EMOJIS = {
    Common    = "⚽",
    Rare      = "🌟",
    Elite     = "💎",
    Legendary = "👑",
    Chaotic   = "🔥",
}

local WALK_SPEEDS = {
    Common    = 10,
    Rare      = 13,
    Elite     = 17,
    Legendary = 22,
    Chaotic   = 15,
}

-- ── State ─────────────────────────────────────────────────────────────────

local ActiveBrainrots: { [string]: any } = {}
local AiTasks:         { [string]: thread } = {}
local spawnPoints:     { Vector3 } = {}

local BrainrotSpawnService = {}

-- ── R6 rig builder ────────────────────────────────────────────────────────
-- Builds a complete R6 character rig from scratch with proper Motor6D joints
-- so standard Roblox walk/idle animations work correctly.

local function buildR6NPC(def: any): (Model, Humanoid, Animator)
    local bodyColor = RARITY_COLORS[def.brainrotType] or Color3.fromRGB(160, 160, 160)
    local speed     = WALK_SPEEDS[def.brainrotType] or 10

    local model = Instance.new("Model")
    model.Name  = "BrainrotNPC_" .. def.id

    -- Helper: create a body part
    local function part(name: string, size: Vector3, color: Color3, canCollide: boolean): Part
        local p = Instance.new("Part")
        p.Name        = name
        p.Size        = size
        p.Color       = color
        p.CanCollide  = canCollide
        p.Anchored    = false
        p.CastShadow  = true
        p.Parent      = model
        return p
    end

    -- Root (invisible, physics anchor)
    local hrp = part("HumanoidRootPart", Vector3.new(2, 2, 1), Color3.new(), false)
    hrp.Transparency = 1

    -- Body parts (visible)
    local torso    = part("Torso",     Vector3.new(2, 2, 1), bodyColor, false)
    local head     = part("Head",      Vector3.new(2, 1, 1), bodyColor, false)
    local leftArm  = part("Left Arm",  Vector3.new(1, 2, 1), bodyColor, false)
    local rightArm = part("Right Arm", Vector3.new(1, 2, 1), bodyColor, false)
    local leftLeg  = part("Left Leg",  Vector3.new(1, 2, 1), bodyColor, false)
    local rightLeg = part("Right Leg", Vector3.new(1, 2, 1), bodyColor, false)

    -- Head mesh (makes it look like a Roblox head, not a flat box)
    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType = Enum.MeshType.Head
    mesh.Scale    = Vector3.new(1.25, 1.25, 1.25)
    mesh.Parent   = head

    -- Humanoid (R6 mode)
    local humanoid = Instance.new("Humanoid")
    humanoid.RigType              = Enum.HumanoidRigType.R6
    humanoid.WalkSpeed            = speed
    humanoid.JumpPower            = 0
    humanoid.MaxHealth            = 100
    humanoid.Health               = 100
    humanoid.DisplayDistanceType  = Enum.HumanoidDisplayDistanceType.None
    humanoid.HealthDisplayDistance = 0
    humanoid.Parent               = model

    local animator = Instance.new("Animator")
    animator.Parent = humanoid

    -- Motor6D joints (exact Roblox R6 default offsets so standard animations work)
    local function motor(parent: BasePart, name: string, p0: BasePart, p1: BasePart, c0: CFrame, c1: CFrame)
        local m  = Instance.new("Motor6D")
        m.Name   = name
        m.Part0  = p0
        m.Part1  = p1
        m.C0     = c0
        m.C1     = c1
        m.Parent = parent
    end

    motor(hrp, "RootJoint", hrp, torso,
        CFrame.new(0, -1, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0),
        CFrame.new(0, -1, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0))

    motor(torso, "Neck", torso, head,
        CFrame.new(0, 1, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0),
        CFrame.new(0, -0.5, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0))

    motor(torso, "Left Shoulder", torso, leftArm,
        CFrame.new(-1, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0),
        CFrame.new(0.5, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0))

    motor(torso, "Right Shoulder", torso, rightArm,
        CFrame.new(1, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0),
        CFrame.new(-0.5, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0))

    motor(torso, "Left Hip", torso, leftLeg,
        CFrame.new(-0.5, -1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0),
        CFrame.new(-0.5, 1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0))

    motor(torso, "Right Hip", torso, rightLeg,
        CFrame.new(0.5, -1, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0),
        CFrame.new(0.5, 1, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0))

    -- Name billboard above head
    local bb = Instance.new("BillboardGui")
    bb.Size         = UDim2.new(0, 160, 0, 50)
    bb.StudsOffset  = Vector3.new(0, 4, 0)
    bb.AlwaysOnTop  = false
    bb.Parent       = hrp

    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size                   = UDim2.fromScale(1, 0.6)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text                   = (RARITY_EMOJIS[def.brainrotType] or "") .. " " .. def.name
    nameLbl.TextColor3             = Color3.new(1, 1, 1)
    nameLbl.TextScaled             = true
    nameLbl.Font                   = Enum.Font.GothamBold
    nameLbl.TextStrokeTransparency = 0
    nameLbl.Parent                 = bb

    local rarLbl = Instance.new("TextLabel")
    rarLbl.Size                   = UDim2.new(1, 0, 0.4, 0)
    rarLbl.Position               = UDim2.fromScale(0, 0.6)
    rarLbl.BackgroundTransparency = 1
    rarLbl.Text                   = "[" .. def.brainrotType .. "]"
    rarLbl.TextColor3             = bodyColor
    rarLbl.TextScaled             = true
    rarLbl.Font                   = Enum.Font.Gotham
    rarLbl.TextStrokeTransparency = 0
    rarLbl.Parent                 = bb

    model.PrimaryPart = hrp
    return model, humanoid, animator
end

-- ── Spawn point collection ────────────────────────────────────────────────

local function collectSpawnPoints()
    local map    = Workspace:FindFirstChild("Map")
    local folder = map and map:FindFirstChild("BrainrotSpawns")
    if not folder then
        warn("[BrainrotSpawnService] Map.BrainrotSpawns not found")
        return
    end
    for _, p in ipairs(folder:GetChildren()) do
        if p:IsA("BasePart") then
            -- +4 so the NPC spawns above ground (R6 rig is ~5 units tall from ground)
            table.insert(spawnPoints, p.Position + Vector3.new(0, 4, 0))
        end
    end
end

local function randomSpawnPoint(): Vector3
    return spawnPoints[math.random(1, #spawnPoints)]
end

-- ── Helpers ───────────────────────────────────────────────────────────────

local function totalActive(): number
    local n = 0
    for _ in pairs(ActiveBrainrots) do n += 1 end
    return n
end

local function countByType(brainrotType: string): number
    local n = 0
    for _, s in pairs(ActiveBrainrots) do
        local d = Brainrots.getById(s.defId)
        if d and d.brainrotType == brainrotType then n += 1 end
    end
    return n
end

local function nearestPlayer(pos: Vector3): (Player?, number)
    local best, bestD = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        local c = p.Character
        local h = c and c:FindFirstChild("HumanoidRootPart")
        if h then
            local d = (h.Position - pos).Magnitude
            if d < bestD then best, bestD = p, d end
        end
    end
    return best, bestD
end

local function loadTrack(animator: Animator, id: string): AnimationTrack
    local anim        = Instance.new("Animation")
    anim.AnimationId  = id
    local track       = animator:LoadAnimation(anim)
    anim:Destroy()
    return track
end

-- ── AI loop ───────────────────────────────────────────────────────────────

local function runAI(instanceId: string, def: any, spawnPos: Vector3)
    -- Randomize start so NPCs don't all move on the same frame
    task.wait(math.random() * 4)

    local state = ActiveBrainrots[instanceId]
    if not state then return end

    local model    = state.model
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
    if not humanoid or not animator then return end

    -- Load standard R6 animations
    local walkTrack = loadTrack(animator, ANIM_WALK)
    local idleTrack = loadTrack(animator, ANIM_IDLE)
    walkTrack.Looped = true
    idleTrack.Looped = true
    idleTrack:Play()

    local function setWalking(on: boolean)
        if on then
            idleTrack:Stop(0.2)
            if not walkTrack.IsPlaying then walkTrack:Play(0.2) end
        else
            walkTrack:Stop(0.2)
            if not idleTrack.IsPlaying then idleTrack:Play(0.2) end
        end
    end

    while true do
        -- Check still alive
        local s = ActiveBrainrots[instanceId]
        if not s or not model.Parent then break end
        if s.beingCaptured then task.wait(0.5); continue end

        local hrp = model:FindFirstChild("HumanoidRootPart")
        if not hrp or humanoid.Health <= 0 then break end

        local pos = hrp.Position

        -- Fall off map → respawn at original point
        if pos.Y < FALL_Y then
            setWalking(false)
            model:PivotTo(CFrame.new(spawnPos))
            task.wait(1)
            continue
        end

        -- Flee from nearby player (highest priority)
        if def.moveStyle == "Flee" then
            local nearP, nearD = nearestPlayer(pos)
            if nearP and nearD < FLEE_RANGE then
                local ph = nearP.Character and nearP.Character:FindFirstChild("HumanoidRootPart")
                if ph then
                    local flat = Vector3.new(pos.X - ph.Position.X, 0, pos.Z - ph.Position.Z)
                    local dir  = flat.Magnitude > 0.1 and flat.Unit or Vector3.new(1, 0, 0)
                    local tx   = math.clamp(pos.X + dir.X * 22, -280, 280)
                    local tz   = math.clamp(pos.Z + dir.Z * 22, -280, 280)
                    setWalking(true)
                    humanoid:MoveTo(Vector3.new(tx, pos.Y, tz))
                    task.wait(1.5)
                    continue
                end
            end
        end

        -- Wander: pick a random point around the spawn origin
        local angle  = math.random() * math.pi * 2
        local radius = math.random(8, WANDER_RADIUS)
        local tx     = math.clamp(spawnPos.X + math.cos(angle) * radius, -280, 280)
        local tz     = math.clamp(spawnPos.Z + math.sin(angle) * radius, -280, 280)
        local target = Vector3.new(tx, pos.Y, tz)

        setWalking(true)
        humanoid:MoveTo(target)

        -- Wait up to 8s for arrival (Roblox's MoveTo timeout)
        local done = false
        local conn = humanoid.MoveToFinished:Connect(function() done = true end)
        local t0   = tick()
        while not done and (tick() - t0) < 8 do
            task.wait(0.2)
            if not ActiveBrainrots[instanceId] then break end
        end
        conn:Disconnect()

        setWalking(false)

        -- Pause before next move (NPCs look more natural with idle breaks)
        task.wait(math.random(2, 5))
    end

    -- Cleanup animations if loop exits
    pcall(function() walkTrack:Stop() end)
    pcall(function() idleTrack:Stop() end)
end

-- ── Spawn / Despawn ───────────────────────────────────────────────────────

local function generateId(): string
    return tostring(math.random(100000, 999999)) .. tostring(os.clock()):gsub("%.", "")
end

function BrainrotSpawnService.spawnBrainrot(defId: string, position: Vector3?): string?
    local def = Brainrots.getById(defId)
    if not def then return nil end

    local spawnPos = position or randomSpawnPoint()
    if not spawnPos then return nil end

    local instanceId            = generateId()
    local model, humanoid, anim = buildR6NPC(def)

    -- Parent first, then pivot (constraints need to be in workspace)
    model.Parent = Workspace
    model:PivotTo(CFrame.new(spawnPos))
    -- Rename after pivot so the name includes the instanceId
    model.Name = "BrainrotNPC_" .. instanceId

    local state = {
        defId         = defId,
        model         = model,
        spawnPos      = spawnPos,
        beingCaptured = false,
        capturedBy    = nil,
        spawnedAt     = os.clock(),
    }
    ActiveBrainrots[instanceId] = state

    local thread = task.spawn(runAI, instanceId, def, spawnPos)
    AiTasks[instanceId] = thread

    task.delay(DESPAWN_AFTER, function()
        if ActiveBrainrots[instanceId] then
            BrainrotSpawnService.despawnBrainrot(instanceId)
        end
    end)

    Remotes.BrainrotSpawned:FireAllClients({
        instanceId = instanceId,
        defId      = defId,
        position   = spawnPos,
        name       = def.name,
        rarity     = def.brainrotType,
    })

    return instanceId
end

function BrainrotSpawnService.despawnBrainrot(instanceId: string)
    local state = ActiveBrainrots[instanceId]
    if not state then return end

    local thread = AiTasks[instanceId]
    if thread then
        task.cancel(thread)
        AiTasks[instanceId] = nil
    end

    if state.model and state.model.Parent then
        state.model:Destroy()
    end

    ActiveBrainrots[instanceId] = nil
    Remotes.BrainrotDespawned:FireAllClients({ instanceId = instanceId })
end

function BrainrotSpawnService.getActive()
    return ActiveBrainrots
end

function BrainrotSpawnService.getState(instanceId: string)
    return ActiveBrainrots[instanceId]
end

function BrainrotSpawnService.lockForCapture(instanceId: string, userId: number): boolean
    local s = ActiveBrainrots[instanceId]
    if not s or s.beingCaptured then return false end
    s.beingCaptured = true
    s.capturedBy    = userId
    return true
end

function BrainrotSpawnService.unlockCapture(instanceId: string)
    local s = ActiveBrainrots[instanceId]
    if s then s.beingCaptured = false; s.capturedBy = nil end
end

-- ── RequestDamage handler ─────────────────────────────────────────────────

local WEAPON_DAMAGE    = { Bate = 34, Boomerang = 25, Pelota = 20 }
local MAX_HIT_DISTANCE = 25

local function onRequestDamage(player: Player, info: any)
    if typeof(info) ~= "table" then return end
    local instanceId = info.instanceId
    local weaponName = info.weaponName

    local state = ActiveBrainrots[instanceId]
    if not state then return end

    local char   = player.Character
    local hrp    = char and char:FindFirstChild("HumanoidRootPart")
    local npcHrp = state.model and state.model:FindFirstChild("HumanoidRootPart")
    if not hrp or not npcHrp then return end
    if (hrp.Position - npcHrp.Position).Magnitude > MAX_HIT_DISTANCE then return end

    local humanoid = state.model:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end

    local damage = WEAPON_DAMAGE[weaponName] or 20
    humanoid.Health = math.max(0, humanoid.Health - damage)

    if humanoid.Health <= 0 then
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
                type    = "success",
                message = "⚽ +" .. coins .. " monedas — " .. def.name .. " eliminado!",
            })
        end

        BrainrotSpawnService.despawnBrainrot(instanceId)
    end
end

-- ── Spawn loop ────────────────────────────────────────────────────────────

local function spawnLoop()
    task.wait(5)
    while true do
        task.wait(Economy.SpawnIntervalSeconds)
        if totalActive() >= MAX_TOTAL_NPCS then continue end

        local spawnable = Brainrots.getAllSpawnable()

        -- Rellenar commons hasta el cap
        local commonCap = Economy.MaxCommonBrainrotsPerZone * 3
        if countByType("Common") < commonCap then
            local commons = {}
            for _, d in ipairs(spawnable) do
                if d.brainrotType == "Common" then table.insert(commons, d) end
            end
            if #commons > 0 then
                BrainrotSpawnService.spawnBrainrot(commons[math.random(1, #commons)].id)
            end
        end

        -- 30% de chance de Rare
        if countByType("Rare") < Economy.MaxRareBrainrotsPerServer and math.random() < 0.3 then
            local rares = {}
            for _, d in ipairs(spawnable) do
                if d.brainrotType == "Rare" then table.insert(rares, d) end
            end
            if #rares > 0 then
                BrainrotSpawnService.spawnBrainrot(rares[math.random(1, #rares)].id)
            end
        end

        -- 10% de chance de Elite
        if math.random() < 0.1 then
            local elites = {}
            for _, d in ipairs(spawnable) do
                if d.brainrotType == "Elite" then table.insert(elites, d) end
            end
            if #elites > 0 then
                BrainrotSpawnService.spawnBrainrot(elites[math.random(1, #elites)].id)
            end
        end
    end
end

-- ── Init ──────────────────────────────────────────────────────────────────

function BrainrotSpawnService.OnStart()
    collectSpawnPoints()

    if #spawnPoints == 0 then
        warn("[BrainrotSpawnService] No spawn points found in Map.BrainrotSpawns")
        return
    end

    Remotes.RequestDamage:Connect(onRequestDamage)

    -- Spawn iniciales staggereados para que no aparezcan todos juntos
    local commons = {}
    for _, d in ipairs(Brainrots.getAllSpawnable()) do
        if d.brainrotType == "Common" then table.insert(commons, d) end
    end

    for i = 1, math.min(5, #commons) do
        task.delay((i - 1) * 1.5, function()
            local def = commons[math.random(1, #commons)]
            BrainrotSpawnService.spawnBrainrot(def.id)
        end)
    end

    task.spawn(spawnLoop)
end

return BrainrotSpawnService
