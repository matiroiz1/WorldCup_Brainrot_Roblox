-- endmatch <winner> <scoreA> <scoreB> [scorer]
-- winner: "teamA" | "teamB" | "draw"
-- scoreA/scoreB: integers
-- scorer: optional string
return {
    Name        = "endmatch",
    Aliases     = { "finishmatch" },
    Description = "Termina el partido activo y reparte recompensas. Uso: endmatch <teamA|teamB|draw> <scoreA> <scoreB> [goleador]",
    Group       = "Admin",
    Args        = {
        { Type = "string",  Name = "winner",  Description = "teamA | teamB | draw" },
        { Type = "integer", Name = "scoreA",  Description = "Goles del equipo local" },
        { Type = "integer", Name = "scoreB",  Description = "Goles del equipo visitante" },
        { Type = "string",  Name = "scorer",  Description = "Primer goleador (opcional)", Optional = true },
    },
    Run = function(_context, winner, scoreA, scoreB, scorer)
        local MES = require(game:GetService("ServerScriptService").Services.MatchEventService)
        local match = MES.getCurrentMatch()
        if not match then
            return "⚠ No hay ningún partido activo."
        end
        if winner ~= "teamA" and winner ~= "teamB" and winner ~= "draw" then
            return '⚠ winner debe ser "teamA", "teamB" o "draw".'
        end
        local ok = MES.endMatch(match.matchId, winner, scoreA, scoreB, scorer)
        if not ok then
            return "❌ No se pudo terminar el partido."
        end
        local winLabel = winner == "teamA" and match.teamA
            or winner == "teamB" and match.teamB
            or "Empate"
        return "✅ Partido terminado. Ganador: " .. winLabel
            .. " | " .. scoreA .. "-" .. scoreB
            .. (scorer and (" | Goleador: " .. scorer) or "")
    end,
}
