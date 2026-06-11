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
local activeScreen: string?     = nil   -- "inventory" | "album" | "album_viewer" | nil

local viewerTargetBaseId: string? = nil
local viewerVictimName: string?   = nil
local activeConfirmConnection: RBXScriptConnection? = nil
local activeBoostConnection: RBXScriptConnection?   = nil

local InventoryController = {}

-- ── Screen: Inventory ─────────────────────────────────────────────────

local invGui = Instance.new("ScreenGui")
invGui.Name           = "InventoryScreen"
invGui.ResetOnSpawn   = false
invGui.Enabled        = false
invGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
invGui.Parent         = PlayerGui

-- Background overlay
local invOverlay = Instance.new("TextButton")
invOverlay.Size              = UDim2.fromScale(1, 1)
invOverlay.BackgroundColor3  = Color3.fromRGB(0, 0, 0)
invOverlay.BackgroundTransparency = 0.5
invOverlay.Text              = ""
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

local albOverlay = Instance.new("TextButton")
albOverlay.Size              = UDim2.fromScale(1, 1)
albOverlay.BackgroundColor3  = Color3.fromRGB(0, 0, 0)
albOverlay.BackgroundTransparency = 0.5
albOverlay.Text              = ""
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

-- Confirm PopUp dialog
local confirmFrame = Instance.new("Frame")
confirmFrame.Name = "ConfirmPopup"
confirmFrame.Size = UDim2.new(0.8, 0, 0.45, 0)
confirmFrame.Position = UDim2.new(0.1, 0, 0.28, 0)
confirmFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 37)
confirmFrame.BorderSizePixel = 0
confirmFrame.Visible = false
confirmFrame.ZIndex = 10
confirmFrame.Parent = albPanel
Instance.new("UICorner", confirmFrame).CornerRadius = UDim.new(0, 12)

local confirmTitle = Instance.new("TextLabel")
confirmTitle.Size = UDim2.new(1, 0, 0.35, 0)
confirmTitle.BackgroundTransparency = 1
confirmTitle.Text = "¿Robar esta carta?"
confirmTitle.TextColor3 = Color3.new(1, 1, 1)
confirmTitle.TextScaled = true
confirmTitle.Font = Enum.Font.GothamBold
confirmTitle.Parent = confirmFrame

local confirmBtnNormal = Instance.new("TextButton")
confirmBtnNormal.Size = UDim2.new(0.42, 0, 0.22, 0)
confirmBtnNormal.Position = UDim2.new(0.06, 0, 0.42, 0)
confirmBtnNormal.BackgroundColor3 = Color3.fromRGB(40, 120, 60)
confirmBtnNormal.Text = "Normal (10s)"
confirmBtnNormal.TextColor3 = Color3.new(1, 1, 1)
confirmBtnNormal.TextScaled = true
confirmBtnNormal.Font = Enum.Font.GothamBold
confirmBtnNormal.Parent = confirmFrame
Instance.new("UICorner", confirmBtnNormal).CornerRadius = UDim.new(0, 6)

local confirmBtnBoost = Instance.new("TextButton")
confirmBtnBoost.Size = UDim2.new(0.42, 0, 0.22, 0)
confirmBtnBoost.Position = UDim2.new(0.52, 0, 0.42, 0)
confirmBtnBoost.BackgroundColor3 = Color3.fromRGB(180, 120, 10)
confirmBtnBoost.Text = "Rápido (3s - 50 🪙)"
confirmBtnBoost.TextColor3 = Color3.new(1, 1, 1)
confirmBtnBoost.TextScaled = true
confirmBtnBoost.Font = Enum.Font.GothamBold
confirmBtnBoost.Parent = confirmFrame
Instance.new("UICorner", confirmBtnBoost).CornerRadius = UDim.new(0, 6)

local confirmBtnCancel = Instance.new("TextButton")
confirmBtnCancel.Size = UDim2.new(0.9, 0, 0.18, 0)
confirmBtnCancel.Position = UDim2.new(0.05, 0, 0.74, 0)
confirmBtnCancel.BackgroundColor3 = Color3.fromRGB(120, 30, 30)
confirmBtnCancel.Text = "Cancelar"
confirmBtnCancel.TextColor3 = Color3.new(1, 1, 1)
confirmBtnCancel.TextScaled = true
confirmBtnCancel.Font = Enum.Font.GothamBold
confirmBtnCancel.Parent = confirmFrame
Instance.new("UICorner", confirmBtnCancel).CornerRadius = UDim.new(0, 6)

