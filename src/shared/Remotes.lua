local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage.Packages.Net)

return Net.CreateDefinitions({

    -- Brainrot / Chase
    BrainrotSpawned      = Net.Definitions.ServerToClientEvent(),
    BrainrotDespawned    = Net.Definitions.ServerToClientEvent(),
    RequestCapture       = Net.Definitions.ClientToServerEvent(),
    CaptureResult        = Net.Definitions.ServerToClientEvent(),

    -- Cards / Inventory
    InventoryUpdated     = Net.Definitions.ServerToClientEvent(),
    AlbumUpdated         = Net.Definitions.ServerToClientEvent(),
    RequestSecureCard    = Net.Definitions.ClientToServerEvent(),

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

    -- Player Data
    PlayerDataLoaded     = Net.Definitions.ServerToClientEvent(),
})
