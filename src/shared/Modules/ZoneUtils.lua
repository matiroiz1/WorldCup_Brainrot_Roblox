--[[
    Modules/ZoneUtils.lua
    Zone detection via AABB checks on Boundary Parts.

    Priority (highest first):
      1. PlayerBases  → "PlayerBase:Base_N"
      2. MiniPitch    → "MiniPitch"
      3. TradingZone  → "TradingZone"
      4. SafeZone     → "SafeZone"
      5. DangerZone   → "DangerZone"
      nil             → outside map

    PlayerBases checked first because base plots sit inside DangerZone
    and would otherwise be incorrectly labelled as danger.
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
                    if child:IsA("BasePart") then
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
        if folder:IsA("Folder") then
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

-- ── Zone detection priority ───────────────────────────────────────────
-- Named zones checked in this order after PlayerBase check.
local NAMED_PRIORITY = {
    Zones.Names.Pitch,    -- MiniPitch
    Zones.Names.Trading,  -- TradingZone
    Zones.Names.Safe,     -- SafeZone
    Zones.Names.Danger,   -- DangerZone
}

-- ── Public API ────────────────────────────────────────────────────────

-- Returns zone tag: "PlayerBase:Base_N", a Zones.Names value, or nil.
function ZoneUtils.getZoneAtPosition(position: Vector3): string?
    -- Priority 1: player bases
    local baseId = getBaseAtPosition(position)
    if baseId then return "PlayerBase:" .. baseId end

    -- Priority 2-5: named zones
    local cache = getZonePartsAll()
    for _, zoneName in ipairs(NAMED_PRIORITY) do
        for _, part in ipairs(cache[zoneName] or {}) do
            if isInsidePart(part, position) then
                return zoneName
            end
        end
    end

    return nil
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
-- All PlayerBases are safe pre-Etapa 9; Etapa 9 will refine to owner-only.
function ZoneUtils.isPlayerSafe(player: Player): boolean
    local zone = ZoneUtils.getPlayerZone(player)
    if not zone then return true end  -- outside map → safe by default
    if zone:sub(1, 11) == "PlayerBase:" then return true end
    return Zones.PvPEnabled[zone] == false
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

-- Returns true if the player is inside their own assigned base.
-- Requires BaseService; use only on server.
function ZoneUtils.isInOwnBase(player: Player): boolean
    local baseId = ZoneUtils.getPlayerBase(player)
    if not baseId then return false end
    local BaseService = require(script.Parent.Parent.Parent.Services.BaseService)
    return BaseService.getPlayerBase(player) == baseId
end

-- Returns the coin multiplier for a zone tag.
function ZoneUtils.getCoinMultiplier(zoneTag: string?): number
    if not zoneTag then return 1.0 end
    if zoneTag:sub(1, 11) == "PlayerBase:" then return 1.0 end
    return Zones.CoinMultiplier[zoneTag] or 1.0
end

-- Returns the rarity multiplier for a zone tag.
function ZoneUtils.getRarityMultiplier(zoneTag: string?): number
    if not zoneTag then return 1.0 end
    if zoneTag:sub(1, 11) == "PlayerBase:" then return 1.0 end
    return Zones.RarityMultiplier[zoneTag] or 1.0
end

-- Invalidate cache (call if map structure changes at runtime).
function ZoneUtils.invalidateCache()
    _zonePartsCache = nil
end

return ZoneUtils
