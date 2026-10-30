--!nocheck
-- BossArena (T172, 2026-10-30): five boss arena variants of the board, one per boss (stages 5, 10, 15, 20, 25).
-- Client-only dressing in workspace.BossArena, built OUTSIDE the lane box (x -44..40, z -21..22): the path, the no-build circles
-- and every collision are untouched (all parts CanCollide/CanQuery/CanTouch false). StageSetClient calls M.setStage(stage) from its
-- apply(); the server events Spawn { boss } (the boss id wins over the stage guess) and BossPhase { phase } come in through
-- M.onEvent. Phase 2 and 3 raise the arena lights and shift them to the phase colour (violet, amber, crimson as in BossFx).
-- Test hooks: M.build(bossId, parent) returns the folder; M.current (boss id or nil); M.BOSS_AT (stage -> boss id). Look UNVERIFIED.
local RS = game:GetService("ReplicatedStorage")
local M = {}

M.ORDER = { "Unbound", "Automaton", "Echo", "Regent", "Clockmaker" }
M.BOSS_AT = { [5] = "Unbound", [10] = "Automaton", [15] = "Echo", [20] = "Regent", [25] = "Clockmaker" }
M.PHASE_COLOR = { Color3.fromRGB(170, 130, 255), Color3.fromRGB(255, 170, 70), Color3.fromRGB(255, 60, 50) }
M.current = nil
M.phase = 1

local CYL, BALL = Enum.PartType.Cylinder, Enum.PartType.Ball
local CX, RX, RZ = -2, 50, 28 -- the ring of props: an ellipse round the lane box

local function mk(root, size, cf, color, mat, shape, tr)
	local p = Instance.new("Part")
	if shape then p.Shape = shape end
	p.Size, p.CFrame, p.Color, p.Material = size, cf, color, mat or Enum.Material.Slate
	p.Transparency = tr or 0
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = root
	return p
end
local function glow(part, color, range, bright)
	local l = Instance.new("PointLight")
	l.Name, l.Color, l.Range, l.Brightness, l.Shadows = "ArenaLight", color, range, bright, false
	l.Parent = part
	part:SetAttribute("BaseBright", bright)
	return l
end
local function ringPos(deg, k) -- a point on the prop ellipse; k scales it inwards or outwards
	local a = math.rad(deg)
	return Vector3.new(CX + math.sin(a) * RX * (k or 1), 0, math.cos(a) * RZ * (k or 1))
end
local function around(n, from, to, f) -- f(index, position, angleDeg) for n props between two angles
	for i = 0, n - 1 do
		local d = from + (to - from) * i / math.max(n - 1, 1)
		f(i, ringPos(d), d)
	end
end

M.variants = {}

-- Shared floor sigil: the boss's mark, laid on the dark ground between the lane rows (about x -16..12, z -17..5), thin and translucent.
local SIG = Vector3.new(-3, 0.08, -6)
local function flat(root, r, color, tr, thick, y)
	local p = mk(root, Vector3.new(thick or 0.12, r * 2, r * 2), CFrame.new(SIG.X, y or SIG.Y, SIG.Z) * CFrame.Angles(0, 0, math.pi / 2), color, Enum.Material.Neon, CYL, tr)
	return p
end
local function spokes(root, n, r0, r1, color, tr)
	for k = 0, n - 1 do
		local a = math.rad(360 * k / n)
		local mid = (r0 + r1) / 2
		mk(root, Vector3.new(0.5, 0.1, r1 - r0), CFrame.new(SIG.X + math.sin(a) * mid, SIG.Y + 0.02, SIG.Z + math.cos(a) * mid) * CFrame.Angles(0, a, 0), color, Enum.Material.Neon, nil, tr)
	end
end

-- 1. The Unbound: a bank of fog. Grey-violet wisp pillars round the courtyard, a shroud along the back wall, a violet ring sigil.
function M.variants.Unbound(root)
	local pale, vio = Color3.fromRGB(176, 170, 200), Color3.fromRGB(150, 120, 230)
	around(10, 20, 340, function(i, p)
		local h = 7 + (i % 3) * 3
		mk(root, Vector3.new(2, h, 2), CFrame.new(p.X, h / 2 - 0.5, p.Z), pale, Enum.Material.Fabric, nil, 0.6).Name = "Wisp"
		local o = mk(root, Vector3.new(2.2, 2.2, 2.2), CFrame.new(p.X, h + 0.8, p.Z), vio, Enum.Material.Neon, BALL, 0.2)
		glow(o, vio, 18, 1.6)
	end)
	for i = 0, 4 do
		mk(root, Vector3.new(16, 9, 0.6), CFrame.new(-40 + i * 20, 4.5, -29.5), pale, Enum.Material.Fabric, nil, 0.55)
	end
	flat(root, 10, vio, 0.65, 0.1).Name = "Sigil"
	flat(root, 8.8, Color3.fromRGB(20, 14, 40), 0.3, 0.12, SIG.Y + 0.02)
	flat(root, 5.4, vio, 0.7, 0.1, SIG.Y + 0.03)
	spokes(root, 3, 0, 5.4, vio, 0.5)
