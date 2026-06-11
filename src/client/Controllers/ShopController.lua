local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local Remotes      = require(ReplicatedStorage.Remotes)
local Economy      = require(ReplicatedStorage.Config.Economy)
local Monetization = require(ReplicatedStorage.Config.Monetization)

local Player    = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- ── Local state ────────────────────────────────────────────────────────
local currentBaseLevel = 1
local currentCoins     = 0

local ShopController = {}

-- ── Colours ────────────────────────────────────────────────────────────
local C = {
    bg      = Color3.fromRGB(14, 14, 24),
    panel   = Color3.fromRGB(22, 22, 38),
    section = Color3.fromRGB(18, 18, 32),
    accent  = Color3.fromRGB(255, 220, 80),
    green   = Color3.fromRGB(20, 160, 70),
    blue    = Color3.fromRGB(40, 110, 220),
    orange  = Color3.fromRGB(210, 110, 10),
    red     = Color3.fromRGB(160, 20, 20),
    robux   = Color3.fromRGB(0, 162, 255),
    white   = Color3.new(1, 1, 1),
    dim     = Color3.fromRGB(140, 140, 160),
}

-- ── Helper builders ────────────────────────────────────────────────────

local function corner(parent, r)
    Instance.new("UICorner", parent).CornerRadius = UDim.new(0, r or 8)
end

local function label(parent, text, pos, size, color, font, xAlign)
    local l = Instance.new("TextLabel")
    l.Size              = size or UDim2.new(1, 0, 0, 28)
    l.Position          = pos or UDim2.new(0, 0, 0, 0)
    l.BackgroundTransparency = 1
    l.Text              = text
    l.TextColor3        = color or C.white
    l.TextScaled        = true
    l.Font              = font or Enum.Font.Gotham
    l.TextXAlignment    = xAlign or Enum.TextXAlignment.Left
    l.Parent            = parent
    return l
end

local function btn(parent, text, pos, size, bg, onClick)
    local b = Instance.new("TextButton")
    b.Size             = size
    b.Position         = pos
    b.BackgroundColor3 = bg
    b.BorderSizePixel  = 0
    b.Text             = text
    b.TextColor3       = C.white
    b.TextScaled       = true
    b.Font             = Enum.Font.GothamBold
    b.Parent           = parent
    corner(b, 7)
    if onClick then b.MouseButton1Click:Connect(onClick) end
    return b
end

-- ── Shop ScreenGui ─────────────────────────────────────────────────────

local shopGui = Instance.new("ScreenGui")
shopGui.Name           = "ShopScreen"
shopGui.ResetOnSpawn   = false
shopGui.Enabled        = false
shopGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
shopGui.Parent         = PlayerGui

local overlay = Instance.new("Frame")
overlay.Size              = UDim2.fromScale(1, 1)
overlay.BackgroundColor3  = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 0.45
overlay.Parent            = shopGui

local panel = Instance.new("Frame")
panel.Name             = "Panel"
panel.Size             = UDim2.new(0, 560, 0, 600)
panel.Position         = UDim2.new(0.5, -280, 0.5, -300)
panel.BackgroundColor3 = C.bg
panel.BorderSizePixel  = 0
panel.Parent           = shopGui
corner(panel, 14)

-- Title
local titleLbl = label(panel, "🛒  TIENDA",
    UDim2.new(0, 16, 0, 10),
    UDim2.new(1, -60, 0, 44),
    C.accent, Enum.Font.GothamBold, Enum.TextXAlignment.Left)

-- Close button
local closeBtn = btn(panel, "✕",
    UDim2.new(1, -50, 0, 8),
    UDim2.new(0, 38, 0, 38),
    C.red,
    function() shopGui.Enabled = false end)

-- Scroll content
local scroll = Instance.new("ScrollingFrame")
scroll.Size                 = UDim2.new(1, -16, 1, -64)
scroll.Position             = UDim2.new(0, 8, 0, 56)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel      = 0
scroll.ScrollBarThickness   = 5
scroll.CanvasSize           = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize  = Enum.AutomaticSize.Y
scroll.Parent               = panel

