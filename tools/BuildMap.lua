-- WORLD CUP BRAINROT — Map Builder
-- Pegar en Roblox Studio Command Bar (Edit mode, NO Play mode)
-- Ring radius reducido a 140 studs (original era 255)
-- Layout de zonas sin cambios (SafeZone central, TradingZone/MiniPitch en anillo medio, DangerZone afuera)

local ws = workspace

-- ── helpers ──────────────────────────────────────────────────────────────

local function clearFolder(f)
	for _, c in ipairs(f:GetChildren()) do c:Destroy() end
end

local function getOrCreate(parent, name, class)
	local f = parent:FindFirstChild(name)
	if f then
		clearFolder(f)
		return f
	end
	f = Instance.new(class or "Folder")
	f.Name   = name
	f.Parent = parent
	return f
end

local function makePart(parent, name, size, cf, color, transp, mat, canCollide)
	local p = Instance.new("Part")
	p.Name        = name
	p.Size        = size
	p.CFrame      = cf
	p.Color       = color   or Color3.new(0.7, 0.7, 0.7)
	p.Transparency = transp  or 0
	p.Material    = mat     or Enum.Material.SmoothPlastic
	p.Anchored    = true
	p.CanCollide  = (canCollide ~= false)
	p.Parent      = parent
	return p
end

-- Invisible boundary part used by ZoneUtils AABB checks
local function makeBoundary(parent, size, cf)
	return makePart(parent, "Boundary", size, cf,
		Color3.new(1,1,1), 1, Enum.Material.SmoothPlastic, false)
end

-- ── folder structure ─────────────────────────────────────────────────────

local map = getOrCreate(ws, "Map")

local playerBases    = getOrCreate(map, "PlayerBases")
local spawnPts       = getOrCreate(map, "SpawnPoints")
local brainrotSpawns = getOrCreate(map, "BrainrotSpawns")
local safeZone       = getOrCreate(map, "SafeZone")
local dangerZone     = getOrCreate(map, "DangerZone")
local tradingZone    = getOrCreate(map, "TradingZone")
local miniPitch      = getOrCreate(map, "MiniPitch")

-- ── GROUND ───────────────────────────────────────────────────────────────

makePart(map, "Ground",
	Vector3.new(390, 2, 390),
	CFrame.new(0, -1, 0),
	Color3.fromRGB(108, 156, 88), 0, Enum.Material.Grass)

-- ── DANGER ZONE (covers everything — lowest priority in ZoneUtils) ────────

-- Large AABB boundary
makeBoundary(dangerZone,
	Vector3.new(390, 40, 390),
	CFrame.new(0, 20, 0))

-- Faint red floor tint so it's visible in Studio
makePart(dangerZone, "Tint",
	Vector3.new(390, 0.3, 390),
	CFrame.new(0, 0.15, 0),
	Color3.fromRGB(220, 50, 50), 0.82, Enum.Material.Neon, false)

-- ── SAFE ZONE (center, 80 × 80) ──────────────────────────────────────────

makeBoundary(safeZone, Vector3.new(80, 24, 80), CFrame.new(0, 12, 0))

makePart(safeZone, "Floor",
	Vector3.new(80, 0.5, 80),
	CFrame.new(0, 0.25, 0),
	Color3.fromRGB(60, 130, 220), 0.4, Enum.Material.Neon, false)

-- Album/safe stand in the middle
makePart(safeZone, "AlbumStand",
	Vector3.new(9, 1.3, 9),
	CFrame.new(0, 1.15, 0),
	Color3.fromRGB(200, 170, 80), 0, Enum.Material.SmoothPlastic)

-- Low fence around SafeZone (4 sides, decorative)
local szFences = {
	{ Vector3.new(81, 2.5, 0.4), CFrame.new(0, 1.25,  40.2) },
	{ Vector3.new(81, 2.5, 0.4), CFrame.new(0, 1.25, -40.2) },
	{ Vector3.new(0.4, 2.5, 81), CFrame.new( 40.2, 1.25, 0) },
	{ Vector3.new(0.4, 2.5, 81), CFrame.new(-40.2, 1.25, 0) },
}
for _, f in ipairs(szFences) do
	makePart(safeZone, "Fence", f[1], f[2],
		Color3.fromRGB(60, 110, 190), 0, Enum.Material.SmoothPlastic)
end

