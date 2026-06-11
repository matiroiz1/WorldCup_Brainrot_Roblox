local Players             = game:GetService("Players")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local Workspace           = game:GetService("Workspace")

local Remotes  = require(ReplicatedStorage.Remotes)
local Economy  = require(ReplicatedStorage.Config.Economy)

local BASE_COUNT = 15

-- Runtime state: baseId -> userId (cleared each server session)
local Occupied: { [string]: number } = {}
-- Runtime state: userId -> baseId
local PlayerBases: { [number]: string } = {}
-- Runtime state: baseId -> isLocked boolean
local LockedBases: { [string]: boolean } = {}

local BaseService = {}

-- ── Private helpers ───────────────────────────────────────────────────

local function getPlayerDataService()
    -- Lazy require to avoid circular dependency at module load time
    return require(script.Parent.PlayerDataService)
end

local function findFreeBase(): string?
    for i = 1, BASE_COUNT do
        local id = "Base_" .. i
        if not Occupied[id] then return id end
    end
    return nil
end

-- Returns the BasePart (Boundary) for a given baseId, or nil
local function getBaseBoundary(baseId: string): BasePart?
    local map = Workspace:FindFirstChild("Map")
    if not map then return nil end
    local basesFolder = map:FindFirstChild("PlayerBases")
    if not basesFolder then return nil end
    local folder = basesFolder:FindFirstChild(baseId)
    if not folder then return nil end
    return folder:FindFirstChild("Boundary") :: BasePart?
end

-- Simple AABB check: is position inside a BasePart?
local function isInsidePart(part: BasePart, position: Vector3): boolean
    local local_ = part.CFrame:PointToObjectSpace(position)
    local half   = part.Size / 2
    return math.abs(local_.X) <= half.X
       and math.abs(local_.Y) <= half.Y
       and math.abs(local_.Z) <= half.Z
end

-- ── Public API ────────────────────────────────────────────────────────

function BaseService.updateBaseVisuals(baseId: string, isLocked: boolean)
    local map = Workspace:FindFirstChild("Map")
    if not map then return end
    local basesFolder = map:FindFirstChild("PlayerBases")
    if not basesFolder then return end
    local folder = basesFolder:FindFirstChild(baseId)
    if not folder then return end
    
    local door = folder:FindFirstChild("Door")
    if door and door:IsA("BasePart") then
        door.CanCollide = isLocked
        door.Transparency = isLocked and 0.2 or 0.9
        door.Color = isLocked and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(50, 255, 50)
        door.Material = Enum.Material.Neon
    end
end

function BaseService.syncPhysicalAlbum(player: Player)
    local baseId = PlayerBases[player.UserId]
    if not baseId then return end
    
    local map = Workspace:FindFirstChild("Map")
    if not map then return end
    local basesFolder = map:FindFirstChild("PlayerBases")
    if not basesFolder then return end
    local baseFolder = basesFolder:FindFirstChild(baseId)
    if not baseFolder then return end
    
    local albumSlotsFolder = baseFolder:FindFirstChild("AlbumSlots")
    if not albumSlotsFolder then
        albumSlotsFolder = Instance.new("Folder")
        albumSlotsFolder.Name = "AlbumSlots"
        albumSlotsFolder.Parent = baseFolder
    end
    
    local data = getPlayerDataService().getData(player)
    local albumProgress = data and data.albumProgress or {}
    
    local wc2026Cards = {
        "card_common_wc2026_arg",
        "card_common_wc2026_bra",
        "card_common_wc2026_fra",
        "card_common_wc2026_eng",
        "card_common_wc2026_esp",
        "card_rare_wc2026_player_random",
        "card_epic_wc2026_player_random"
    }
    
    for _, cardId in ipairs(wc2026Cards) do
        local key = "wc2026_" .. cardId
        local hasCard = not not albumProgress[key]
        
        local val = albumSlotsFolder:FindFirstChild(cardId)
        if not val then
            val = Instance.new("BoolValue")
            val.Name = cardId
            val.Parent = albumSlotsFolder
        end
        val.Value = hasCard
    end
end

function BaseService.getPlayerBase(player: Player): string?
    return PlayerBases[player.UserId]
end

function BaseService.getBaseOwner(baseId: string): number?
    return Occupied[baseId]
end

function BaseService.isBaseLocked(baseId: string): boolean
    return LockedBases[baseId] or false
end

function BaseService.toggleLock(player: Player)
    local baseId = PlayerBases[player.UserId]
    if not baseId then return end
    
    local currentState = LockedBases[baseId] or false
    
    if not currentState then
        -- Intentando bloquear. Verificar si tiene al menos 5 monedas (o gemas)
        local PDS = getPlayerDataService()
        local data = PDS.getData(player)
        if not data or data.coins < 5 then
            Remotes.Notification:FireClient(player, {type = "error", message = "No tienes suficientes monedas para bloquear."})
            return
        end
    end

    LockedBases[baseId] = not currentState
    local newState = LockedBases[baseId]
    
    BaseService.updateBaseVisuals(baseId, newState)

    Remotes.Notification:FireClient(player, {
        type = "info", 
        message = newState and "Base BLOQUEADA (Consumiendo monedas)" or "Base DESBLOQUEADA"
    })
