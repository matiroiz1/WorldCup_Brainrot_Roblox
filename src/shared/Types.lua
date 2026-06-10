--[[
    Types.lua — Central type definitions for WorldCup Brainrot
    All types used across server/client/shared live here.
]]

export type Rarity = "Common" | "Rare" | "Epic" | "Legendary"
export type CardVariant = "Normal" | "Shiny" | "Golden" | "Signed" | "Glitch"
export type CardOrigin = "Spawn" | "Event" | "Trade" | "Season" | "Match" | "Craft" | "Mission"
export type ZoneName = "SafeZone" | "DangerZone" | "TradingZone" | "MiniPitch"
export type BrainrotType = "Common" | "Rare" | "Elite" | "Legendary" | "Chaotic"
export type ToolType = "StunGlove" | "Net" | "Smoke" | "Shield" | "SprintBoost" | "Detector"

-- Card data definition
export type CardDef = {
    cardId: string,
    playerName: string,
    tournament: string,
    year: number,
    country: string,
    rarity: Rarity,
    variant: CardVariant,
    dropSources: { CardOrigin },
    tradable: boolean,
    albumSetId: string,
    marketBaseValue: number,
    eventTags: { string },
}

-- Player's owned card instance
export type OwnedCard = {
    cardId: string,
    variant: CardVariant,
    obtainedAt: number,
    secured: boolean,
}

-- Brainrot NPC definition
export type BrainrotDef = {
    id: string,
    name: string,
    brainrotType: BrainrotType,
    spawnWeight: number,
    spawnZones: { ZoneName },
    moveStyle: "Wander" | "Flee" | "Chase" | "Patrol",
    captureDifficulty: number,
    rewardsTable: { { cardId: string, weight: number } },
    canFightBack: boolean,
    eventOnly: boolean,
}

-- Player data schema (what gets persisted in ProfileStore)
export type PlayerData = {
    coins: number,
    eventTokens: number,
    cards: { OwnedCard },
    securedCards: { OwnedCard },
    albumProgress: { [string]: boolean },
    inventorySlots: number,
    storageSlots: number,
    toolUpgrades: { [string]: number },
    missionProgress: { [string]: number },
    dailyStreak: number,
    lastLogin: number,
    weeklyScore: number,
    seasonScore: number,
    totalCaptures: number,
}

-- Trade session between two players
export type TradeSession = {
    sessionId: string,
    playerA: number,
    playerB: number,
    offeredA: { OwnedCard },
    offeredB: { OwnedCard },
    confirmedA: boolean,
    confirmedB: boolean,
    createdAt: number,
}

-- Active brainrot NPC in the world
export type ActiveBrainrot = {
    instanceId: string,
    defId: string,
    position: Vector3,
    zone: ZoneName,
    spawnedAt: number,
    chasedBy: { number },
}

return {}