-- ── TRADING ZONE (60 × 60, northeast of center) ──────────────────────────
-- Center at (95, 0, 40) — clear of SafeZone (which ends at ±40)

local TX, TZ = 95, 40

makeBoundary(tradingZone, Vector3.new(60, 24, 60), CFrame.new(TX, 12, TZ))

makePart(tradingZone, "Floor",
	Vector3.new(60, 0.5, 60),
	CFrame.new(TX, 0.25, TZ),
	Color3.fromRGB(55, 190, 90), 0.4, Enum.Material.Neon, false)

-- 3 market stalls
for i = -1, 1 do
	makePart(tradingZone, "StallBody",
		Vector3.new(6, 3, 4),
		CFrame.new(TX + i*16, 1.5, TZ),
		Color3.fromRGB(200, 160, 60), 0, Enum.Material.Wood)
	makePart(tradingZone, "StallRoof",
		Vector3.new(7, 0.3, 5),
		CFrame.new(TX + i*16, 3.15, TZ),
		Color3.fromRGB(180, 80, 30), 0, Enum.Material.SmoothPlastic)
	makePart(tradingZone, "Counter",
		Vector3.new(5, 0.5, 1.5),
		CFrame.new(TX + i*16, 1.25, TZ + 1.8),
		Color3.fromRGB(160, 120, 50), 0, Enum.Material.Wood)
end

-- ── MINI PITCH (100 × 58, northwest of center) ───────────────────────────
-- Center at (-80, 0, 50) — clear of SafeZone

local PX, PZ = -80, 50

makeBoundary(miniPitch, Vector3.new(100, 24, 58), CFrame.new(PX, 12, PZ))

-- Grass
makePart(miniPitch, "Grass",
	Vector3.new(100, 0.5, 58),
	CFrame.new(PX, 0.25, PZ),
	Color3.fromRGB(80, 160, 50), 0, Enum.Material.Grass)

-- Field lines
makePart(miniPitch, "CenterLine",
	Vector3.new(0.7, 0.6, 58),
	CFrame.new(PX, 0.55, PZ),
	Color3.new(1,1,1), 0)

makePart(miniPitch, "CenterCircle",
	Vector3.new(20, 0.6, 20),
	CFrame.new(PX, 0.55, PZ),
	Color3.new(1,1,1), 0.65, Enum.Material.Neon, false)

-- Goals (east and west ends)
for _, side in ipairs({-1, 1}) do
	-- post
	makePart(miniPitch, "GoalPost",
		Vector3.new(0.5, 4, 10),
		CFrame.new(PX + side*49.75, 2.25, PZ),
		Color3.new(1,1,1))
	-- crossbar
	makePart(miniPitch, "Crossbar",
		Vector3.new(0.5, 0.5, 10),
		CFrame.new(PX + side*49.75, 4.5, PZ),
		Color3.new(1,1,1))
end

-- Ball (unanchored so it rolls during play)
local ball = makePart(miniPitch, "Ball",
	Vector3.new(2, 2, 2),
	CFrame.new(PX, 2, PZ),
	Color3.new(1,1,1), 0)
ball.Shape    = Enum.PartType.Ball
ball.Anchored = false

-- ── PLAYER BASES (15 in ring, radius 140) ────────────────────────────────

local BASE_COUNT  = 15
local RING_RADIUS = 140   -- reduced from 255
local BASE_W      = 18    -- plot side length
local WALL_H      = 4     -- house wall height
local WALL_CLR    = Color3.fromRGB(210, 200, 185)
local ROOF_CLR    = Color3.fromRGB(185, 80, 40)

