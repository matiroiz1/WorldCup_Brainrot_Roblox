local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes  = require(ReplicatedStorage.Remotes)
local Economy  = require(ReplicatedStorage.Config.Economy)
local ZoneUtils = require(ReplicatedStorage.Modules.ZoneUtils)

-- ── Constants ─────────────────────────────────────────────────────────
local STEAL_INIT_RANGE = 10   -- studs: must be this close to start
local STEAL_HOLD_RANGE = 18   -- studs: must stay within this during hold
local STEAL_COOLDOWN   = 5    -- seconds between steal attempts per thief
local HOLD_TICK        = 0.25 -- seconds between hold checks

-- ── State ─────────────────────────────────────────────────────────────
-- LastAttempt[userId] = os.clock() of last steal attempt
local LastAttempt: { [number]: number } = {}
-- BeingStolenFrom[userId] = thiefUserId (prevents double steal)
local BeingStolenFrom: { [number]: number } = {}

local StealService = {}

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

local function getHRP(player: Player): BasePart?
    local char = player.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function distance(a: Player, b: Player): number
    local ha, hb = getHRP(a), getHRP(b)
    if not ha or not hb then return math.huge end
    return (ha.Position - hb.Position).Magnitude
end

-- Pick one random card from victim's unsecured cards
local function pickRandomCard(cards: { any }): (any?, number?)
    if #cards == 0 then return nil, nil end
    local idx = math.random(1, #cards)
    return cards[idx], idx
end

-- ── Steal flow ────────────────────────────────────────────────────────

local function doSteal(thief: Player, victim: Player)
    local PDS = getPDS()
    local BSS = getBaseService()

    -- Get victim's antisteal delay from their base level
    local victimData = PDS.getData(victim)
    if not victimData then
        BeingStolenFrom[victim.UserId] = nil
        return
    end

    local baseLevel   = victimData.baseLevel or 1
    local holdSeconds = Economy.BaseLevelPerks[baseLevel].antistealDelaySec

    -- Notify thief: steal started, show hold bar
    Remotes.StealResult:FireClient(thief, {
        success  = nil,
        duration = holdSeconds,
        victimName = victim.DisplayName,
    })

    -- Notify victim: someone is stealing from them!
    Remotes.StealAttemptNotify:FireClient(victim, {
        thiefName = thief.DisplayName,
        duration  = holdSeconds,
    })

    -- Hold loop
    local elapsed = 0
    while elapsed < holdSeconds do
        task.wait(HOLD_TICK)
        elapsed += HOLD_TICK

        -- Thief or victim left game?
        if not thief:IsDescendantOf(Players) or not victim:IsDescendantOf(Players) then
            BeingStolenFrom[victim.UserId] = nil
            return
        end

        -- Thief too far from victim?
        if distance(thief, victim) > STEAL_HOLD_RANGE then
            BeingStolenFrom[victim.UserId] = nil
            Remotes.StealResult:FireClient(thief, {
                success = false,
                reason  = "thief_moved",
            })
            Remotes.Notification:FireClient(victim, {
                type    = "info",
                message = "✅ ¡Escapaste del robo de " .. thief.DisplayName .. "!",
            })
            return
        end

        -- Victim escaped to their own base?
        if BSS.isPlayerInOwnBase(victim) then
            BeingStolenFrom[victim.UserId] = nil
            Remotes.StealResult:FireClient(thief, {
                success = false,
                reason  = "victim_escaped",
            })
            Remotes.Notification:FireClient(victim, {
                type    = "success",
                message = "✅ ¡Base alcanzada! Robo cancelado.",
            })
            return
        end

        -- Thief entered safe zone?
        if ZoneUtils.isPlayerSafe(thief) then
            BeingStolenFrom[victim.UserId] = nil
            Remotes.StealResult:FireClient(thief, {
                success = false,
                reason  = "thief_safe_zone",
            })
            return
        end
    end

    -- ── SUCCESS ──────────────────────────────────────────────────────

    -- Re-fetch victim data (may have changed during hold)
    local freshVictimData = PDS.getData(victim)
    if not freshVictimData or #freshVictimData.cards == 0 then
        BeingStolenFrom[victim.UserId] = nil
        Remotes.StealResult:FireClient(thief, {
            success = false,
            reason  = "no_cards",
        })
        return
    end

    local card, cardIdx = pickRandomCard(freshVictimData.cards)
    if not card or not cardIdx then
        BeingStolenFrom[victim.UserId] = nil
        Remotes.StealResult:FireClient(thief, { success = false, reason = "no_cards" })
        return
    end

    local stolenCard = {
        cardId     = card.cardId,
        variant    = card.variant,
        obtainedAt = os.time(),
        secured    = false,
    }

    -- Remove from victim, add to thief
    PDS.update(victim, function(d)
        table.remove(d.cards, cardIdx)
    end)
    PDS.update(thief, function(d)
        table.insert(d.cards, stolenCard)
    end)

    BeingStolenFrom[victim.UserId] = nil

    -- Fire inventory updates
    local newVictimData = PDS.getData(victim)
    local newThiefData  = PDS.getData(thief)

    if newVictimData then
        Remotes.InventoryUpdated:FireClient(victim, {
            cards        = newVictimData.cards,
            securedCards = newVictimData.securedCards,
            albumProgress = newVictimData.albumProgress,
            inventorySlots = newVictimData.inventorySlots,
            storageSlots   = newVictimData.storageSlots,
        })
    end
    if newThiefData then
        Remotes.InventoryUpdated:FireClient(thief, {
            cards        = newThiefData.cards,
            securedCards = newThiefData.securedCards,
            albumProgress = newThiefData.albumProgress,
            inventorySlots = newThiefData.inventorySlots,
            storageSlots   = newThiefData.storageSlots,
        })
    end

    -- Notify both
    Remotes.StealResult:FireClient(thief, {
        success    = true,
        stolenCard = stolenCard,
        victimName = victim.DisplayName,
    })
    Remotes.StealResult:FireClient(victim, {
        success    = false,
        reason     = "stolen",
        thiefName  = thief.DisplayName,
        lostCardId = card.cardId,
    })

    Remotes.Notification:FireClient(thief, {
        type    = "success",
        message = "🃏 ¡Robaste " .. (card.cardId or "carta") .. " a " .. victim.DisplayName .. "!",
    })
    Remotes.Notification:FireClient(victim, {
        type    = "error",
        message = "🃏 " .. thief.DisplayName .. " te robó " .. (card.cardId or "una carta") .. ".",
    })
end

-- ── Remote handler ────────────────────────────────────────────────────

local function onRequestSteal(thief: Player, targetUserId: number)
    if type(targetUserId) ~= "number" then return end
    if targetUserId == thief.UserId then return end

    -- Cooldown
    local now = os.clock()
    if (now - (LastAttempt[thief.UserId] or 0)) < STEAL_COOLDOWN then
        Remotes.StealResult:FireClient(thief, { success = false, reason = "cooldown" })
        return
    end
    LastAttempt[thief.UserId] = now

    local victim = getPlayerByUserId(targetUserId)
    if not victim then
        Remotes.StealResult:FireClient(thief, { success = false, reason = "target_not_found" })
        return
    end

    -- Zone checks
    if ZoneUtils.isPlayerSafe(thief) then
        Remotes.StealResult:FireClient(thief, { success = false, reason = "thief_safe_zone" })
        return
    end
    if ZoneUtils.isPlayerSafe(victim) then
        Remotes.StealResult:FireClient(thief, { success = false, reason = "victim_safe_zone" })
        return
    end

    -- Victim in own base?
    local BSS = getBaseService()
    if BSS.isPlayerInOwnBase(victim) then
        Remotes.StealResult:FireClient(thief, { success = false, reason = "victim_in_base" })
        return
    end

    -- Distance check
    if distance(thief, victim) > STEAL_INIT_RANGE then
        Remotes.StealResult:FireClient(thief, { success = false, reason = "too_far" })
        return
    end

    -- Victim already being stolen from?
    if BeingStolenFrom[victim.UserId] then
        Remotes.StealResult:FireClient(thief, { success = false, reason = "already_targeted" })
        return
    end

    -- Victim has unsecured cards?
    local PDS  = getPDS()
    local data = PDS.getData(victim)
    if not data or #data.cards == 0 then
        Remotes.StealResult:FireClient(thief, { success = false, reason = "no_cards" })
        return
    end

    -- Victim shield active?
    if data.shieldExpiresAt and data.shieldExpiresAt > os.time() then
        Remotes.StealResult:FireClient(thief, { success = false, reason = "victim_shielded" })
        Remotes.Notification:FireClient(thief, {
            type    = "warning",
            message = "🛡 " .. victim.DisplayName .. " tiene escudo activo.",
        })
        return
    end

    -- Lock victim
    BeingStolenFrom[victim.UserId] = thief.UserId

    task.spawn(doSteal, thief, victim)
end

-- ── Init ──────────────────────────────────────────────────────────────

function StealService.OnStart()
    Remotes.RequestSteal:Connect(onRequestSteal)

    Players.PlayerRemoving:Connect(function(player)
        LastAttempt[player.UserId]      = nil
        BeingStolenFrom[player.UserId]  = nil
        -- If this player was being stolen from, the doSteal loop handles cleanup
        -- If this player WAS a thief, remove their lock on any victim
        for userId, thiefId in pairs(BeingStolenFrom) do
            if thiefId == player.UserId then
                BeingStolenFrom[userId] = nil
            end
        end
    end)
end

return StealService
