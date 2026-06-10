local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes      = require(ReplicatedStorage.Remotes)
local UIController = require(script.Parent.UIController)

local Player    = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- ── Constants ─────────────────────────────────────────────────────────

local RARITY_COLORS = {
    Common    = Color3.fromRGB(180, 180, 180),
    Rare      = Color3.fromRGB(60, 120, 220),
    Epic      = Color3.fromRGB(160, 40, 200),
    Legendary = Color3.fromRGB(220, 160, 20),
}

-- ── State ─────────────────────────────────────────────────────────────

local currentInventoryData: any = nil
local currentAlbumData: any     = nil
local activeScreen: string?     = nil   -- "inventory" | "album" | nil

local InventoryController = {}

-- ── Screen: Inventory ─────────────────────────────────────────────────

local invGui = Instance.new("ScreenGui")
invGui.Name           = "InventoryScreen"
invGui.ResetOnSpawn   = false
invGui.Enabled        = false
invGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
invGui.Parent         = PlayerGui

-- Background overlay
local invOverlay = Instance.new("Frame")
invOverlay.Size              = UDim2.fromScale(1, 1)
invOverlay.BackgroundColor3  = Color3.fromRGB(0, 0, 0)
invOverlay.BackgroundTransparency = 0.5
invOverlay.Parent            = invGui

-- Main panel
local invPanel = Instance.new("Frame")
invPanel.Name              = "Panel"
invPanel.Size              = UDim2.new(0, 520, 0, 600)
invPanel.Position          = UDim2.new(0.5, -260, 0.5, -300)
invPanel.BackgroundColor3  = Color3.fromRGB(18, 18, 28)
invPanel.BorderSizePixel   = 0
invPanel.Parent            = invGui
Instance.new("UICorner", invPanel).CornerRadius = UDim.new(0, 14)

-- Title bar
local invTitle = Instance.new("TextLabel")
invTitle.Name              = "Title"
invTitle.Size              = UDim2.new(1, -50, 0, 50)
invTitle.Position          = UDim2.new(0, 0, 0, 0)
invTitle.BackgroundTransparency = 1
invTitle.Text              = "🎴 Inventario"
invTitle.TextColor3        = Color3.new(1, 1, 1)
invTitle.TextScaled        = true
invTitle.Font              = Enum.Font.GothamBold
invTitle.Parent            = invPanel

-- Close button
local invClose = Instance.new("TextButton")
invClose.Name              = "CloseBtn"
invClose.Size              = UDim2.new(0, 40, 0, 40)
invClose.Position          = UDim2.new(1, -46, 0, 5)
invClose.BackgroundColor3  = Color3.fromRGB(160, 20, 20)
invClose.BorderSizePixel   = 0
invClose.Text              = "✕"
invClose.TextColor3        = Color3.new(1, 1, 1)
invClose.TextScaled        = true
invClose.Font              = Enum.Font.GothamBold
invClose.Parent            = invPanel
Instance.new("UICorner", invClose).CornerRadius = UDim.new(0, 8)

-- Slot counter
local invSlotCount = Instance.new("TextLabel")
invSlotCount.Name              = "SlotCount"
invSlotCount.Size              = UDim2.new(1, 0, 0, 28)
invSlotCount.Position          = UDim2.new(0, 0, 0, 50)
invSlotCount.BackgroundTransparency = 1
invSlotCount.Text              = "Slots: 0/10"
invSlotCount.TextColor3        = Color3.fromRGB(180, 180, 180)
invSlotCount.TextScaled        = true
invSlotCount.Font              = Enum.Font.Gotham
invSlotCount.Parent            = invPanel

-- Scroll frame for cards
local invScroll = Instance.new("ScrollingFrame")
invScroll.Name                  = "CardScroll"
invScroll.Size                  = UDim2.new(1, -20, 1, -90)
invScroll.Position              = UDim2.new(0, 10, 0, 82)
invScroll.BackgroundTransparency = 1
invScroll.BorderSizePixel       = 0
invScroll.ScrollBarThickness    = 6
invScroll.ScrollBarImageColor3  = Color3.fromRGB(100, 100, 200)
invScroll.CanvasSize            = UDim2.new(0, 0, 0, 0)
invScroll.AutomaticCanvasSize   = Enum.AutomaticSize.Y
invScroll.Parent                = invPanel

local invListLayout = Instance.new("UIListLayout")
invListLayout.SortOrder        = Enum.SortOrder.LayoutOrder
invListLayout.Padding          = UDim.new(0, 6)
invListLayout.Parent           = invScroll

