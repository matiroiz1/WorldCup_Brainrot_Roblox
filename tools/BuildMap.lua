-- WORLD CUP BRAINROT — Classic Blocky Simulator Map Builder
-- Paste this into the Roblox Studio Command Bar (Edit mode) to generate the map.

local ws = workspace

-- ── 1. WORKSPACE FOLDER HIERARCHY ──────────────────────────────────────────

local mapFolder = ws:FindFirstChild("Map") or Instance.new("Folder", ws)
mapFolder.Name = "Map"

local zonesFolder = ws:FindFirstChild("Zones") or Instance.new("Folder", ws)
zonesFolder.Name = "Zones"

local playerBasesFolder = mapFolder:FindFirstChild("PlayerBases") or Instance.new("Folder", mapFolder)
playerBasesFolder.Name = "PlayerBases"

local brainrotSpawnsFolder = mapFolder:FindFirstChild("BrainrotSpawns") or Instance.new("Folder", mapFolder)
brainrotSpawnsFolder.Name = "BrainrotSpawns"

local decorationFolder = mapFolder:FindFirstChild("Decoration") or Instance.new("Folder", mapFolder)
decorationFolder.Name = "Decoration"

-- Clear existing objects to prevent duplicates
playerBasesFolder:ClearAllChildren()
brainrotSpawnsFolder:ClearAllChildren()
zonesFolder:ClearAllChildren()
decorationFolder:ClearAllChildren()

-- Remove loose parts in Map folder except the subfolders we want to keep
for _, child in ipairs(mapFolder:GetChildren()) do
	if child ~= playerBasesFolder and child ~= brainrotSpawnsFolder and child ~= decorationFolder then
		child:Destroy()
	end
end

-- ── 2. LIGHTING & COLOR CORRECTION ───────────────────────────────────────────

local Lighting = game:GetService("Lighting")
Lighting.ClockTime = 14
Lighting.Brightness = 3
Lighting.GlobalShadows = false
Lighting.Ambient = Color3.fromRGB(150, 150, 150)

local colorCorrection = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
if not colorCorrection then
	colorCorrection = Instance.new("ColorCorrectionEffect", Lighting)
end
colorCorrection.Saturation = 0.5
colorCorrection.Contrast = 0.15

-- ── 3. MAP FLOOR & HILLS ───────────────────────────────────────────────────

local baseplate = ws:FindFirstChild("Baseplate")
if baseplate and baseplate:IsA("BasePart") then
	baseplate.Position = Vector3.new(baseplate.Position.X, -8.5, baseplate.Position.Z)
end

local ground = Instance.new("Part")
ground.Name = "Ground"
ground.Size = Vector3.new(650, 2, 650)
ground.Position = Vector3.new(0, -1, 0)
ground.Material = Enum.Material.Plastic
ground.Color = Color3.fromRGB(85, 255, 0)
ground.TopSurface = Enum.SurfaceType.Studs
ground.BottomSurface = Enum.SurfaceType.Smooth
ground.Anchored = true
ground.Parent = mapFolder

-- Generate Blocky Hills
local numHills = 36
local hillRadius = 290
for i = 1, numHills do
	local angle = i * (2 * math.pi / numHills)
	local hx = hillRadius * math.cos(angle)
	local hz = hillRadius * math.sin(angle)
	
	local height = 20 + math.random() * 30
	local width = 45 + math.random() * 10
	local depth = 40 + math.random() * 10
	
	-- Base (Brown)
	local hillBase = Instance.new("Part")
	hillBase.Name = "HillBase"
	hillBase.Size = Vector3.new(width, height, depth)
	hillBase.Position = Vector3.new(hx, height/2 - 1, hz)
	hillBase.CFrame = CFrame.new(hillBase.Position) * CFrame.Angles(0, -angle + math.pi/2, 0)
	hillBase.Color = Color3.fromRGB(100, 60, 30)
	hillBase.Material = Enum.Material.Plastic
	hillBase.TopSurface = Enum.SurfaceType.Smooth
	hillBase.Anchored = true
	hillBase.Parent = decorationFolder
	
	-- Top (Green)
	local hillTop = Instance.new("Part")
	hillTop.Name = "HillTop"
	hillTop.Size = Vector3.new(width + 2, 4, depth + 2)
	hillTop.Position = hillBase.Position + Vector3.new(0, height/2 + 2, 0)
	hillTop.CFrame = CFrame.new(hillTop.Position) * CFrame.Angles(0, -angle + math.pi/2, 0)
	hillTop.Color = Color3.fromRGB(70, 200, 40)
	hillTop.Material = Enum.Material.Plastic
	hillTop.TopSurface = Enum.SurfaceType.Studs
	hillTop.Anchored = true
	hillTop.Parent = decorationFolder
