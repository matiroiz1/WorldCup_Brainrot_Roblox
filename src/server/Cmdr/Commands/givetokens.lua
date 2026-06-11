return {
    Name        = "givetokens",
    Aliases     = { "tokens" },
    Description = "Da tokens de evento a un jugador. Uso: givetokens <player> <amount>",
    Group       = "Admin",
    Args        = {
        { Type = "player",  Name = "target", Description = "Jugador destino" },
        { Type = "integer", Name = "amount", Description = "Cantidad de tokens" },
    },
    Run = function(_context, target, amount)
        local PDS = require(game:GetService("ServerScriptService").Services.PlayerDataService)
        PDS.addTokens(target, amount)
        return "✅ +" .. amount .. " tokens → " .. target.Name
    end,
}
