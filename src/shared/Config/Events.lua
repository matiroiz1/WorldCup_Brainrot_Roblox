--[[
    Config/Events.lua
    Scheduled events (auto by UTC hour) and match event structure.
    Admin can override via Cmdr commands.
]]

local Events = {}

-- ── Hourly elite spawn schedule (UTC hours) ───────────────────────────
-- At these hours, an Elite brainrot spawns server-wide.
Events.EliteSpawnHours = { 12, 15, 18, 21, 0 }

-- ── Legendary event cooldown ─────────────────────────────────────────
-- After one legendary, can't spawn another for this many minutes.
Events.LegendaryEventCooldownMinutes = 180

-- ── Drop boost events ─────────────────────────────────────────────────
-- During these UTC hours, all drops +50% rarity upgrade chance.
Events.DropBoostHours = { 20, 21 }
Events.DropBoostMultiplier = 1.5

-- ── Match event structure ─────────────────────────────────────────────
-- Populated at runtime from MatchEventService.
-- Static config for prediction types and reward keys.
Events.PredictionTypes = {
    "MatchResult",
    "FinalScore",
    "FirstScorer",
}

-- ── Notification messages ─────────────────────────────────────────────
Events.Announcements = {
    EliteSpawn     = "⚡ ¡Un brainrot ÉLITE apareció en la Danger Zone!",
    LegendarySpawn = "🌟 ¡LA LEYENDA VIVIENTE apareció! ¡Todos al DangerZone!",
    DropBoostStart = "🔥 ¡Boost de drops activo! +50% rarezas por 1 hora.",
    MatchStart     = "⚽ ¡Partido comenzando! Hacé tus predicciones.",
    MatchEnd       = "🏁 Partido terminado. Recompensas de predicción enviadas.",
}

return Events