confirmBtnCancel.MouseButton1Click:Connect(function()
    confirmFrame.Visible = false
end)

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

    if filled then
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.fromScale(1, 1)
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.Parent = slot
        
        btn.MouseButton1Click:Connect(function()
            if activeConfirmConnection then activeConfirmConnection:Disconnect() end
            if activeBoostConnection then activeBoostConnection:Disconnect() end
            
            local albumKey = "wc2026_" .. cardId
            
            if viewerTargetBaseId == nil then
                -- Despegar propia carta
                confirmTitle.Text = "¿Despegar " .. (CARD_NAMES[cardId] or cardId) .. " del álbum?"
                confirmBtnNormal.Text = "Despegar al Inventario"
                confirmBtnNormal.BackgroundColor3 = Color3.fromRGB(40, 120, 60)
                confirmBtnNormal.Position = UDim2.new(0.05, 0, 0.42, 0)
                confirmBtnNormal.Size = UDim2.new(0.9, 0, 0.22, 0)
                confirmBtnBoost.Visible = false
                
                activeConfirmConnection = confirmBtnNormal.MouseButton1Click:Connect(function()
                    confirmFrame.Visible = false
                    Remotes.DetachCardSelf:FireServer(albumKey)
                end)
            else
                -- Robar carta ajena
                confirmTitle.Text = "¿Robar " .. (CARD_NAMES[cardId] or cardId) .. " de " .. viewerVictimName .. "?"
                confirmBtnNormal.Text = "Normal (10s)"
                confirmBtnNormal.BackgroundColor3 = Color3.fromRGB(40, 100, 180)
                confirmBtnNormal.Position = UDim2.new(0.06, 0, 0.42, 0)
                confirmBtnNormal.Size = UDim2.new(0.42, 0, 0.22, 0)
                confirmBtnBoost.Visible = true
                
                activeConfirmConnection = confirmBtnNormal.MouseButton1Click:Connect(function()
                    confirmFrame.Visible = false
                    Remotes.RequestStealAlbumCard:FireServer(viewerTargetBaseId, albumKey, false)
                end)
                
                activeBoostConnection = confirmBtnBoost.MouseButton1Click:Connect(function()
                    confirmFrame.Visible = false
                    Remotes.RequestStealAlbumCard:FireServer(viewerTargetBaseId, albumKey, true)
                end)
            end
            
            confirmFrame.Visible = true
        end)
    end

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
    confirmFrame.Visible = false
    activeScreen   = nil
    viewerTargetBaseId = nil
    viewerVictimName   = nil
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
    albTitle.Text = "📋 Álbum — Mundial 2026"
    renderAlbum(currentAlbumData)
    albGui.Enabled = true
    activeScreen   = "album"
end

local function openAlbumViewer(targetBaseId: string, victimName: string, albumProgress: any)
    closeAll()
    viewerTargetBaseId = targetBaseId
    viewerVictimName   = victimName
    
    albTitle.Text = "📋 Álbum de " .. victimName
    renderAlbum(albumProgress)
    
    albGui.Enabled = true
    activeScreen   = "album_viewer"
end

local PAGES_CONFIG = {
    [1] = {
        country = "Argentina",
        flag = "🇦🇷",
        cardId = "card_common_wc2026_arg",
        activeSlot = 9,
        players = {
            "E. Martinez", "N. Molina", "C. Romero", "N. Otamendi", "E. Fernandez",
            "A. Mac Allister", "R. De Paul", "J. Alvarez", "L. Messi", "A. Di Maria", "L. Martinez"
        }
    },
    [2] = {
        country = "Brasil",
        flag = "🇧🇷",
        cardId = "card_common_wc2026_bra",
        activeSlot = 10,
        players = {
            "Alisson", "Danilo", "Marquinhos", "Gabriel", "Casemiro",
            "B. Guimaraes", "Paqueta", "Raphinha", "Rodrygo", "Vinicius Jr", "Richarlison"
        }
    },
    [3] = {
        country = "Francia",
        flag = "🇫🇷",
        cardId = "card_common_wc2026_fra",
        activeSlot = 7,
        players = {
            "Maignan", "Kounde", "Upamecano", "Saliba", "Hernandez",
            "Tchouameni", "K. Mbappe", "Rabiot", "Griezmann", "Dembele", "Giroud"
        }
    },
    [4] = {
        country = "Inglaterra",
        flag = "🏴󠁧󠁢󠁥󠁮󠁧󠁿",
        cardId = "card_common_wc2026_eng",
        activeSlot = 9,
        players = {
            "Pickford", "Walker", "Stones", "Maguire", "Trippier",
            "Rice", "Bellingham", "Saka", "H. Kane", "Foden", "Rashford"
        }
    },
    [5] = {
        country = "España",
        flag = "🇪🇸",
        cardId = "card_common_wc2026_esp",
        activeSlot = 10,
        players = {
            "U. Simon", "Carvajal", "Le Normand", "Laporte", "Cucurella",
            "Rodri", "F. Ruiz", "L. Yamal", "N. Williams", "D. Olmo", "Morata"
        }
    }
}

