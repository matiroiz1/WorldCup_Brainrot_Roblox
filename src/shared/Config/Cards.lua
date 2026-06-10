--[[
    Config/Cards.lua
    All card definitions for WorldCup Brainrot MVP.

    Sets:
      - wc2026      : Current World Cup 2026 (album base)
      - historical  : Past World Cup legends (high rarity, non-album)
      - golden      : Golden variants of top legends (Messi, CR7, etc.)
      - signed      : Signed variants (very rare)
]]

local Cards = {}

-- ── Album Set: WC2026 ────────────────────────────────────────────────
-- These form the completable album. All obtainable f2p with time.

Cards["card_common_wc2026_arg"] = {
    cardId = "card_common_wc2026_arg",
    playerName = "Argentina - Jugador",
    tournament = "World Cup 2026",
    year = 2026,
    country = "Argentina",
    rarity = "Common",
    variant = "Normal",
    dropSources = { "Spawn", "Mission" },
    tradable = true,
    albumSetId = "wc2026",
    marketBaseValue = 10,
    eventTags = {},
}

Cards["card_common_wc2026_bra"] = {
    cardId = "card_common_wc2026_bra",
    playerName = "Brasil - Jugador",
    tournament = "World Cup 2026",
    year = 2026,
    country = "Brasil",
    rarity = "Common",
    variant = "Normal",
    dropSources = { "Spawn", "Mission" },
    tradable = true,
    albumSetId = "wc2026",
    marketBaseValue = 10,
    eventTags = {},
}

Cards["card_common_wc2026_fra"] = {
    cardId = "card_common_wc2026_fra",
    playerName = "Francia - Jugador",
    tournament = "World Cup 2026",
    year = 2026,
    country = "Francia",
    rarity = "Common",
    variant = "Normal",
    dropSources = { "Spawn", "Mission" },
    tradable = true,
    albumSetId = "wc2026",
    marketBaseValue = 10,
    eventTags = {},
}

Cards["card_common_wc2026_eng"] = {
    cardId = "card_common_wc2026_eng",
    playerName = "Inglaterra - Jugador",
    tournament = "World Cup 2026",
    year = 2026,
    country = "Inglaterra",
    rarity = "Common",
    variant = "Normal",
    dropSources = { "Spawn", "Mission" },
    tradable = true,
    albumSetId = "wc2026",
    marketBaseValue = 10,
    eventTags = {},
}

Cards["card_common_wc2026_esp"] = {
    cardId = "card_common_wc2026_esp",
    playerName = "España - Jugador",
    tournament = "World Cup 2026",
    year = 2026,
    country = "España",
    rarity = "Common",
    variant = "Normal",
    dropSources = { "Spawn", "Mission" },
    tradable = true,
    albumSetId = "wc2026",
    marketBaseValue = 10,
    eventTags = {},
}

Cards["card_rare_wc2026_player_random"] = {
    cardId = "card_rare_wc2026_player_random",
    playerName = "WC2026 - Figura",
    tournament = "World Cup 2026",
    year = 2026,
    country = "Unknown",
    rarity = "Rare",
    variant = "Normal",
    dropSources = { "Spawn", "Event" },
    tradable = true,
    albumSetId = "wc2026",
    marketBaseValue = 80,
    eventTags = {},
}

Cards["card_epic_wc2026_player_random"] = {
    cardId = "card_epic_wc2026_player_random",
    playerName = "WC2026 - Estrella",
    tournament = "World Cup 2026",
    year = 2026,
    country = "Unknown",
    rarity = "Epic",
    variant = "Normal",
    dropSources = { "Spawn", "Event", "Mission" },
    tradable = true,
    albumSetId = "wc2026",
    marketBaseValue = 350,
    eventTags = {},
}

-- ── Historical Legends (non-album, high value) ────────────────────────

Cards["card_legendary_historical_random"] = {
    cardId = "card_legendary_historical_random",
    playerName = "Leyenda Histórica",
    tournament = "Historical",
    year = 0,
    country = "Unknown",
    rarity = "Legendary",
    variant = "Normal",
    dropSources = { "Spawn", "Event", "Craft" },
    tradable = true,
    albumSetId = "historical",
    marketBaseValue = 1000,
    eventTags = { "historical" },
}

-- ── Golden Variants — Top Legends ────────────────────────────────────

Cards["card_golden_messi"] = {
    cardId = "card_golden_messi",
    playerName = "La Pulga Inmortal",
    tournament = "Historical",
    year = 0,
    country = "Argentina",
    rarity = "Legendary",
    variant = "Golden",
    dropSources = { "Event" },
    tradable = true,
    albumSetId = "golden",
    marketBaseValue = 5000,
    eventTags = { "historical", "golden", "legend" },
}

Cards["card_golden_cr7"] = {
    cardId = "card_golden_cr7",
    playerName = "El Bicho Eterno",
    tournament = "Historical",
    year = 0,
    country = "Portugal",
    rarity = "Legendary",
    variant = "Golden",
    dropSources = { "Event" },
    tradable = true,
    albumSetId = "golden",
    marketBaseValue = 5000,
    eventTags = { "historical", "golden", "legend" },
}

Cards["card_golden_legend_random"] = {
    cardId = "card_golden_legend_random",
    playerName = "Leyenda Dorada",
    tournament = "Historical",
    year = 0,
    country = "Unknown",
    rarity = "Legendary",
    variant = "Golden",
    dropSources = { "Event", "Craft" },
    tradable = true,
    albumSetId = "golden",
    marketBaseValue = 3000,
    eventTags = { "historical", "golden" },
}

Cards["card_signed_legend_random"] = {
    cardId = "card_signed_legend_random",
    playerName = "Firmada - Leyenda",
    tournament = "Historical",
    year = 0,
    country = "Unknown",
    rarity = "Legendary",
    variant = "Signed",
    dropSources = { "Event" },
    tradable = true,
    albumSetId = "golden",
    marketBaseValue = 8000,
    eventTags = { "historical", "signed", "legend" },
}

-- ── Helpers ───────────────────────────────────────────────────────────

Cards.getById = function(id: string)
    return Cards[id]
end

-- Return all cards belonging to a given albumSetId
Cards.getSetCards = function(setId: string)
    local result = {}
    for id, def in pairs(Cards) do
        if type(def) == "table" and def.albumSetId == setId then
            table.insert(result, def)
        end
    end
    return result
end

return Cards