local layout = Instance.new("UIListLayout")
layout.Padding   = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent    = scroll

-- ── Section header ─────────────────────────────────────────────────────

local function sectionHeader(title, order)
    local f = Instance.new("Frame")
    f.Size             = UDim2.new(1, 0, 0, 30)
    f.BackgroundColor3 = C.panel
    f.BorderSizePixel  = 0
    f.LayoutOrder      = order
    f.Parent           = scroll
    corner(f, 6)
    label(f, title, UDim2.new(0, 10, 0, 0), UDim2.new(1, -12, 1, 0),
        C.accent, Enum.Font.GothamBold, Enum.TextXAlignment.Left)
    return f
end

-- ── Shop row ────────────────────────────────────────────────────────────

local function shopRow(name, desc, priceText, priceColor, order, onBuy)
    local f = Instance.new("Frame")
    f.Size             = UDim2.new(1, 0, 0, 66)
    f.BackgroundColor3 = C.section
    f.BorderSizePixel  = 0
    f.LayoutOrder      = order
    f.Parent           = scroll
    corner(f, 8)

    label(f, name,
        UDim2.new(0, 10, 0, 6),
        UDim2.new(0.65, 0, 0, 26),
        C.white, Enum.Font.GothamBold, Enum.TextXAlignment.Left)

    label(f, desc,
        UDim2.new(0, 10, 0, 34),
        UDim2.new(0.65, 0, 0, 24),
        C.dim, Enum.Font.Gotham, Enum.TextXAlignment.Left)

    btn(f, priceText,
        UDim2.new(1, -120, 0.5, -18),
        UDim2.new(0, 112, 0, 36),
        priceColor or C.green,
        onBuy)

    return f
end

-- ── Populate shop ──────────────────────────────────────────────────────

local upgradeRowRef: Frame? = nil  -- re-rendered when base level changes

local function buildBaseSection()
    sectionHeader("🏠  MEJORA DE BASE", 10)

    local function makeUpgradeRow()
        if upgradeRowRef then upgradeRowRef:Destroy() end

        local nextLevel = currentBaseLevel + 1
        if nextLevel > 5 then
            -- Max level indicator
            local f = Instance.new("Frame")
            f.Size             = UDim2.new(1, 0, 0, 52)
            f.BackgroundColor3 = C.section
            f.BorderSizePixel  = 0
            f.LayoutOrder      = 11
            f.Parent           = scroll
            corner(f, 8)
            label(f, "🏆 Base al nivel máximo (5)",
                UDim2.new(0, 10, 0, 0),
                UDim2.new(1, -12, 1, 0),
                C.accent, Enum.Font.GothamBold, Enum.TextXAlignment.Left)
            upgradeRowRef = f
            return
        end

        local cost = Economy.BaseUpgradeCosts[nextLevel]
        local priceText, priceColor, onBuy

        if cost.coins > 0 then
            priceText  = "🪙 " .. cost.coins
            priceColor = (currentCoins >= cost.coins) and C.green or C.red
            onBuy      = function()
                Remotes.RequestBaseUpgrade:FireServer()
            end
        else
            priceText  = "R$ " .. cost.robux
            priceColor = C.robux
            local productKey = "BaseUpgrade_" .. nextLevel
            local product = Monetization.DevProducts[productKey]
            onBuy = function()
                if product then
                    MarketplaceService:PromptProductPurchase(Player, product.id)
                end
            end
        end

        local row = shopRow(
            "Nivel " .. nextLevel .. " → " .. nextLevel,
            "Lv " .. currentBaseLevel .. " → Lv " .. nextLevel,
            priceText, priceColor, 11,
            onBuy
        )
        upgradeRowRef = row
    end

    makeUpgradeRow()

    -- Refresh row when level or coins change
    Remotes.BaseUpgraded:Connect(function(info)
        currentBaseLevel = info.baseLevel or currentBaseLevel
        makeUpgradeRow()
    end)
    Remotes.CoinsUpdated:Connect(function(amount)
        currentCoins = amount
        makeUpgradeRow()
    end)
