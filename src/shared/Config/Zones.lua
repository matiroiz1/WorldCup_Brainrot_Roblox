--[[
    Config/Zones.lua
    Zone names must match exactly the Folder names in Workspace.Map.
    The code never hardcodes zone names — always reads from here.
]]

local Zones = {}

Zones.Names = {
    Danger  = "DangerZone",
    Trading = "TradeZone",
    Pitch   = "Estadio",
}

-- Which zones allow PvP
Zones.PvPEnabled = {
    DangerZone  = true,
    TradeZone = true,
    Estadio   = true,
}

-- Coin multiplier per zone
Zones.CoinMultiplier = {
    DangerZone  = 1.5,
    TradeZone = 1.0,
    Estadio   = 1.0,
}

-- Drop rarity multiplier per zone
Zones.RarityMultiplier = {
    DangerZone  = 1.4,
    TradeZone = 1.0,
    Estadio   = 1.1,
}

return Zones