end

-- 2. The Clockmaker's Automaton: a brass gear sigil, steam stacks with amber fire round the courtyard.
function M.variants.Automaton(root)
	local brass, dark, amber = Color3.fromRGB(176, 130, 64), Color3.fromRGB(50, 42, 38), Color3.fromRGB(255, 160, 60)
	local R = 8.6
	flat(root, R, brass, 0.35, 0.3).Name = "Sigil"
	for k = 0, 15 do
		local a = math.rad(22.5 * k)
		mk(root, Vector3.new(0.3, 2.6, 2.4), CFrame.new(SIG.X + math.cos(a) * (R + 0.8), SIG.Y + 0.05, SIG.Z + math.sin(a) * (R + 0.8)) * CFrame.Angles(0, -a, 0), brass, Enum.Material.Metal, nil, 0.3)
	end
	flat(root, 3, dark, 0.1, 0.4, SIG.Y + 0.04)
	spokes(root, 6, 3, R - 1, dark, 0.2)
	around(8, 30, 330, function(i, p)
		mk(root, Vector3.new(9, 2.6, 2.6), CFrame.new(p.X, 4, p.Z), dark, Enum.Material.Metal, CYL).Orientation = Vector3.new(0, 0, 90)
		local f = mk(root, Vector3.new(2.4, 2.4, 2.4), CFrame.new(p.X, 9, p.Z), amber, Enum.Material.Neon, BALL, 0.15)
		glow(f, amber, 20, 1.8)
	end)
end

-- 3. The Star Choir's Echo: tall pale-blue glass panels round the courtyard, chorus stones, a ring-and-spokes star sigil.
function M.variants.Echo(root)
	local ice, deep = Color3.fromRGB(150, 196, 255), Color3.fromRGB(30, 38, 86)
	around(9, 60, 300, function(i, p, d)
		local h = 10 + (i % 2) * 4
		local panel = mk(root, Vector3.new(6, h, 0.7), CFrame.new(p.X, h / 2, p.Z) * CFrame.Angles(0, math.rad(d), 0), ice, Enum.Material.Glass, nil, 0.4)
		panel.Name = "ChoirPanel"
		glow(panel, ice, 20, 1.4)
	end)
	around(14, 0, 360, function(i, p)
		mk(root, Vector3.new(2, 4, 2), CFrame.new(p.X * 1.04, 1.5, p.Z * 1.04), deep, Enum.Material.Slate).Name = "ChorusStone"
		mk(root, Vector3.new(1, 1, 1), CFrame.new(p.X * 1.04, 4.4, p.Z * 1.04), ice, Enum.Material.Neon, BALL)
	end)
	flat(root, 10, ice, 0.65, 0.1).Name = "Sigil"
	flat(root, 8.4, deep, 0.4, 0.12, SIG.Y + 0.02)
	spokes(root, 8, 0, 10, ice, 0.5)
end

-- 4. The Hollow Court Regent: seven tall candles (the boss lights them in phase 2), a gold crown sigil, red banners on the back wall.
function M.variants.Regent(root)
	local wax, flame, gold, red = Color3.fromRGB(226, 214, 190), Color3.fromRGB(255, 190, 90), Color3.fromRGB(200, 160, 70), Color3.fromRGB(120, 28, 36)
	around(7, 70, 290, function(i, p)
		mk(root, Vector3.new(9, 2.6, 2.6), CFrame.new(p.X, 4, p.Z), wax, Enum.Material.SmoothPlastic, CYL).Orientation = Vector3.new(0, 0, 90)
		local f = mk(root, Vector3.new(1.4, 2.4, 1.4), CFrame.new(p.X, 9.6, p.Z), flame, Enum.Material.Neon, BALL, 0.1)
		f.Name = "Flame"
		glow(f, flame, 22, 1.8)
	end)
	flat(root, 10, gold, 0.75, 0.1).Name = "Sigil"
	for k = 0, 6 do -- crown points round the ring
		local a = math.rad(360 * k / 7)
		mk(root, Vector3.new(2, 5, 2), CFrame.new(SIG.X + math.sin(a) * 7.5, 2.5, SIG.Z + math.cos(a) * 7.5) * CFrame.Angles(0, a, 0), gold, Enum.Material.Metal, nil, 0.35).Name = "CrownSpike"
	end
	for _, x in { -40, -4, 34 } do
		mk(root, Vector3.new(7, 12, 0.5), CFrame.new(x, 6, -29.5), red, Enum.Material.Fabric).Name = "Banner"
	end
