return {
    Name        = "dropboost",
    Aliases     = { "boost" },
    Description = "Toggle drop boost (+50% rareza en drops).",
    Group       = "Admin",
    Args        = {},
    Run = function(_context)
        local EventService = require(game:GetService("ServerScriptService").Services.EventService)
        EventService.adminToggleDropBoost()
        local state = EventService.isDropBoostActive() and "ACTIVADO" or "DESACTIVADO"
        return "✅ Drop boost " .. state .. "."
    end,
}
