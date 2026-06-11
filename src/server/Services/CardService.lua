local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes      = require(ReplicatedStorage.Remotes)
local RarityUtils  = require(ReplicatedStorage.Modules.RarityUtils)
local Cards        = require(ReplicatedStorage.Config.Cards)
local Economy      = require(ReplicatedStorage.Config.Economy)

local CardService = {}

local function getPDS()
    return require(script.Parent.PlayerDataService)
end

-- ── Private helpers ───────────────────────────────────────────────────

local function fireInventoryUpdate(player: Player)
    local data = getPDS().getData(player)
    if not data then return end
    Remotes.InventoryUpdated:FireClient(player, {
        cards        = data.cards,
        securedCards = data.securedCards,
        albumProgress = data.albumProgress,
        inventorySlots = data.inventorySlots,
        storageSlots   = data.storageSlots,
    })
end

local function isinventoryFull(data): boolean
    return #data.cards >= data.inventorySlots
end

-- ── Public API ────────────────────────────────────────────────────────

-- Give a card to a player. Called by ChaseService after capture.
-- rewardsTable: { { cardId, weight } }
-- Returns the cardId given, or nil if inventory full.
function CardService.giveRewardCard(player: Player, rewardsTable: { { cardId: string, weight: number } }): string?
    local PDS  = getPDS()
    local data = PDS.getData(player)
    if not data then return nil end

    if isinventoryFull(data) then
        Remotes.Notification:FireClient(player, {
            type    = "warning",
            message = "¡Inventario lleno! Asegurá o vendé cartas.",
        })
        return nil
    end

    local cardId = RarityUtils.resolveCardDrop(rewardsTable)
    local card = {
        cardId     = cardId,
        variant    = "Normal",
        obtainedAt = os.time(),
        secured    = false,
    }

    PDS.update(player, function(d)
        table.insert(d.cards, card)
    end)

    fireInventoryUpdate(player)
    return cardId
end

-- Secure a card: move it from unsecured cards to securedCards.
-- cardIndex: index into data.cards (1-based)
function CardService.secureCard(player: Player, cardIndex: number): boolean
    local PDS  = getPDS()
    local data = PDS.getData(player)
    if not data then return false end

    local card = data.cards[cardIndex]
    if not card then return false end
    if card.secured then return false end

    -- Check storage capacity
    if #data.securedCards >= data.storageSlots then
        Remotes.Notification:FireClient(player, {
            type    = "warning",
            message = "¡Storage lleno! Comprá más slots.",
        })
        return false
    end

    PDS.update(player, function(d)
        local c = d.cards[cardIndex]
        if not c then return end
        c.secured = true
        table.insert(d.securedCards, c)
        table.remove(d.cards, cardIndex)
    end)

    fireInventoryUpdate(player)
    return true
end

-- Stick a card into the album (mark albumProgress for its set).
-- stickTimeSec is handled client-side countdown; server validates the request here.
function CardService.stickCardToAlbum(player: Player, cardIndex: number): (boolean, string)
    local PDS  = getPDS()
    local data = PDS.getData(player)
    if not data then return false, "data_not_loaded" end

    local card = data.securedCards[cardIndex]
    if not card then return false, "card_not_found" end

    local def = Cards.getById(card.cardId)
    if not def then return false, "invalid_card_def" end

    local albumKey = def.albumSetId .. "_" .. card.cardId

    if data.albumProgress[albumKey] then
        return false, "already_in_album"
    end

    PDS.update(player, function(d)
        d.albumProgress[albumKey] = true
        -- Remove from securedCards
        local found = false
        for i, c in ipairs(d.securedCards) do
            if c.cardId == card.cardId and c.obtainedAt == card.obtainedAt then
                table.remove(d.securedCards, i)
                found = true
                break
            end
        end
        if not found then
            -- Card wasn't in securedCards, remove from unsecured as fallback
            for i, c in ipairs(d.cards) do
                if c.cardId == card.cardId and c.obtainedAt == card.obtainedAt then
                    table.remove(d.cards, i)
                    break
                end
            end
        end
    end)

    Remotes.AlbumUpdated:FireClient(player, {
        albumProgress = getPDS().getData(player).albumProgress,
    })
    fireInventoryUpdate(player)
    
    local BaseService = require(script.Parent.BaseService)
    BaseService.syncPhysicalAlbum(player)
    
    return true, "ok"
end

-- Despegar una carta propia del álbum instantáneamente
function CardService.detachCardSelf(player: Player, albumKey: string): (boolean, string)
    local PDS  = getPDS()
    local data = PDS.getData(player)
    if not data then return false, "data_not_loaded" end

    if not data.albumProgress[albumKey] then
        return false, "not_in_album"
    end

    if isinventoryFull(data) then
        return false, "inventory_full"
    end

    -- Extraer el cardId original del albumKey (formato: "SetID_CardID")
    local split = string.split(albumKey, "_")
    local cardId = split[2]

    local card = {
        cardId     = cardId,
        variant    = "Normal",
        obtainedAt = os.time(),
        secured    = false,
    }

    PDS.update(player, function(d)
        d.albumProgress[albumKey] = nil
        table.insert(d.cards, card)
    end)

    Remotes.AlbumUpdated:FireClient(player, {
        albumProgress = getPDS().getData(player).albumProgress,
    })
    fireInventoryUpdate(player)
    
    local BaseService = require(script.Parent.BaseService)
    BaseService.syncPhysicalAlbum(player)
    
    Remotes.Notification:FireClient(player, {type = "success", message = "Carta recuperada al inventario."})
    return true, "ok"
