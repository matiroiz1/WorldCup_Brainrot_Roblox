return {
    Name        = "eliteevent",
    Aliases     = { "elite" },
    Description = "Fuerza un evento de brainrot élite ahora mismo.",
    Group       = "Admin",
    Args        = {},
    Run = function(_context)
        local EventService = require(game:GetService("ServerScriptService").Services.EventService)
        EventService.adminTriggerElite()
        return "✅ Evento élite activado."
    end,
}
