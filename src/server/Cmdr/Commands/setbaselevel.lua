-- Sets a player's base level directly (bypasses cost checks — for testing only).
return {
    Name        = "setbaselevel",
    Aliases     = { "baselevel", "setbase" },
    Description = "Setea el nivel de base de un jugador (1-5). Uso: setbaselevel <player> <level>",
    Group       = "Admin",
    Args        = {
        { Type = "player",  Name = "target", Description = "Jugador destino" },
        { Type = "integer", Name = "level",  Description = "Nivel de base (1-5)" },
    },
    Run = function(_context, target, level)
        if level < 1 or level > 5 then
            return "⚠ Nivel debe estar entre 1 y 5."
        end

        local ServerScriptService = game:GetService("ServerScriptService")
        local PDS     = require(ServerScriptService.Services.PlayerDataService)
        local Remotes = require(game:GetService("ReplicatedStorage").Remotes)
        local Economy = require(game:GetService("ReplicatedStorage").Config.Economy)

        local data = PDS.getData(target)
        if not data then
            return "❌ Datos de " .. target.Name .. " no cargados aún."
        end

        local prevLevel = data.baseLevel or 1

        -- Recalculate storage to avoid double-adding
        -- Remove all previous level bonus storage, apply new level's
        local prevBonus, newBonus = 0, 0
        for lvl = 2, prevLevel do
            prevBonus += (Economy.BaseLevelPerks[lvl] and Economy.BaseLevelPerks[lvl].extraStorage or 0)
        end
        for lvl = 2, level do
            newBonus += (Economy.BaseLevelPerks[lvl] and Economy.BaseLevelPerks[lvl].extraStorage or 0)
        end

        PDS.update(target, function(d)
            d.baseLevel    = level
            d.storageSlots = d.storageSlots - prevBonus + newBonus
        end)

        Remotes.BaseUpgraded:FireClient(target, {
            baseLevel = level,
            perks     = Economy.BaseLevelPerks[level],
        })

        return "✅ " .. target.Name .. " → Base Lv." .. level
    end,
}
