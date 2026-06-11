local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Net = require(ReplicatedStorage.Packages.Net)

local definitions = Net.CreateDefinitions({

    -- Reflex replication / middlewares
    broadcast            = Net.Definitions.ServerToClientEvent(),
    start                = Net.Definitions.ClientToServerEvent(),

    -- Brainrot / Chase
    BrainrotSpawned      = Net.Definitions.ServerToClientEvent(),
    BrainrotDespawned    = Net.Definitions.ServerToClientEvent(),
    RequestCapture       = Net.Definitions.ClientToServerEvent(),
    CaptureResult        = Net.Definitions.ServerToClientEvent(),

    -- Cards / Inventory
    InventoryUpdated     = Net.Definitions.ServerToClientEvent(),
    AlbumUpdated         = Net.Definitions.ServerToClientEvent(),
    RequestSecureCard    = Net.Definitions.ClientToServerEvent(),
    DetachCardSelf       = Net.Definitions.ClientToServerEvent(),
    RequestStealAlbumCard = Net.Definitions.ClientToServerEvent(),
    ViewAlbum            = Net.Definitions.ServerToClientEvent(),

    -- Economy
    CoinsUpdated         = Net.Definitions.ServerToClientEvent(),
    TokensUpdated        = Net.Definitions.ServerToClientEvent(),

    -- Shop
    RequestPurchase      = Net.Definitions.ClientToServerEvent(),
    PurchaseResult       = Net.Definitions.ServerToClientEvent(),

    -- Trade
    RequestTradeInit     = Net.Definitions.ClientToServerEvent(),
    TradeRequested       = Net.Definitions.ServerToClientEvent(),
    TradeRespondRequest  = Net.Definitions.ClientToServerEvent(),
    TradeSessionUpdate   = Net.Definitions.ServerToClientEvent(),
    TradeOfferUpdate     = Net.Definitions.ClientToServerEvent(),
    TradeConfirm         = Net.Definitions.ClientToServerEvent(),
    TradeCancel          = Net.Definitions.ClientToServerEvent(),
    TradeCompleted       = Net.Definitions.ServerToClientEvent(),

    -- Events
    EventStarted         = Net.Definitions.ServerToClientEvent(),
    EventEnded           = Net.Definitions.ServerToClientEvent(),
    MatchEventUpdate     = Net.Definitions.ServerToClientEvent(),
    RequestPrediction    = Net.Definitions.ClientToServerEvent(),
    PredictionResult     = Net.Definitions.ServerToClientEvent(),

    -- Combat / Weapons
    RequestDamage        = Net.Definitions.ClientToServerEvent(),
    RequestStickToAlbum  = Net.Definitions.ClientToServerEvent(),

    -- Steal / PvP
    RequestSteal         = Net.Definitions.ClientToServerEvent(),
    StealResult          = Net.Definitions.ServerToClientEvent(),
    StealAttemptNotify   = Net.Definitions.ServerToClientEvent(),

    -- Notifications
    Notification         = Net.Definitions.ServerToClientEvent(),

    -- Base
    BaseAssigned         = Net.Definitions.ServerToClientEvent(),
    RequestBaseUpgrade   = Net.Definitions.ClientToServerEvent(),
    BaseUpgraded         = Net.Definitions.ServerToClientEvent(),
    ToggleBaseLock       = Net.Definitions.ClientToServerEvent(),

    -- Player Data
    PlayerDataLoaded     = Net.Definitions.ServerToClientEvent(),
})

-- Metatable wrapper to automatically handle:
-- 1. Direct indexing (e.g. Remotes.Notification)
-- 2. .Server / .Client namespaces (for Reflex middleware)
-- 3. :FindFirstChild("EventName") (for compatibility checks in services)
local wrapper = {}
local isServer = RunService:IsServer()

-- Expose .Server and .Client explicitly for store middleware compatibility
wrapper.Server = definitions.Server
wrapper.Client = definitions.Client

function wrapper:FindFirstChild(key: string)
    local ok, event = pcall(function()
        if isServer then
            return definitions.Server:Get(key)
        else
            return definitions.Client:Get(key)
        end
    end)
    return if ok then event else nil
end

setmetatable(wrapper, {
    __index = function(self, key)
        -- If they check for Server or Client directly
        if key == "Server" or key == "Client" then
            return definitions[key]
        elseif key == "FindFirstChild" then
            return wrapper.FindFirstChild
        end
        
        -- Otherwise, automatically resolve using Get on the current side
        if isServer then
            return definitions.Server:Get(key)
        else
            return definitions.Client:Get(key)
        end
    end
})

return wrapper