end

function BaseService.getBaseLevel(player: Player): number
    local data = getPlayerDataService().getData(player)
    return data and (data.baseLevel or 1) or 1
end

-- Returns true if the player is inside their own base boundary
function BaseService.isPlayerInOwnBase(player: Player): boolean
    local baseId = PlayerBases[player.UserId]
    if not baseId then return false end
    local boundary = getBaseBoundary(baseId)
    if not boundary then return false end
    local char = player.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    return isInsidePart(boundary, hrp.Position)
end

-- Returns the baseId if position is inside ANY base boundary, else nil
function BaseService.getBaseAtPosition(position: Vector3): string?
    local map = Workspace:FindFirstChild("Map")
    if not map then return nil end
    local basesFolder = map:FindFirstChild("PlayerBases")
    if not basesFolder then return nil end
    for _, folder in ipairs(basesFolder:GetChildren()) do
        if folder:IsA("Folder") then
            local boundary = folder:FindFirstChild("Boundary")
            if boundary and boundary:IsA("BasePart") then
                if isInsidePart(boundary :: BasePart, position) then
                    return folder.Name
                end
            end
        end
    end
    return nil
end

-- Assign a base on join. Uses saved base if still free, else first free.
function BaseService.assignBase(player: Player)
    local PDS  = getPlayerDataService()
    local data = PDS.getData(player)
    if not data then return end

    local baseId: string?

    if data.assignedBase and data.assignedBase ~= "" then
        if not Occupied[data.assignedBase] then
            baseId = data.assignedBase
        end
    end

    if not baseId then
        baseId = findFreeBase()
    end

    if not baseId then
        warn("[BaseService] No free base for", player.Name)
        return
    end

    Occupied[baseId]          = player.UserId
    PlayerBases[player.UserId] = baseId

    PDS.update(player, function(d)
        d.assignedBase = baseId
    end)

    local perks = Economy.BaseLevelPerks[data.baseLevel or 1]
    Remotes.BaseAssigned:FireClient(player, {
        baseId    = baseId,
        baseLevel = data.baseLevel or 1,
        perks     = perks,
    })
    
    -- Sync physical album immediately on join/assignment
    BaseService.syncPhysicalAlbum(player)
end

function BaseService.releaseBase(player: Player)
    local baseId = PlayerBases[player.UserId]
    if baseId then
        Occupied[baseId]          = nil
        PlayerBases[player.UserId] = nil
        LockedBases[baseId]        = false
        BaseService.updateBaseVisuals(baseId, false)
        
        -- Reset physical album slot values on release
        local map = Workspace:FindFirstChild("Map")
        local basesFolder = map and map:FindFirstChild("PlayerBases")
        local baseFolder = basesFolder and basesFolder:FindFirstChild(baseId)
        local albumSlotsFolder = baseFolder and baseFolder:FindFirstChild("AlbumSlots")
        if albumSlotsFolder then
            for _, val in ipairs(albumSlotsFolder:GetChildren()) do
                if val:IsA("BoolValue") then
                    val.Value = false
                end
            end
        end
    end
end

-- Upgrade the player's base one level.
-- Returns (success: boolean, reason: string)
-- If Robux is required, returns (false, "USE_ROBUX:<amount>") — ShopService handles Robux flow.
function BaseService.upgradeBase(player: Player): (boolean, string)
    local PDS  = getPlayerDataService()
    local data = PDS.getData(player)
    if not data then return false, "data_not_loaded" end

    local currentLevel = data.baseLevel or 1
    if currentLevel >= 5 then return false, "max_level" end

    local nextLevel = currentLevel + 1
    local cost = Economy.BaseUpgradeCosts[nextLevel]

    if cost.robux > 0 then
        return false, "USE_ROBUX:" .. cost.robux
    end

    if data.coins < cost.coins then
        return false, "insufficient_coins"
    end

    local extraStorage = Economy.BaseLevelPerks[nextLevel].extraStorage or 0

    PDS.update(player, function(d)
        d.coins     = d.coins - cost.coins
        d.baseLevel = nextLevel
        d.storageSlots = d.storageSlots + extraStorage
    end)

    local newData = PDS.getData(player)
    Remotes.CoinsUpdated:FireClient(player, newData.coins)
    Remotes.BaseUpgraded:FireClient(player, {
        baseLevel = nextLevel,
        perks     = Economy.BaseLevelPerks[nextLevel],
    })

    return true, "ok"
end

