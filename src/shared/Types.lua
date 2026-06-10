--[[
    Types.lua — Central type definitions for WorldCup Brainrot
]]

export type Rarity = "Common" | "Rare" | "Epic" | "Legendary"
export type CardVariant = "Normal" | "Shiny" | "Golden" | "Signed" | "Glitch"
export type CardOrigin = "Spawn" | "Event" | "Trade" | "Season" | "Match" | "Craft" | "Mission"
export type BrainrotType = "Common" | "Rare" | "Elite" | "Legendary" | "Chaotic"
export type ToolType = "StunGlove" | "Net" | "Smoke" | "Shield" | "SprintBoost" | "Detector"
export type ZoneName = "SafeZone" | "DangerZone" | "PlazaCentral" | "Parque" | "Estadio"
    | "MercadoNegro" | "Puerto" | "Barrio" | "ZonaEvento"

-- Card definition (from Config)
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

-- Card instance owned by a player
export type OwnedCard = {
    cardId: string,
    variant: CardVariant,
    obtainedAt: number,
    secured: boolean,
}

-- Brainrot NPC definition (from Config)
export type BrainrotDef = {
    id: string,
    name: string,
    brainrotType: BrainrotType,
    spawnWeight: number,
    spawnZones: { string },
    moveStyle: "Wander" | "Flee" | "Chase" | "Patrol",
    captureDifficulty: number,
    rewardsTable: { { cardId: string, weight: number } },
    canFightBack: boolean,
    eventOnly: boolean,
}

-- Player-owned base info
export type BaseData = {
    baseId: string,
    level: number,
    stickTimeSec: number,
    antistealDelaySec: number,
    extraStorage: number,
    zonePadding: number,
}

-- Player data schema — persisted via ProfileService
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
    assignedBase: string,
    baseLevel: number,
}

-- Trade session
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

-- Live brainrot NPC in the world (server-side state)
export type ActiveBrainrot = {
    instanceId: string,
    defId: string,
    model: Model,
    zone: string,
    spawnedAt: number,
    beingCaptured: boolean,
    capturedBy: number?,
}

return {}
