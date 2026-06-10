--[[
    Modules/RarityUtils.lua
    Weighted random selection used by CardService and BrainrotSpawnService.
]]

local RarityUtils = {}

-- Select one item from a weighted table: { { value, weight }, ... }
function RarityUtils.weightedRandom(items: { { value: any, weight: number } }): any
    local totalWeight = 0
    for _, item in ipairs(items) do
        totalWeight += item.weight
    end

    local roll = math.random() * totalWeight
    local cumulative = 0
    for _, item in ipairs(items) do
        cumulative += item.weight
        if roll <= cumulative then
            return item.value
        end
    end

    return items[#items].value
end

-- Convert a rewardsTable (array of {cardId, weight}) to the format above
function RarityUtils.resolveCardDrop(rewardsTable: { { cardId: string, weight: number } }): string
    local items = {}
    for _, entry in ipairs(rewardsTable) do
        table.insert(items, { value = entry.cardId, weight = entry.weight })
    end
    return RarityUtils.weightedRandom(items)
end

return RarityUtils
