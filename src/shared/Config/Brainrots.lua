--[[
    Config/Brainrots.lua
    Table of all brainrot NPC definitions for WorldCup Brainrot MVP.
    10 brainrots: 5 Common, 2 Rare, 2 Elite, 1 Legendary
]]

local Brainrots = {}

-- ── Common (always active, all zones) ────────────────────────────────

Brainrots["brainrot_pelotero"] = {
    id = "brainrot_pelotero",
    name = "Pelotero Loco",
    brainrotType = "Common",
    spawnWeight = 30,
    spawnZones = { "DangerZone", "SafeZone" },
    moveStyle = "Wander",
    captureDifficulty = 1,
    rewardsTable = {
        { cardId = "card_common_wc2026_player_random", weight = 70 },
        { cardId = "card_rare_wc2026_player_random",   weight = 25 },
        { cardId = "card_epic_wc2026_player_random",   weight = 5 },
    },
    canFightBack = false,
    eventOnly = false,
}

Brainrots["brainrot_hincha"] = {
    id = "brainrot_hincha",
    name = "Hincha Desbordado",
    brainrotType = "Common",
    spawnWeight = 28,
    spawnZones = { "DangerZone", "MiniPitch" },
    moveStyle = "Wander",
    captureDifficulty = 1,
    rewardsTable = {
        { cardId = "card_common_wc2026_player_random", weight = 75 },
        { cardId = "card_rare_wc2026_player_random",   weight = 20 },
        { cardId = "card_epic_wc2026_player_random",   weight = 5 },
    },
    canFightBack = false,
    eventOnly = false,
}

Brainrots["brainrot_arbitro"] = {
    id = "brainrot_arbitro",
    name = "Árbitro Caótico",
    brainrotType = "Common",
    spawnWeight = 25,
    spawnZones = { "DangerZone" },
    moveStyle = "Patrol",
    captureDifficulty = 2,
    rewardsTable = {
        { cardId = "card_common_wc2026_player_random", weight = 60 },
        { cardId = "card_rare_wc2026_player_random",   weight = 30 },
        { cardId = "card_epic_wc2026_player_random",   weight = 10 },
    },
    canFightBack = false,
    eventOnly = false,
}

Brainrots["brainrot_camaraman"] = {
    id = "brainrot_camaraman",
    name = "Camarógrafo Viral",
    brainrotType = "Common",
    spawnWeight = 22,
    spawnZones = { "DangerZone", "MiniPitch", "TradingZone" },
    moveStyle = "Wander",
    captureDifficulty = 1,
    rewardsTable = {
        { cardId = "card_common_wc2026_player_random", weight = 65 },
        { cardId = "card_rare_wc2026_player_random",   weight = 30 },
        { cardId = "card_epic_wc2026_player_random",   weight = 5 },
    },
    canFightBack = false,
    eventOnly = false,
}

Brainrots["brainrot_vendedor"] = {
    id = "brainrot_vendedor",
    name = "Vendedor Ambulante",
    brainrotType = "Common",
    spawnWeight = 20,
    spawnZones = { "TradingZone", "SafeZone" },
    moveStyle = "Wander",
    captureDifficulty = 2,
    rewardsTable = {
        { cardId = "card_common_wc2026_player_random", weight = 50 },
        { cardId = "card_rare_wc2026_player_random",   weight = 35 },
        { cardId = "card_epic_wc2026_player_random",   weight = 15 },
    },
    canFightBack = false,
    eventOnly = false,
}

-- ── Rare (every few minutes) ──────────────────────────────────────────

Brainrots["brainrot_dt"] = {
    id = "brainrot_dt",
    name = "DT Obsesionado",
    brainrotType = "Rare",
    spawnWeight = 10,
    spawnZones = { "DangerZone" },
    moveStyle = "Flee",
    captureDifficulty = 3,
    rewardsTable = {
        { cardId = "card_rare_wc2026_player_random",     weight = 55 },
        { cardId = "card_epic_wc2026_player_random",     weight = 35 },
        { cardId = "card_legendary_historical_random",   weight = 10 },
    },
    canFightBack = false,
    eventOnly = false,
}

Brainrots["brainrot_mascota"] = {
    id = "brainrot_mascota",
    name = "Mascota Oficial Mutante",
    brainrotType = "Rare",
    spawnWeight = 8,
    spawnZones = { "DangerZone", "MiniPitch" },
    moveStyle = "Flee",
    captureDifficulty = 3,
    rewardsTable = {
        { cardId = "card_rare_wc2026_player_random",     weight = 50 },
        { cardId = "card_epic_wc2026_player_random",     weight = 35 },
        { cardId = "card_legendary_historical_random",   weight = 15 },
    },
    canFightBack = false,
    eventOnly = false,
}

-- ── Elite (fixed-hour events) ─────────────────────────────────────────

Brainrots["brainrot_capitan"] = {
    id = "brainrot_capitan",
    name = "Capitán Dorado",
    brainrotType = "Elite",
    spawnWeight = 4,
    spawnZones = { "DangerZone" },
    moveStyle = "Flee",
    captureDifficulty = 5,
    rewardsTable = {
        { cardId = "card_epic_wc2026_player_random",     weight = 50 },
        { cardId = "card_legendary_historical_random",   weight = 35 },
        { cardId = "card_golden_legend_random",          weight = 15 },
    },
    canFightBack = true,
    eventOnly = false,
}

Brainrots["brainrot_portero_supremo"] = {
    id = "brainrot_portero_supremo",
    name = "Portero Supremo",
    brainrotType = "Elite",
    spawnWeight = 3,
    spawnZones = { "DangerZone" },
    moveStyle = "Chase",
    captureDifficulty = 6,
    rewardsTable = {
        { cardId = "card_epic_wc2026_player_random",     weight = 40 },
        { cardId = "card_legendary_historical_random",   weight = 40 },
        { cardId = "card_golden_legend_random",          weight = 20 },
    },
    canFightBack = true,
    eventOnly = false,
}

-- ── Legendary (server-wide event) ────────────────────────────────────

Brainrots["brainrot_legendario"] = {
    id = "brainrot_legendario",
    name = "La Leyenda Viviente",
    brainrotType = "Legendary",
    spawnWeight = 1,
    spawnZones = { "DangerZone" },
    moveStyle = "Flee",
    captureDifficulty = 10,
    rewardsTable = {
        { cardId = "card_legendary_historical_random",   weight = 40 },
        { cardId = "card_golden_legend_random",          weight = 35 },
        { cardId = "card_golden_cr7",                    weight = 10 },
        { cardId = "card_golden_messi",                  weight = 10 },
        { cardId = "card_signed_legend_random",          weight = 5 },
    },
    canFightBack = true,
    eventOnly = true,
}

-- Lookup by id
Brainrots.getById = function(id: string)
    return Brainrots[id]
end

-- All non-event brainrots
Brainrots.getAllSpawnable = function()
    local result = {}
    for id, def in pairs(Brainrots) do
        if type(def) == "table" and not def.eventOnly then
            table.insert(result, def)
        end
    end
    return result
end

return Brainrots
