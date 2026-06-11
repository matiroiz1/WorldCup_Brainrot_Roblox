local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")

local Remotes      = require(ReplicatedStorage.Remotes)
local UIController = require(script.Parent.UIController)

local Player    = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- ── Constants ─────────────────────────────────────────────────────────
local TRADE_INIT_RANGE = 12  -- studs to trigger T-key trade request
local RARITY_COLORS = {
    Common    = Color3.fromRGB(180, 180, 180),
    Rare      = Color3.fromRGB(60, 120, 220),
    Epic      = Color3.fromRGB(160, 40, 200),
    Legendary = Color3.fromRGB(220, 160, 20),
}

-- ── State ─────────────────────────────────────────────────────────────
local currentSession: any    = nil  -- active TradeSession payload from server
local myOfferedCards: { any } = {}  -- cards this client is currently offering
local localInventory: any    = nil  -- latest inventory data (cards + securedCards)

local TradeController = {}

-- ── ScreenGui ─────────────────────────────────────────────────────────

local tradeGui = Instance.new("ScreenGui")
tradeGui.Name          = "TradeScreen"
tradeGui.ResetOnSpawn  = false
tradeGui.Enabled       = false
tradeGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
tradeGui.Parent        = PlayerGui

-- Overlay
local overlay = Instance.new("Frame")
overlay.Size              = UDim2.fromScale(1, 1)
overlay.BackgroundColor3  = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 0.45
overlay.Parent            = tradeGui

-- Main panel
local panel = Instance.new("Frame")
panel.Name             = "Panel"
panel.Size             = UDim2.new(0, 620, 0, 560)
panel.Position         = UDim2.new(0.5, -310, 0.5, -280)
panel.BackgroundColor3 = Color3.fromRGB(14, 14, 24)
panel.BorderSizePixel  = 0
panel.Parent           = tradeGui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)

-- Title
local title = Instance.new("TextLabel")
title.Size              = UDim2.new(1, -50, 0, 50)
title.BackgroundTransparency = 1
title.Text              = "🔄 INTERCAMBIO"
title.TextColor3        = Color3.fromRGB(255, 220, 100)
title.TextScaled        = true
title.Font              = Enum.Font.GothamBold
title.Parent            = panel

-- Cancel button (top-right)
local cancelBtn = Instance.new("TextButton")
cancelBtn.Name             = "CancelBtn"
cancelBtn.Size             = UDim2.new(0, 40, 0, 40)
cancelBtn.Position         = UDim2.new(1, -46, 0, 5)
cancelBtn.BackgroundColor3 = Color3.fromRGB(160, 20, 20)
cancelBtn.BorderSizePixel  = 0
cancelBtn.Text             = "✕"
cancelBtn.TextColor3       = Color3.new(1, 1, 1)
cancelBtn.TextScaled       = true
cancelBtn.Font             = Enum.Font.GothamBold
cancelBtn.Parent           = panel
Instance.new("UICorner", cancelBtn).CornerRadius = UDim.new(0, 8)

-- ── Two-panel layout ──────────────────────────────────────────────────

local function makeSidePanel(parent, name, xPos)
    local side = Instance.new("Frame")
    side.Name             = name
    side.Size             = UDim2.new(0, 268, 0, 390)
    side.Position         = UDim2.new(0, xPos, 0, 60)
    side.BackgroundColor3 = Color3.fromRGB(22, 22, 38)
    side.BorderSizePixel  = 0
    side.Parent           = parent
    Instance.new("UICorner", side).CornerRadius = UDim.new(0, 10)

    local header = Instance.new("TextLabel")
    header.Size              = UDim2.new(1, 0, 0, 36)
    header.BackgroundTransparency = 1
    header.TextScaled        = true
    header.Font              = Enum.Font.GothamBold
    header.TextColor3        = Color3.new(1, 1, 1)
    header.Parent            = side

    local scroll = Instance.new("ScrollingFrame")
    scroll.Name                  = "CardList"
    scroll.Size                  = UDim2.new(1, -10, 1, -42)
    scroll.Position              = UDim2.new(0, 5, 0, 38)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel       = 0
    scroll.ScrollBarThickness    = 5
    scroll.CanvasSize            = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize   = Enum.AutomaticSize.Y
    scroll.Parent                = side

    local layout = Instance.new("UIListLayout")
    layout.Padding   = UDim.new(0, 5)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent    = scroll

    return side, header, scroll