end

-- 5. The Clockmaker: a clock face laid on the ground with a hand that sweeps, hour posts round the courtyard, lamp orange.
function M.variants.Clockmaker(root)
	local brass, night, lamp = Color3.fromRGB(150, 118, 64), Color3.fromRGB(26, 28, 44), Color3.fromRGB(255, 170, 70)
	flat(root, 10, brass, 0.45, 0.2).Name = "Sigil"
	flat(root, 9.4, night, 0.2, 0.12, SIG.Y + 0.02).Name = "ClockFace"
	for k = 0, 11 do
		local a = math.rad(30 * k)
		mk(root, Vector3.new(0.6, 0.15, 2.4), CFrame.new(SIG.X + math.sin(a) * 8.4, SIG.Y + 0.05, SIG.Z + math.cos(a) * 8.4) * CFrame.Angles(0, a, 0), lamp, Enum.Material.Neon, nil, 0.1)
	end
	local hand = mk(root, Vector3.new(0.8, 0.2, 7.5), CFrame.new(SIG.X, SIG.Y + 0.1, SIG.Z - 3.75), lamp, Enum.Material.Neon)
	hand.Name = "ClockHand"
	glow(hand, lamp, 18, 1.6)
	hand:SetAttribute("PivotX", SIG.X)
	hand:SetAttribute("PivotY", SIG.Y + 0.1)
	hand:SetAttribute("PivotZ", SIG.Z)
	around(12, 15, 345, function(i, p)
		mk(root, Vector3.new(7, 2.4, 2.4), CFrame.new(p.X, 3, p.Z), brass, Enum.Material.Metal, CYL).Orientation = Vector3.new(0, 0, 90)
		local t = mk(root, Vector3.new(1.3, 1.3, 1.3), CFrame.new(p.X, 7, p.Z), lamp, Enum.Material.Neon, BALL)
		if i % 3 == 0 then glow(t, lamp, 16, 1.2) end
	end)
end
function M.build(boss, parent)
	local f = Instance.new("Folder")
	f.Name = "BossArena_" .. boss
	local v = M.variants[boss]
	if not v then return nil end
	v(f)
	f:SetAttribute("Boss", boss)
	f.Parent = parent
	return f
end

local function clear()
	local old = workspace:FindFirstChild("BossArena")
	if old then old:Destroy() end -- client-only folder this module made itself
end

function M.show(boss)
	if boss == M.current then return end
	clear()
	M.current, M.phase = boss, 1
	if not boss or not M.variants[boss] then M.current = nil return end
	local holder = Instance.new("Folder")
	holder.Name = "BossArena"
	holder.Parent = workspace
	M.build(boss, holder)
end

-- stage: current stage number; a boss stage shows its arena, any other stage removes it
function M.setStage(stage)
	M.show(M.BOSS_AT[stage or 0])
end

local function tune(phase)
	M.phase = phase
	local holder = workspace:FindFirstChild("BossArena")
	if not holder then return end
	local c = M.PHASE_COLOR[math.clamp(phase, 1, 3)]
	for _, l in holder:GetDescendants() do
		if l:IsA("PointLight") then
			local base = l.Parent:GetAttribute("BaseBright") or 1.5
			l.Brightness = base * (1 + 0.5 * (phase - 1))
			if phase > 1 then l.Color = c end
		end
	end
end

function M.onEvent(kind, data)
	if type(data) ~= "table" then return end
	if kind == "Spawn" and data.boss then
		M.show(data.boss) -- the boss id wins over the stage guess
	elseif kind == "BossPhase" and data.phase then
		tune(data.phase)
	end
end

-- the clock hand sweeps (Clockmaker only)
task.spawn(function()
	while true do
		task.wait(0.1)
		local h = M.current == "Clockmaker" and workspace:FindFirstChild("BossArena") and workspace.BossArena:FindFirstChild("ClockHand", true)
		if h then
			local pivot = Vector3.new(h:GetAttribute("PivotX") or 0, h:GetAttribute("PivotY") or 34, h:GetAttribute("PivotZ") or -56)
			local ang = os.clock() * (M.phase >= 3 and -0.6 or 0.25)
			h.CFrame = CFrame.new(pivot) * CFrame.Angles(0, -ang, 0) * CFrame.new(0, 0, -3.75)
		end
	end
end)

pcall(function()
	RS:WaitForChild("Remotes", 10):WaitForChild("Event", 10).OnClientEvent:Connect(M.onEvent)
end)

return M
