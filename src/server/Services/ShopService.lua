local Players              = game:GetService("Players")
local MarketplaceService   = game:GetService("MarketplaceService")
local ReplicatedStorage    = game:GetService("ReplicatedStorage")

local Remotes      = require(ReplicatedStorage.Remotes)
local Economy      = require(ReplicatedStorage.Config.Economy)
local Monetization = require(ReplicatedStorage.Config.Monetization)

-- ── Session-only gamepass flags ────────────────────────────────────────
-- Refreshed on each server join via UserOwnsGamePassAsync.
-- Not persisted — ProfileService stores coins/slots, not pass ownership.
local PlayerFlags: { [number]: { hasVIP: boolean, hasPremiumStorage: boolean, hasSpeedBoost: boolean } } = {}

local ShopService = {}

-- ── Helpers ───────────────────────────────────────────────────────────

local function getPDS()
    return require(script.Parent.PlayerDataService)
end

local function getBaseService()
    return require(script.Parent.BaseService)
end

local function getPlayerByUserId(userId: number): Player?
    for _, p in ipairs(Players:GetPlayers()) do
        if p.UserId == userId then return p end
    end
    return nil
end

local function applySpeed(player: Player)
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = 16 * Monetization.GamePasses.SpeedBoost.perks.speedMultiplier
    end
end

-- ── GamePass perk application ─────────────────────────────────────────

local function applyGamePassPerks(player: Player)
    local userId = player.UserId

    local hasVIP, hasPremium, hasSpeed = false, false, false

    local ok1, res1 = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, userId, Monetization.GamePasses.VIP.id)
    if ok1 then hasVIP = res1 end

    local ok2, res2 = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, userId, Monetization.GamePasses.PremiumStorage.id)
    if ok2 then hasPremium = res2 end

    local ok3, res3 = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, userId, Monetization.GamePasses.SpeedBoost.id)
    if ok3 then hasSpeed = res3 end

    PlayerFlags[userId] = {
        hasVIP            = hasVIP,
        hasPremiumStorage = hasPremium,
        hasSpeedBoost     = hasSpeed,
    }

    local PDS = getPDS()
    local data = PDS.getData(player)
    if not data then return end

    -- Apply one-time storage bonuses (only if not already applied)
    PDS.update(player, function(d)
        if hasVIP and not d._vipGranted then
            d._vipGranted  = true
            d.storageSlots = d.storageSlots + Monetization.GamePasses.VIP.perks.extraStorageSlots
        end
        if hasPremium and not d._premiumGranted then
            d._premiumGranted = true
            d.storageSlots    = d.storageSlots + Monetization.GamePasses.PremiumStorage.perks.extraStorageSlots
        end
    end)

    if hasSpeed then
        -- Apply now and again on respawn
        applySpeed(player)
        player.CharacterAdded:Connect(function()
            task.wait(0.1)
            applySpeed(player)
        end)
    end

    if hasVIP then
        Remotes.Notification:FireClient(player, {
            type    = "success",
            message = "⭐ VIP activo — doble monedas y bóveda extra!",
        })
    end
end

-- ── Public accessors (used by other services) ─────────────────────────

function ShopService.hasVIP(player: Player): boolean
    return (PlayerFlags[player.UserId] or {}).hasVIP == true
end

function ShopService.hasPremiumStorage(player: Player): boolean
    return (PlayerFlags[player.UserId] or {}).hasPremiumStorage == true
end

function ShopService.hasSpeedBoost(player: Player): boolean
    return (PlayerFlags[player.UserId] or {}).hasSpeedBoost == true
end

-- Coin multiplier (1.0 or 2.0 for VIP)
function ShopService.getCoinMultiplier(player: Player): number
    return ShopService.hasVIP(player) and Monetization.GamePasses.VIP.perks.coinMultiplier or 1.0
end

-- ── RequestPurchase handler (coin-based shop items) ───────────────────

local WEAPON_PRICES = {
    Bate      = 100,
    Boomerang = 200,
    Pelota    = 150,
}