Instance.new("UIPadding", invScroll).PaddingTop = UDim.new(0, 4)

-- ── Screen: Album ─────────────────────────────────────────────────────

local albGui = Instance.new("ScreenGui")
albGui.Name           = "AlbumScreen"
albGui.ResetOnSpawn   = false
albGui.Enabled        = false
albGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
albGui.Parent         = PlayerGui

local albOverlay = Instance.new("Frame")
albOverlay.Size              = UDim2.fromScale(1, 1)
albOverlay.BackgroundColor3  = Color3.fromRGB(0, 0, 0)
albOverlay.BackgroundTransparency = 0.5
albOverlay.Parent            = albGui

local albPanel = Instance.new("Frame")
albPanel.Name              = "Panel"
albPanel.Size              = UDim2.new(0, 560, 0, 580)
albPanel.Position          = UDim2.new(0.5, -280, 0.5, -290)
albPanel.BackgroundColor3  = Color3.fromRGB(18, 18, 28)
albPanel.BorderSizePixel   = 0
albPanel.Parent            = albGui
Instance.new("UICorner", albPanel).CornerRadius = UDim.new(0, 14)

local albTitle = Instance.new("TextLabel")
albTitle.Size              = UDim2.new(1, -50, 0, 50)
albTitle.BackgroundTransparency = 1
albTitle.Text              = "📋 Álbum — Mundial 2026"
albTitle.TextColor3        = Color3.fromRGB(255, 220, 100)
albTitle.TextScaled        = true
albTitle.Font              = Enum.Font.GothamBold
albTitle.Parent            = albPanel

local albClose = Instance.new("TextButton")
albClose.Size              = UDim2.new(0, 40, 0, 40)
albClose.Position          = UDim2.new(1, -46, 0, 5)
albClose.BackgroundColor3  = Color3.fromRGB(160, 20, 20)
albClose.BorderSizePixel   = 0
albClose.Text              = "✕"
albClose.TextColor3        = Color3.new(1, 1, 1)
albClose.TextScaled        = true
albClose.Font              = Enum.Font.GothamBold
albClose.Parent            = albPanel
Instance.new("UICorner", albClose).CornerRadius = UDim.new(0, 8)

local albProgress = Instance.new("TextLabel")
albProgress.Size              = UDim2.new(1, 0, 0, 28)
albProgress.Position          = UDim2.new(0, 0, 0, 50)
albProgress.BackgroundTransparency = 1
albProgress.Text              = "Completado: 0 / 7"
albProgress.TextColor3        = Color3.fromRGB(160, 220, 160)
albProgress.TextScaled        = true
albProgress.Font              = Enum.Font.Gotham
albProgress.Parent            = albPanel

local albGrid = Instance.new("ScrollingFrame")
albGrid.Size                  = UDim2.new(1, -20, 1, -90)
albGrid.Position              = UDim2.new(0, 10, 0, 82)
albGrid.BackgroundTransparency = 1
albGrid.BorderSizePixel       = 0
albGrid.ScrollBarThickness    = 6
albGrid.ScrollBarImageColor3  = Color3.fromRGB(200, 160, 40)
albGrid.CanvasSize            = UDim2.new(0, 0, 0, 0)
albGrid.AutomaticCanvasSize   = Enum.AutomaticSize.Y
albGrid.Parent                = albPanel

local albGridLayout = Instance.new("UIGridLayout")
albGridLayout.CellSize         = UDim2.new(0, 96, 0, 120)
albGridLayout.CellPadding      = UDim2.new(0, 8, 0, 8)
albGridLayout.SortOrder        = Enum.SortOrder.LayoutOrder
albGridLayout.Parent           = albGrid

Instance.new("UIPadding", albGrid).PaddingLeft = UDim.new(0, 8)

-- ── Card row builder ──────────────────────────────────────────────────

