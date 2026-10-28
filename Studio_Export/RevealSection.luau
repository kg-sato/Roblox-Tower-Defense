--!nocheck
-- Full-screen summon: the orrery (four rings caught = rarity), the reveal card and the hand-off to the world.
-- Split out of GameClient (T14), same method as UltFX: GameClient builds the ctx table, this returns what it needs.
-- ctx: new, label, round, tween, fadeLabel, setLabelVisible, STYLE, UI, FXK, Config, Models, burst, ring, pillar, groundOf,
--      screenFlash, flushBanners, shake, pending, setPet, camera, gui, snap() (latest snapshot), quick(), auto()
-- returns { gui, queue, running(), playRoll(slot, pet, rarity) }

return function(ctx)
	local new, label, round, tween, fadeLabel, setLabelVisible = ctx.new, ctx.label, ctx.round, ctx.tween, ctx.fadeLabel, ctx.setLabelVisible
	local STYLE, UI, FXK, Config, Models = ctx.STYLE, ctx.UI, ctx.FXK, ctx.Config, ctx.Models
	local burst, ring, pillar, groundOf, screenFlash, flushBanners = ctx.burst, ctx.ring, ctx.pillar, ctx.groundOf, ctx.screenFlash, ctx.flushBanners
	local shake, pending, setPet, camera, gui = ctx.shake, ctx.pending, ctx.setPet, ctx.camera, ctx.gui
	local TweenService, RunService, Debris = game:GetService("TweenService"), game:GetService("RunService"), game:GetService("Debris")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local revealGui = new("Frame", { Name = "Reveal", BackgroundColor3 = Color3.fromRGB(6, 7, 18), BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, ZIndex = 15, Active = true }, gui)
	local revealGlow = new("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1.5, 1.5), SizeConstraint = Enum.SizeConstraint.RelativeYY, ZIndex = 15 }, revealGui)
	new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, revealGlow)
	local rays = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(10, 10), ZIndex = 16 }, revealGui)
	local rayBars = {}
	for i = 1, 8 do
		local bar = new("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.72, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(i % 2 == 0 and 44 or 22, 3000), Rotation = (i - 1) * (180 / 8), BorderSizePixel = 0, ZIndex = 16 }, rays)
		new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.2), NumberSequenceKeypoint.new(1, 1) }) }, bar)
		rayBars[i] = bar
	end
	rays.Visible = false
	local vpf = new("ViewportFrame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 17, Ambient = Color3.fromRGB(170, 170, 190), LightColor = Color3.new(1, 1, 1), LightDirection = Vector3.new(-0.4, -1, -0.6) }, revealGui)
	local vcam = new("Camera", { FieldOfView = 45, CFrame = CFrame.lookAt(Vector3.new(0, 3.2, 12.5), Vector3.new(0, 2.6, 0)) }, vpf)
	vpf.CurrentCamera = vcam
	local revealTitle = label(revealGui, "", 64, STYLE.gold, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.13), UDim2.fromOffset(900, 80))
	revealTitle.ZIndex = 20
	-- name, odds and hint sit nearer the familiar, clear of the ROLL button (UI Quality Bar gap 2)
	local revealName = label(revealGui, "", 40, STYLE.text, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.77), UDim2.fromOffset(900, 52))
	revealName.ZIndex = 20
	local revealOdds = label(revealGui, "", 22, STYLE.muted, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.82), UDim2.fromOffset(900, 30), STYLE.fontB)
	revealOdds.ZIndex = 20
	local revealHint = label(revealGui, "Tap to continue", 18, STYLE.muted, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.865), UDim2.fromOffset(400, 26), STYLE.fontB)
	revealHint.ZIndex = 20
	for _, l in { revealTitle, revealName, revealOdds, revealHint } do
		setLabelVisible(l, false)
	end
	if UI.fa then
		-- soft painted glow instead of a hard-edged disc: the old frame keeps driving colour and fade, the image shows it
		UI.mirror(revealGlow, UI.fa.glow())
		-- Magic circle instead of sunburst rays (Sol's RNG-style staging: darkness, fog, then a rotating sign).
		-- It lives inside `rays`, so the existing show/hide and spin logic drives it.
		for _, bar in rayBars do
			bar.Visible = false
		end
		local sig = new("ImageLabel", { Name = "Sigil", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(560, 560), ImageTransparency = 1, ZIndex = 16 }, rays)
		local sigScale = new("UIScale", { Scale = 0.6 }, sig)
		rays:GetPropertyChangedSignal("Visible"):Connect(function()
			if rays.Visible then
				sig.ImageContent = UI.fa.sigil() -- painted on the first reveal (FrameArt caches it), not at load
				local d = math.floor(camera.ViewportSize.Y * 0.78)
				sig.Size = UDim2.fromOffset(d, d)
				sig.ImageColor3 = revealGlow.BackgroundColor3:Lerp(Color3.new(1, 1, 1), 0.2)
				sig.ImageTransparency = 1
				sigScale.Scale = 0.6
				tween(sig, 0.6, { ImageTransparency = 0.12 })
				tween(sigScale, 0.8, { Scale = 1 }, Enum.EasingStyle.Quint)
			end
		end)
		-- slow drifting fog behind everything while a reveal is open
		for i = 1, 3 do
			local fog = new("ImageLabel", { Name = "Fog", BackgroundTransparency = 1, ImageContent = UI.fa.glow(), ImageColor3 = Color3.fromRGB(120, 100, 170), ImageTransparency = 0.82, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.2 + i * 0.25, 0.35 + (i % 2) * 0.3), Size = UDim2.fromScale(0.9, 0.7), ZIndex = 15 }, revealGui)
			TweenService:Create(fog, TweenInfo.new(7 + i * 2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Position = UDim2.fromScale(0.8 - i * 0.2, 0.65 - (i % 2) * 0.3) }):Play()
		end
		-- shockwave ring for the burst (replaces most of the hard white flash)
		function FXK.shock(color)
			local ring = new("ImageLabel", { BackgroundTransparency = 1, ImageContent = UI.fa.ring(), ImageColor3 = color:Lerp(Color3.new(1, 1, 1), 0.4), ImageTransparency = 0.05, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(80, 80), ZIndex = 19 }, revealGui)
			local d = camera.ViewportSize.Y * 1.6
			tween(ring, 0.65, { Size = UDim2.fromOffset(d, d), ImageTransparency = 1 }, Enum.EasingStyle.Quint)
			Debris:AddItem(ring, 0.7)
		end
		for _, l in { revealTitle, revealName } do
			l:SetAttribute("KeepFont", true)
			l.FontFace = UI.TITLE_FONT
		end
		UI.motes(revealGui, STYLE.gold, 12)
		UI.blurHolders[revealGui] = true
	end
	local revealState = { phase = "idle", skip = false, dismiss = false }
	local revealQueue = {}
	local revealRunning = false

	revealGui.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if revealState.phase == "anim" then
				revealState.skip = true
			elseif revealState.phase == "hold" then
				revealState.dismiss = true
			end
		end
	end)

	local timeScale = 1

	local function animate(duration, fn)
		duration *= timeScale
		local start = os.clock()
		while true do
			local a = revealState.skip and 1 or math.clamp((os.clock() - start) / duration, 0, 1)
			fn(a)
			if a >= 1 then
				break
			end
			RunService.RenderStepped:Wait()
		end
	end

	local function ease(a, style, dir)
		return TweenService:GetValue(a, style, dir)
	end

	local function sparkBurst(color, count, far)
		for i = 1, count do
			local size = math.random(8, 22)
			local spark = new("Frame", {
				BackgroundColor3 = math.random() < 0.3 and Color3.new(1, 1, 1) or color, AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(size, size), Rotation = math.random(0, 90), ZIndex = 19,
			}, revealGui)
			round(spark, 3)
			local a = math.random() * math.pi * 2
			local d = far * (0.4 + math.random() * 0.6)
			tween(spark, 0.7 + math.random() * 0.4, {
				Position = UDim2.new(0.5, math.cos(a) * d, 0.5, math.sin(a) * d * 0.7), BackgroundTransparency = 1,
				Size = UDim2.fromOffset(2, 2), Rotation = math.random(-200, 200),
			})
			Debris:AddItem(spark, 1.3)
		end
	end

	-- Rarity accents in the world after the familiar lands (T20). All local to this player:
	-- Rare+ a loot beam (taller and wider by rarity) and a small aura on the familiar (ZOffset 1 so it draws in front);
	-- Epic+ keeps the aura; Legendary adds a ground ring and sigil. Shared moments are the server's job (SharedSummon).
	local okTD, TD = pcall(function() return require(ReplicatedStorage:WaitForChild("TDFeedback", 2)) end)
	TD = okTD and TD or nil
	local function accents(slot, rarity)
		local rdef = Config.RARITIES[rarity]
		local order, color = rdef.order, rdef.color
		if order < 2 then
			return
		end
		local pos = groundOf(slot)
		local h, w = 6 + 7 * order, 0.8 + 0.5 * order
		local beam = new("Part", { Shape = Enum.PartType.Cylinder, Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Material = Enum.Material.Neon, Color = color, Transparency = 0.25, Size = Vector3.new(h, w, w), CFrame = CFrame.new(pos + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)) }, workspace)
		beam.Name = "LootBeam"
		local life = 0.5 + 0.5 * order
		TweenService:Create(beam, TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Transparency = 1, Size = Vector3.new(h, w * 0.3, w * 0.3) }):Play()
		Debris:AddItem(beam, life + 0.1)
		local model = ctx.petModel and ctx.petModel(slot)
		local root = model and (model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true))
		if root then
			local pe = Instance.new("ParticleEmitter")
			pe.Name = "RarityAura"
			pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			pe.Color = ColorSequence.new(color)
			pe.LightEmission, pe.LightInfluence, pe.ZOffset = 1, 0, 1
			pe.Size = NumberSequence.new(0.5 + 0.15 * order, 0)
			pe.Lifetime = NumberRange.new(1, 1.4)
			pe.Rate = 2 * order
			pe.Speed = NumberRange.new(0.5, 1.5)
			pe.SpreadAngle = Vector2.new(180, 180)
			pe.LockedToPart = true
			pe.Parent = root -- moves with the familiar and goes away with its model
			if order == 2 then
				Debris:AddItem(pe, 4) -- Rare: a short shimmer only
			end
		end
		if order >= 4 and TD then
			TD.splash(pos, 14, color)
			TD.placement(pos, color)
		end
	end

	local function placePet(slot, pet, rarity)
		pending[slot] = nil
		local info = ctx.snap() and ctx.snap().grid[tostring(slot)]
		if not info then
			return -- deleted before it finished
		end
		local order = Config.RARITIES[rarity].order
		setPet(slot, pet, info.tier, true)
		accents(slot, rarity)
		local rcolor = Config.RARITIES[rarity].color
		burst(groundOf(slot) + Vector3.new(0, 2, 0), rcolor, 8 + order * 10, 14 + order * 5)
		ring(groundOf(slot), rcolor, 8 + order * 5, 0.5 + order * 0.1)
		if order >= 3 then
			pillar(groundOf(slot), rcolor, 0.9)
		end
	end

	local function runReveal(job)
		local pet, rarity, slot = job.pet, job.rarity, job.slot
		local rdef = Config.RARITIES[rarity]
		local order, rcolor = rdef.order, rdef.color
		revealState.skip, revealState.dismiss, revealState.phase = false, false, "anim"

		revealGui.Visible = true
		revealGui.BackgroundTransparency = 1
		tween(revealGui, 0.2, { BackgroundTransparency = 0.12 })
		revealGlow.BackgroundColor3 = Color3.fromRGB(60, 64, 96)
		revealGlow.BackgroundTransparency = 0.8
		rays.Visible = false
		for _, l in { revealTitle, revealName, revealOdds, revealHint } do
			setLabelVisible(l, false)
		end

		-- ===== THE ORRERY (our summon; no competitor uses one) =====
		-- Four brass gimbal rings spin around a dark glass core. One by one they slow and lock with a clack.
		-- A ring that catches lights up in the next rarity's colour; the first ring that fails goes dark and
		-- drops away, and the rest drop with it. Rings caught = rarity (Common 1 ... Legendary 4).
		local spin = TweenService:Create(rays, TweenInfo.new(10, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), { Rotation = 360 })
		local orr, rings, core, fill = Models.buildOrrery()
		orr.Parent = vpf
		local CENTER = CFrame.new(0, 2.6, 0)
		local axes = { Vector3.new(1, 0.2, 0).Unit, Vector3.new(0, 1, 0.3).Unit, Vector3.new(0.6, 0.8, 0).Unit, Vector3.new(0.2, 0.4, 1).Unit }
		local ang = { 0.4, 1.3, 2.2, 3.1 }
		local speed = { 9, -11, 13, -15 }
		local locked, dropped = {}, {}
		local orrScale = 0.3
		local function poseRings(dt)
			for i, r in rings do
				if dropped[i] then
					continue
				end
				if not locked[i] then
					ang[i] += speed[i] * dt
				end
				r:PivotTo(CENTER * CFrame.fromAxisAngle(axes[i], ang[i]))
			end
			core.CFrame = CENTER
			fill.CFrame = CENTER
		end
		local last = os.clock()
		local function tick()
			local now = os.clock()
			local dt = math.min(now - last, 0.05) / math.max(timeScale, 0.01)
			last = now
			poseRings(dt)
		end
		local function setRingColor(r, color, neon)
			for _, p in r:GetChildren() do
				if p:IsA("BasePart") then
					p.Color = color
					p.Material = neon and Enum.Material.Neon or Enum.Material.Metal
				end
			end
		end
		orr:ScaleTo(orrScale)
		FXK.play("wish_pull")
		-- 1. it forms out of the fog, spinning fast
		animate(0.45, function(a)
			local s = 0.3 + 0.7 * ease(a, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			orr:ScaleTo(s)
			tick()
		end)
		animate(0.35, function()
			tick()
		end)
		-- 2. lock the rings one by one
		local failed = false
		for i = 1, 4 do
			local catches = i <= order
			local r = rings[i]
			if catches then
				-- decelerate to the nearest full turn, with a little overshoot, then clack
				local from = ang[i]
				local target = math.ceil(from / (math.pi * 2) + 0.35) * math.pi * 2
				locked[i] = true
				if i >= 2 then
					FXK.play("anticipation", { pitch = 0.9 + i * 0.08 })
				end
				animate(0.32 + i * 0.06, function(a)
					ang[i] = from + (target - from) * ease(a, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
					tick()
				end)
				ang[i] = target
				local tierColor = Config.RARITIES[Config.RARITY_ORDER[i]].color
				setRingColor(r, tierColor, true)
				FXK.play("ring", { pitch = 0.8 + i * 0.12 })
				fill.Color = tierColor:Lerp(Color3.new(1, 1, 1), 0.35)
				fill.Size = Vector3.one * (0.5 + i * 0.4)
				revealGlow.BackgroundColor3 = tierColor
				revealGlow.BackgroundTransparency = 0.85 - 0.08 * i
				shake.t, shake.amp = 0.12, 0.3 * i
				sparkBurst(tierColor, 4 + i * 3, 160 + i * 40)
				-- hold a beat: will the next ring catch?
				animate(i < 4 and (0.18 + i * 0.05) or 0.1, function()
					tick()
				end)
			else
				failed = true
				break
			end
		end
		if failed then
			-- the remaining rings stall, go dark and drop out of frame together
			local falling = {}
			for i = order + 1, 4 do
				setRingColor(rings[i], Color3.fromRGB(70, 60, 50), false)
				table.insert(falling, i)
			end
			local base = {}
			for _, i in falling do
				base[i] = rings[i]:GetPivot()
				dropped[i] = true
			end
			animate(0.35, function(a)
				for k, i in falling do
					rings[i]:PivotTo(base[i] * CFrame.new(0, -a * a * (9 + k * 2), 0) * CFrame.Angles(a * 1.5, 0, a * k))
				end
				tick()
			end)
			for _, i in falling do
				rings[i]:Destroy()
			end
		else
			-- all four caught: the orrery hums and the core swells (legendary)
			FXK.play("legendary_gather")
			spin:Play()
			animate(0.7, function(a)
				fill.Size = Vector3.one * (2.1 + a * 0.5 + math.sin(a * 40) * 0.08)
				revealGlow.BackgroundTransparency = 0.5 - 0.25 * a
				tick()
			end)
		end
		-- 3. the core cracks; the caught rings expand into a halo and fade
		FXK.play("summon")
		local haloBase = {}
		for i, r in rings do
			if r.Parent and not dropped[i] then
				haloBase[i] = r
			end
		end
		core:Destroy()
		fill:Destroy()
		task.spawn(function()
			animate(0.5, function(a)
				for i, r in haloBase do
					if r.Parent then
						r:ScaleTo(math.max(0.05, 1 + a * 1.4))
						for _, p in r:GetChildren() do
							if p:IsA("BasePart") then
								p.Transparency = a
							end
						end
					end
				end
			end)
			orr:Destroy()
		end)

		-- burst: flash, sparks, the familiar pops in
		FXK.play(({ "common", "rare", "epic", "legendary_burst" })[order])
		-- softer flash; the shockwave ring carries the impact now
		screenFlash(Color3.new(1, 1, 1), order >= 4 and 0.55 or (order >= 3 and 0.4 or 0.2))
		if FXK.shock then
			FXK.shock(rcolor)
		end
		sparkBurst(rcolor, 14 + order * 10, 380 + order * 90)
		revealGlow.BackgroundColor3 = rcolor
		revealGlow.BackgroundTransparency = 0.5 - order * 0.05
		-- (the orrery halo replaces the old magic-circle backdrop)
		shake.t, shake.amp = 0.35, 0.8 * order

		local model = Models.buildPet(pet, 1)
		-- the flat neon rarity disc looks cheap in the reveal; the magic circle does that job here
		if model:FindFirstChild("AuraRing") then
			model.AuraRing:Destroy()
		end
		model.Parent = vpf
		local function placePetVp(scale, yaw)
			model:ScaleTo(math.max(0.05, scale * 0.78))
			model:PivotTo(CFrame.new(0, 0, 0) * CFrame.Angles(0, math.pi + yaw, 0))
		end
		revealState.skip = false
		animate(0.45, function(a) placePetVp(1.5 * ease(a, Enum.EasingStyle.Back, Enum.EasingDirection.Out), 0) end)

		local sizes = { 38, 46, 58, 72 }
		revealTitle.Text = rarity:upper()
		revealTitle.TextColor3 = rcolor
		revealTitle.TextSize = sizes[order]
		revealName.Text = Config.PETS[pet].name
		local pct = Config.rarityPercents(ctx.snap() and ctx.snap().luck or 0)[rarity] / #Config.petsOfRarity(rarity)
		revealOdds.Text = string.format("1 in %d", math.max(1, math.floor(100 / pct + 0.5)))
		for _, l in { revealTitle, revealName, revealOdds } do
			setLabelVisible(l, true)
		end
		setLabelVisible(revealHint, order >= 3)
		revealState.phase = "hold"
		local holdUntil = os.clock() + ({ 0.7, 1.0, 1.6, 2.4 })[order] * timeScale
		local t0 = os.clock()
		while not revealState.dismiss and (os.clock() < holdUntil or order >= 4 and os.clock() - t0 < 1.0) do
			placePetVp(1.5, math.sin((os.clock() - t0) * 2) * 0.35)
			RunService.RenderStepped:Wait()
		end

		-- close and let the pet land on its pad in the world
		revealState.phase = "idle"
		for _, l in { revealTitle, revealName, revealOdds, revealHint } do
			fadeLabel(l, 0.2)
		end
		tween(revealGui, 0.25, { BackgroundTransparency = 1 })
		tween(revealGlow, 0.25, { BackgroundTransparency = 1 })
		task.wait(0.25)
		spin:Cancel()
		rays.Rotation = 0
		rays.Visible = false
		model:Destroy()
		revealGui.Visible = false
		placePet(slot, pet, rarity)
	end

	local function pumpReveals()
		if revealRunning then
			return
		end
		revealRunning = true
		task.spawn(function()
			while #revealQueue > 0 do
				local job = table.remove(revealQueue, 1)
				local ok, err = pcall(runReveal, job)
				if not ok then
					warn("reveal failed: " .. tostring(err))
					revealGui.Visible = false
					for _, ch in vpf:GetChildren() do
						if ch:IsA("Model") then ch:Destroy() end
					end
					placePet(job.slot, job.pet, job.rarity)
				end
			end
			revealRunning = false
			flushBanners()
		end)
	end

	local function playRoll(slot, pet, rarity)
		local order = Config.RARITIES[rarity].order
		pending[slot] = true
		if (ctx.quick() or ctx.auto()) and order <= 2 then
			task.delay(0.1, placePet, slot, pet, rarity)
			return
		end
		table.insert(revealQueue, { slot = slot, pet = pet, rarity = rarity })
		pumpReveals()
	end

	-- QA hook (Studio only): replay any rarity's hatch, slowed down, without rolling.
	if RunService:IsStudio() then
		local debugEvent = Instance.new("BindableEvent")
		debugEvent.Name = "DebugReveal"
		debugEvent.Parent = ReplicatedStorage
		debugEvent.Event:Connect(function(rarity, scale, slot)
			timeScale = scale or 1
			local ids = Config.petsOfRarity(rarity)
			table.insert(revealQueue, { slot = slot or 1, pet = ids[#ids], rarity = rarity })
			pending[slot or 1] = nil
			pumpReveals()
		end)
	end


	return { gui = revealGui, queue = revealQueue, running = function() return revealRunning end, playRoll = playRoll }
end
