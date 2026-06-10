local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local Remotes  = require(ReplicatedStorage.Remotes)
local Brainrots = require(ReplicatedStorage.Config.Brainrots)
local Events   = require(ReplicatedStorage.Config.Events)
local Economy  = require(ReplicatedStorage.Config.Economy)

-- ── State ─────────────────────────────────────────────────────────────
local dropBoostActive    = false
local lastEliteHour      = -1
local lastLegendaryTime  = 0  -- os.time() of last legendary spawn
local activeEventType: string? = nil

local EventService = {}

-- ── Helpers ───────────────────────────────────────────────────────────

local function getBSS()
    return require(script.Parent.BrainrotSpawnService)
end

local function getDefsByType(bType: string): { any }
    local result = {}
    for _, def in pairs(Brainrots) do
        if type(def) == "table" and def.brainrotType == bType then
            table.insert(result, def)
        end
    end
    return result
end

local function announceAll(notifType: string, message: string)
    Remotes.Notification:FireAllClients({ type = notifType, message = message })
end

-- ── Drop boost ────────────────────────────────────────────────────────

local function activateDropBoost()
    if dropBoostActive then return end
    dropBoostActive = true
    announceAll("event", Events.Announcements.DropBoostStart)
    Remotes.EventStarted:FireAllClients({
        eventType       = "DropBoost",
        message         = Events.Announcements.DropBoostStart,
        durationSeconds = 3600,
    })
end

local function deactivateDropBoost()
    if not dropBoostActive then return end
    dropBoostActive = false
    Remotes.EventEnded:FireAllClients({ eventType = "DropBoost" })
end

-- ── Elite event ────────────────────────────────────────────────────────

local function triggerEliteEvent()
    local candidates = getDefsByType("Elite")
    if #candidates == 0 then return end

    announceAll("event", Events.Announcements.EliteSpawn)
    Remotes.EventStarted:FireAllClients({
        eventType       = "EliteSpawn",
        message         = Events.Announcements.EliteSpawn,
        durationSeconds = 1800,
    })
    activeEventType = "EliteSpawn"

    local pick = candidates[math.random(1, #candidates)]
    getBSS().spawnBrainrot(pick.id)

    -- Auto-close event window after 30 min
    task.delay(1800, function()
        if activeEventType == "EliteSpawn" then
            activeEventType = nil
            Remotes.EventEnded:FireAllClients({ eventType = "EliteSpawn" })
        end
    end)
end

-- ── Legendary event ───────────────────────────────────────────────────

local function triggerLegendaryEvent()
    local cooldownSec = Economy.LegendaryEventCooldownMinutes * 60
    if os.time() - lastLegendaryTime < cooldownSec then return end

    local candidates = getDefsByType("Legendary")
    if #candidates == 0 then return end

    lastLegendaryTime = os.time()
    announceAll("event", Events.Announcements.LegendarySpawn)
    Remotes.EventStarted:FireAllClients({
        eventType       = "LegendarySpawn",
        message         = Events.Announcements.LegendarySpawn,
        durationSeconds = 900,
    })
    activeEventType = "LegendarySpawn"

    local pick = candidates[math.random(1, #candidates)]
    getBSS().spawnBrainrot(pick.id)

    task.delay(900, function()
        if activeEventType == "LegendarySpawn" then
            activeEventType = nil
            Remotes.EventEnded:FireAllClients({ eventType = "LegendarySpawn" })
        end
    end)
end

-- ── Schedule check loop ───────────────────────────────────────────────

local function scheduleLoop()
    while true do
        task.wait(30)

        local utcHour = os.date("!*t").hour :: number

        -- Elite spawn at scheduled UTC hours
        if utcHour ~= lastEliteHour then
            for _, h in ipairs(Events.EliteSpawnHours) do
                if utcHour == h then
                    lastEliteHour = utcHour
                    triggerEliteEvent()
                    break
                end
            end
        end

        -- Drop boost during specified UTC hours
        local inBoostWindow = false
        for _, h in ipairs(Events.DropBoostHours) do
            if utcHour == h then
                inBoostWindow = true
                break
            end
        end

        if inBoostWindow and not dropBoostActive then
            activateDropBoost()
        elseif not inBoostWindow and dropBoostActive then
            deactivateDropBoost()
        end
    end
end

-- ── Public API ────────────────────────────────────────────────────────

-- Called by CardService / RarityUtils to apply boost to rewards tables
function EventService.isDropBoostActive(): boolean
    return dropBoostActive
end

-- Apply drop boost multiplier to a rewards table (used by CardService)
function EventService.applyDropBoost(rewardsTable: { any }): { any }
    if not dropBoostActive then return rewardsTable end
    local mult = Events.DropBoostMultiplier
    local boosted = {}
    for _, entry in ipairs(rewardsTable) do
        local boostedEntry = { cardId = entry.cardId, weight = entry.weight }
        -- Boost non-common weights
        if entry.rarity and entry.rarity ~= "Common" then
            boostedEntry.weight = math.floor(entry.weight * mult)
        end
        table.insert(boosted, boostedEntry)
    end
    return boosted
end

-- Admin override: force elite spawn immediately
function EventService.adminTriggerElite()
    triggerEliteEvent()
end

-- Admin override: force legendary spawn (ignores cooldown)
function EventService.adminTriggerLegendary()
    lastLegendaryTime = 0  -- reset cooldown
    triggerLegendaryEvent()
end

-- Admin override: toggle drop boost
function EventService.adminToggleDropBoost()
    if dropBoostActive then
        deactivateDropBoost()
    else
        activateDropBoost()
    end
end

-- ── Studio test ───────────────────────────────────────────────────────

local function studioTest()
    if not RunService:IsStudio() then return end
    task.delay(20, function()
        print("[EventService] Studio: triggering test elite event")
        triggerEliteEvent()
    end)
end

-- ── Init ──────────────────────────────────────────────────────────────

function EventService.OnStart()
    task.spawn(scheduleLoop)
    studioTest()
end

return EventService