end

-- ── 4. SAFEZONE & SHOPS (Half Size) ────────────────────────────────────────

local safeZoneSize = 50 -- Reduced to half
local safeZone = Instance.new("Part")
safeZone.Name = "SafeZone"
safeZone.Size = Vector3.new(safeZoneSize, 0.5, safeZoneSize)
safeZone.Position = Vector3.new(0, 0.25, 0)
safeZone.Color = Color3.fromRGB(100, 240, 100)
safeZone.Material = Enum.Material.Plastic
safeZone.TopSurface = Enum.SurfaceType.Studs
safeZone.Anchored = true
safeZone.CanCollide = false
safeZone.Parent = zonesFolder

local function buildShopBoard(name, position, rotation, guiTitle, bgColor)
	local shopFolder = Instance.new("Folder")
	shopFolder.Name = name
	shopFolder.Parent = zonesFolder
	
	local C = position

	local counter = Instance.new("Part")
	counter.Name = "Counter"
	counter.Size = Vector3.new(10, 3, 3)
	counter.Position = C + Vector3.new(0, 1.5, 0)
	counter.CFrame = CFrame.new(counter.Position) * CFrame.Angles(0, rotation, 0)
	counter.Color = Color3.fromRGB(130, 70, 30)
	counter.Material = Enum.Material.Wood
	counter.TopSurface = Enum.SurfaceType.Studs
	counter.Anchored = true
	counter.Parent = shopFolder
	
	for _, dx in ipairs({-4, 4}) do
		local post = Instance.new("Part")
		post.Name = "Post"
		post.Size = Vector3.new(1, 12, 1)
		local offset = CFrame.Angles(0, rotation, 0) * Vector3.new(dx, 6, -2)
		post.Position = C + offset
		post.CFrame = CFrame.new(post.Position) * CFrame.Angles(0, rotation, 0)
		post.Color = Color3.fromRGB(100, 50, 20)
		post.Material = Enum.Material.Wood
		post.Anchored = true
		post.Parent = shopFolder
	end

	local board = Instance.new("Part")
	board.Name = "Board"
	board.Size = Vector3.new(12, 8, 1)
	local boardOffset = CFrame.Angles(0, rotation, 0) * Vector3.new(0, 8, -1.5)
	board.Position = C + boardOffset
	board.CFrame = CFrame.new(board.Position) * CFrame.Angles(0, rotation, 0)
	board.Color = Color3.fromRGB(255, 200, 100)
	board.Material = Enum.Material.Wood
	board.Anchored = true
	board.Parent = shopFolder

	local sGui = Instance.new("SurfaceGui")
	sGui.Face = Enum.NormalId.Front
	sGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sGui.PixelsPerStud = 50
	sGui.Parent = board

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = bgColor
	frame.BorderSizePixel = 4
	frame.BorderColor3 = Color3.new(0,0,0)
	frame.Parent = sGui

	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0.05, 0)
	uiCorner.Parent = frame

	local title = Instance.new("TextLabel")
	title.Size = UDim2.fromScale(1, 0.4)
	title.Position = UDim2.fromScale(0, 0.1)
	title.BackgroundTransparency = 1
	title.Text = guiTitle
	title.TextScaled = true
	title.Font = Enum.Font.FredokaOne
	title.TextColor3 = Color3.new(1,1,1)
	title.TextStrokeTransparency = 0
	title.Parent = frame

	local subTitle = Instance.new("TextLabel")
	subTitle.Size = UDim2.fromScale(0.8, 0.3)
	subTitle.Position = UDim2.fromScale(0.1, 0.6)
	subTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	subTitle.Text = "Interactuar"
	subTitle.TextScaled = true
	subTitle.Font = Enum.Font.GothamBlack
	subTitle.TextColor3 = Color3.new(0,0,0)
	subTitle.Parent = frame
	local subCorner = Instance.new("UICorner")
	subCorner.CornerRadius = UDim.new(0.2, 0)
	subCorner.Parent = subTitle

	local dealerOffset = CFrame.Angles(0, rotation, 0) * Vector3.new(0, 2.5, -1)
	local dealer = Instance.new("Part")
	dealer.Name = "Dealer"
	dealer.Size = Vector3.new(2, 4, 2)
	dealer.Position = C + dealerOffset
	dealer.CFrame = CFrame.new(dealer.Position) * CFrame.Angles(0, rotation, 0)
	dealer.Color = Color3.fromRGB(255, 255, 0)
	dealer.Material = Enum.Material.Plastic
	dealer.Anchored = true
	dealer.Parent = shopFolder

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ShopPrompt"
	prompt.ActionText = "Abrir"
	prompt.ObjectText = name
	prompt.Parent = dealer
