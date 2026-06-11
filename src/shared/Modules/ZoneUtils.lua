--[[
    Modules/ZoneUtils.lua
    Zone detection via AABB checks on Boundary Parts.

    Priority (highest first):
      1. PlayerBases  → "PlayerBase:Base_N"
      2. DangerZone   → "DangerZone"
      nil             → outside map
]]

local Workspace = game:GetService("Workspace")
local Zones     = require(script.Parent.Parent.Config.Zones)

local ZoneUtils = {}

-- ── AABB helper ───────────────────────────────────────────────────────

local function isInsidePart(part: BasePart, position: Vector3): boolean
    local local_ = part.CFrame:PointToObjectSpace(position)
    local half   = part.Size / 2
    return math.abs(local_.X) <= half.X
       and math.abs(local_.Y) <= half.Y
       and math.abs(local_.Z) <= half.Z
end

-- ── Named-zone parts cache ────────────────────────────────────────────
-- Cached once (map doesn't change at runtime).

local _zonePartsCache: { [string]: { BasePart } }? = nil

local function getZonePartsAll(): { [string]: { BasePart } }
    if _zonePartsCache then return _zonePartsCache end

    local cache: { [string]: { BasePart } } = {}
    local map = Workspace:FindFirstChild("Map")

    for _, zoneName in pairs(Zones.Names) do
        cache[zoneName] = {}
        if map then
            local folder = map:FindFirstChild(zoneName)
            if folder then
                for _, child in ipairs(folder:GetDescendants()) do
                    if child:IsA("BasePart") and child.Name == "Boundary" then
                        table.insert(cache[zoneName], child :: BasePart)
                    end
                end
            end
        end
    end

    _zonePartsCache = cache
    return cache
end

-- ── PlayerBase detection ──────────────────────────────────────────────

local function getBaseAtPosition(position: Vector3): string?
    local map = Workspace:FindFirstChild("Map")
    if not map then return nil end
    local basesFolder = map:FindFirstChild("PlayerBases")
    if not basesFolder then return nil end
    for _, folder in ipairs(basesFolder:GetChildren()) do
        if folder:IsA("Model") or folder:IsA("Folder") then
            local boundary = folder:FindFirstChild("Boundary")
            if boundary and boundary:IsA("BasePart") then
                if isInsidePart(boundary :: BasePart, position) then
                    return folder.Name  -- "Base_1" … "Base_15"
                end
            end
        end
    end
    return nil
end

-- ── Public API ────────────────────────────────────────────────────────

-- Returns zone tag: "PlayerBase:Base_N", a Zones.Names value, or nil.
function ZoneUtils.getZoneAtPosition(position: Vector3): string?
    -- Priority 1: player bases
    local baseId = getBaseAtPosition(position)
    if baseId then return "PlayerBase:" .. baseId end

    -- Priority 2: named zones (DangerZone, TradeZone, etc.)
    local cache = getZonePartsAll()
    for _, zoneName in pairs(Zones.Names) do
        for _, part in ipairs(cache[zoneName] or {}) do
            if isInsidePart(part, position) then
                return zoneName
            end
        end
    end

    return "DangerZone" -- Default to DangerZone if on map
end

-- Returns the zone tag for a player's HumanoidRootPart position.
function ZoneUtils.getPlayerZone(player: Player): string?
    local char = player.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    return ZoneUtils.getZoneAtPosition(hrp.Position)
end

-- Returns true if the player is currently in a safe (non-PvP) zone.
function ZoneUtils.isPlayerSafe(player: Player): boolean
    local zone = ZoneUtils.getPlayerZone(player)
    if not zone then return false end
    
    if zone:sub(1, 11) == "PlayerBase:" then
        local baseId = zone:sub(12)
        -- Check with BaseService if this base is currently locked
        -- We must use a safe require to avoid circular dependencies if called from client
        local ok, BaseService = pcall(function()
            return require(script.Parent.Parent.Parent.server.Services.BaseService)
        end)
        
        if ok and BaseService then
            return BaseService.isBaseLocked(baseId)
        else
            -- If on client, or BaseService not available, we assume it's unsafe 
            -- or rely on a ReplicatedStorage state (For now, assume false on client)
            -- A proper implementation would sync LockedBases to ReplicatedStorage.
            return false 
        end
    end
    
    return false -- Everything else is PvP
end

-- Returns "Base_N" if position is inside any player base, else nil.
function ZoneUtils.getBaseAtPosition(position: Vector3): string?
    return getBaseAtPosition(position)
end

-- Returns "Base_N" if the player is inside any base boundary, else nil.
function ZoneUtils.getPlayerBase(player: Player): string?
    local char = player.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    return getBaseAtPosition(hrp.Position)
end

-- Invalidate cache (call if map structure changes at runtime).
function ZoneUtils.invalidateCache()
    _zonePartsCache = nil
end

return ZoneUtils
