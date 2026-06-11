--[[
    Config/FarmingNodes.lua
    Configuration for static destructible clicker nodes.
]]

local FarmingNodes = {}

FarmingNodes["node_botin_oro"] = {
    id = "node_botin_oro",
    name = "Botín de Oro Falso",
    maxHealth = 100,
    respawnTimeSec = 30,
    spawnZones = { "SafeZone", "MiniPitch" },
    rewardsTable = {
        { drop = "coins", minAmount = 10, maxAmount = 50, weight = 70 },
        { drop = "shards", minAmount = 1, maxAmount = 3, weight = 30 },
    }
}

FarmingNodes["node_copa_mundo"] = {
    id = "node_copa_mundo",
    name = "Réplica de la Copa",
    maxHealth = 250,
    respawnTimeSec = 60,
    spawnZones = { "DangerZone" },
    rewardsTable = {
        { drop = "coins", minAmount = 50, maxAmount = 150, weight = 60 },
        { drop = "shards", minAmount = 3, maxAmount = 10, weight = 35 },
        { drop = "card_rare_wc2026_player_random", minAmount = 1, maxAmount = 1, weight = 5 },
    }
}

FarmingNodes.getById = function(id: string)
    return FarmingNodes[id]
end

FarmingNodes.getAll = function()
    local result = {}
    for id, def in pairs(FarmingNodes) do
        if type(def) == "table" then
            table.insert(result, def)
        end
    end
    return result
end

return FarmingNodes
