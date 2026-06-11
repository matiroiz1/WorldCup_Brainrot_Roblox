return {
    Name        = "givecoins",
    Aliases     = { "coins" },
    Description = "Da monedas a un jugador. Uso: givecoins <player> <amount>",
    Group       = "Admin",
    Args        = {
        { Type = "player",  Name = "target", Description = "Jugador destino" },
        { Type = "integer", Name = "amount", Description = "Cantidad de monedas (puede ser negativo)" },
    },
    Run = function(_context, target, amount)
        local PDS = require(game:GetService("ServerScriptService").Services.PlayerDataService)
        PDS.addCoins(target, amount)
        local sign = amount >= 0 and "+" or ""
        return "✅ " .. sign .. amount .. " monedas → " .. target.Name
    end,
}