end

-- Robar una carta del álbum de otra base
function CardService.requestStealAlbumCard(thief: Player, targetBaseId: string, albumKey: string, useBoost: boolean)
    local BaseService = require(script.Parent.BaseService)
    local PDS = getPDS()
    
    -- Validar si la base está bloqueada
    if BaseService.isBaseLocked(targetBaseId) then
        Remotes.Notification:FireClient(thief, {type = "error", message = "¡La base está asegurada! No podés robar."})
        return
    end

    local ownerId = BaseService.getBaseOwner(targetBaseId)
    if not ownerId then return end
    
    local victim = Players:GetPlayerByUserId(ownerId)
    if not victim then return end

    local victimData = PDS.getData(victim)
    if not victimData or not victimData.albumProgress[albumKey] then
        Remotes.Notification:FireClient(thief, {type = "error", message = "La carta ya no está ahí."})
        return
    end

    local thiefData = PDS.getData(thief)
    if not thiefData then return end

    if isinventoryFull(thiefData) then
        Remotes.Notification:FireClient(thief, {type = "warning", message = "Tu inventario está lleno."})
        return
    end

    -- Tiempo de despegue (base 10s, si usa boost y tiene plata 3s)
    local stealTime = 10
    if useBoost then
        local boostCost = 50 -- Costo hardcodeado por ahora
        if thiefData.coins >= boostCost then
            PDS.update(thief, function(d) d.coins = d.coins - boostCost end)
            Remotes.CoinsUpdated:FireClient(thief, thiefData.coins - boostCost)
            stealTime = 3
            Remotes.Notification:FireClient(thief, {type = "info", message = "¡Boost activado! Robo acelerado."})
        else
            Remotes.Notification:FireClient(thief, {type = "warning", message = "No tenés monedas para el boost."})
        end
    end

    Remotes.Notification:FireClient(thief, {type = "info", message = "Despegando carta... ("..stealTime.."s)"})
    Remotes.Notification:FireClient(victim, {type = "warning", message = "¡ALERTA! Están robando tu álbum."})

    -- Iniciar cuenta regresiva (debería validarse la distancia en un loop real, pero aquí usamos wait simple para MVP)
    task.delay(stealTime, function()
        -- Revalidar datos después del tiempo
        if not thief:IsDescendantOf(Players) or not victim:IsDescendantOf(Players) then return end
        if BaseService.isBaseLocked(targetBaseId) then return end -- si el dueño logró bloquearla en ese tiempo
        
        local freshVictimData = PDS.getData(victim)
        if not freshVictimData.albumProgress[albumKey] then return end

        local split = string.split(albumKey, "_")
        local cardId = split[2]

        local stolenCard = {
            cardId     = cardId,
            variant    = "Normal",
            obtainedAt = os.time(),
            secured    = false,
        }

        PDS.update(victim, function(d) d.albumProgress[albumKey] = nil end)
        PDS.update(thief, function(d) table.insert(d.cards, stolenCard) end)

        Remotes.AlbumUpdated:FireClient(victim, {albumProgress = PDS.getData(victim).albumProgress})
        fireInventoryUpdate(thief)
        
        BaseService.syncPhysicalAlbum(victim)
        
        Remotes.Notification:FireClient(thief, {type = "success", message = "¡Robaste la carta del álbum!"})
        Remotes.Notification:FireClient(victim, {type = "error", message = "¡Te robaron una carta del álbum!"})
    end)
end

-- ── Init ──────────────────────────────────────────────────────────────

function CardService.OnStart()
    -- Secure card request from client (player taps secure button)
    Remotes.RequestSecureCard:Connect(function(player, cardIndex: number)
        if type(cardIndex) ~= "number" then return end
        CardService.secureCard(player, cardIndex)
    end)
    
    -- Agregar listeners temporales hasta definir remotes oficiales
    if Remotes:FindFirstChild("DetachCardSelf") then
        Remotes.DetachCardSelf:Connect(function(player, albumKey)
            CardService.detachCardSelf(player, albumKey)
        end)
    end
    
    if Remotes:FindFirstChild("RequestStealAlbumCard") then
        Remotes.RequestStealAlbumCard:Connect(function(player, targetBaseId, albumKey, useBoost)
            CardService.requestStealAlbumCard(player, targetBaseId, albumKey, useBoost)
        end)
    end

    Remotes.RequestStickToAlbum:Connect(function(player, cardIndex: number)
        if type(cardIndex) ~= "number" then return end
        local ok, reason = CardService.stickCardToAlbum(player, cardIndex)
        if ok then
            Remotes.Notification:FireClient(player, {
                type = "success",
                message = "📋 ¡Carta pegada al álbum!",
            })
        else
            Remotes.Notification:FireClient(player, {
                type = "warning",
                message = "No se pudo pegar: " .. (reason or "error"),
            })
        end
    end)
end

return CardService
