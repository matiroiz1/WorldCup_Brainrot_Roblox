local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes      = require(ReplicatedStorage.Remotes)
local RarityUtils  = require(ReplicatedStorage.Modules.RarityUtils)
local Cards        = require(ReplicatedStorage.Config.Cards)

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
    return true, "ok"
end

-- ── Init ──────────────────────────────────────────────────────────────

function CardService.OnStart()
    -- Secure card request from client (player taps secure button)
    Remotes.RequestSecureCard:Connect(function(player, cardIndex: number)
        if type(cardIndex) ~= "number" then return end
        CardService.secureCard(player, cardIndex)
    end)
end

return CardService
