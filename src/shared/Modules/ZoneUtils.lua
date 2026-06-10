--[[
    Modules/ZoneUtils.lua
    Determine which zone a world position or player belongs to.
    Zones are Folders in Workspace.Map containing at least one BasePart
    marked as a zone boundary (any part named "Boundary").
]]

local Workspace = game:GetService("Workspace")
local Zones = require(script.Parent.Parent.Config.Zones)

local ZoneUtils = {}

local function getZoneParts(zoneName: string): { BasePart }
    local map = Workspace:FindFirstChild("Map")
    if not map then return {} end
    local folder = map:FindFirstChild(zoneName)
    if not folder then return {} end

    local parts = {}
    for _, child in ipairs(folder:GetDescendants()) do
        if child:IsA("BasePart") then
            table.insert(parts, child)
        end
    end
    return parts
end

-- Returns the ZoneName the position is inside, or nil
function ZoneUtils.getZoneAtPosition(position: Vector3): string?
    for _, zoneName in pairs(Zones.Names) do
        local parts = getZoneParts(zoneName)
        for _, part in ipairs(parts) do
            local size = part.Size
            local cf   = part.CFrame
            local local_ = cf:PointToObjectSpace(position)
            if  math.abs(local_.X) <= size.X / 2
            and math.abs(local_.Y) <= size.Y / 2
            and math.abs(local_.Z) <= size.Z / 2 then
                return zoneName
            end
        end
    end
    return nil
end

-- Returns the ZoneName a player is currently inside
function ZoneUtils.getPlayerZone(player: Player): string?
    local character = player.Character
    if not character then return nil end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    return ZoneUtils.getZoneAtPosition(hrp.Position)
end

-- Returns true if the player is in a safe zone
function ZoneUtils.isPlayerSafe(player: Player): boolean
    local zone = ZoneUtils.getPlayerZone(player)
    if not zone then return false end
    return Zones.PvPEnabled[zone] == false
end

return ZoneUtils
