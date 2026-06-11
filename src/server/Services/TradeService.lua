local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes  = require(ReplicatedStorage.Remotes)
local Economy  = require(ReplicatedStorage.Config.Economy)
local Cards    = require(ReplicatedStorage.Config.Cards)

-- ── Constants ─────────────────────────────────────────────────────────
local MAX_OFFER_CARDS = 5

-- ── State ─────────────────────────────────────────────────────────────

-- PendingRequests[fromUserId] = { toUserId, sessionId, expiresAt }
local PendingRequests: { [number]: any } = {}

-- ActiveSessions[sessionId] = TradeSession table
local ActiveSessions: { [string]: any } = {}

-- PlayerInSession[userId] = sessionId (nil if not in a trade)
local PlayerInSession: { [number]: string? } = {}

local TradeService = {}

-- ── Helpers ───────────────────────────────────────────────────────────

local function getPDS()
    return require(script.Parent.PlayerDataService)
end

local function generateSessionId(): string
    return "trade_" .. tostring(os.clock()):gsub("%.", "") .. tostring(math.random(1000, 9999))
end

local function getPlayerByUserId(userId: number): Player?
    for _, p in ipairs(Players:GetPlayers()) do
        if p.UserId == userId then return p end
    end
    return nil
end

-- Find a card in player data by cardId + obtainedAt (unique fingerprint)
local function findCardInData(data: any, cardId: string, obtainedAt: number): (any?, number?, string?)
    for i, c in ipairs(data.cards) do
        if c.cardId == cardId and c.obtainedAt == obtainedAt then
            return c, i, "cards"
        end
    end
    for i, c in ipairs(data.securedCards) do
        if c.cardId == cardId and c.obtainedAt == obtainedAt then
            return c, i, "securedCards"
        end
    end
    return nil, nil, nil
end

-- Validate that all cards in an offer actually exist in the player's data
local function validateOffer(data: any, offeredCards: { any }): (boolean, string)
    if #offeredCards > MAX_OFFER_CARDS then
        return false, "max_cards_exceeded"
    end
    for _, offered in ipairs(offeredCards) do
        local card, _, _ = findCardInData(data, offered.cardId, offered.obtainedAt)
        if not card then
            return false, "card_not_found:" .. (offered.cardId or "?")
        end
        -- Check tradable flag in card config
        local def = Cards.getById(offered.cardId)
        if def and not def.tradable then
            return false, "card_not_tradable:" .. offered.cardId
        end
    end
    return true, "ok"
end

local function buildSessionPayload(session: any): any
    return {
        sessionId = session.sessionId,
        playerA   = {
            userId       = session.playerA,
            name         = session.nameA,
            offeredCards = session.offeredA,
            confirmed    = session.confirmedA,
        },
        playerB   = {
            userId       = session.playerB,
            name         = session.nameB,
            offeredCards = session.offeredB,
            confirmed    = session.confirmedB,
        },
        status    = session.status,
    }
end

local function fireSessionUpdate(session: any)
    local payload = buildSessionPayload(session)
    local pA = getPlayerByUserId(session.playerA)
    local pB = getPlayerByUserId(session.playerB)
    if pA then Remotes.TradeSessionUpdate:FireClient(pA, payload) end
    if pB then Remotes.TradeSessionUpdate:FireClient(pB, payload) end
end

local function cancelSession(sessionId: string, reason: string)
    local session = ActiveSessions[sessionId]
    if not session then return end

    session.status = "cancelled"
    fireSessionUpdate(session)

    local pA = getPlayerByUserId(session.playerA)
    local pB = getPlayerByUserId(session.playerB)
    local msg = "Trade cancelado: " .. reason

    if pA then Remotes.Notification:FireClient(pA, { type = "warning", message = msg }) end
    if pB then Remotes.Notification:FireClient(pB, { type = "warning", message = msg }) end

    PlayerInSession[session.playerA] = nil
    PlayerInSession[session.playerB] = nil
    ActiveSessions[sessionId]        = nil
end

-- ── Trade execution ───────────────────────────────────────────────────

