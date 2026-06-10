--[[
    Config/Monetization.lua
    GamePass and Developer Product IDs + what they grant.

    IMPORTANT: Replace placeholder IDs (999xxxxx) with real IDs
    from Creator Hub BEFORE publishing. Never use placeholder IDs live.
]]

local Monetization = {}

-- ── GamePasses (one-time purchase, permanent benefit) ─────────────────
Monetization.GamePasses = {
    VIP = {
        id = 999000001,
        name = "VIP Mundial",
        description = "Doble monedas, slot extra de storage, icono VIP.",
        perks = {
            coinMultiplier = 2.0,
            extraStorageSlots = 3,
            vipBadge = true,
        },
    },
    PremiumStorage = {
        id = 999000002,
        name = "Bóveda Premium",
        description = "+10 slots de storage seguros permanentes.",
        perks = {
            extraStorageSlots = 10,
        },
    },
    SpeedBoost = {
        id = 999000003,
        name = "Botas Mágicas",
        description = "Velocidad de movimiento permanentemente +15%.",
        perks = {
            speedMultiplier = 1.15,
        },
    },
}

-- ── Developer Products (repeatable purchases) ─────────────────────────
Monetization.DevProducts = {
    CoinPack_Small = {
        id = 999001001,
        name = "Pack Monedas Chico",
        description = "500 monedas.",
        grant = { coins = 500 },
    },
    CoinPack_Medium = {
        id = 999001002,
        name = "Pack Monedas Medio",
        description = "1500 monedas.",
        grant = { coins = 1500 },
    },
    CoinPack_Large = {
        id = 999001003,
        name = "Pack Monedas Grande",
        description = "5000 monedas.",
        grant = { coins = 5000 },
    },
    TokenPack = {
        id = 999001004,
        name = "Pack Tokens Evento",
        description = "20 tokens de evento.",
        grant = { eventTokens = 20 },
    },
    WelcomePack = {
        id = 999001005,
        name = "Pack Bienvenida",
        description = "300 monedas + 5 tokens + 2 slots de inventario.",
        grant = { coins = 300, eventTokens = 5, inventorySlots = 2 },
    },
    ProtectionShield = {
        id = 999001006,
        name = "Escudo 30min",
        description = "30 minutos de protección de cartas sin asegurar.",
        grant = { shieldMinutes = 30 },
    },
}

-- ── Lookup helpers ────────────────────────────────────────────────────
Monetization.getGamePassById = function(id: number)
    for _, pass in pairs(Monetization.GamePasses) do
        if pass.id == id then return pass end
    end
    return nil
end

Monetization.getDevProductById = function(id: number)
    for _, product in pairs(Monetization.DevProducts) do
        if product.id == id then return product end
    end
    return nil
end

return Monetization