end

local function buildCoinPacksSection()
    sectionHeader("🪙  PACKS DE MONEDAS", 20)

    local packs = {
        { key = "CoinPack_Small",  order = 21 },
        { key = "CoinPack_Medium", order = 22 },
        { key = "CoinPack_Large",  order = 23 },
    }

    for _, info in ipairs(packs) do
        local product = Monetization.DevProducts[info.key]
        if product then
            shopRow(
                product.name,
                product.description,
                "Comprar Robux",
                C.robux,
                info.order,
                function()
                    MarketplaceService:PromptProductPurchase(Player, product.id)
                end
            )
        end
    end
end

local function buildSpecialPacksSection()
    sectionHeader("🎁  PACKS ESPECIALES", 30)

    local packs = {
        { key = "TokenPack",       order = 31 },
        { key = "WelcomePack",     order = 32 },
        { key = "ProtectionShield", order = 33 },
    }

    for _, info in ipairs(packs) do
        local product = Monetization.DevProducts[info.key]
        if product then
            shopRow(
                product.name,
                product.description,
                "Comprar Robux",
                C.orange,
                info.order,
                function()
                    MarketplaceService:PromptProductPurchase(Player, product.id)
                end
            )
        end
    end
end

local function buildGamePassSection()
    sectionHeader("⭐  PASES PREMIUM", 40)

    local passes = {
        { key = "VIP",            order = 41 },
        { key = "PremiumStorage", order = 42 },
        { key = "SpeedBoost",     order = 43 },
    }

    for _, info in ipairs(passes) do
        local pass = Monetization.GamePasses[info.key]
        if pass then
            shopRow(
                pass.name,
                pass.description,
                "Comprar Robux",
                Color3.fromRGB(160, 80, 220),
                info.order,
                function()
                    MarketplaceService:PromptGamePassPurchase(Player, pass.id)
                end
            )
        end
    end
end

-- ── HUD Shop button ─────────────────────────────────────────────────────

local function addShopButton()
    local hud = PlayerGui:WaitForChild("WorldCupHUD", 10)
    if not hud then return end

    local shopBtn = Instance.new("TextButton")
    shopBtn.Name            = "ShopBtn"
    shopBtn.Size            = UDim2.new(0, 130, 0, 48)
    shopBtn.Position        = UDim2.new(1, -424, 1, -64)
    shopBtn.BackgroundColor3 = Color3.fromRGB(160, 90, 10)
    shopBtn.BorderSizePixel = 0
    shopBtn.Text            = "🛒 Tienda"
    shopBtn.TextColor3      = Color3.new(1, 1, 1)
    shopBtn.TextScaled      = true
    shopBtn.Font            = Enum.Font.GothamBold
    shopBtn.Parent          = hud
    corner(shopBtn, 8)

    shopBtn.MouseButton1Click:Connect(function()
        shopGui.Enabled = not shopGui.Enabled
    end)
end

-- ── Init ──────────────────────────────────────────────────────────────

function ShopController.OnStart()
    -- Sync state
    Remotes.PlayerDataLoaded:Connect(function(data)
        currentBaseLevel = data.baseLevel or 1
        currentCoins     = data.coins or 0
    end)

    Remotes.BaseAssigned:Connect(function(info)
        currentBaseLevel = info.baseLevel or 1
    end)

    -- Build shop content once
    buildBaseSection()
    buildCoinPacksSection()
    buildSpecialPacksSection()
    buildGamePassSection()

    -- Add button to existing HUD
    task.spawn(addShopButton)

    -- PurchaseResult feedback
    Remotes.PurchaseResult:Connect(function(result)
        if result.success then
            if result.type == "slot_inventory" then
                -- InventoryController will update via InventoryUpdated; just notify
            elseif result.type == "slot_storage" then
                -- same
            end
        end
    end)
end

return ShopController