-- Upgrade to a specific level without coin check (used by ShopService after Robux payment).
-- Only works if player is exactly one level below targetLevel.
function BaseService.upgradeToLevel(player: Player, targetLevel: number): boolean
    local PDS  = getPlayerDataService()
    local data = PDS.getData(player)
    if not data then return false end

    local currentLevel = data.baseLevel or 1
    if currentLevel ~= targetLevel - 1 then return false end
    if targetLevel > 5 then return false end

    local perks        = Economy.BaseLevelPerks[targetLevel]
    local extraStorage = perks.extraStorage or 0

    PDS.update(player, function(d)
        d.baseLevel    = targetLevel
        d.storageSlots = d.storageSlots + extraStorage
    end)

    Remotes.BaseUpgraded:FireClient(player, {
        baseLevel = targetLevel,
        perks     = perks,
    })
    return true
end

local function setupBasePrompts()
    local map = Workspace:FindFirstChild("Map")
    if not map then return end
    local basesFolder = map:FindFirstChild("PlayerBases")
    if not basesFolder then return end

    for _, folder in ipairs(basesFolder:GetChildren()) do
        if folder:IsA("Folder") or folder:IsA("Model") then
            local baseId = folder.Name

            -- LockSwitch Prompt
            local lockSwitch = folder:FindFirstChild("LockSwitch")
            if lockSwitch then
                local prompt = lockSwitch:FindFirstChild("LockPrompt") :: ProximityPrompt?
                if prompt then
                    prompt.Triggered:Connect(function(player)
                        local myBaseId = PlayerBases[player.UserId]
                        if myBaseId == baseId then
                            BaseService.toggleLock(player)
                        else
                            Remotes.Notification:FireClient(player, {
                                type    = "error",
                                message = "Solo el dueño puede bloquear esta base.",
                            })
                        end
                    end)
                end
            end

            -- Album Prompt
            local album = folder:FindFirstChild("Album")
            if album then
                local prompt = album:FindFirstChild("AlbumPrompt") :: ProximityPrompt?
                if prompt then
                    prompt.Triggered:Connect(function(player)
                        local ownerId = Occupied[baseId]
                        if ownerId == player.UserId then
                            -- El dueño interactúa con su propio álbum
                            -- Firing AlbumUpdated syncs data; we'll also tell client to open their own album screen
                            Remotes.AlbumUpdated:FireClient(player, {
                                albumProgress = getPlayerDataService().getData(player).albumProgress or {}
                            })
                        else
                            -- Ladrón intentando interactuar
                            if BaseService.isBaseLocked(baseId) then
                                Remotes.Notification:FireClient(player, {
                                    type    = "error",
                                    message = "¡La base está asegurada! No podés robar.",
                                })
                                return
                            end

                            if not ownerId then
                                Remotes.Notification:FireClient(player, {
                                    type    = "warning",
                                    message = "Esta base no tiene dueño asignado.",
                                })
                                return
                            end

                            local victim = Players:GetPlayerByUserId(ownerId)
                            if not victim then return end

                            local victimData = getPlayerDataService().getData(victim)
                            if not victimData then return end

                            -- Abrir visor del álbum de la víctima para el ladrón
                            Remotes.ViewAlbum:FireClient(player, baseId, victim.DisplayName, victimData.albumProgress or {})
                        end
                    end)
                end
            end
        end
    end
end

-- ── Init ──────────────────────────────────────────────────────────────

function BaseService.OnStart()
    setupBasePrompts()

    Players.PlayerAdded:Connect(function(player)
        -- PlayerDataService loads profile asynchronously; wait for it
        task.delay(2.5, function()
            if player:IsDescendantOf(Players) then
                BaseService.assignBase(player)
            end
        end)
    end)

    Players.PlayerRemoving:Connect(BaseService.releaseBase)

    Remotes.RequestBaseUpgrade:Connect(function(player)
        local success, reason = BaseService.upgradeBase(player)
        if not success then
            Remotes.Notification:FireClient(player, {
                type    = "error",
                message = reason,
            })
        end
    end)
    
    -- Agregar ToggleLock a Remotes si no existe
    if Remotes:FindFirstChild("ToggleBaseLock") then
        Remotes.ToggleBaseLock:Connect(function(player)
            BaseService.toggleLock(player)
        end)
    end

    -- Loop de cobro por bloqueo (cada 5 segundos cobra 5 monedas)
    task.spawn(function()
        while true do
            task.wait(5)
            local PDS = getPlayerDataService()
            for baseId, isLocked in pairs(LockedBases) do
                if isLocked then
                    local ownerId = Occupied[baseId]
                    if ownerId then
                        local player = Players:GetPlayerByUserId(ownerId)
                        if player then
                            local data = PDS.getData(player)
                            if data and data.coins >= 5 then
                                PDS.update(player, function(d) d.coins = d.coins - 5 end)
                                Remotes.CoinsUpdated:FireClient(player, data.coins - 5)
                            else
                                -- Se quedó sin plata, desbloqueamos la base
                                LockedBases[baseId] = false
                                BaseService.updateBaseVisuals(baseId, false)
                                Remotes.Notification:FireClient(player, {type = "error", message = "Base desbloqueada: Sin saldo suficiente."})
                            end
                        else
                            LockedBases[baseId] = false
                            BaseService.updateBaseVisuals(baseId, false)
                        end
                    end
                end
            end
        end
    end)
end

return BaseService