local function setupPhysicalAlbums()
    local map = workspace:WaitForChild("Map")
    local basesFolder = map:WaitForChild("PlayerBases")
    
    local function setupBase(baseFolder)
        local albumPart = baseFolder:WaitForChild("Album")
        local albumSlots = baseFolder:WaitForChild("AlbumSlots")
        local albumPage = baseFolder:WaitForChild("AlbumPage") :: IntValue
        
        -- Find or create SurfaceGui
        local sg = albumPart:FindFirstChild("AlbumSurface")
        if not sg then
            sg = Instance.new("SurfaceGui")
            sg.Name = "AlbumSurface"
            sg.Face = Enum.NormalId.Front
            sg.SizingMode = Enum.SurfaceGuiSizingMode.Pixels
            sg.CanvasSize = Vector2.new(800, 600)
            sg.Parent = albumPart
        end
        
        -- Create container frame
        local mainFrame = sg:FindFirstChild("MainFrame")
        if not mainFrame then
            mainFrame = Instance.new("Frame")
            mainFrame.Name = "MainFrame"
            mainFrame.Size = UDim2.fromScale(1, 1)
            mainFrame.BackgroundColor3 = Color3.fromRGB(240, 240, 245) -- book page white
            mainFrame.BorderSizePixel = 6
            mainFrame.BorderColor3 = Color3.fromRGB(35, 45, 60)
            mainFrame.Parent = sg
            
            -- Header Bar
            local header = Instance.new("Frame")
            header.Name = "Header"
            header.Size = UDim2.new(1, 0, 0, 80)
            header.BackgroundColor3 = Color3.fromRGB(35, 45, 60)
            header.BorderSizePixel = 0
            header.Parent = mainFrame
            
            -- Title text
            local title = Instance.new("TextLabel")
            title.Name = "Title"
            title.Size = UDim2.new(0.7, 0, 1, 0)
            title.Position = UDim2.fromScale(0.05, 0)
            title.BackgroundTransparency = 1
            title.Text = "WE ARE ARGENTINA"
            title.TextColor3 = Color3.new(1, 1, 1)
            title.TextSize = 32
            title.Font = Enum.Font.GothamBold
            title.TextXAlignment = Enum.TextXAlignment.Left
            title.Parent = header
            
            -- Flag label
            local flagLbl = Instance.new("TextLabel")
            flagLbl.Name = "Flag"
            flagLbl.Size = UDim2.new(0.2, 0, 1, 0)
            flagLbl.Position = UDim2.fromScale(0.75, 0)
            flagLbl.BackgroundTransparency = 1
            flagLbl.Text = "🇦🇷"
            flagLbl.TextSize = 44
            flagLbl.TextXAlignment = Enum.TextXAlignment.Right
            flagLbl.Parent = header
            
            -- Grid area for cards
            local gridFrame = Instance.new("Frame")
            gridFrame.Name = "GridFrame"
            gridFrame.Size = UDim2.new(1, 0, 1, -80)
            gridFrame.Position = UDim2.fromScale(0, 80)
            gridFrame.BackgroundTransparency = 1
            gridFrame.Parent = mainFrame
            
            local grid = Instance.new("UIGridLayout")
            grid.CellSize = UDim2.new(0, 110, 0, 150)
            grid.CellPadding = UDim2.new(0, 14, 0, 14)
            grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
            grid.VerticalAlignment = Enum.VerticalAlignment.Center
            grid.SortOrder = Enum.SortOrder.LayoutOrder
            grid.Parent = gridFrame
            
            -- Create 11 slots
            for slotIndex = 1, 11 do
                local slot = Instance.new("Frame")
                slot.Name = "Slot_" .. slotIndex
                slot.BackgroundColor3 = Color3.fromRGB(50, 55, 65)
                slot.BorderSizePixel = 2
                slot.BorderColor3 = Color3.fromRGB(150, 155, 165)
                slot.LayoutOrder = slotIndex
                slot.Parent = gridFrame
                
                local label = Instance.new("TextLabel")
                label.Name = "Label"
                label.Size = UDim2.fromScale(1, 1)
                label.BackgroundTransparency = 1
                label.Text = "#" .. slotIndex
                label.TextColor3 = Color3.fromRGB(180, 185, 195)
                label.TextSize = 12
                label.TextWrapped = true
                label.Font = Enum.Font.GothamMedium
                label.Parent = slot
            end
        end
        
        local header = mainFrame:WaitForChild("Header")
        local title = header:WaitForChild("Title") :: TextLabel
        local flagLbl = header:WaitForChild("Flag") :: TextLabel
        local gridFrame = mainFrame:WaitForChild("GridFrame")
        
        local function renderPage()
            local page = albumPage.Value
            local config = PAGES_CONFIG[page] or PAGES_CONFIG[1]
            
            title.Text = "WE ARE " .. config.country:upper()
            flagLbl.Text = config.flag
            
            -- Get album data value
            local hasActiveCard = false
            local targetVal = albumSlots:FindFirstChild(config.cardId)
            if targetVal and targetVal:IsA("BoolValue") then
                hasActiveCard = targetVal.Value
            end
            
            for slotIndex = 1, 11 do
                local slot = gridFrame:FindFirstChild("Slot_" .. slotIndex)
                if slot then
                    local label = slot:FindFirstChild("Label") :: TextLabel?
                    if label then
                        local playerName = config.players[slotIndex] or "Jugador"
                        
                        if slotIndex == config.activeSlot then
                            if hasActiveCard then
                                -- Completed card
                                slot.BackgroundColor3 = Color3.fromRGB(35, 160, 75)
                                slot.BorderColor3 = Color3.fromRGB(255, 215, 0)
                                label.TextColor3 = Color3.new(1, 1, 1)
                                label.Text = "★ CRACK ★\n" .. playerName:upper()
                            else
                                -- Locked/missing card
                                slot.BackgroundColor3 = Color3.fromRGB(80, 85, 95)
                                slot.BorderColor3 = Color3.fromRGB(220, 50, 50)
                                label.TextColor3 = Color3.fromRGB(220, 200, 200)
                                label.Text = "#" .. slotIndex .. "\n" .. playerName .. "\n(BLOQUEADO)"
                            end
                        else
                            -- Dummy slots
                            slot.BackgroundColor3 = Color3.fromRGB(210, 210, 215)
                            slot.BorderColor3 = Color3.fromRGB(170, 175, 180)
                            label.TextColor3 = Color3.fromRGB(100, 100, 105)
                            label.Text = "#" .. slotIndex .. "\n" .. playerName
                        end
                    end
                end
            end
        end
        
        renderPage()
        
        albumPage.Changed:Connect(renderPage)
        
        for _, val in ipairs(albumSlots:GetChildren()) do
            if val:IsA("BoolValue") then
                val.Changed:Connect(renderPage)
            end
        end
        
        albumSlots.ChildAdded:Connect(function(val)
            if val:IsA("BoolValue") then
                task.wait(0.05)
                renderPage()
                val.Changed:Connect(renderPage)
            end
        end)
    end
    
    for _, baseFolder in ipairs(basesFolder:GetChildren()) do
        task.spawn(setupBase, baseFolder)
    end
    
    basesFolder.ChildAdded:Connect(function(baseFolder)
        task.spawn(setupBase, baseFolder)
    end)
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

    if Remotes:FindFirstChild("ViewAlbum") then
        Remotes.ViewAlbum:Connect(function(targetBaseId, victimName, albumProgress)
            openAlbumViewer(targetBaseId, victimName, albumProgress)
        end)
    end

    local Workspace = game:GetService("Workspace")
    Remotes.BaseAssigned:Connect(function(info)
        local baseId = info.baseId
        task.spawn(function()
            local map = Workspace:WaitForChild("Map")
            local basesFolder = map:WaitForChild("PlayerBases")
            local baseFolder = basesFolder:WaitForChild(baseId)
            local album = baseFolder:WaitForChild("Album")
            local prompt = album:WaitForChild("AlbumPrompt") :: ProximityPrompt?
            if prompt then
                prompt.Triggered:Connect(function(player)
                    if player == Player then
                        openAlbum()
                    end
                end)
            end
        end)
    end)

    -- Initialize physical album boards
    task.spawn(setupPhysicalAlbums)
end

return InventoryController
