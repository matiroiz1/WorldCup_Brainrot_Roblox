--[[
    Config/Zones.lua
    Zone names must match exactly the Folder names in Workspace.Map.
    The code never hardcodes zone names — always reads from here.
]]

local Zones = {}

Zones.Names = {
    Safe    = "SafeZone",
    Danger  = "DangerZone",
    Trading = "TradingZone",
    Pitch   = "MiniPitch",
}

-- Which zones allow PvP (Etapa 9)
Zones.PvPEnabled = {
    SafeZone    = false,
    DangerZone  = true,
    TradingZone = false,
    MiniPitch   = false,
}

-- Coin multiplier per zone (DangerZone pays more)
Zones.CoinMultiplier = {
    SafeZone    = 0.8,
    DangerZone  = 1.5,
    TradingZone = 1.0,
    MiniPitch   = 1.0,
}

-- Drop rarity multiplier per zone
Zones.RarityMultiplier = {
    SafeZone    = 0.8,
    DangerZone  = 1.4,
    TradingZone = 1.0,
    MiniPitch   = 1.1,
}

return Zones