end

-- Adjusted shop positions for the smaller 50x50 SafeZone
buildShopBoard("TiendaSemillas", Vector3.new(-12, 0, 0), math.rad(45), "ROLLOS\n$2,000", Color3.fromRGB(255, 0, 100))
buildShopBoard("ExpandirGranja", Vector3.new(12, 0, 0), math.rad(-45), "EXPANDIR\n$8,000", Color3.fromRGB(150, 0, 255))
buildShopBoard("Recompensas", Vector3.new(0, 0, -15), math.rad(0), "RECOMPENSAS", Color3.fromRGB(255, 150, 0))

-- ── 5. WOODEN FENCES (SafeZone Perimeter with gaps) ─────────────────────────

local function isNearPath(pos)
	-- Check if a given position is too close to any of the 10 radial paths
	for i = 1, 10 do
		local angle = (i - 1) * (2 * math.pi / 10)
		local basePos = Vector3.new(130 * math.cos(angle), 0, 130 * math.sin(angle))
		
		-- Simple radial check
		local posAngle = math.atan2(pos.Z, pos.X)
		if posAngle < 0 then posAngle = posAngle + 2 * math.pi end
		
		local pAngle = math.atan2(basePos.Z, basePos.X)
		if pAngle < 0 then pAngle = pAngle + 2 * math.pi end
		
		local diff = math.abs(posAngle - pAngle)
		if diff > math.pi then diff = 2 * math.pi - diff end
		
		-- If within ~12 degrees of a path, don't build a fence here
		if diff < math.rad(12) then
			return true
		end
	end
	return false
end

local edgeRadius = safeZoneSize / 2
for edge = 1, 4 do
	-- Step by 5 studs along the edge
	for t = -edgeRadius, edgeRadius, 5 do
		local pos
		local isX = false
		if edge == 1 then pos = Vector3.new(t, 0, edgeRadius); isX = true -- Top
		elseif edge == 2 then pos = Vector3.new(t, 0, -edgeRadius); isX = true -- Bottom
		elseif edge == 3 then pos = Vector3.new(edgeRadius, 0, t) -- Right
		elseif edge == 4 then pos = Vector3.new(-edgeRadius, 0, t) -- Left
		end
		
		if not isNearPath(pos) then
			-- Post
			local post = Instance.new("Part")
			post.Size = Vector3.new(1.5, 3, 1.5)
			post.Position = pos + Vector3.new(0, 1.5, 0)
			post.Color = Color3.fromRGB(120, 70, 40)
			post.Material = Enum.Material.Wood
			post.TopSurface = Enum.SurfaceType.Studs
			post.Anchored = true
			post.Parent = decorationFolder
			
			-- Rail
			if t < edgeRadius then
				local rail = Instance.new("Part")
				rail.Size = isX and Vector3.new(5, 0.5, 0.5) or Vector3.new(0.5, 0.5, 5)
				local railOffset = isX and Vector3.new(2.5, 0, 0) or Vector3.new(0, 0, 2.5)
				rail.Position = pos + railOffset + Vector3.new(0, 2, 0)
				
				-- Ensure rail doesn't cross into a path zone
				if not isNearPath(pos + railOffset) then
					rail.Color = Color3.fromRGB(120, 70, 40)
					rail.Material = Enum.Material.Wood
					rail.Anchored = true
					rail.Parent = decorationFolder
				end
			end
		end
	end
