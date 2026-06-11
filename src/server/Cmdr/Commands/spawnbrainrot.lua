return {
    Name        = "spawnbrainrot",
    Aliases     = { "spawn", "spawnb" },
    Description = "Spawnea un brainrot por su defId. Uso: spawnbrainrot <defId>",
    Group       = "Admin",
    Args        = {
        { Type = "string", Name = "defId", Description = "ID del brainrot (ej: brainrot_legendario)" },
    },
    Run = function(_context, defId)
        local BSS      = require(game:GetService("ServerScriptService").Services.BrainrotSpawnService)
        local Brainrots = require(game:GetService("ReplicatedStorage").Config.Brainrots)
        local def = Brainrots.getById(defId)
        if not def then
            return "❌ DefId inválido: " .. defId
                .. "\nDisponibles: brainrot_pelotero, brainrot_hincha, brainrot_arbitro, "
                .. "brainrot_camaraman, brainrot_vendedor, brainrot_dt, brainrot_mascota, "
                .. "brainrot_capitan, brainrot_portero_supremo, brainrot_legendario"
        end
        local instanceId = BSS.spawnBrainrot(defId)
        if instanceId then
            return "✅ Spawneado: " .. def.name .. " (instance: " .. instanceId .. ")"
        else
            return "❌ Spawn falló (sin spawn points en el mapa?)."
        end
    end,
}