local function onRequestPurchase(player: Player, itemType: string, _itemId: any)
    local PDS  = getPDS()
    local data = PDS.getData(player)
    if not data then return end

    if itemType == "weapon" then
        local weaponName = _itemId
        local cost = WEAPON_PRICES[weaponName]
        if not cost then
            Remotes.PurchaseResult:FireClient(player, { success = false, reason = "unknown_weapon" })
            return
        end
        -- Check already owned
        for _, w in ipairs(data.ownedWeapons or {}) do
            if w == weaponName then
                Remotes.PurchaseResult:FireClient(player, { success = false, reason = "already_owned" })
                return
            end
        end
        if data.coins < cost then
            Remotes.PurchaseResult:FireClient(player, { success = false, reason = "insufficient_coins" })
            return
        end
        PDS.update(player, function(d)
            d.coins = d.coins - cost
            d.ownedWeapons = d.ownedWeapons or {}
            table.insert(d.ownedWeapons, weaponName)
        end)
        -- Give the tool to the player's backpack now
        local weaponsFolder = game:GetService("ReplicatedStorage"):FindFirstChild("Assets")
            and game:GetService("ReplicatedStorage").Assets:FindFirstChild("Weapons")
        if weaponsFolder then
            local tool = weaponsFolder:FindFirstChild(weaponName)
            if tool then
                local clone = tool:Clone()
                clone.Parent = player.Backpack
            end
        end
        local newData = PDS.getData(player)
        Remotes.CoinsUpdated:FireClient(player, newData.coins)
        Remotes.PurchaseResult:FireClient(player, { success = true, type = "weapon", weaponName = weaponName })

    elseif itemType == "slot_inventory" then
        local bought = #data.cards  -- approximate: use how many extra slots bought
        local priceTable = Economy.SlotPrices.InventorySlot
        local slotsBought = math.max(0, data.inventorySlots - Economy.StartingInventorySlots)
        local priceIdx = math.min(slotsBought + 1, #priceTable)
        local cost = priceTable[priceIdx]
        if data.coins < cost then
            Remotes.PurchaseResult:FireClient(player, { success = false, reason = "insufficient_coins" })
            return
        end
        PDS.update(player, function(d)
            d.coins         = d.coins - cost
            d.inventorySlots = d.inventorySlots + 1
        end)
        local newData = PDS.getData(player)
        Remotes.CoinsUpdated:FireClient(player, newData.coins)
        Remotes.PurchaseResult:FireClient(player, { success = true, type = "slot_inventory" })

    elseif itemType == "slot_storage" then
        local priceTable = Economy.SlotPrices.StorageSlot
        local slotsBought = math.max(0, data.storageSlots - Economy.StartingStorageSlots)
        local priceIdx = math.min(slotsBought + 1, #priceTable)
        local cost = priceTable[priceIdx]
        if data.coins < cost then
            Remotes.PurchaseResult:FireClient(player, { success = false, reason = "insufficient_coins" })
            return
        end
        PDS.update(player, function(d)
            d.coins       = d.coins - cost
            d.storageSlots = d.storageSlots + 1
        end)
        local newData = PDS.getData(player)
        Remotes.CoinsUpdated:FireClient(player, newData.coins)
        Remotes.PurchaseResult:FireClient(player, { success = true, type = "slot_storage" })
    end
end

-- ── ProcessReceipt ────────────────────────────────────────────────────

local function processReceipt(info: { PlayerId: number, ProductId: number, PurchaseId: string })
    local player = getPlayerByUserId(info.PlayerId)
    if not player then
        -- Player not in server; retry later
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    local PDS = getPDS()
    local data = PDS.getData(player)
    if not data then
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    local product = Monetization.getDevProductById(info.ProductId)
    if not product then
        -- Unknown product — grant to avoid infinite retry
        warn("[ShopService] Unknown productId:", info.ProductId)
        return Enum.ProductPurchaseDecision.PurchaseGranted
    end

    local grant = product.grant

    if grant.coins then
        PDS.addCoins(player, grant.coins)
        Remotes.Notification:FireClient(player, {
            type    = "success",
            message = "🪙 +" .. grant.coins .. " monedas!",
        })
    end

    if grant.eventTokens then
        PDS.addTokens(player, grant.eventTokens)
        Remotes.Notification:FireClient(player, {
            type    = "success",
            message = "🎟 +" .. grant.eventTokens .. " tokens de evento!",
        })
    end

    if grant.inventorySlots then
        PDS.update(player, function(d)
            d.inventorySlots = d.inventorySlots + grant.inventorySlots
        end)
        Remotes.Notification:FireClient(player, {
            type    = "success",
            message = "📦 +" .. grant.inventorySlots .. " slots de inventario!",
        })
    end

    if grant.shieldMinutes then
        PDS.update(player, function(d)
            local now = os.time()
            local current = d.shieldExpiresAt or 0
            -- Extend if already active, otherwise start fresh
            d.shieldExpiresAt = math.max(current, now) + (grant.shieldMinutes * 60)
        end)
        Remotes.Notification:FireClient(player, {
            type    = "success",
            message = "🛡 ¡Escudo de " .. grant.shieldMinutes .. " min activado!",
        })
    end

    if grant.baseUpgradeLevel then
        local BaseService = getBaseService()
        local ok = BaseService.upgradeToLevel(player, grant.baseUpgradeLevel)
        if not ok then
            -- Player wasn't at the right level — refund not possible, but notify
            Remotes.Notification:FireClient(player, {
                type    = "warning",
                message = "⚠ No se pudo aplicar la mejora de base. Ya tenés ese nivel o superior.",
            })
        else
            Remotes.Notification:FireClient(player, {
                type    = "success",
                message = "🏠 ¡Base mejorada al nivel " .. grant.baseUpgradeLevel .. "!",
            })
        end
    end

    return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- ── Init ──────────────────────────────────────────────────────────────

function ShopService.OnStart()
    MarketplaceService.ProcessReceipt = processReceipt

    Remotes.RequestPurchase:Connect(onRequestPurchase)

    Players.PlayerAdded:Connect(function(player)
        -- Wait for PlayerDataService to load profile
        task.delay(3, function()
            if player:IsDescendantOf(Players) then
                applyGamePassPerks(player)
            end
        end)
    end)

    Players.PlayerRemoving:Connect(function(player)
        PlayerFlags[player.UserId] = nil
    end)

    -- Check players already in server (Studio test)
    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(function()
            task.wait(3)
            if player:IsDescendantOf(Players) then
                applyGamePassPerks(player)
            end
        end)
    end
end

return ShopService