end


-- ── 6. TREES & LAMPS SYSTEM ────────────────────────────────────────────────

local function createBlockyTree(pos)
	local treeModel = Instance.new("Model")
	treeModel.Name = "Tree"
	treeModel.Parent = decorationFolder

	local trunkHeight = 6 + math.random(0, 4)
	local trunk = Instance.new("Part")
	trunk.Name = "Trunk"
	trunk.Size = Vector3.new(3, trunkHeight, 3)
	trunk.Position = Vector3.new(pos.X, trunkHeight/2, pos.Z)
	trunk.Color = Color3.fromRGB(120, 80, 50)
	trunk.Material = Enum.Material.Wood
	trunk.TopSurface = Enum.SurfaceType.Studs
	trunk.Anchored = true
	trunk.Parent = treeModel

	local leafSize = 8 + math.random(0, 2)
	local leaves = Instance.new("Part")
	leaves.Name = "Leaves"
	leaves.Size = Vector3.new(leafSize, leafSize-2, leafSize)
	leaves.Position = Vector3.new(pos.X, trunkHeight + (leafSize-2)/2 - 1, pos.Z)
	leaves.Color = Color3.fromRGB(50, 200, 50)
	leaves.Material = Enum.Material.Plastic
	leaves.TopSurface = Enum.SurfaceType.Studs
	leaves.BottomSurface = Enum.SurfaceType.Studs
	leaves.Anchored = true
	leaves.Parent = treeModel
	
	local leafTopSize = leafSize - 3
	local leavesTop = Instance.new("Part")
	leavesTop.Name = "LeavesTop"
	leavesTop.Size = Vector3.new(leafTopSize, 3, leafTopSize)
	leavesTop.Position = leaves.Position + Vector3.new(0, (leafSize-2)/2 + 1.5, 0)
	leavesTop.Color = Color3.fromRGB(50, 200, 50)
	leavesTop.Material = Enum.Material.Plastic
	leavesTop.TopSurface = Enum.SurfaceType.Studs
	leavesTop.Anchored = true
	leavesTop.Parent = treeModel
end

local function createBlockyLamp(pos)
	local model = Instance.new("Model")
	model.Name = "Lamp"
	model.Parent = decorationFolder
	
	local post = Instance.new("Part")
	post.Size = Vector3.new(1.5, 10, 1.5)
	post.Position = pos + Vector3.new(0, 5, 0)
	post.Color = Color3.fromRGB(100, 50, 20)
	post.Material = Enum.Material.Wood
	post.Anchored = true
	post.Parent = model
	
	local top = Instance.new("Part")
	top.Size = Vector3.new(2.5, 2.5, 2.5)
	top.Position = pos + Vector3.new(0, 10.5, 0)
	top.Color = Color3.fromRGB(255, 255, 150)
	top.Material = Enum.Material.Neon
	top.Anchored = true
	top.Parent = model
	
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 255, 200)
	light.Range = 25
	light.Brightness = 0.5 -- REDUCIDO COMO PEDISTE
	light.Parent = top
end

