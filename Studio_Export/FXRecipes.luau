--!nocheck
-- FXRecipes: the game's effect recipes on top of FlipbookFX. Every recipe has three beats (anticipation, hit, aftermath),
-- one hit-stop of 2 to 5 frames and one camera shake per impact, both scaled to importance. Colour and size come in one
-- call: FXRecipes.play(name, cframe, { color, scale, rarity }).
-- Art: particles use built-in textures through FlipbookFX (a ParticleEmitter cannot show an EditableImage, T18); flashes
-- and rings are FrameArt images on BillboardGuis (EditableImage works in UI), so nothing has to be uploaded yet.
-- Install as ReplicatedStorage.FXRecipes (HTTP pull from VFX/). Client side only.
--
--   local R = FXRecipes.new({ shake = function(amount) end, hitStop = function(frames) end, settings = SETTINGS })
--   R.play("merge", CFrame.new(pos), { color = tierColor, scale = 1.2 })
--   R.play("summonBurst", cf, { rarity = "Epic" })     -- violet -> gold -> white ramp by rarity
-- Recipes: placement, merge, enemyDefeat, familiarHit, summonBurst, ultimateImpact.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local FXRecipes = {}

-- violet -> gold -> white by rarity (Common .. Legendary), used when a recipe gets `rarity` instead of `color`
FXRecipes.RAMP = {
	Common = Color3.fromRGB(150, 110, 230),
	Rare = Color3.fromRGB(190, 120, 255),
	Epic = Color3.fromRGB(255, 196, 90),
	Legendary = Color3.fromRGB(255, 248, 230),
	Mythic = Color3.fromRGB(255, 130, 195), -- added 2026-10-29 with the Mythic and Celestial rarities
	Celestial = Color3.fromRGB(185, 250, 255),
}
FXRecipes.ORDER = { Common = 1, Rare = 2, Epic = 3, Legendary = 4, Mythic = 5, Celestial = 6 }

-- importance: hit-stop frames (at 60 fps) and shake amount, one of each per impact
FXRecipes.WEIGHT = {
	familiarHit = { stop = 2, shake = 0.05 },
	placement = { stop = 2, shake = 0.1 },
	enemyDefeat = { stop = 2, shake = 0.15 },
	merge = { stop = 3, shake = 0.25 },
	summonBurst = { stop = 3, shake = 0.4 }, -- +0..2 frames and more shake by rarity
	ultimateImpact = { stop = 5, shake = 1.0 },
}

