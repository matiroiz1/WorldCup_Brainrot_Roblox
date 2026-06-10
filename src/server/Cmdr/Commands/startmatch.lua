return {
    Name        = "startmatch",
    Aliases     = { "match" },
    Description = "Crea e inicia un partido para predicciones. Uso: startmatch <TeamA> <TeamB>",
    Group       = "Admin",
    Args        = {
        { Type = "string", Name = "teamA", Description = "Equipo local (ej: Argentina)" },
        { Type = "string", Name = "teamB", Description = "Equipo visitante (ej: Brasil)" },
    },
    Run = function(_context, teamA, teamB)
        local MES = require(game:GetService("ServerScriptService").Services.MatchEventService)
        local existing = MES.getCurrentMatch()
        if existing and existing.status == "active" then
            return "⚠ Ya hay un partido activo: " .. existing.teamA .. " vs " .. existing.teamB .. ". Usá endmatch primero."
        end
        local id = MES.createMatch(teamA, teamB)
        MES.startMatch(id)
        return "✅ Partido iniciado: " .. teamA .. " vs " .. teamB .. " (id: " .. id .. ")"
    end,
}