-- Trees behind the bases (Circle at radius 170)
for i = 1, 40 do
	local angle = i * (2 * math.pi / 40)
	local r = 240 + math.random(-8, 8)
	local pos = Vector3.new(r * math.cos(angle), 0, r * math.sin(angle))
	createBlockyTree(pos)
end

-- Trees in the center Safe Zone corners
for _, pos in ipairs({Vector3.new(18,0,18), Vector3.new(-18,0,18), Vector3.new(18,0,-18), Vector3.new(-18,0,-18)}) do
	createBlockyTree(pos)
end


-- ── 7. 10 PLAYER BASES (Open Plots) ─────────────────────────────────────────

local baseColors = {
	Color3.fromRGB(200, 40, 40),
	Color3.fromRGB(40, 200, 40),
	Color3.fromRGB(40, 80, 200),
	Color3.fromRGB(200, 40, 200),
	Color3.fromRGB(200, 100, 40),
	Color3.fromRGB(200, 200, 40),
	Color3.fromRGB(40, 200, 200),
	Color3.fromRGB(100, 40, 200),
	Color3.fromRGB(210, 210, 210),
	Color3.fromRGB(210, 120, 160)
}

local function createPath(A, B)
	local center = (A + B) / 2
	local dist = (B - A).Magnitude
	local path = Instance.new("Part")
	path.Name = "Pathway"
	path.Size = Vector3.new(12, 0.2, dist)
	path.CFrame = CFrame.lookAt(Vector3.new(center.X, 0.1, center.Z), Vector3.new(B.X, 0.1, B.Z))
	path.Color = Color3.fromRGB(200, 140, 80)
	path.Material = Enum.Material.Plastic
	path.TopSurface = Enum.SurfaceType.Studs
	path.Anchored = true
	path.CanCollide = false
	path.Parent = decorationFolder
	return path
end