function FXRecipes.new(deps)
	deps = deps or {}
	local F = deps.flipbook or require(ReplicatedStorage:WaitForChild("FlipbookFX"))
	local okFA, FA = pcall(function()
		return deps.frameArt or require(ReplicatedStorage:WaitForChild("FrameArt", 3))
	end)
	FA = okFA and FA or nil
	F.defineDefaults()
	local R = { log = {} }
	local tweens = setmetatable({}, { __mode = "k" })
	local function tw(inst, info, props)
		local t = TweenService:Create(inst, info, props)
		tweens[t] = true
		t:Play()
		return t
	end
	local function later(inst, t)
		task.delay(t, function()
			while F.frozen do
				task.wait(0.1)
			end
			inst:Destroy()
		end)
	end
	-- Freeze-frame for captures: pause every tween and emitter of ours, hold clean-up, then resume.
	function R.freeze(on)
		F.frozen = on
		for t in tweens do
			if on then
				t:Pause()
			elseif t.PlaybackState == Enum.PlaybackState.Paused then
				t:Play()
			end
		end
		for _, root in { workspace:FindFirstChild("FXRecipes"), workspace:FindFirstChild("FlipbookFX") } do
			for _, d in root and root:GetDescendants() or {} do
				if d:IsA("ParticleEmitter") then
					d.TimeScale = on and 0 or 1
				end
			end
		end
	end
	local settings = deps.settings or {}

	local folder = workspace:FindFirstChild("FXRecipes") or Instance.new("Folder")
	folder.Name = "FXRecipes"
	folder.Parent = workspace

	-- a flat, camera-facing FrameArt image in the world (glow or ring), grows and fades
	local function flare(cf, art, color, size0, size1, life, brightness)
		local anchor = Instance.new("Part")
		anchor.Anchored, anchor.CanCollide, anchor.CanQuery, anchor.CanTouch = true, false, false, false
		anchor.Transparency, anchor.Size, anchor.CFrame = 1, Vector3.one * 0.2, cf
		anchor.Parent = folder
		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.fromScale(size0, size0)
		bb.LightInfluence = 0
		-- lift the image so the ground does not cut it in half (AlwaysOnTop billboards did not draw in Studio tests)
		bb.StudsOffsetWorldSpace = Vector3.new(0, math.max(size0, size1) * 0.45, 0)
		bb.Brightness = brightness or 2
		bb.Adornee = anchor
		bb.Parent = anchor
		local img = Instance.new("ImageLabel")
		img.BackgroundTransparency = 1
		img.Size = UDim2.fromScale(1, 1)
		img.ImageColor3 = color
		if FA then
			img.ImageContent = art == "ring" and (FA.thinRing and FA.thinRing() or FA.ring()) or FA.glow()
		else
			img.Image = "rbxasset://textures/particles/sparkles_main.dds"
		end
		img.Parent = bb
		tw(bb, TweenInfo.new(life, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = UDim2.fromScale(size1, size1) })
		tw(img, TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { ImageTransparency = 1 })
		later(anchor, life + 0.1)
		return anchor
	end

	local function impact(name, extraStop, extraShake)
		local w = FXRecipes.WEIGHT[name]
		local frames = math.clamp(w.stop + (extraStop or 0), 2, 5)
		local shake = w.shake + (extraShake or 0)
		if settings.reducedMotion or settings.shake == false then
			shake = 0
		end
		if deps.hitStop then
			deps.hitStop(frames)
		end
		if deps.shake and shake > 0 then
			deps.shake(shake)
		end
		table.insert(R.log, { recipe = name, hitStop = frames, shake = shake })
		return frames
	end

	-- Beats: anticipation -> hit -> aftermath. `opts.onBeat(beat)` is called at each (tests freeze there).
	local function run(name, opts, ant, hit, after)
		local function beat(b)
			if opts.onBeat then
				opts.onBeat(b, name)
			end
		end
		task.spawn(function()
			beat("anticipation")
			ant()
			beat("hit")
			local frames = hit()
			task.wait(frames / 60) -- the hit-stop holds the world for these frames before the aftermath moves on
			beat("aftermath")
			after()
		end)
	end

	local recipes = {}

	recipes.placement = function(cf, color, k, opts)
		run("placement", opts, function()
			flare(cf * CFrame.new(0, 0.3, 0), "ring", color, 7 * k, 3 * k, 0.12, 1.5)
			task.wait(0.12)
		end, function()
			flare(cf * CFrame.new(0, 0.5, 0), "glow", color, 3 * k, 7 * k, 0.25)
			F.play("Sparkle", cf * CFrame.new(0, 0.5, 0), { scale = k, color = color })
			return impact("placement")
		end, function()
			F.play("Smoke", cf, { scale = 0.7 * k })
		end)
	end

	recipes.merge = function(cf, color, k, opts)
		run("merge", opts, function()
			for _, side in { -1, 1 } do -- two motes converge
				local p = Instance.new("Part")
				p.Anchored, p.CanCollide, p.CanQuery, p.Material = true, false, false, Enum.Material.Neon
				p.Shape, p.Color, p.Size = Enum.PartType.Ball, color, Vector3.one * 0.8 * k
				p.CFrame = cf * CFrame.new(3 * k * side, 1, 0)
				p.Parent = folder
				tw(p, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = cf * CFrame.new(0, 1, 0), Size = Vector3.one * 0.3 * k })
				later(p, 0.2)
			end
			task.wait(0.18)
		end, function()
			flare(cf * CFrame.new(0, 1, 0), "glow", color, 2 * k, 9 * k, 0.3, 3)
			flare(cf * CFrame.new(0, 0.2, 0), "ring", color, 2 * k, 12 * k, 0.45)
			F.play("Ember", cf * CFrame.new(0, 1, 0), { scale = k, color = color })
			return impact("merge")
		end, function()
			F.play("Sparkle", cf * CFrame.new(0, 2.5, 0), { scale = 0.8 * k, color = color })
		end)
	end

	recipes.enemyDefeat = function(cf, color, k, opts)
		run("enemyDefeat", opts, function()
			flare(cf, "glow", Color3.new(1, 1, 1), 2 * k, 3 * k, 0.06, 4)
			task.wait(0.06)
		end, function()
			F.play("Smoke", cf, { scale = k })
			F.play("Ember", cf, { scale = 0.8 * k, color = color })
			return impact("enemyDefeat")
		end, function()
			F.play("Sparkle", cf * CFrame.new(0, 1.5, 0), { scale = 0.6 * k, color = Color3.fromRGB(255, 208, 96) }) -- coin glint
		end)
	end

	recipes.familiarHit = function(cf, color, k, opts)
		run("familiarHit", opts, function()
			task.wait(0.03)
		end, function()
			flare(cf, "glow", color, 1.5 * k, 3 * k, 0.15, 2)
			F.play("Sparkle", cf, { scale = 0.5 * k, color = color })
			return impact("familiarHit")
		end, function() end)
	end

	recipes.summonBurst = function(cf, color, k, opts)
		local order = FXRecipes.ORDER[opts.rarity or "Common"] or 1
		run("summonBurst", opts, function()
			local charge = flare(cf * CFrame.new(0, 1, 0), "glow", color, 1 * k, 4 * k * order, 0.15 * order, 2)
			task.wait(0.15 * order) -- longer charge for rarer results
		end, function()
			flare(cf * CFrame.new(0, 1, 0), "glow", color, 4 * k, (8 + 4 * order) * k, 0.4, 3)
			flare(cf * CFrame.new(0, 0.2, 0), "ring", color, 3 * k, (10 + 5 * order) * k, 0.5)
			F.play("Ember", cf * CFrame.new(0, 1, 0), { scale = (0.8 + 0.2 * order) * k, color = color })
			return impact("summonBurst", order - 1 >= 2 and 2 or order - 1, 0.15 * (order - 1))
		end, function()
			for i = 1, order do
				task.delay(0.08 * i, function()
					F.play("Sparkle", cf * CFrame.new(math.cos(i * 2.4) * 2 * k, 1.5 + i * 0.3, math.sin(i * 2.4) * 2 * k), { scale = 0.6 * k, color = color })
				end)
			end
		end)
	end

	recipes.ultimateImpact = function(cf, color, k, opts)
		run("ultimateImpact", opts, function()
			flare(cf * CFrame.new(0, 2, 0), "ring", color, 18 * k, 2 * k, 0.35, 2) -- energy pulls in
			task.wait(0.35)
		end, function()
			flare(cf * CFrame.new(0, 2, 0), "glow", Color3.new(1, 1, 1), 4 * k, 20 * k, 0.5, 4)
			flare(cf * CFrame.new(0, 0.3, 0), "ring", color, 4 * k, 28 * k, 0.7)
			F.play("Ember", cf * CFrame.new(0, 1, 0), { scale = 2 * k, color = color })
			F.play("Smoke", cf, { scale = 2 * k })
			return impact("ultimateImpact")
		end, function()
			flare(cf * CFrame.new(0, 1, 0), "glow", color, 10 * k, 12 * k, 1.0, 1)
		end)
	end

	function R.play(name, cf, opts)
		opts = opts or {}
		local fn = recipes[name]
		if not fn then
			warn("FXRecipes: unknown recipe " .. tostring(name))
			return
		end
		local color = opts.color or FXRecipes.RAMP[opts.rarity or "Rare"]
		fn(cf, color, opts.scale or 1, opts)
	end

	-- Ported recipes (T30): layer numbers from Yuruzuu's open-source effects (YuruzuuPorts, credit in VFX/ASSETS.md),
	-- our textures. Each original layer streams for 0.35 s at its own rate, like the source emitters.
	local okP, Ports = pcall(function() return require(ReplicatedStorage:WaitForChild("YuruzuuPorts", 3)) end)
	if okP and Ports then
		for key, layers in Ports do
			local spec = { layers = {} }
			for _, l in layers do
				-- Arrow Rain repeats its rig per arrow; keep only its busier layers so 3 drops stay under the T26 emitter cap
				if key == "ArrowRain" and (l.rate or 0) < 20 then
					continue
				end
				local copy = table.clone(l)
				copy.emitDuration = 0.35
				copy.emitCount = math.max(1, math.floor((l.rate or 10) * 0.35 + 0.5))
				table.insert(spec.layers, copy)
			end
			F.define("YZ_" .. key, spec)
		end
	end

	-- Hollow Purple as the orb ultimate: a violet orb gathers, then the ported layers burst at the target.
	recipes.hollowPurple = function(cf, color, k, opts)
		run("ultimateImpact", opts, function()
			flare(cf * CFrame.new(0, 2, 0), "glow", Color3.fromRGB(170, 90, 255), 2 * k, 9 * k, 0.4, 3)
			task.wait(0.4)
		end, function()
			F.play("YZ_HollowPurple", cf * CFrame.new(0, 2, 0), { scale = k })
			return impact("ultimateImpact")
		end, function()
			flare(cf * CFrame.new(0, 1, 0), "glow", Color3.fromRGB(150, 80, 255), 8 * k, 10 * k, 0.8, 1)
		end)
	end

	-- Healing: green shards, plus signs and specks rise from the familiar.
	recipes.healing = function(cf, color, k, opts)
		run("familiarHit", opts, function()
			task.wait(0.05)
		end, function()
			F.play("YZ_Healing", cf, { scale = k })
			return impact("familiarHit")
		end, function() end)
	end

	-- Arrow Rain (projectile rain): the ported arrow-and-impact layers land at random points over the area.
	recipes.arrowRain = function(cf, color, k, opts)
		run("merge", opts, function()
			flare(cf * CFrame.new(0, 0.3, 0), "ring", Color3.fromRGB(255, 220, 140), 14 * k, 12 * k, 0.3, 1.5)
			task.wait(0.3)
		end, function()
			for i = 1, 3 do
				task.delay(0.12 * i, function()
					local off = Vector3.new(math.cos(i * 2.4) * 4 * k, 0, math.sin(i * 2.4) * 4 * k)
					F.play("YZ_ArrowRain", cf + off, { scale = 0.6 * k })
				end)
			end
			return impact("merge")
		end, function() end)
	end

	R.names = { "placement", "merge", "enemyDefeat", "familiarHit", "summonBurst", "ultimateImpact", "hollowPurple", "healing", "arrowRain" }
	return R
end

return FXRecipes
