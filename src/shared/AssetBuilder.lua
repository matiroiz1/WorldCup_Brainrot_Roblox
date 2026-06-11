local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local AssetBuilder = {}
local built = false

function AssetBuilder.BuildAll()
    if built then return end
    built = true

    local assets = ReplicatedStorage:FindFirstChild("Assets")
    if not assets then
        assets = Instance.new("Folder")
        assets.Name = "Assets"
        assets.Parent = ReplicatedStorage
    end

    local mobsFolder = assets:FindFirstChild("Mobs")
    if not mobsFolder then
        mobsFolder = Instance.new("Folder")
        mobsFolder.Name = "Mobs"
        mobsFolder.Parent = assets
    end

    local nodesFolder = assets:FindFirstChild("FarmingNodes")
    if not nodesFolder then
        nodesFolder = Instance.new("Folder")
        nodesFolder.Name = "FarmingNodes"
        nodesFolder.Parent = assets
    end

    local weaponsFolder = assets:FindFirstChild("Weapons")
    if not weaponsFolder then
        weaponsFolder = Instance.new("Folder")
        weaponsFolder.Name = "Weapons"
        weaponsFolder.Parent = assets
    end

    local function fixHipHeight(model)
        local hrp = model:FindFirstChild("HumanoidRootPart")
        local hum = model:FindFirstChildOfClass("Humanoid")
        if hrp and hum then
            local minY = math.huge
            for _, part in ipairs(model:GetDescendants()) do
                if part:IsA("BasePart") then
                    local bottom = part.Position.Y - (part.Size.Y / 2)
                    if bottom < minY then minY = bottom end
                    if part ~= hrp then
                        part.CanCollide = false
                        part.Massless = true
                    end
                end
            end
            local distToBottom = hrp.Position.Y - minY
            hum.HipHeight = distToBottom + 0.5
        end
    end

    local function createBlockyNPC(name, colorHead, colorBody)
        local m = Instance.new("Model")
        m.Name = name
        
        local hrp = Instance.new("Part")
        hrp.Name = "HumanoidRootPart"
        hrp.Size = Vector3.new(2, 2, 1)
        hrp.Transparency = 1
        hrp.CanCollide = false
        hrp.Parent = m
        m.PrimaryPart = hrp
        
        local torso = Instance.new("Part")
        torso.Name = "Torso"
        torso.Size = Vector3.new(2, 3, 1)
        torso.Color = colorBody
        torso.Parent = m
        local w1 = Instance.new("WeldConstraint", hrp); w1.Part0 = hrp; w1.Part1 = torso
        
        local head = Instance.new("Part")
        head.Name = "Head"
        head.Size = Vector3.new(1.5, 1.5, 1.5)
        head.Color = colorHead
        head.CFrame = hrp.CFrame * CFrame.new(0, 2.25, 0)
        head.Parent = m
        local w2 = Instance.new("WeldConstraint", hrp); w2.Part0 = hrp; w2.Part1 = head
        
        local hum = Instance.new("Humanoid")
        hum.Parent = m
        
        fixHipHeight(m)
        return m
    end

    local function ensureExists(name, cHead, cBody)
        local existing = mobsFolder:FindFirstChild(name)
        if not existing or #existing:GetChildren() < 2 then
            if existing then existing:Destroy() end
            local m = createBlockyNPC(name, cHead, cBody)
            m.Parent = mobsFolder
        else
            if existing:IsA("Model") then
                fixHipHeight(existing)
            end
        end
    end

    local BrainrotsConfig = require(ReplicatedStorage.Config.Brainrots)
    for k, def in pairs(BrainrotsConfig) do
        if type(def) == "table" and def.id then
            local cHead = Color3.fromRGB(200, 200, 200)
            local cBody = Color3.fromRGB(150, 150, 150)
            
            if def.brainrotType == "Rare" then cBody = Color3.fromRGB(50, 100, 255)
            elseif def.brainrotType == "Elite" then cBody = Color3.fromRGB(150, 50, 200)
            elseif def.brainrotType == "Legendary" then cBody = Color3.fromRGB(255, 215, 0)
            elseif def.brainrotType == "Chaotic" then cBody = Color3.fromRGB(255, 80, 0) end
            
            if def.id == "brainrot_vendedor" then
                cHead = Color3.fromRGB(255, 200, 150)
                cBody = Color3.fromRGB(80, 50, 20)
            elseif def.id == "brainrot_messi_dorado" then
                cHead = Color3.fromRGB(255, 215, 0)
                cBody = Color3.fromRGB(100, 150, 255)
            elseif def.id == "brainrot_cr7_fuego" then
                cHead = Color3.fromRGB(255, 100, 100)
                cBody = Color3.fromRGB(200, 0, 0)
            end
            
            ensureExists(def.id, cHead, cBody)
        end
    end

    if not nodesFolder:FindFirstChild("TemplateChest") then
        local chest = Instance.new("Model")
        chest.Name = "TemplateChest"
        
        local base = Instance.new("Part")
        base.Name = "Base"
        base.Size = Vector3.new(3, 2, 2)
        base.Color = Color3.fromRGB(139, 69, 19)
        base.Material = Enum.Material.Wood
        base.Parent = chest
        
        local lid = Instance.new("Part")
        lid.Name = "Lid"
        lid.Size = Vector3.new(3, 1, 2)
        lid.Color = Color3.fromRGB(160, 82, 45)
        lid.CFrame = base.CFrame * CFrame.new(0, 1.5, 0)
        lid.Material = Enum.Material.Wood
        lid.Parent = chest
        
        local w = Instance.new("WeldConstraint", base)
        w.Part0 = base
        w.Part1 = lid
        w.Parent = base
        
        chest.PrimaryPart = base
        chest.Parent = nodesFolder
    end

    local function makeTool(name, color, size, meshType)
        local existing = weaponsFolder:FindFirstChild(name)
        if existing then existing:Destroy() end
        
        local tool = Instance.new("Tool")
        tool.Name = name
        tool.RequiresHandle = true
        
        local handle = Instance.new("Part")
        handle.Name = "Handle"
        handle.Size = size
        handle.Color = color
        
        if meshType then
            local mesh = Instance.new("SpecialMesh")
            mesh.MeshType = meshType
            mesh.Parent = handle
        end
        
        handle.Parent = tool
        tool.Parent = weaponsFolder
    end

    makeTool("Bate", BrickColor.new("Brown").Color, Vector3.new(0.4, 3, 0.4), Enum.MeshType.Cylinder)
    makeTool("Boomerang", BrickColor.new("Bright blue").Color, Vector3.new(1.5, 0.2, 1.5), nil)
    makeTool("Pelota", BrickColor.new("Institutional white").Color, Vector3.new(1.2, 1.2, 1.2), Enum.MeshType.Sphere)
    
    -- Colocar Vendedor fijo en el mapa para probar
    task.spawn(function()
        local map = Workspace:WaitForChild("Map", 5)
        if map then
            local tZone = map:FindFirstChild("TradingZone")
            if tZone and not tZone:FindFirstChild("VendedorFijo") then
                local v = mobsFolder:FindFirstChild("brainrot_vendedor")
                if v then
                    local clone = v:Clone()
                    clone.Name = "VendedorFijo"
                    if clone.PrimaryPart then
                        clone:PivotTo(CFrame.new(0, 3, 0)) -- Centro del mapa
                    end
                    clone.Parent = tZone
                    
                    -- Cartel para que se vea claro
                    local bb = Instance.new("BillboardGui")
                    bb.Size = UDim2.new(0, 200, 0, 50)
                    bb.StudsOffset = Vector3.new(0, 4, 0)
                    local txt = Instance.new("TextLabel")
                    txt.Size = UDim2.fromScale(1, 1)
                    txt.Text = "¡Vendedor 3D!"
                    txt.TextScaled = true
                    txt.BackgroundTransparency = 1
                    txt.TextColor3 = Color3.new(1, 1, 0)
                    txt.Parent = bb
                    bb.Parent = clone.PrimaryPart
                end
            end
        end
    end)
end

return AssetBuilder
