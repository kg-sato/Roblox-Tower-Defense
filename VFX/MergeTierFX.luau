--!nocheck
-- MergeTierFX (T135, overnight fx-audio, 2026-10-29): the merge effect for each result tier 1 to 8, and the morph cut onto the new model.
-- Installed as ReplicatedStorage.MergeTierFX. FxLayer calls play + morph when a merged familiar appears; FXRecipes.merge takes `tier` too.
--   MergeTierFX.play(base, color, tier)   -- base = ground point under the new familiar; 1 = placement spark, 8 = full crown
--   MergeTierFX.morph(model, color, tier) -- morph cut: a 0.1 s cream wash on the new model and a 0.24 s scale pop (1.14 -> 1)
-- Ladder (each tier keeps the layers below it): 1 ring + motes / 2 column + chevron / 3 second ring + orbiting motes / 4 halo + embers /
--   5 crown of gold spires / 6 ground sigil + ribbons / 7 eight gold rays + second shockwave / 8 pillar, 12 rays, falling gold ash.
-- Look: cream core, antique-gold structure, the familiar's colour as the accent. Budget: tier 1-3: 1 emitter, 4-6: 2, 7-8: 3 (FxCommon.take).
-- Reduced motion: rings, column and halo fade in place; nothing orbits, spins, scatters or shakes. Flashes off: the wash is skipped.
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local C = require(RS:WaitForChild("FxCommon"))

local M = { log = {} }
local V3 = Vector3.new
local function flatRing(pos, color, d0, d1, life, alpha, dy)
	local p = C.part({ Shape = Enum.PartType.Cylinder, Color = color, Transparency = alpha or .25, Size = V3(.1, d0, d0), CFrame = CFrame.new(pos.X, pos.Y + (dy or .2), pos.Z) * CFrame.Angles(0, 0, math.pi / 2) })
	C.tw(p, life, { Size = V3(.1, d1, d1), Transparency = 1 }, Enum.EasingStyle.Quint)
	C.gone(p, life)
	return p
end

