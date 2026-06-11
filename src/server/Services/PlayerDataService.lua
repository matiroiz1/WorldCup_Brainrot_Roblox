local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local RunService         = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local ProfileStore = require(ServerScriptService.Packages.ProfileService)
local Remotes      = require(ReplicatedStorage.Remotes)
local Economy      = require(ReplicatedStorage.Config.Economy)

-- ── Data schema ───────────────────────────────────────────────────────
-- Every new player gets this default data. Reconcile() fills in missing keys
-- for existing players after updates.
local DEFAULT_DATA = {
    coins              = Economy.StartingCoins,
    eventTokens        = 0,
    cards              = {},
    securedCards       = {},
    albumProgress      = {},
    inventorySlots     = Economy.StartingInventorySlots,
    storageSlots       = Economy.StartingStorageSlots,
    toolUpgrades       = {},
    missionProgress    = {},
    dailyStreak        = 0,
    lastLogin          = 0,
    weeklyScore        = 0,
    seasonScore        = 0,
    totalCaptures      = 0,
    assignedBase       = "",
    baseLevel          = 1,
    shieldExpiresAt    = 0,
    _vipGranted        = false,
    _premiumGranted    = false,
}

local DATASTORE_NAME = RunService:IsStudio() and "Development" or "Production"

local GameProfileStore = ProfileStore.GetProfileStore(DATASTORE_NAME, DEFAULT_DATA)

-- ── Internal state ────────────────────────────────────────────────────
local Profiles: { [number]: any } = {}

local PlayerDataService = {}

-- ── Private helpers ───────────────────────────────────────────────────

local function setupLeaderstats(player: Player, data: typeof(DEFAULT_DATA))
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player

    local coinsVal = Instance.new("NumberValue")
    coinsVal.Name   = "Coins"
    coinsVal.Value  = data.coins
    coinsVal.Parent = leaderstats

    local capturesVal = Instance.new("NumberValue")
    capturesVal.Name   = "Capturas"
    capturesVal.Value  = data.totalCaptures
    capturesVal.Parent = leaderstats

    local weeklyVal = Instance.new("NumberValue")
    weeklyVal.Name   = "SemanaCapturas"
    weeklyVal.Value  = data.weeklyScore or 0
    weeklyVal.Parent = leaderstats

    local baseLvlVal = Instance.new("NumberValue")
    baseLvlVal.Name   = "BaseNivel"
    baseLvlVal.Value  = data.baseLevel or 1
    baseLvlVal.Parent = leaderstats
end

local function onPlayerAdded(player: Player)
    local profile = GameProfileStore:LoadProfileAsync("Player_" .. player.UserId)

    if not profile then
        -- DataStore failed to load — kick so the client doesn't play with empty data
        player:Kick("No se pudo cargar tu perfil. Reintentá más tarde.")
        return
    end

    profile:AddUserId(player.UserId)
    profile:Reconcile()

    profile:ListenToRelease(function()
        Profiles[player.UserId] = nil
        player:Kick("Tu sesión fue cerrada en otro servidor.")
    end)

    -- Player left before profile finished loading
    if not player:IsDescendantOf(Players) then
        profile:Release()
        return
    end

    Profiles[player.UserId] = profile

    setupLeaderstats(player, profile.Data)

    -- Send initial data to client
    Remotes.PlayerDataLoaded:SendToPlayer(player, {
        coins          = profile.Data.coins,
        eventTokens    = profile.Data.eventTokens,
        cards          = profile.Data.cards,
        securedCards   = profile.Data.securedCards,
        albumProgress  = profile.Data.albumProgress,
        inventorySlots = profile.Data.inventorySlots,
        storageSlots   = profile.Data.storageSlots,
        dailyStreak    = profile.Data.dailyStreak,
        weeklyScore    = profile.Data.weeklyScore,
        baseLevel      = profile.Data.baseLevel,
    })
end

local function onPlayerRemoving(player: Player)
    local profile = Profiles[player.UserId]
    if profile then
        profile:Release()
    end
end

-- ── Public API (used by other services) ──────────────────────────────

-- Returns the raw profile data table for a player, or nil if not loaded.
function PlayerDataService.getData(player: Player): typeof(DEFAULT_DATA)?
    local profile = Profiles[player.UserId]
    return profile and profile.Data or nil
end

-- Safely modify a player's data. Callback receives the data table to mutate.
-- Returns true on success, false if profile not loaded.
function PlayerDataService.update(player: Player, callback: (data: typeof(DEFAULT_DATA)) -> ()): boolean
    local profile = Profiles[player.UserId]
    if not profile then return false end
    callback(profile.Data)
    return true
end

-- Shorthand: add coins, clamp to 0 minimum.
function PlayerDataService.addCoins(player: Player, amount: number)
    PlayerDataService.update(player, function(data)
        data.coins = math.max(0, data.coins + amount)
    end)
    local profile = Profiles[player.UserId]
    if profile then
        Remotes.CoinsUpdated:SendToPlayer(player, profile.Data.coins)
        local ls = player:FindFirstChild("leaderstats")
        if ls then
            local v = ls:FindFirstChild("Coins")
            if v then v.Value = profile.Data.coins end
        end
    end
end

-- Sync leaderstats values to current profile data.
-- Call after any stat update that should appear on the leaderboard.
function PlayerDataService.updateLeaderstats(player: Player)
    local profile = Profiles[player.UserId]
    if not profile then return end
    local ls = player:FindFirstChild("leaderstats")
    if not ls then return end
    local d = profile.Data
    local coins   = ls:FindFirstChild("Coins");         if coins then coins.Value = d.coins end
    local caps    = ls:FindFirstChild("Capturas");      if caps  then caps.Value  = d.totalCaptures end
    local weekly  = ls:FindFirstChild("SemanaCapturas"); if weekly then weekly.Value = d.weeklyScore or 0 end
    local baseLvl = ls:FindFirstChild("BaseNivel");     if baseLvl then baseLvl.Value = d.baseLevel or 1 end
end

-- Shorthand: add event tokens.
function PlayerDataService.addTokens(player: Player, amount: number)
    PlayerDataService.update(player, function(data)
        data.eventTokens = math.max(0, data.eventTokens + amount)
    end)
    local profile = Profiles[player.UserId]
    if profile then
        Remotes.TokensUpdated:SendToPlayer(player, profile.Data.eventTokens)
    end
end

-- ── Init ──────────────────────────────────────────────────────────────

function PlayerDataService.OnStart()
    Players.PlayerAdded:Connect(onPlayerAdded)
    Players.PlayerRemoving:Connect(onPlayerRemoving)

    for _, player in Players:GetPlayers() do
        task.spawn(onPlayerAdded, player)
    end
end

return PlayerDataService
