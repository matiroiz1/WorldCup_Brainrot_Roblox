return {
    Name        = "clearbrainrots",
    Aliases     = { "clearb", "despawnall" },
    Description = "Despawnea todos los brainrots activos.",
    Group       = "Admin",
    Args        = {},
    Run = function(_context)
        local BSS    = require(game:GetService("ServerScriptService").Services.BrainrotSpawnService)
        local active = BSS.getActive()
        local count  = 0
        -- Collect ids first (can't mutate while iterating)
        local ids = {}
        for id in pairs(active) do
            table.insert(ids, id)
        end
        for _, id in ipairs(ids) do
            BSS.despawnBrainrot(id)
            count += 1
        end
        return "✅ Despawneados " .. count .. " brainrot(s)."
    end,
}
