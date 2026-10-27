--!nocheck
-- ImpactFX: hit feedback for big moments. Client only, cosmetic (the server already decided the outcome).
-- Source: VFX/ImpactFX.luau, installed as ReplicatedStorage.ImpactFX.
--
--   ImpactFX.impactFrame(settings)          -- 2-3 frame high-contrast "impact frame", then eases back (flashes off: skipped)
--   ImpactFX.scorch(pos, radius, life)      -- dark ground mark with an ember edge, fades out (default 2.5 s)
--   local t = ImpactFX.telegraph(pos, radius, color)  t.set(0..1)  t.destroy()
--                                           -- outline ring + inner disc that fills as the fraction rises (where AND when)
--   ImpactFX.shakeOffset(time, amount)      -- smooth (noise-based) camera offset; amount 0..1 is squared ("trauma")
--   ImpactFX.audit()                        -- runs everything headless and checks clean-up
-- Research: [[Research/TikTok VFX Reference Study]] (viewers asked for impact frames and shake), trauma shake from
-- Squirrel Eiserloh's GDC 2014 talk "Juice It or Lose It" via the community write-ups cited there.

local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local ImpactFX = {}
ImpactFX.FRAME = 0.06 -- impact frame hold, seconds (rule of thumb 50-100 ms on heavy hits)

local function tween(inst, t, props, style, dir)
	local tw = TweenService:Create(inst, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local function folder()
	local f = workspace:FindFirstChild("ImpactFX")
	if not f then
		f = Instance.new("Folder")
		f.Name = "ImpactFX"
		f.Parent = workspace
	end
	return f
end

local function disc(props)
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Cylinder
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	for k, v in pairs(props) do
		p[k] = v
	end
	p.Parent = folder()
	return p
end

local function flat(pos, y, d)
	return CFrame.new(pos.X, pos.Y + y, pos.Z) * CFrame.Angles(0, 0, math.pi / 2), Vector3.new(0.05, d, d)
end

-- One short burst of contrast and desaturation. Reuses a single ColorCorrection so overlapping hits don't stack.
local busyUntil = 0
function ImpactFX.impactFrame(settings)
	settings = settings or {}
	if settings.flashes == false then
		return false
	end
	local cc = Lighting:FindFirstChild("ImpactCC")
	if not cc then
		cc = Instance.new("ColorCorrectionEffect")
		cc.Name = "ImpactCC"
		cc.Parent = Lighting
	end
	local now = os.clock()
	if now < busyUntil then
		return false
	end
	busyUntil = now + ImpactFX.FRAME + 0.12
	local strength = settings.reducedMotion and 0.5 or 1
	cc.Contrast, cc.Saturation, cc.Brightness = 0.55 * strength, -0.7 * strength, 0.12 * strength
	task.delay(ImpactFX.FRAME, function()
		tween(cc, 0.12, { Contrast = 0, Saturation = 0, Brightness = 0 })
	end)
	return true
end

function ImpactFX.scorch(pos, radius, life)
	radius, life = radius or 6, life or 2.5
	local cf, size = flat(pos, 0.06, radius * 2)
	local mark = disc({ Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(22, 16, 20), Transparency = 0.25, CFrame = cf, Size = size, Name = "Scorch" })
	local cf2, size2 = flat(pos, 0.08, radius * 2.15)
	local edge = disc({ Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 120, 50), Transparency = 0.55, CFrame = cf2, Size = size2, Name = "ScorchEdge" })
	tween(edge, 0.6, { Transparency = 1 }, Enum.EasingStyle.Sine)
	task.delay(life * 0.4, function()
		if mark.Parent then
			tween(mark, life * 0.6, { Transparency = 1 }, Enum.EasingStyle.Sine)
		end
	end)
	Debris:AddItem(mark, life + 0.1)
	Debris:AddItem(edge, 0.7)
	return mark
end

function ImpactFX.telegraph(pos, radius, color)
	color = color or Color3.fromRGB(255, 76, 90)
	local cfO, sizeO = flat(pos, 0.1, radius * 2)
	local outer = disc({ Material = Enum.Material.Neon, Color = color, Transparency = 0.55, CFrame = cfO, Size = sizeO, Name = "TelegraphOuter" })
	local cfB, sizeB = flat(pos, 0.11, radius * 2 - 0.6)
	local hole = disc({ Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(20, 20, 30), Transparency = 0.6, CFrame = cfB, Size = sizeB, Name = "TelegraphBase" })
	local cfI, _ = flat(pos, 0.12, 0.1)
	local inner = disc({ Material = Enum.Material.Neon, Color = color, Transparency = 0.35, CFrame = cfI, Size = Vector3.new(0.05, 0.1, 0.1), Name = "TelegraphFill" })
	local h = { parts = { outer, hole, inner }, fraction = 0 }
	function h.set(f)
		f = math.clamp(f, 0, 1)
		h.fraction = f
		local d = math.max(0.1, (radius * 2 - 0.6) * f)
		inner.Size = Vector3.new(0.05, d, d)
		-- pulse faster as it fills
		outer.Transparency = 0.35 + 0.25 * (0.5 + 0.5 * math.sin(os.clock() * (4 + 10 * f)))
	end
	function h.destroy()
		for _, p in h.parts do
			if p.Parent then
				tween(p, 0.2, { Transparency = 1 })
				Debris:AddItem(p, 0.25)
			end
		end
	end
	return h
end

-- Smooth shake: Perlin noise per axis, amplitude scales with amount^2 so small hits stay subtle.
function ImpactFX.shakeOffset(t, amount)
	local a = math.clamp(amount, 0, 4)
	a = a * a
	return Vector3.new(math.noise(t * 14, 1.7) * a, math.noise(t * 14, 9.3) * a, 0) * 1.2
end

function ImpactFX.audit()
	local results, ok = {}, true
	local f1 = ImpactFX.impactFrame({ flashes = false })
	table.insert(results, ("flashes off skips impact frame: %s"):format(tostring(f1 == false)))
	ok = ok and f1 == false
	busyUntil = 0
	local f2 = ImpactFX.impactFrame({ flashes = true })
	local cc = Lighting:FindFirstChild("ImpactCC")
	local peak = cc and cc.Contrast or 0
	table.insert(results, ("impact frame peak contrast %.2f (want 0.55)"):format(peak))
	ok = ok and f2 and math.abs(peak - 0.55) < 0.01
	ImpactFX.scorch(Vector3.new(0, 1, 0), 5, 0.6)
	local t = ImpactFX.telegraph(Vector3.new(0, 1, 20), 6)
	t.set(0.5)
	local d = t.parts[3].Size.Y
	table.insert(results, ("telegraph fill at 50%%: %.2f (want %.2f)"):format(d, (12 - 0.6) * 0.5))
	ok = ok and math.abs(d - 5.7) < 0.01
	t.destroy()
	local s1 = ImpactFX.shakeOffset(1, 0.3).Magnitude
	local s2 = ImpactFX.shakeOffset(1, 1).Magnitude
	table.insert(results, ("shake grows with amount: %.3f -> %.3f"):format(s1, s2))
	ok = ok and s2 >= s1
	task.wait(1)
	local left = #folder():GetChildren()
	local cc2 = Lighting:FindFirstChild("ImpactCC")
	table.insert(results, ("left after 1 s: %d parts, contrast %.2f"):format(left, cc2 and cc2.Contrast or 0))
	ok = ok and left == 0 and cc2 and cc2.Contrast < 0.01
	return ok, table.concat(results, "\n")
end

return ImpactFX