for i = 1, BASE_COUNT do
	local angle = (i - 1) * (2 * math.pi / BASE_COUNT)
	local bx    = math.floor(RING_RADIUS * math.cos(angle) + 0.5)
	local bz    = math.floor(RING_RADIUS * math.sin(angle) + 0.5)

	local folder     = Instance.new("Folder")
	folder.Name      = "Base_" .. i
	folder.Parent    = playerBases

	-- Grass plot
	makePart(folder, "Plot",
		Vector3.new(BASE_W, 0.5, BASE_W),
		CFrame.new(bx, 0.25, bz),
		Color3.fromRGB(100, 180, 70), 0, Enum.Material.Grass)

	-- BOUNDARY (larger than plot, tall enough for AABB detection)
	makeBoundary(folder,
		Vector3.new(BASE_W + 2, 16, BASE_W + 2),
		CFrame.new(bx, 8, bz))

	-- 4 walls (axis-aligned)
	makePart(folder, "WallFront",
		Vector3.new(BASE_W, WALL_H, 0.5),
		CFrame.new(bx, WALL_H/2, bz + BASE_W/2),
		WALL_CLR)
	makePart(folder, "WallBack",
		Vector3.new(BASE_W, WALL_H, 0.5),
		CFrame.new(bx, WALL_H/2, bz - BASE_W/2),
		WALL_CLR)
	makePart(folder, "WallLeft",
		Vector3.new(0.5, WALL_H, BASE_W),
		CFrame.new(bx + BASE_W/2, WALL_H/2, bz),
		WALL_CLR)
	makePart(folder, "WallRight",
		Vector3.new(0.5, WALL_H, BASE_W),
		CFrame.new(bx - BASE_W/2, WALL_H/2, bz),
		WALL_CLR)

	-- Roof
	makePart(folder, "Roof",
		Vector3.new(BASE_W + 1, 0.5, BASE_W + 1),
		CFrame.new(bx, WALL_H + 0.25, bz),
		ROOF_CLR)

	-- Number sign (front wall, visible in Studio)
	local sign = Instance.new("Part")
	sign.Name     = "Sign"
	sign.Size     = Vector3.new(2.6, 1.8, 0.2)
	sign.CFrame   = CFrame.new(bx, WALL_H - 0.6, bz + BASE_W/2 + 0.15)
	sign.Anchored = true
	sign.CanCollide = false
	sign.Color    = Color3.fromRGB(255, 220, 0)
	sign.Parent   = folder

	local sg = Instance.new("SurfaceGui")
	sg.Face   = Enum.NormalId.Front
	sg.Parent = sign

	local lb = Instance.new("TextLabel")
	lb.Size                 = UDim2.fromScale(1, 1)
	lb.BackgroundTransparency = 1
	lb.Text                 = tostring(i)
	lb.TextScaled           = true
	lb.Font                 = Enum.Font.GothamBold
	lb.TextColor3           = Color3.new(0, 0, 0)
	lb.Parent               = sg

	-- SpawnLocation inside the base (used by default Roblox spawn system)
	local sp               = Instance.new("SpawnLocation")
	sp.Name                = "Spawn_" .. i
	sp.Size                = Vector3.new(4, 0.4, 4)
	sp.CFrame              = CFrame.new(bx, 0.7, bz)
	sp.Anchored            = true
	sp.Transparency        = 0.85
	sp.Color               = Color3.fromRGB(60, 140, 255)
	sp.AllowTeamChangeOnTouch = false
	sp.TeamColor           = BrickColor.new("Medium stone grey")
	sp.Parent              = spawnPts
end

-- ── BRAINROT SPAWN POINTS (20 pts scattered in middle ring) ───────────────
-- Distributed between radius 65–100, inside the base ring (140)

local SPAWN_RADII = { 68, 78, 88, 97, 72 }  -- cycling

for i = 1, 20 do
	local angle  = (i - 1) * (2 * math.pi / 20) + math.pi / 20
	local radius = SPAWN_RADII[((i-1) % 5) + 1]
	local sx     = math.floor(radius * math.cos(angle) + 0.5)
	local sz     = math.floor(radius * math.sin(angle) + 0.5)

	makePart(brainrotSpawns, "Spawn_" .. i,
		Vector3.new(3, 0.5, 3),
		CFrame.new(sx, 0.75, sz),
		Color3.fromRGB(255, 140, 0), 0.35, Enum.Material.Neon, false)
end

-- ── DEFAULT SPAWN (center, for unassigned / overflow players) ─────────────

local defSpawn               = Instance.new("SpawnLocation")
defSpawn.Name                = "DefaultSpawn"
defSpawn.Size                = Vector3.new(8, 1, 8)
defSpawn.CFrame              = CFrame.new(0, 1, 0)
defSpawn.Anchored            = true
defSpawn.Transparency        = 0.75
defSpawn.Color               = Color3.fromRGB(80, 140, 220)
defSpawn.AllowTeamChangeOnTouch = false
defSpawn.Parent              = spawnPts

-- ── DONE ─────────────────────────────────────────────────────────────────

print(string.format(
	"[MapBuilder] Listo! Bases: %d | BrainrotSpawns: 20 | Radio del anillo: %d studs",
	BASE_COUNT, RING_RADIUS
))