local function makeCardRow(parent, card: any, index: number)
    local row = Instance.new("Frame")
    row.Name             = "CardRow_" .. index
    row.Size             = UDim2.new(1, 0, 0, 54)
    row.BackgroundColor3 = Color3.fromRGB(28, 28, 44)
    row.BorderSizePixel  = 0
    row.LayoutOrder      = index
    row.Parent           = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

    -- Rarity color strip
    local strip = Instance.new("Frame")
    strip.Size            = UDim2.new(0, 6, 1, 0)
    strip.BackgroundColor3 = RARITY_COLORS[card.rarity] or RARITY_COLORS.Common
    strip.BorderSizePixel = 0
    strip.Parent          = row
    Instance.new("UICorner", strip).CornerRadius = UDim.new(0, 4)

    -- Card name
    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size              = UDim2.new(0.55, 0, 0.55, 0)
    nameLbl.Position          = UDim2.new(0, 14, 0, 4)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text              = card.cardId or "?"
    nameLbl.TextColor3        = Color3.new(1, 1, 1)
    nameLbl.TextXAlignment    = Enum.TextXAlignment.Left
    nameLbl.TextScaled        = true
    nameLbl.Font              = Enum.Font.GothamBold
    nameLbl.Parent            = row

    -- Rarity label
    local rarityLbl = Instance.new("TextLabel")
    rarityLbl.Size              = UDim2.new(0.55, 0, 0.35, 0)
    rarityLbl.Position          = UDim2.new(0, 14, 0.58, 0)
    rarityLbl.BackgroundTransparency = 1
    rarityLbl.Text              = card.variant or "Normal"
    rarityLbl.TextColor3        = RARITY_COLORS[card.rarity] or RARITY_COLORS.Common
    rarityLbl.TextXAlignment    = Enum.TextXAlignment.Left
    rarityLbl.TextScaled        = true
    rarityLbl.Font              = Enum.Font.Gotham
    rarityLbl.Parent            = row

    -- Secure button
    if not card.secured then
        local secureBtn = Instance.new("TextButton")
        secureBtn.Size            = UDim2.new(0, 90, 0, 36)
        secureBtn.Position        = UDim2.new(1, -100, 0.5, -18)
        secureBtn.BackgroundColor3 = Color3.fromRGB(20, 120, 60)
        secureBtn.BorderSizePixel = 0
        secureBtn.Text            = "🔒 Asegurar"
        secureBtn.TextColor3      = Color3.new(1, 1, 1)
        secureBtn.TextScaled      = true
        secureBtn.Font            = Enum.Font.GothamBold
        secureBtn.Parent          = row
        Instance.new("UICorner", secureBtn).CornerRadius = UDim.new(0, 6)

        secureBtn.MouseButton1Click:Connect(function()
            Remotes.RequestSecureCard:FireServer(index)
        end)
    else
        -- "Secured" badge
        local badge = Instance.new("TextLabel")
        badge.Size             = UDim2.new(0, 80, 0, 30)
        badge.Position         = UDim2.new(1, -90, 0.5, -15)
        badge.BackgroundColor3 = Color3.fromRGB(20, 80, 20)
        badge.BorderSizePixel  = 0
        badge.Text             = "✅ Segura"
        badge.TextColor3       = Color3.fromRGB(180, 255, 180)
        badge.TextScaled       = true
        badge.Font             = Enum.Font.Gotham
        badge.Parent           = row
        Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 6)
    end

    return row
end

-- ── Album slot builder ────────────────────────────────────────────────

-- wc2026 album card IDs
local WC2026_CARDS = {
    "card_common_wc2026_arg",
    "card_common_wc2026_bra",
    "card_common_wc2026_fra",
    "card_common_wc2026_eng",
    "card_common_wc2026_esp",
    "card_rare_wc2026_player_random",
    "card_epic_wc2026_player_random",
}

local CARD_NAMES = {
    card_common_wc2026_arg = "Argentina",
    card_common_wc2026_bra = "Brasil",
    card_common_wc2026_fra = "Francia",
    card_common_wc2026_eng = "Inglaterra",
    card_common_wc2026_esp = "España",
    card_rare_wc2026_player_random  = "Figura WC",
    card_epic_wc2026_player_random  = "Estrella WC",
}

local function makeAlbumSlot(parent, cardId: string, filled: boolean, order: number)
    local slot = Instance.new("Frame")
    slot.Name             = "Slot_" .. cardId
    slot.BackgroundColor3 = filled
        and Color3.fromRGB(20, 100, 40)
        or  Color3.fromRGB(30, 30, 50)
    slot.BorderSizePixel  = 0
    slot.LayoutOrder      = order
    slot.Parent           = parent
    Instance.new("UICorner", slot).CornerRadius = UDim.new(0, 8)

    -- Card art placeholder (colored rectangle)
    local art = Instance.new("Frame")
    art.Size             = UDim2.new(0.85, 0, 0.6, 0)
    art.Position         = UDim2.new(0.075, 0, 0.05, 0)
    art.BackgroundColor3 = filled
        and Color3.fromRGB(40, 160, 80)
        or  Color3.fromRGB(50, 50, 70)
    art.BorderSizePixel  = 0
    art.Parent           = slot
    Instance.new("UICorner", art).CornerRadius = UDim.new(0, 6)

    local icon = Instance.new("TextLabel")
    icon.Size              = UDim2.fromScale(1, 1)
    icon.BackgroundTransparency = 1
    icon.Text              = filled and "⚽" or "?"
    icon.TextScaled        = true
    icon.Font              = Enum.Font.GothamBold
    icon.TextColor3        = Color3.new(1, 1, 1)
    icon.Parent            = art

    -- Name
    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size              = UDim2.new(1, 0, 0.32, 0)
    nameLbl.Position          = UDim2.new(0, 0, 0.68, 0)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text              = CARD_NAMES[cardId] or cardId
    nameLbl.TextColor3        = filled
        and Color3.fromRGB(200, 255, 200)
        or  Color3.fromRGB(120, 120, 140)
    nameLbl.TextScaled        = true
    nameLbl.Font              = Enum.Font.GothamBold
    nameLbl.Parent            = slot

    return slot
