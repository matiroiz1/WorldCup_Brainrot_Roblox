return {
    Name        = "legendaryevent",
    Aliases     = { "legendary", "legend" },
    Description = "Fuerza un evento de La Leyenda Viviente (ignora cooldown).",
    Group       = "Admin",
    Args        = {},
    Run = function(_context)
        local EventService = require(game:GetService("ServerScriptService").Services.EventService)
        EventService.adminTriggerLegendary()
        return "✅ Evento legendario activado."
    end,
}
