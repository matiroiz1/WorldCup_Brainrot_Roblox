local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local FarmingNodesConfig = require(ReplicatedStorage.Config.FarmingNodes)
local PlayerDataService = require(ServerScriptService.Services.PlayerDataService)

local FarmingNodeService = {}

local activeNodes = {}

local function spawnNode(defId: string, position: Vector3)
    local def = FarmingNodesConfig.getById(defId)
    if not def then return end

    local model
    local nodesFolder = ReplicatedStorage:FindFirstChild("Assets") and ReplicatedStorage.Assets:FindFirstChild("FarmingNodes")
    if nodesFolder and nodesFolder:FindFirstChild("TemplateChest") then
        model = nodesFolder.TemplateChest:Clone()
        model.Name = "FarmingNode_" .. def.id
        model.PrimaryPart = model:FindFirstChild("Base")
        if model.PrimaryPart then
            model:PivotTo(CFrame.new(position))
        end
    else
        model = Instance.new("Model")
        model.Name = "FarmingNode_" .. def.id
        local part = Instance.new("Part")
        part.Size = Vector3.new(4, 4, 4)
        part.Position = position
        part.Anchored = true
        part.BrickColor = BrickColor.new("Bright yellow")
        part.Material = Enum.Material.Neon
        part.Parent = model
        model.PrimaryPart = part
    end

    local clickDetector = Instance.new("ClickDetector")
    clickDetector.MaxActivationDistance = 15
    clickDetector.Parent = model

    model.Parent = Workspace

    local state = {
        def = def,
        health = def.maxHealth or 30,
        model = model
    }

    clickDetector.MouseClick:Connect(function(player)
        local damage = 10
        local char = player.Character
        local tool = char and char:FindFirstChildOfClass("Tool")
        if tool then
            if tool.Name == "Bate" then damage = 25
            elseif tool.Name == "Boomerang" then damage = 40
            elseif tool.Name == "Pelota" then damage = 60
            end
        end
        
        state.health -= damage
        
        local base = model:FindFirstChild("Base") or model.PrimaryPart
        if base then
            local oldColor = base.Color
            base.Color = Color3.new(1, 0, 0)
            task.delay(0.1, function()
                if base and base.Parent then base.Color = oldColor end
            end)
        end

        if state.health <= 0 then
            if base then
                local emitPart = Instance.new("Part")
                emitPart.Transparency = 1
                emitPart.CanCollide = false
                emitPart.Anchored = true
                emitPart.CFrame = base.CFrame
                emitPart.Parent = Workspace
                
                local pe = Instance.new("ParticleEmitter")
                pe.Texture = "rbxassetid://152554763"
                pe.Speed = NumberRange.new(20, 35)
                pe.Lifetime = NumberRange.new(1.5, 2.5)
                pe.Rate = 0
                pe.SpreadAngle = Vector2.new(-180, 180)
                pe.Parent = emitPart
                pe:Emit(25)
                
                game:GetService("Debris"):AddItem(emitPart, 3)
            end
            
            FarmingNodeService.destroyNode(model, player)
        end
    end)

    table.insert(activeNodes, state)
end

local function getRandomSpawnPosition()
    -- Spawn en anillo alrededor del safe zone (radio 30 a 160 studs)
    local dist = 30 + math.random() * 130
    local angle = math.random() * 2 * math.pi
    return Vector3.new(dist * math.cos(angle), 2, dist * math.sin(angle))
end

function FarmingNodeService.destroyNode(model: Model, player: Player)
    -- Find state
    for i, state in ipairs(activeNodes) do
        if state.model == model then
            print(player.Name .. " destroyed " .. state.def.name .. "!")
            
            -- Reward logic based on Config/FarmingNodes.lua
            if state.def.rewardsTable then
                for _, reward in ipairs(state.def.rewardsTable) do
                    -- Roll independent chance
                    if math.random(1, 100) <= reward.weight then
                        local amount = math.random(reward.minAmount, reward.maxAmount)
                        if reward.drop == "coins" then
                            PlayerDataService.addCoins(player, amount)
                        end
                        -- (future drops like cards or shards can be handled here)
                    end
                end
            end
            
            model:Destroy()
            table.remove(activeNodes, i)
            
            -- Schedule respawn in a new random location
            task.delay(state.def.respawnTimeSec, function()
                spawnNode(state.def.id, getRandomSpawnPosition())
            end)
            break
        end
    end
end

function FarmingNodeService.OnStart()
    require(ReplicatedStorage.AssetBuilder).BuildAll()
    print("[FarmingNodeService] Started")
    -- Spawn initial nodes randomly
    for i = 1, 3 do
        spawnNode("node_botin_oro", getRandomSpawnPosition())
    end
    for i = 1, 2 do
        spawnNode("node_copa_mundo", getRandomSpawnPosition())
    end
end

return FarmingNodeService