end

-- ── Render functions ──────────────────────────────────────────────────

local function renderInventory(data: any)
    -- Clear existing rows
    for _, child in ipairs(invScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    local allCards = {}
    for _, c in ipairs(data.cards or {}) do
        table.insert(allCards, c)
    end
    for _, c in ipairs(data.securedCards or {}) do
        table.insert(allCards, c)
    end

    invSlotCount.Text = "Slots: " .. #(data.cards or {})
        .. "/" .. (data.inventorySlots or 10)
        .. "  |  Aseguradas: " .. #(data.securedCards or {})
        .. "/" .. (data.storageSlots or 5)

    if #allCards == 0 then
        local empty = Instance.new("TextLabel")
        empty.Size              = UDim2.new(1, 0, 0, 60)
        empty.BackgroundTransparency = 1
        empty.Text              = "No tenés cartas todavía. ¡Salí a capturar brainrots!"
        empty.TextColor3        = Color3.fromRGB(140, 140, 160)
        empty.TextScaled        = true
        empty.Font              = Enum.Font.Gotham
        empty.Parent            = invScroll
        return
    end

    for i, card in ipairs(allCards) do
        makeCardRow(invScroll, card, i)
    end
end

local function renderAlbum(albumProgress: any)
    for _, child in ipairs(albGrid:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    local completed = 0
    for i, cardId in ipairs(WC2026_CARDS) do
        local key    = "wc2026_" .. cardId
        local filled = albumProgress and albumProgress[key] == true
        if filled then completed += 1 end
        makeAlbumSlot(albGrid, cardId, filled, i)
    end

    albProgress.Text = "Completado: " .. completed .. " / " .. #WC2026_CARDS
end

-- ── Toggle logic ──────────────────────────────────────────────────────

local function closeAll()
    invGui.Enabled = false
    albGui.Enabled = false
    activeScreen   = nil
end

local function openInventory()
    if activeScreen == "inventory" then
        closeAll()
        return
    end
    closeAll()
    if currentInventoryData then
        renderInventory(currentInventoryData)
    end
    invGui.Enabled = true
    activeScreen   = "inventory"
end

local function openAlbum()
    if activeScreen == "album" then
        closeAll()
        return
    end
    closeAll()
    renderAlbum(currentAlbumData)
    albGui.Enabled = true
    activeScreen   = "album"
end

-- ── Init ──────────────────────────────────────────────────────────────

function InventoryController.OnStart()
    -- Wire HUD buttons
    UIController.InventoryButton.MouseButton1Click:Connect(openInventory)
    UIController.AlbumButton.MouseButton1Click:Connect(openAlbum)

    -- Close buttons
    invClose.MouseButton1Click:Connect(closeAll)
    albClose.MouseButton1Click:Connect(closeAll)

    -- Close on overlay click
    invOverlay.MouseButton1Click:Connect(closeAll)
    albOverlay.MouseButton1Click:Connect(closeAll)

    -- Initial data load
    Remotes.PlayerDataLoaded:Connect(function(data)
        currentInventoryData = data
        currentAlbumData     = data.albumProgress or {}
        if activeScreen == "inventory" then renderInventory(data) end
        if activeScreen == "album"     then renderAlbum(data.albumProgress or {}) end
    end)

    -- Live inventory updates
    Remotes.InventoryUpdated:Connect(function(data)
        currentInventoryData = data
        currentAlbumData     = data.albumProgress or {}
        if activeScreen == "inventory" then renderInventory(data) end
    end)

    Remotes.AlbumUpdated:Connect(function(data)
        currentAlbumData = data.albumProgress or {}
        if activeScreen == "album" then renderAlbum(currentAlbumData) end
    end)
end

return InventoryController
