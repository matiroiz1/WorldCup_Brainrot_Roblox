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

local proxyCache = {}

local function getProxy(key: string)
    if proxyCache[key] then return proxyCache[key] end
    
    local proxy = {}
    setmetatable(proxy, {
        __index = function(_, k)
            if isServer then
                if k == "FireClient" then return function(_, player, ...) local e = definitions.Server:Get(key); e:SendToPlayer(player, ...) end end
                if k == "FireAllClients" then return function(_, ...) local e = definitions.Server:Get(key); e:SendToAllPlayers(...) end end
            else
                if k == "FireServer" then return function(_, ...) local e = definitions.Client:Get(key); e:SendToServer(...) end end
            end
            
            -- Fallback for any other method (Connect, SendToServer, etc.)
            return function(_, ...)
                local event = isServer and definitions.Server:Get(key) or definitions.Client:Get(key)
                local val = event[k]
                if type(val) == "function" then
                    return val(event, ...)
                end
                return val
            end
        end
    })
    
    proxyCache[key] = proxy
    return proxy
end

function wrapper:FindFirstChild(key: string)
    return getProxy(key)
end

setmetatable(wrapper, {
    __index = function(self, key)
        if key == "Server" or key == "Client" then
            return definitions[key]
        elseif key == "FindFirstChild" then
            return wrapper.FindFirstChild
        end
        
        return getProxy(key)
    end
})

return wrapper