local function executeTrade(session: any)
    local PDS  = getPDS()
    local pA   = getPlayerByUserId(session.playerA)
    local pB   = getPlayerByUserId(session.playerB)

    if not pA or not pB then
        cancelSession(session.sessionId, "player_left")
        return
    end

    local dataA = PDS.getData(pA)
    local dataB = PDS.getData(pB)

    if not dataA or not dataB then
        cancelSession(session.sessionId, "data_unavailable")
        return
    end

    -- Final validation before executing
    local okA, errA = validateOffer(dataA, session.offeredA)
    local okB, errB = validateOffer(dataB, session.offeredB)

    if not okA then
        cancelSession(session.sessionId, "invalid_offer_A:" .. errA)
        return
    end
    if not okB then
        cancelSession(session.sessionId, "invalid_offer_B:" .. errB)
        return
    end

    -- Collect cards to swap (indices to remove, cards to add)
    local removeFromA: { { list: string, idx: number } } = {}
    local removeFromB: { { list: string, idx: number } } = {}

    for _, offered in ipairs(session.offeredA) do
        local _, idx, list = findCardInData(dataA, offered.cardId, offered.obtainedAt)
        if idx then table.insert(removeFromA, { list = list, idx = idx }) end
    end
    for _, offered in ipairs(session.offeredB) do
        local _, idx, list = findCardInData(dataB, offered.cardId, offered.obtainedAt)
        if idx then table.insert(removeFromB, { list = list, idx = idx }) end
    end

    -- Sort descending so removing by index doesn't shift earlier entries
    table.sort(removeFromA, function(a, b) return a.idx > b.idx end)
    table.sort(removeFromB, function(a, b) return a.idx > b.idx end)

    -- Apply: remove from givers, add to receivers
    PDS.update(pA, function(d)
        for _, entry in ipairs(removeFromA) do
            table.remove(d[entry.list], entry.idx)
        end
        for _, card in ipairs(session.offeredB) do
            -- Reset secured status when changing hands
            table.insert(d.cards, {
                cardId     = card.cardId,
                variant    = card.variant,
                obtainedAt = os.time(),
                secured    = false,
            })
        end
    end)

    PDS.update(pB, function(d)
        for _, entry in ipairs(removeFromB) do
            table.remove(d[entry.list], entry.idx)
        end
        for _, card in ipairs(session.offeredA) do
            table.insert(d.cards, {
                cardId     = card.cardId,
                variant    = card.variant,
                obtainedAt = os.time(),
                secured    = false,
            })
        end
    end)

    -- Notify both
    session.status = "completed"
    fireSessionUpdate(session)

    Remotes.TradeCompleted:FireClient(pA, {
        sessionId     = session.sessionId,
        success       = true,
        receivedCards = session.offeredB,
    })
    Remotes.TradeCompleted:FireClient(pB, {
        sessionId     = session.sessionId,
        success       = true,
        receivedCards = session.offeredA,
    })

    -- Notify inventory update
    local newDataA = PDS.getData(pA)
    local newDataB = PDS.getData(pB)

    Remotes.InventoryUpdated:FireClient(pA, {
        cards        = newDataA.cards,
        securedCards = newDataA.securedCards,
        albumProgress = newDataA.albumProgress,
        inventorySlots = newDataA.inventorySlots,
        storageSlots   = newDataA.storageSlots,
    })
    Remotes.InventoryUpdated:FireClient(pB, {
        cards        = newDataB.cards,
        securedCards = newDataB.securedCards,
        albumProgress = newDataB.albumProgress,
        inventorySlots = newDataB.inventorySlots,
        storageSlots   = newDataB.storageSlots,
    })

    PlayerInSession[session.playerA] = nil
    PlayerInSession[session.playerB] = nil
    ActiveSessions[session.sessionId] = nil
end

-- ── Remote handlers ───────────────────────────────────────────────────

local function onRequestTradeInit(player: Player, targetUserId: number)
    if type(targetUserId) ~= "number" then return end
    if targetUserId == player.UserId then return end

    -- Both must be free
    if PlayerInSession[player.UserId] then
        Remotes.Notification:FireClient(player, { type = "warning", message = "Ya estás en un trade." })
        return
    end
    if PlayerInSession[targetUserId] then
        Remotes.Notification:FireClient(player, { type = "warning", message = "Ese jugador ya está en un trade." })
        return
    end

    local target = getPlayerByUserId(targetUserId)
    if not target then
        Remotes.Notification:FireClient(player, { type = "error", message = "Jugador no encontrado." })
        return
    end

    -- Cancel any existing pending request from this player
    PendingRequests[player.UserId] = nil

    local sessionId = generateSessionId()
    PendingRequests[player.UserId] = {
        toUserId  = targetUserId,
        sessionId = sessionId,
        expiresAt = os.clock() + Economy.TradeRequestTimeoutSeconds,
    }

    -- Notify target
    Remotes.TradeRequested:FireClient(target, {
        sessionId  = sessionId,
        fromUserId = player.UserId,
        fromName   = player.Name,
    })

    Remotes.Notification:FireClient(player, { type = "info", message = "Solicitud enviada a " .. target.Name .. "." })

    -- Auto-expire request
    task.delay(Economy.TradeRequestTimeoutSeconds, function()
        if PendingRequests[player.UserId] and PendingRequests[player.UserId].sessionId == sessionId then
            PendingRequests[player.UserId] = nil
            Remotes.Notification:FireClient(player, { type = "warning", message = "La solicitud de trade expiró." })
        end
    end)
