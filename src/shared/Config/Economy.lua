--[[
    Config/Economy.lua
    All economic constants: prices, cooldowns, drop windows, slot costs.
    Change values here only — never hardcode in services.
]]

local Economy = {}

-- ── Starting values ───────────────────────────────────────────────────
Economy.StartingCoins        = 100
Economy.StartingInventorySlots = 10
Economy.StartingStorageSlots   = 5

-- ── Capture rewards (coins) ───────────────────────────────────────────
Economy.CaptureCoins = {
    Common    = 15,
    Rare      = 40,
    Elite     = 100,
    Legendary = 500,
    Chaotic   = 30,
}

-- ── Card secure window ────────────────────────────────────────────────
-- Seconds after capture during which cards are unprotected (stealable in Etapa 9)
Economy.SecureWindowSeconds = 15

-- ── Slot shop prices (coins) ─────────────────────────────────────────
Economy.SlotPrices = {
    InventorySlot = { 50, 100, 200, 400, 800, 1600 },
    StorageSlot   = { 80, 160, 320, 640, 1280 },
}

-- ── Tool upgrade prices (coins) ───────────────────────────────────────
Economy.ToolUpgradePrices = {
    StunGlove  = { 120, 300, 600 },
    Net        = { 150, 350, 700 },
    Shield     = { 200, 400, 800 },
    SprintBoost = { 100, 250, 500 },
    Detector   = { 180, 400, 800 },
}

-- ── Trade ─────────────────────────────────────────────────────────────
Economy.TradeRequestTimeoutSeconds = 30
Economy.TradeSessionTimeoutSeconds = 120

-- ── Mission rewards ───────────────────────────────────────────────────
Economy.MissionRewards = {
    DailyCapture3   = { coins = 50,  tokens = 1 },
    DailyCapture10  = { coins = 150, tokens = 3 },
    WeeklyAlbumPage = { coins = 300, tokens = 5 },
    WeeklyCapture50 = { coins = 500, tokens = 10 },
}

-- ── Daily streak ──────────────────────────────────────────────────────
Economy.StreakRewards = {
    [1] = { coins = 30,  tokens = 0 },
    [2] = { coins = 50,  tokens = 1 },
    [3] = { coins = 75,  tokens = 1 },
    [5] = { coins = 150, tokens = 2 },
    [7] = { coins = 300, tokens = 5 },
}

-- ── Match prediction ─────────────────────────────────────────────────
Economy.PredictionRewards = {
    CorrectResult  = { coins = 100, tokens = 2 },
    CorrectScore   = { coins = 300, tokens = 5 },
    CorrectScorer  = { coins = 200, tokens = 3 },
}

-- ── Spawn rates & timing ──────────────────────────────────────────────
Economy.SpawnIntervalSeconds      = 45
Economy.MaxCommonBrainrotsPerZone = 3
Economy.MaxRareBrainrotsPerServer = 2
Economy.EliteEventIntervalMinutes = 60
Economy.LegendaryEventCooldownMinutes = 180

-- ── Max players per server ────────────────────────────────────────────
Economy.MaxPlayersPerServer = 15

-- ── Base upgrade costs ────────────────────────────────────────────────
-- Levels 2-3: coins only. Levels 4-5: Robux required.
Economy.BaseUpgradeCosts = {
    [2] = { coins = 400,  robux = 0   },
    [3] = { coins = 1200, robux = 0   },
    [4] = { coins = 0,    robux = 75  },
    [5] = { coins = 0,    robux = 200 },
}

-- Perks per base level
-- stickTimeSec:      seconds to secure a card into the album
-- antistealDelaySec: seconds intruder must wait before stealing (Etapa 9)
-- extraStorage:      bonus storage slots granted at this level
-- zonePadding:       extra studs added to safe zone radius (future use)
Economy.BaseLevelPerks = {
    [1] = { stickTimeSec = 20, antistealDelaySec = 2,  extraStorage = 0,  zonePadding = 0  },
    [2] = { stickTimeSec = 14, antistealDelaySec = 5,  extraStorage = 2,  zonePadding = 3  },
    [3] = { stickTimeSec = 8,  antistealDelaySec = 10, extraStorage = 5,  zonePadding = 6  },
    [4] = { stickTimeSec = 4,  antistealDelaySec = 18, extraStorage = 10, zonePadding = 10 },
    [5] = { stickTimeSec = 1,  antistealDelaySec = 30, extraStorage = 20, zonePadding = 15 },
}

return Economy