end

local mySide,    myHeader,   myScroll  = makeSidePanel(panel, "MySide",    16)
local theirSide, theirHeader, theirScroll = makeSidePanel(panel, "TheirSide", 332)

-- ── Divider ───────────────────────────────────────────────────────────
local divider = Instance.new("Frame")
divider.Size             = UDim2.new(0, 2, 0, 390)
divider.Position         = UDim2.new(0, 306, 0, 60)
divider.BackgroundColor3 = Color3.fromRGB(60, 60, 100)
divider.BorderSizePixel  = 0
divider.Parent           = panel

-- ── Bottom buttons ────────────────────────────────────────────────────

local addCardBtn = Instance.new("TextButton")
addCardBtn.Name            = "AddCardBtn"
addCardBtn.Size            = UDim2.new(0, 200, 0, 44)
addCardBtn.Position        = UDim2.new(0, 16, 1, -56)
addCardBtn.BackgroundColor3 = Color3.fromRGB(40, 100, 200)
addCardBtn.BorderSizePixel = 0
addCardBtn.Text            = "+ Agregar carta"
addCardBtn.TextColor3      = Color3.new(1, 1, 1)
addCardBtn.TextScaled      = true
addCardBtn.Font            = Enum.Font.GothamBold
addCardBtn.Parent          = panel
Instance.new("UICorner", addCardBtn).CornerRadius = UDim.new(0, 8)

local confirmBtn = Instance.new("TextButton")
confirmBtn.Name            = "ConfirmBtn"
confirmBtn.Size            = UDim2.new(0, 186, 0, 44)
confirmBtn.Position        = UDim2.new(1, -204, 1, -56)
confirmBtn.BackgroundColor3 = Color3.fromRGB(20, 140, 60)
confirmBtn.BorderSizePixel = 0
confirmBtn.Text            = "✅ Confirmar"
confirmBtn.TextColor3      = Color3.new(1, 1, 1)
confirmBtn.TextScaled      = true
confirmBtn.Font            = Enum.Font.GothamBold
confirmBtn.Parent          = panel
Instance.new("UICorner", confirmBtn).CornerRadius = UDim.new(0, 8)

-- Status label
local statusLbl = Instance.new("TextLabel")
statusLbl.Size              = UDim2.new(1, 0, 0, 24)
statusLbl.Position          = UDim2.new(0, 0, 1, -64)
statusLbl.BackgroundTransparency = 1
statusLbl.Text              = ""
statusLbl.TextColor3        = Color3.fromRGB(180, 180, 200)
statusLbl.TextScaled        = true
statusLbl.Font              = Enum.Font.Gotham
statusLbl.Parent            = panel

-- ── Card Picker sub-screen ────────────────────────────────────────────

local pickerGui = Instance.new("ScreenGui")
pickerGui.Name          = "CardPickerScreen"
pickerGui.ResetOnSpawn  = false
pickerGui.Enabled       = false
pickerGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pickerGui.Parent        = PlayerGui

local pickerOverlay = Instance.new("TextButton")
pickerOverlay.Size              = UDim2.fromScale(1, 1)
pickerOverlay.BackgroundTransparency = 0.5
pickerOverlay.BackgroundColor3  = Color3.fromRGB(0, 0, 0)
pickerOverlay.Text              = ""
pickerOverlay.Parent            = pickerGui

local pickerPanel = Instance.new("Frame")
pickerPanel.Size             = UDim2.new(0, 400, 0, 500)
pickerPanel.Position         = UDim2.new(0.5, -200, 0.5, -250)
pickerPanel.BackgroundColor3 = Color3.fromRGB(18, 18, 32)
pickerPanel.BorderSizePixel  = 0
pickerPanel.Parent           = pickerGui
Instance.new("UICorner", pickerPanel).CornerRadius = UDim.new(0, 12)