end

local function onTradeRespondRequest(player: Player, sessionId: string, accept: boolean)
    if type(sessionId) ~= "string" or type(accept) ~= "boolean" then return end

    -- Find who sent this request
    local initiatorId: number? = nil
    for userId, req in pairs(PendingRequests) do
        if req.sessionId == sessionId then
            initiatorId = userId
            break
        end
    end

    if not initiatorId then
        Remotes.Notification:FireClient(player, { type = "error", message = "Trade ya no disponible." })
        return
    end

    local initiator = getPlayerByUserId(initiatorId)
    PendingRequests[initiatorId] = nil

    if not accept then
        if initiator then
            Remotes.Notification:FireClient(initiator, { type = "warning", message = player.Name .. " rechazó el trade." })
        end
        return
    end

    if not initiator then
        Remotes.Notification:FireClient(player, { type = "error", message = "El jugador ya no está." })
        return
    end

    -- Both still free?
    if PlayerInSession[initiatorId] or PlayerInSession[player.UserId] then
        Remotes.Notification:FireClient(player,    { type = "warning", message = "Trade no disponible." })
        Remotes.Notification:FireClient(initiator, { type = "warning", message = "Trade no disponible." })
        return
    end

    -- Create session
    local session = {
        sessionId  = sessionId,
        playerA    = initiatorId,
        playerB    = player.UserId,
        nameA      = initiator.Name,
        nameB      = player.Name,
        offeredA   = {},
        offeredB   = {},
        confirmedA = false,
        confirmedB = false,
        status     = "active",
        startedAt  = os.clock(),
    }

    ActiveSessions[sessionId]      = session
    PlayerInSession[initiatorId]   = sessionId
    PlayerInSession[player.UserId] = sessionId

    fireSessionUpdate(session)

    -- Session timeout
    task.delay(Economy.TradeSessionTimeoutSeconds, function()
        if ActiveSessions[sessionId] then
            cancelSession(sessionId, "timeout")
        end
    end)
end

local function onTradeOfferUpdate(player: Player, sessionId: string, offeredCards: { any })
    if type(sessionId) ~= "string" then return end

    local session = ActiveSessions[sessionId]
    if not session or session.status ~= "active" then return end

    -- Validate player belongs to session
    local isA = session.playerA == player.UserId
    local isB = session.playerB == player.UserId
    if not isA and not isB then return end

    local PDS  = getPDS()
    local data = PDS.getData(player)
    if not data then return end

    local ok, err = validateOffer(data, offeredCards or {})
    if not ok then
        Remotes.Notification:FireClient(player, { type = "error", message = "Oferta inválida: " .. err })
        return
    end

    -- Update offer and reset both confirmations (offer changed)
    if isA then
        session.offeredA   = offeredCards or {}
    else
        session.offeredB   = offeredCards or {}
    end
    session.confirmedA = false
    session.confirmedB = false

    fireSessionUpdate(session)
end

local function onTradeConfirm(player: Player, sessionId: string)
    if type(sessionId) ~= "string" then return end

    local session = ActiveSessions[sessionId]
    if not session or session.status ~= "active" then return end

    local isA = session.playerA == player.UserId
    local isB = session.playerB == player.UserId
    if not isA and not isB then return end

    if isA then session.confirmedA = true end
    if isB then session.confirmedB = true end

    fireSessionUpdate(session)

    -- Both confirmed → execute
    if session.confirmedA and session.confirmedB then
        executeTrade(session)
    end
end

local function onTradeCancel(player: Player, sessionId: string)
    if type(sessionId) ~= "string" then return end
    local session = ActiveSessions[sessionId]
    if not session then return end
    if session.playerA ~= player.UserId and session.playerB ~= player.UserId then return end
    cancelSession(sessionId, player.Name .. " canceló el trade")
end

-- ── Init ──────────────────────────────────────────────────────────────

function TradeService.OnStart()
    Remotes.RequestTradeInit:Connect(onRequestTradeInit)
    Remotes.TradeRespondRequest:Connect(onTradeRespondRequest)
    Remotes.TradeOfferUpdate:Connect(onTradeOfferUpdate)
    Remotes.TradeConfirm:Connect(onTradeConfirm)
    Remotes.TradeCancel:Connect(onTradeCancel)

    Players.PlayerRemoving:Connect(function(player)
        -- Cancel active session
        local sessionId = PlayerInSession[player.UserId]
        if sessionId then
            cancelSession(sessionId, player.Name .. " salió del juego")
        end
        -- Cancel pending request
        PendingRequests[player.UserId] = nil
        PlayerInSession[player.UserId] = nil
    end)
end

return TradeService