local function decalSigil(pos, color, size, life)
	local okFA, FA = pcall(function() return require(RS:WaitForChild("FrameArt", 3)) end)
	local p = C.part({ Transparency = 1, Size = V3(size, .05, size), CFrame = CFrame.new(pos.X, pos.Y + .25, pos.Z) })
	local sg = Instance.new("SurfaceGui")
	sg.Face, sg.LightInfluence, sg.Brightness, sg.SizingMode, sg.PixelsPerStud = Enum.NormalId.Top, 0, 2, Enum.SurfaceGuiSizingMode.PixelsPerStud, 20
	sg.Parent = p
	local img = Instance.new("ImageLabel")
	img.BackgroundTransparency, img.Size, img.ImageColor3, img.ImageTransparency = 1, UDim2.fromScale(1, 1), color, .15
	if okFA and FA then img.ImageContent = FA.sigil() else img.Image = "rbxasset://textures/particles/sparkles_main.dds" end
	img.Parent = sg
	if not C.still() then C.tw(img, life, { Rotation = 90 }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut) end
	C.tw(img, life, { ImageTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	C.gone(p, life + .1)
end

function M.play(base, color, tier)
	tier = math.clamp(math.floor(tonumber(tier) or 1), 1, 8)
	local still = C.still()
	local k = .8 + .2 * tier
	local gold, cream = C.GOLD, C.CREAM
	local acc = color:Lerp(cream, .15)
	table.insert(M.log, { tier = tier, still = still, quality = C.quality })
	C.note("merge_tier" .. tier)
	-- 1: ring + motes
	flatRing(base, acc, 2 * k, 7 * k, .45)
	local a = C.part({ Transparency = 1, Size = Vector3.one * .2, Position = base + V3(0, 1, 0) })
	C.emit(a, { c0 = cream, c1 = acc, n = 4 + tier * 2, life = .8, speed = 5 + tier, size = .45, accel = V3(0, 2, 0) })
	C.gone(a, 1.8)
	if tier >= 2 then -- column + chevron
		local h = 8 + tier * 1.2
		local col = C.part({ Shape = Enum.PartType.Cylinder, Color = acc:Lerp(gold, .35), Transparency = .55, Size = V3(h, .6, .6), CFrame = CFrame.new(base + V3(0, h / 2, 0)) * CFrame.Angles(0, 0, math.pi / 2) })
		C.tw(col, .15, { Size = V3(h, .8 + .12 * tier, .8 + .12 * tier) }, Enum.EasingStyle.Back)
		task.delay(.45 * C.slow, function() if col.Parent then C.tw(col, .45, { Transparency = 1, Size = V3(h, .2, .2) }) end end)
		C.gone(col, 1)
		if not still then
			local ch = C.part({ Color = cream, Size = V3(2.4, .35, .35), CFrame = CFrame.new(base + V3(0, 2, 0)) })
			C.tw(ch, .7, { CFrame = ch.CFrame + V3(0, 7, 0), Transparency = 1 })
			C.gone(ch, .8)
		end
	end
	if tier >= 3 then
		task.delay(.12 * C.slow, function() flatRing(base, gold, 3 * k, 11 * k, .5, .35) end)
		if not still then -- orbiting motes
			for i = 1, 3 do
				local m = C.part({ Shape = Enum.PartType.Ball, Color = cream, Size = Vector3.one * .4, Position = base })
				local t0 = os.clock()
				local life = .9 * C.slow
				local conn
				conn = RunService.Heartbeat:Connect(function()
					local e = (os.clock() - t0) / life
					if e >= 1 or not m.Parent then conn:Disconnect() m:Destroy() return end
					local ang = e * math.pi * 3 + i * 2.09
					m.Position = base + V3(math.cos(ang) * 2.6 * k, 1.2 + e * 5, math.sin(ang) * 2.6 * k)
					m.Transparency = e
				end)
			end
		end
	end
	if tier >= 4 then -- halo + embers
		local halo = C.part({ Shape = Enum.PartType.Cylinder, Color = C.GOLD_HI, Transparency = .2, Size = V3(.14, 2.6 * k, 2.6 * k), CFrame = CFrame.new(base + V3(0, 6 + k, 0)) * CFrame.Angles(0, 0, math.pi / 2) })
		C.tw(halo, 1.1, { Transparency = 1, CFrame = halo.CFrame + V3(0, 1.4, 0) }, Enum.EasingStyle.Sine)
		C.gone(halo, 1.2)
		local e = C.part({ Transparency = 1, Size = Vector3.one * .2, Position = base + V3(0, 1, 0) })
		C.emit(e, { texture = "rbxasset://textures/particles/fire_main.dds", c0 = gold, c1 = acc, n = 6, life = .9, speed = 6, size = 1.1, accel = V3(0, 4, 0), light = .6 })
		C.gone(e, 1.8)
	end
	if tier >= 5 then -- crown of spires
		for i = 1, 5 do
			local ang = i / 5 * math.pi * 2
			local sp = C.part({ Shape = Enum.PartType.Wedge, Color = gold:Lerp(cream, .2), Size = V3(.25, 2 + tier * .15, .6), CFrame = CFrame.new(base + V3(math.cos(ang) * 2.4, 0, math.sin(ang) * 2.4)) * CFrame.Angles(0, -ang + math.pi / 2, 0) })
			C.tw(sp, .35, { Position = sp.Position + V3(0, 2.2, 0) }, Enum.EasingStyle.Back)
			task.delay(.55 * C.slow, function() if sp.Parent then C.tw(sp, .4, { Transparency = 1 }) end end)
			C.gone(sp, 1.05)
		end
	end
	if tier >= 6 then
		decalSigil(base, gold, 11 * k, 1.1)
		if not still then
			for i = 1, 2 do -- two ribbons climbing
				local r = C.part({ Color = acc, Transparency = .3, Size = V3(.2, 3, .2), Position = base + V3(i == 1 and -1.6 or 1.6, 1, 0) })
				C.tw(r, .9, { Position = r.Position + V3(0, 9, 0), Transparency = 1 })
				C.gone(r, 1)
			end
		end
	end
	if tier >= 7 then
		if not still then
			for i = 0, 7 do
				local ray = C.part({ Color = C.GOLD_HI, Transparency = C.softAlpha(.2), Size = V3(.18, .18, 2), CFrame = CFrame.new(base + V3(0, 1.5, 0)) * CFrame.Angles(0, i * math.pi / 4, .35) * CFrame.new(0, 0, -1.5) })
				C.tw(ray, .5, { Transparency = 1, Size = V3(.04, .04, 9 + tier) })
				C.gone(ray, .55)
			end
		end
		task.delay(.25 * C.slow, function() flatRing(base, cream, 4, 18, .6, .4) end)
	end
	if tier >= 8 then
		local pil = C.part({ Shape = Enum.PartType.Cylinder, Color = cream, Transparency = C.softAlpha(.5), Size = V3(26, 2.2, 2.2), CFrame = CFrame.new(base + V3(0, 13, 0)) * CFrame.Angles(0, 0, math.pi / 2) })
		C.tw(pil, .9, { Transparency = 1, Size = V3(26, .3, .3) }, Enum.EasingStyle.Quint)
		C.gone(pil, 1)
		if not still then
			for i = 0, 3 do
				local ray = C.part({ Color = gold, Transparency = .25, Size = V3(.16, .16, 2), CFrame = CFrame.new(base + V3(0, 2, 0)) * CFrame.Angles(0, i * math.pi / 4 + math.pi / 8, .6) * CFrame.new(0, 0, -1.5) })
				C.tw(ray, .6, { Transparency = 1, Size = V3(.04, .04, 12) })
				C.gone(ray, .65)
			end
			local ash = C.part({ Transparency = 1, Size = Vector3.one * .2, Position = base + V3(0, 9, 0) })
			C.emit(ash, { c0 = C.GOLD_HI, c1 = C.INK, n = 14, life = 1.4, speed = 3, size = .4, accel = V3(0, -3, 0), light = .3 })
			C.gone(ash, 2.2)
		end
	end
end

-- Highlights are capped at 31 for the whole game (enemies use most): the wash only runs while there is room.
local function highlights() local n = 0 for _, d in workspace:GetDescendants() do if d:IsA("Highlight") then n += 1 end end return n end

function M.morph(model, color, tier)
	if not model or not model.Parent then return false end
	local ok = pcall(function()
		local hl
		if C.flashes and not C.still() and highlights() < 28 then
			hl = Instance.new("Highlight")
			hl.Name = "MorphWash"
			hl.Adornee, hl.FillColor, hl.FillTransparency, hl.OutlineTransparency = model, C.CREAM, .15, 1
			hl.DepthMode = Enum.HighlightDepthMode.Occluded
			hl.Parent = model
			C.tw(hl, .1, { FillTransparency = 1 })
			C.gone(hl, .12)
		end
		if not C.still() then
			local s0 = model:GetScale()
			model:ScaleTo(s0 * 1.14)
			local v = Instance.new("NumberValue")
			v.Value = s0 * 1.14
			v.Changed:Connect(function(x) if model.Parent then model:ScaleTo(x) end end)
			C.tw(v, .24, { Value = s0 }, Enum.EasingStyle.Back)
			C.gone(v, .3)
		end
	end)
	table.insert(M.log, { morph = ok, tier = tier })
	C.note(ok and "morph" or "morph_fail")
	return ok
end

return M