local pickerTitle = Instance.new("TextLabel")
pickerTitle.Size              = UDim2.new(1, -50, 0, 46)
pickerTitle.BackgroundTransparency = 1
pickerTitle.Text              = "Elegí una carta para ofrecer"
pickerTitle.TextColor3        = Color3.new(1, 1, 1)
pickerTitle.TextScaled        = true
pickerTitle.Font              = Enum.Font.GothamBold
pickerTitle.Parent            = pickerPanel

local pickerClose = Instance.new("TextButton")
pickerClose.Size             = UDim2.new(0, 38, 0, 38)
pickerClose.Position         = UDim2.new(1, -44, 0, 4)
pickerClose.BackgroundColor3 = Color3.fromRGB(140, 20, 20)
pickerClose.BorderSizePixel  = 0
pickerClose.Text             = "✕"
pickerClose.TextColor3       = Color3.new(1, 1, 1)
pickerClose.TextScaled       = true
pickerClose.Font             = Enum.Font.GothamBold
pickerClose.Parent           = pickerPanel
Instance.new("UICorner", pickerClose).CornerRadius = UDim.new(0, 6)

local pickerScroll = Instance.new("ScrollingFrame")
pickerScroll.Size                 = UDim2.new(1, -16, 1, -52)
pickerScroll.Position             = UDim2.new(0, 8, 0, 48)
pickerScroll.BackgroundTransparency = 1
pickerScroll.BorderSizePixel      = 0
pickerScroll.ScrollBarThickness   = 5
pickerScroll.CanvasSize           = UDim2.new(0, 0, 0, 0)
pickerScroll.AutomaticCanvasSize  = Enum.AutomaticSize.Y
pickerScroll.Parent               = pickerPanel

local pickerLayout = Instance.new("UIListLayout")
pickerLayout.Padding   = UDim.new(0, 5)
pickerLayout.SortOrder = Enum.SortOrder.LayoutOrder
pickerLayout.Parent    = pickerScroll

-- ── Helpers ───────────────────────────────────────────────────────────

local function isAlreadyOffered(card: any): boolean
    for _, c in ipairs(myOfferedCards) do
        if c.cardId == card.cardId and c.obtainedAt == card.obtainedAt then
            return true
        end
    end
    return false
end

local function makeCardRow(parent, card: any, order: number, onClickFn)
    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1, -4, 0, 50)
    row.BackgroundColor3 = Color3.fromRGB(26, 26, 42)
    row.BorderSizePixel  = 0
    row.LayoutOrder      = order
    row.Parent           = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 7)

    local strip = Instance.new("Frame")
    strip.Size            = UDim2.new(0, 5, 1, 0)
    strip.BackgroundColor3 = RARITY_COLORS[card.rarity] or RARITY_COLORS.Common
    strip.BorderSizePixel = 0
    strip.Parent          = row
    Instance.new("UICorner", strip).CornerRadius = UDim.new(0, 4)

    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size              = UDim2.new(0.65, 0, 0.55, 0)
    nameLbl.Position          = UDim2.new(0, 12, 0, 3)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text              = card.cardId or "?"
    nameLbl.TextColor3        = Color3.new(1, 1, 1)
    nameLbl.TextXAlignment    = Enum.TextXAlignment.Left
    nameLbl.TextScaled        = true
    nameLbl.Font              = Enum.Font.GothamBold
    nameLbl.Parent            = row

    local rarityLbl = Instance.new("TextLabel")
    rarityLbl.Size              = UDim2.new(0.65, 0, 0.35, 0)
    rarityLbl.Position          = UDim2.new(0, 12, 0.6, 0)
    rarityLbl.BackgroundTransparency = 1
    rarityLbl.Text              = card.secured and "🔒 Asegurada" or "📦 Sin asegurar"
    rarityLbl.TextColor3        = Color3.fromRGB(160, 160, 180)
    rarityLbl.TextXAlignment    = Enum.TextXAlignment.Left
    rarityLbl.TextScaled        = true
    rarityLbl.Font              = Enum.Font.Gotham
    rarityLbl.Parent            = row

    if onClickFn then
        local btn = Instance.new("TextButton")
        btn.Size            = UDim2.new(0, 76, 0, 34)
        btn.Position        = UDim2.new(1, -82, 0.5, -17)
        btn.BackgroundColor3 = Color3.fromRGB(40, 100, 200)
        btn.BorderSizePixel = 0
        btn.Text            = "Ofrecer"
        btn.TextColor3      = Color3.new(1, 1, 1)
        btn.TextScaled      = true
        btn.Font            = Enum.Font.GothamBold
        btn.Parent          = row
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        btn.MouseButton1Click:Connect(function()
            onClickFn(card)
        end)
    end

    return row
