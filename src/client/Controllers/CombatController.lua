local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")

local Remotes = require(ReplicatedStorage.Remotes)

local Player     = Players.LocalPlayer
local Camera     = workspace.CurrentCamera

-- Max distance a weapon hit is valid at
local MAX_RANGE  = 20
-- Cooldown between hits per weapon type (seconds)
local COOLDOWNS  = {
    Bate      = 0.8,
    Boomerang = 1.2,
    Pelota    = 1.5,
}
local DEFAULT_COOLDOWN = 1.0

local lastHitTime = 0

local CombatController = {}

-- Raycast from camera toward mouse cursor, find a BrainrotNPC hit
local function raycastForNPC(): (string?, Vector3?)
    local character = Player.Character
    if not character then return nil, nil end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil, nil end

    local mousePos = UserInputService:GetMouseLocation()
    local ray = Camera:ViewportPointToRay(mousePos.X, mousePos.Y)

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    -- Exclude the player's own character
    raycastParams.FilterDescendantsInstances = { character }

    local result = workspace:Raycast(ray.Origin, ray.Direction * MAX_RANGE, raycastParams)
    if not result then return nil, nil end

    -- Walk up to find a BrainrotNPC model
    local hit = result.Instance
    local model = hit:FindFirstAncestorOfClass("Model")
    if not model then return nil, nil end

    local name = model.Name
    -- BrainrotNPC models are named "BrainrotNPC_<instanceId>"
    if not name:match("^BrainrotNPC_") then return nil, nil end

    local instanceId = name:sub(#"BrainrotNPC_" + 1)
    return instanceId, result.Position
end

local function onToolActivated(tool: Tool)
    local toolName = tool.Name
    local cooldown = COOLDOWNS[toolName] or DEFAULT_COOLDOWN

    local now = tick()
    if now - lastHitTime < cooldown then return end

    local instanceId, hitPos = raycastForNPC()
    if not instanceId then return end

    lastHitTime = now
    Remotes.RequestDamage:FireServer({
        instanceId = instanceId,
        weaponName = toolName,
        hitPosition = hitPos,
    })
end

local function hookTool(tool: Tool)
    tool.Activated:Connect(function()
        onToolActivated(tool)
    end)
end

local function onCharacterAdded(character: Model)
    -- Hook tools already in backpack + future equips
    local backpack = Player.Backpack
    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") then hookTool(tool) end
    end
    backpack.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then hookTool(child) end
    end)
    character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then hookTool(child) end
    end)
end

function CombatController.OnStart()
    if Player.Character then
        onCharacterAdded(Player.Character)
    end
    Player.CharacterAdded:Connect(onCharacterAdded)
end

return CombatController
