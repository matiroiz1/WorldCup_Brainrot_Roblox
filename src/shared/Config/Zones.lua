--[[
    Config/Zones.lua
    Zone names must match exactly the Folder names in Workspace.Map.
    The code never hardcodes zone names — always reads from here.
]]

local Zones = {}

Zones.Names = {
    Danger  = "DangerZone",
    Trading = "TradingZone",
    Pitch   = "MiniPitch",
    Safe    = "SafeZone",
}

Zones.PvPEnabled = {
    DangerZone   = true,
    TradingZone  = true,
    MiniPitch    = true,
}

Zones.CoinMultiplier = {
    DangerZone   = 1.5,
    TradingZone  = 1.0,
    MiniPitch    = 1.0,
}

Zones.RarityMultiplier = {
    DangerZone   = 1.4,
    TradingZone  = 1.0,
    MiniPitch    = 1.1,
}

return Zones