end

-- ── Render my offer panel ─────────────────────────────────────────────

local function renderMyOffer()
    for _, c in ipairs(myScroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end

    if #myOfferedCards == 0 then
        local empty = Instance.new("TextLabel")
        empty.Size              = UDim2.new(1, 0, 0, 50)
        empty.BackgroundTransparency = 1
        empty.Text              = "Sin cartas ofrecidas"
        empty.TextColor3        = Color3.fromRGB(120, 120, 140)
        empty.TextScaled        = true
        empty.Font              = Enum.Font.Gotham
        empty.Parent            = myScroll
        return
    end

    for i, card in ipairs(myOfferedCards) do
        local row = makeCardRow(myScroll, card, i, nil)
        -- Remove button
        local removeBtn = Instance.new("TextButton")
        removeBtn.Size            = UDim2.new(0, 68, 0, 30)
        removeBtn.Position        = UDim2.new(1, -74, 0.5, -15)
        removeBtn.BackgroundColor3 = Color3.fromRGB(140, 20, 20)
        removeBtn.BorderSizePixel = 0
        removeBtn.Text            = "Quitar"
        removeBtn.TextColor3      = Color3.new(1, 1, 1)
        removeBtn.TextScaled      = true
        removeBtn.Font            = Enum.Font.GothamBold
        removeBtn.Parent          = row
        Instance.new("UICorner", removeBtn).CornerRadius = UDim.new(0, 5)

        local capturedI = i
        removeBtn.MouseButton1Click:Connect(function()
            table.remove(myOfferedCards, capturedI)
            renderMyOffer()
            if currentSession then
                Remotes.TradeOfferUpdate:FireServer(currentSession.sessionId, myOfferedCards)
            end
        end)
    end
end

-- ── Render their offer panel ──────────────────────────────────────────

local function renderTheirOffer(offeredCards: { any })
    for _, c in ipairs(theirScroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end

    if #offeredCards == 0 then
        local empty = Instance.new("TextLabel")
        empty.Size              = UDim2.new(1, 0, 0, 50)
        empty.BackgroundTransparency = 1
        empty.Text              = "Sin cartas ofrecidas"
        empty.TextColor3        = Color3.fromRGB(120, 120, 140)
        empty.TextScaled        = true
        empty.Font              = Enum.Font.Gotham
        empty.Parent            = theirScroll
        return
    end

    for i, card in ipairs(offeredCards) do
        makeCardRow(theirScroll, card, i, nil)
    end
end

-- ── Render full session ────────────────────────────────────────────────

local function renderSession(session: any)
    local isA  = session.playerA.userId == Player.UserId
    local me   = isA and session.playerA or session.playerB
    local them = isA and session.playerB or session.playerA

    myHeader.Text    = "Vos (" .. me.name .. ")"
    theirHeader.Text = them.name

    -- My offer is the server's version
    myOfferedCards = me.offeredCards or {}
    renderMyOffer()
    renderTheirOffer(them.offeredCards or {})

    -- Status
    local myConfirmed    = me.confirmed
    local theirConfirmed = them.confirmed

    if myConfirmed and theirConfirmed then
        statusLbl.Text = "✅ Ambos confirmaron — ejecutando..."
    elseif myConfirmed then
        statusLbl.Text = "⏳ Esperando confirmación de " .. them.name .. "..."
    elseif theirConfirmed then
        statusLbl.Text = "⚡ " .. them.name .. " confirmó. ¡Confirmá vos!"
    else
        statusLbl.Text = "📋 Agregá cartas y confirmá cuando estés listo."
    end

    confirmBtn.BackgroundColor3 = myConfirmed
        and Color3.fromRGB(20, 80, 20)
        or  Color3.fromRGB(20, 140, 60)
    confirmBtn.Text = myConfirmed and "✅ Confirmado" or "✅ Confirmar"
end

-- ── Card picker ────────────────────────────────────────────────────────

local function openCardPicker()
    for _, c in ipairs(pickerScroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end

    local allCards = {}
    if localInventory then
        for _, c in ipairs(localInventory.cards or {}) do
            table.insert(allCards, c)
        end
        for _, c in ipairs(localInventory.securedCards or {}) do
            table.insert(allCards, c)
        end
    end

    local shown = 0
    for i, card in ipairs(allCards) do
        if not isAlreadyOffered(card) then
            shown += 1
            makeCardRow(pickerScroll, card, i, function(selectedCard)
                if #myOfferedCards >= 5 then
                    UIController.showNotification("warning", "Máximo 5 cartas por oferta.")
                    return
                end
                table.insert(myOfferedCards, {
                    cardId     = selectedCard.cardId,
                    variant    = selectedCard.variant,
                    obtainedAt = selectedCard.obtainedAt,
                    rarity     = selectedCard.rarity,
                    secured    = selectedCard.secured,
                })
                pickerGui.Enabled = false
                renderMyOffer()
                if currentSession then
                    Remotes.TradeOfferUpdate:FireServer(currentSession.sessionId, myOfferedCards)
                end
            end)
        end
    end

    if shown == 0 then
        local empty = Instance.new("TextLabel")
        empty.Size              = UDim2.new(1, 0, 0, 60)
        empty.BackgroundTransparency = 1
        empty.Text              = "No tenés cartas disponibles."
        empty.TextColor3        = Color3.fromRGB(140, 140, 160)
        empty.TextScaled        = true
        empty.Font              = Enum.Font.Gotham
        empty.Parent            = pickerScroll
    end

    pickerGui.Enabled = true
end

-- ── Open / Close trade screen ─────────────────────────────────────────

local function openTrade(session: any)
    currentSession = session
    myOfferedCards = {}
    tradeGui.Enabled = true
    renderSession(session)
end

local function closeTrade()
    tradeGui.Enabled  = false
    pickerGui.Enabled = false
    currentSession    = nil
    myOfferedCards    = {}
end

-- ── Incoming trade request UI ─────────────────────────────────────────

local function showTradeRequest(fromName: string, sessionId: string)
    -- Simple notification with Accept/Decline buttons
    local reqGui = Instance.new("ScreenGui")
    reqGui.Name          = "TradeRequestPopup"
    reqGui.ResetOnSpawn  = false
    reqGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    reqGui.Parent        = PlayerGui

    local reqPanel = Instance.new("Frame")
    reqPanel.Size             = UDim2.new(0, 360, 0, 120)
    reqPanel.Position         = UDim2.new(0.5, -180, 0, 80)
    reqPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 36)
    reqPanel.BorderSizePixel  = 0
    reqPanel.Parent           = reqGui
    Instance.new("UICorner", reqPanel).CornerRadius = UDim.new(0, 12)

    local reqLabel = Instance.new("TextLabel")
    reqLabel.Size              = UDim2.new(1, 0, 0, 52)
    reqLabel.Position          = UDim2.new(0, 0, 0, 4)
    reqLabel.BackgroundTransparency = 1
    reqLabel.Text              = "🔄 " .. fromName .. " quiere intercambiar"
    reqLabel.TextColor3        = Color3.new(1, 1, 1)
    reqLabel.TextScaled        = true
    reqLabel.Font              = Enum.Font.GothamBold
    reqLabel.Parent            = reqPanel

    local acceptBtn = Instance.new("TextButton")
    acceptBtn.Size             = UDim2.new(0, 140, 0, 44)
    acceptBtn.Position         = UDim2.new(0, 14, 1, -52)
    acceptBtn.BackgroundColor3 = Color3.fromRGB(20, 140, 60)
    acceptBtn.BorderSizePixel  = 0
    acceptBtn.Text             = "✅ Aceptar"
    acceptBtn.TextColor3       = Color3.new(1, 1, 1)
    acceptBtn.TextScaled       = true
    acceptBtn.Font             = Enum.Font.GothamBold
    acceptBtn.Parent           = reqPanel
    Instance.new("UICorner", acceptBtn).CornerRadius = UDim.new(0, 8)

    local declineBtn = Instance.new("TextButton")
    declineBtn.Size            = UDim2.new(0, 140, 0, 44)
    declineBtn.Position        = UDim2.new(1, -154, 1, -52)
    declineBtn.BackgroundColor3 = Color3.fromRGB(160, 20, 20)
    declineBtn.BorderSizePixel = 0
    declineBtn.Text            = "❌ Rechazar"
    declineBtn.TextColor3      = Color3.new(1, 1, 1)
    declineBtn.TextScaled      = true
    declineBtn.Font            = Enum.Font.GothamBold
    declineBtn.Parent          = reqPanel
    Instance.new("UICorner", declineBtn).CornerRadius = UDim.new(0, 8)

    local function dismiss()
        if reqGui and reqGui.Parent then reqGui:Destroy() end
    end

    acceptBtn.MouseButton1Click:Connect(function()
        Remotes.TradeRespondRequest:FireServer(sessionId, true)
        dismiss()
    end)

    declineBtn.MouseButton1Click:Connect(function()
        Remotes.TradeRespondRequest:FireServer(sessionId, false)
        dismiss()
    end)

    -- Auto-dismiss after 30s
    task.delay(30, function()
        if reqGui and reqGui.Parent then
            reqGui:Destroy()
        end
    end)
end

-- ── T-key: initiate trade with nearest player ─────────────────────────

local lastTradeRequest = 0

local function findNearestPlayer(): (Player?, number)
    local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil, math.huge end
    local myPos  = hrp.Position
    local best: Player? = nil
    local bestDist = TRADE_INIT_RANGE + 1

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player then
            local char = p.Character
            if char then
                local otherHRP = char:FindFirstChild("HumanoidRootPart")
                if otherHRP then
                    local dist = (otherHRP.Position - myPos).Magnitude
                    if dist < bestDist then
                        bestDist = dist
                        best     = p
                    end
                end
            end
        end
    end
    return best, bestDist
end

-- ── Init ──────────────────────────────────────────────────────────────

function TradeController.OnStart()

    -- T key → request trade with nearest player
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode ~= Enum.KeyCode.T then return end
        if currentSession then return end
        if os.clock() - lastTradeRequest < 3 then return end

        local target, dist = findNearestPlayer()
        if not target then
            UIController.showNotification("warning", "No hay ningún jugador cerca para tradear. (T)")
            return
        end

        lastTradeRequest = os.clock()
        Remotes.RequestTradeInit:FireServer(target.UserId)
    end)

    -- Incoming trade request
    Remotes.TradeRequested:Connect(function(info)
        showTradeRequest(info.fromName, info.sessionId)
    end)

    -- Session update (both players see this)
    Remotes.TradeSessionUpdate:Connect(function(session)
        currentSession = session
        if session.status == "active" then
            if not tradeGui.Enabled then
                openTrade(session)
            else
                renderSession(session)
            end
        elseif session.status == "cancelled" then
            closeTrade()
        end
    end)

    -- Trade completed
    Remotes.TradeCompleted:Connect(function(result)
        closeTrade()
        if result.success then
            local received = result.receivedCards or {}
            local msg = "🔄 ¡Trade completado! Recibiste " .. #received .. " carta(s)."
            UIController.showNotification("success", msg)
        else
            UIController.showNotification("error", "❌ Trade fallido.")
        end
    end)

    -- Button wiring
    cancelBtn.MouseButton1Click:Connect(function()
        if currentSession then
            Remotes.TradeCancel:FireServer(currentSession.sessionId)
        end
        closeTrade()
    end)

    confirmBtn.MouseButton1Click:Connect(function()
        if currentSession then
            Remotes.TradeConfirm:FireServer(currentSession.sessionId)
        end
    end)

    addCardBtn.MouseButton1Click:Connect(openCardPicker)

    pickerClose.MouseButton1Click:Connect(function()
        pickerGui.Enabled = false
    end)

    pickerOverlay.MouseButton1Click:Connect(function()
        pickerGui.Enabled = false
    end)

    -- Keep local inventory in sync
    Remotes.PlayerDataLoaded:Connect(function(data)
        localInventory = data
    end)

    Remotes.InventoryUpdated:Connect(function(data)
        localInventory = data
    end)
end

return TradeController