for i = 1, 10 do
	local baseFolder = Instance.new("Folder")
	baseFolder.Name = "Base_" .. i
	baseFolder.Parent = playerBasesFolder

	local angle = (i - 1) * (2 * math.pi / 10)
	local radius = 180
	local basePos = Vector3.new(radius * math.cos(angle), 0, radius * math.sin(angle))
	
	local lookAwayTarget = basePos + Vector3.new(math.cos(angle), 0, math.sin(angle))
	local baseCFrame = CFrame.lookAt(basePos, lookAwayTarget)

	local plotSize = 50
	local plot = Instance.new("Part")
	plot.Name = "Plot"
	plot.Size = Vector3.new(plotSize, 0.5, plotSize)
	plot.CFrame = baseCFrame * CFrame.new(0, 0.35, 0)
	plot.Color = baseColors[i]
	plot.Material = Enum.Material.Plastic
	plot.TopSurface = Enum.SurfaceType.Studs
	plot.Anchored = true
	plot.Parent = baseFolder

	local borderThickness = 1.5
	local offsets = {
		{CFrame.new(0, 0.6, -plotSize/2), Vector3.new(plotSize, 1, borderThickness)}, 
		{CFrame.new(0, 0.6, plotSize/2), Vector3.new(plotSize/2 - 4, 1, borderThickness), true}, 
		{CFrame.new(-plotSize/2, 0.6, 0), Vector3.new(borderThickness, 1, plotSize)}, 
		{CFrame.new(plotSize/2, 0.6, 0), Vector3.new(borderThickness, 1, plotSize)} 
	}
	
	for idx, data in ipairs(offsets) do
		if data[3] then
			local p1 = Instance.new("Part")
			p1.Size = data[2]
			p1.CFrame = baseCFrame * CFrame.new(plotSize/4 + 2, 0.6, plotSize/2)
			p1.Color = baseColors[i]
			p1.Material = Enum.Material.SmoothPlastic
			p1.Anchored = true
			p1.Parent = baseFolder
			
			local p2 = Instance.new("Part")
			p2.Size = data[2]
			p2.CFrame = baseCFrame * CFrame.new(-plotSize/4 - 2, 0.6, plotSize/2)
			p2.Color = baseColors[i]
			p2.Material = Enum.Material.SmoothPlastic
			p2.Anchored = true
			p2.Parent = baseFolder
		else
			local p = Instance.new("Part")
			p.Size = data[2]
			p.CFrame = baseCFrame * data[1]
			p.Color = baseColors[i]
			p.Material = Enum.Material.SmoothPlastic
			p.Anchored = true
			p.Parent = baseFolder
		end
	end

	local album = Instance.new("Part")
	album.Name = "Album"
	album.Size = Vector3.new(20, 14, 1)
	album.CFrame = baseCFrame * CFrame.new(0, 7, -plotSize/2 + 2)
	album.Color = Color3.fromRGB(150, 100, 50)
	album.Material = Enum.Material.Wood
	album.TopSurface = Enum.SurfaceType.Studs
	album.Anchored = true
	album.Parent = baseFolder
	
	local albumBoard = Instance.new("Part")
	albumBoard.Name = "AlbumBoard"
	albumBoard.Size = Vector3.new(18, 12, 1.2)
	albumBoard.CFrame = baseCFrame * CFrame.new(0, 7, -plotSize/2 + 2)
	albumBoard.Color = Color3.fromRGB(30, 30, 40)
	albumBoard.Material = Enum.Material.Plastic
	albumBoard.Anchored = true
	albumBoard.Parent = baseFolder

	local spawnLoc = Instance.new("SpawnLocation")
	spawnLoc.Name = "SpawnLocation"
	spawnLoc.Size = Vector3.new(6, 0.5, 6)
	spawnLoc.CFrame = baseCFrame * CFrame.new(0, 0.6, 0)
	spawnLoc.Color = baseColors[i]
	spawnLoc.Material = Enum.Material.Plastic
	spawnLoc.TopSurface = Enum.SurfaceType.Studs
	spawnLoc.Anchored = true
	spawnLoc.Neutral = true
	spawnLoc.Parent = baseFolder

	local doorPos = (baseCFrame * CFrame.new(0, 0.1, plotSize/2)).Position
	
	-- Intersection with SafeZone square
	local dir = doorPos.Unit
	local safeZoneEdge = dir * (safeZoneSize/2)
	-- To make it hit the square perfectly:
	local scale = (safeZoneSize/2) / math.max(math.abs(dir.X), math.abs(dir.Z))
	safeZoneEdge = dir * scale
	
	local targetEntry = Vector3.new(safeZoneEdge.X, 0.1, safeZoneEdge.Z)
	
	createPath(doorPos, targetEntry)

	-- Lamps along the path
	local pathDir = (targetEntry - doorPos).Unit
	local perp = Vector3.new(-pathDir.Z, 0, pathDir.X)

	local lampFractions = {0.3, 0.7}
	for lIndex, lf in ipairs(lampFractions) do
		local sideOffset = (lIndex % 2 == 0) and 8 or -8
		local lampPos = doorPos:Lerp(targetEntry, lf) + perp * sideOffset
		createBlockyLamp(lampPos)
	end
end

for r = 1, 40 do
	local dist = 60 + math.random() * 100
	local angle = math.random() * 2 * math.pi
	local spawnPos = Vector3.new(dist * math.cos(angle), 2, dist * math.sin(angle))

	local spawnPart = Instance.new("Part")
	spawnPart.Name = "BrainrotSpawn"
	spawnPart.Size = Vector3.new(2, 2, 2)
	spawnPart.Position = spawnPos
	spawnPart.CFrame = CFrame.new(spawnPos) * CFrame.Angles(0, math.random() * math.pi, 0)
	spawnPart.Color = Color3.fromRGB(255, 200, 0)
	spawnPart.Material = Enum.Material.Neon
	spawnPart.TopSurface = Enum.SurfaceType.Studs
	spawnPart.Transparency = 1
	spawnPart.CanCollide = false
	spawnPart.Anchored = true
	spawnPart.Parent = brainrotSpawnsFolder
end

print("SUCCESS: Map generated with fences, reduced lamps, and repositioned trees!")
