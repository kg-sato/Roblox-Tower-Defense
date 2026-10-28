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
	-- 2026-10-28 night (the user: "the rolling animation needs a lot of work"): the summon is staged in our world. A
	-- painted Lampwick Lane night sits behind it, a brass clock ring turns behind the card and takes each rarity colour
	-- as the tell climbs, the card's back is a pocket watch, and at the end the familiar flies down to its pad as a
	-- streak of light instead of the screen fading out.
	local okArt, ART = pcall(function() return require(ReplicatedStorage:WaitForChild("ArtIds", 3)) end)
	ART = okArt and ART or {}
	local scene = new("ImageLabel", { Name = "Scene", BackgroundTransparency = 1, Image = ART.road_lane or "", ImageColor3 = Color3.fromRGB(150, 160, 200), ImageTransparency = 0.35, ScaleType = Enum.ScaleType.Crop, Size = UDim2.fromScale(1, 1), ZIndex = 15 }, revealGui)
	local shade = new("Frame", { Name = "SceneShade", BackgroundColor3 = Color3.fromRGB(4, 5, 12), BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 15 }, revealGui)
	new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(0.5, 0.75), NumberSequenceKeypoint.new(1, 0.15) }) }, shade)
	local clockRing = new("ImageLabel", { Name = "ClockRing", BackgroundTransparency = 1, Image = ART.ring or "", ImageColor3 = Color3.fromRGB(220, 180, 120), ImageTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.46), Size = UDim2.fromScale(0.62, 0.62), SizeConstraint = Enum.SizeConstraint.RelativeYY, ZIndex = 16 }, revealGui)
	local ringSpin = TweenService:Create(clockRing, TweenInfo.new(24, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), { Rotation = 360 })
	ringSpin:Play()
	local revealState = { phase = "idle", skip = false, dismiss = false }
	local revealQueue = {}
	local revealRunning = false

	revealGui.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if revealState.phase == "anim" then
				revealState.skip = true
			elseif revealState.phase == "hold" or revealState.phase == "turn" then -- "turn": the player turns the card
				revealState.dismiss = true
			end
		end
	end)

	local timeScale = 1
	task.spawn(function() -- the Reading's card art must be ready before the first draw (it showed blank on the first reveal)
		pcall(function() game:GetService("ContentProvider"):PreloadAsync({ "rbxassetid://93758813189086", "rbxassetid://78270426727572", "rbxassetid://128142388272489", "rbxassetid://140628629392455" }) end)
	end)

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
		scene.ImageTransparency, shade.BackgroundTransparency = 1, 1
		tween(scene, 0.35, { ImageTransparency = 0.35 })
		tween(shade, 0.35, { BackgroundTransparency = 0 })
		clockRing.ImageColor3, clockRing.ImageTransparency, clockRing.Size = Color3.fromRGB(220, 180, 120), 1, UDim2.fromScale(0.4, 0.4)
		tween(clockRing, 0.5, { ImageTransparency = 0.25, Size = UDim2.fromScale(0.62, 0.62) }, Enum.EasingStyle.Quint)
		revealGlow.BackgroundColor3 = Color3.fromRGB(60, 64, 96)
		revealGlow.BackgroundTransparency = 0.8
		rays.Visible = false
		for _, l in { revealTitle, revealName, revealOdds, revealHint } do
			setLabelVisible(l, false)
		end

		-- ===== THE READING (2026-10-28, replaces the orrery; user: "rolling animation still too generic") =====
		-- From the summon study (Roblox Dev/Research/VFX and Animation/Summon References): a seated first-person view of a
		-- fortune-teller's table; a tarot card is drawn and lands face down over a chalk circle; its rim climbs the rarity
		-- colours one tier at a time (the "tell", like FGO's gold card and Genshin's meteor colour); Epic and above wait for
		-- the player to turn the card (Hearthstone's flip) and the card shatters; then hero cuts on the familiar.
		local TAROT, RINGTEX = "rbxassetid://93758813189086", "rbxassetid://78270426727572"
		local spin = TweenService:Create(rays, TweenInfo.new(10, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), { Rotation = 360 })
		local stageM = Instance.new("Model")
		stageM.Name = "Reading"
		stageM.Parent = vpf
		local function vp(props)
			local p = Instance.new("Part")
			p.Anchored, p.CanCollide, p.CastShadow = true, false, false
			for k, v in props do
				p[k] = v
			end
			p.Parent = stageM
			return p
		end
		-- abstract (2026-10-28, "everything abstract"): no tablecloth and no candles; the card is an abstract plate: the
		-- af Klint spiral on its back, the vesica (two circles meeting) on its face, tinted with the rarity
		local SPIRAL, VESICA = "rbxassetid://128142388272489", "rbxassetid://140628629392455"
		local circle = vp({ Size = Vector3.new(6.5, 0.02, 6.5), Transparency = 1, CFrame = CFrame.new(0, 0.02, 0) })
		local chalk = Instance.new("Decal")
		chalk.Texture, chalk.Face, chalk.Color3, chalk.Transparency = ART.ring or RINGTEX, Enum.NormalId.Top, Color3.fromRGB(255, 214, 140), 0.15 -- a brass clock ring on the table
		chalk.Parent = circle
		for _, x in {} do -- (removed 2026-10-28 night: the two candle points read as stray dots beside the card)
			vp({ Shape = Enum.PartType.Ball, Size = Vector3.new(0.35, 0.35, 0.35), Color = Color3.fromRGB(255, 190, 90), Material = Enum.Material.Neon, CFrame = CFrame.new(x, 1.6, -1.2) })
		end
		local card = vp({ Size = Vector3.new(2.4, 4, 0.06), Color = Color3.fromRGB(30, 16, 50), Material = Enum.Material.SmoothPlastic })
		local back = Instance.new("Decal")
		back.Texture, back.Face, back.Color3 = ART.clock or SPIRAL, Enum.NormalId.Back, ART.clock and Color3.new(1, 1, 1) or Color3.fromRGB(255, 214, 130) -- the card's back: a pocket watch
		back.Parent = card
		local front = Instance.new("Decal")
		front.Texture, front.Face, front.Color3 = VESICA, Enum.NormalId.Front, rcolor:Lerp(Color3.new(1, 1, 1), 0.3)
		front.Parent = card
		local rim = vp({ Size = Vector3.new(2.75, 4.35, 0.03), Material = Enum.Material.Neon, Color = Color3.new(1, 1, 1), Transparency = 0.6 })
		local HOME = CFrame.new(0, 2.6, 0)
		local function poseCard(cf)
			card.CFrame = cf
			rim.CFrame = cf.Rotation + cf.Position + Vector3.new(0, 0, -0.06) -- always on the far side, even after the flip
		end
		vcam.CFrame = CFrame.lookAt(Vector3.new(0, 4.4, 9.5), Vector3.new(0, 2.1, 0)) -- seated at the table
		FXK.play("wish_pull")
		-- 1. draw: the card arcs up from the deck below the frame and lands face down over the circle
		animate(0.5, function(a)
			local e = ease(a, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			poseCard(CFrame.new(0, -3.4 + 6 * e, 6 * (1 - e)) * CFrame.Angles(math.rad(-75 * (1 - e)), 0, math.rad(-14 * (1 - e))))
		end)
		-- 2. the tell: the rim climbs the tiers, each step a clack, a pulse and a harder tremble
		for i = 1, order do
			local tierColor = Config.RARITIES[Config.RARITY_ORDER[i]].color
			if i >= 2 then
				FXK.play("anticipation", { pitch = 0.9 + i * 0.08 })
			end
			FXK.play("ring", { pitch = 0.8 + i * 0.12 })
			rim.Color = tierColor
			rim.Transparency = 0.1
			tween(clockRing, 0.25, { ImageColor3 = tierColor:Lerp(Color3.fromRGB(220, 180, 120), 0.35), ImageTransparency = 0.15 - i * 0.03 })
			clockRing.Size = UDim2.fromScale(0.66, 0.66)
			tween(clockRing, 0.3, { Size = UDim2.fromScale(0.62, 0.62) }, Enum.EasingStyle.Back)
			revealGlow.BackgroundColor3 = tierColor
			revealGlow.BackgroundTransparency = 0.85 - 0.08 * i
			shake.t, shake.amp = 0.12, 0.3 * i
			sparkBurst(tierColor, 4 + i * 3, 160 + i * 40)
			animate(0.2 + i * 0.12, function(a)
				local tr = 0.035 * i * (1 - a * 0.3)
				poseCard(HOME * CFrame.new(math.sin(a * 70) * tr, math.sin(a * math.pi) * 0.12, 0) * CFrame.Angles(0, 0, math.sin(a * 55) * tr * 0.6))
			end)
		end
		-- 3. turn the card: Epic and above wait for the player (up to 2.5 s); the rest turn by themselves
		if order >= 3 and not ctx.quick() then
			revealHint.Text = "Tap to turn the card"
			setLabelVisible(revealHint, true)
			revealState.phase, revealState.dismiss = "turn", false
			local w0 = os.clock()
			while not revealState.dismiss and os.clock() - w0 < 1.2 do -- (review: a long wait read as dead time)
				local a = os.clock() - w0
				poseCard(HOME * CFrame.new(math.sin(a * 60) * 0.05, math.sin(a * 3) * 0.1, 0))
				RunService.RenderStepped:Wait()
			end
			revealState.dismiss, revealState.phase = false, "anim"
			setLabelVisible(revealHint, false)
			revealHint.Text = "Tap to continue"
		end
		FXK.play("summon")
		animate(0.3, function(a)
			poseCard(HOME * CFrame.Angles(0, math.pi * ease(a, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), 0))
		end)
		if order >= 3 then
			-- the card shatters: shards of the face fly out in the rarity colour
			card.Transparency, back.Transparency, front.Transparency, rim.Transparency = 1, 1, 1, 1
			local shards = {}
			for k = 1, 12 do
				local s = vp({ Size = Vector3.new(0.5 + math.random() * 0.5, 0.7 + math.random() * 0.7, 0.05), Material = Enum.Material.Neon, Color = k % 3 == 0 and Color3.new(1, 1, 1) or rcolor, CFrame = HOME * CFrame.new((math.random() - 0.5) * 2, (math.random() - 0.5) * 3.4, 0) })
				local dir = (s.Position - HOME.Position + Vector3.new(0, 0, 1.5)).Unit
				shards[k] = { s, s.CFrame, dir, Vector3.new(math.random(), math.random(), math.random()) * 8 }
			end
			task.spawn(function()
				animate(0.6, function(a)
					for _, sh in shards do
						sh[1].CFrame = sh[2] + sh[3] * (a * 9) + Vector3.new(0, -a * a * 4, 0)
						sh[1].CFrame *= CFrame.Angles(sh[4].X * a, sh[4].Y * a, sh[4].Z * a)
						sh[1].Transparency = a
					end
				end)
				stageM:Destroy()
			end)
		else
			task.spawn(function()
				animate(0.35, function(a)
					card.Transparency, rim.Transparency = a, 0.1 + a * 0.9
					back.Transparency, front.Transparency = a, a
				end)
				stageM:Destroy()
			end)
		end
		vcam.CFrame = CFrame.lookAt(Vector3.new(0, 3.2, 12.5), Vector3.new(0, 2.6, 0))
		if order >= 4 then
			spin:Play()
		end

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
		if order >= 4 and not ctx.quick() and not (ctx.cineLite and ctx.cineLite()) then
			-- ===== LEGENDARY: manga cinematic (2026-10-28). The user sent a "manga animated" edit (Tokyo Ghoul, Arima):
			-- iridescent flash into a white page, a drifting title wiped by a vivid butterfly, slow push-ins on ink panels,
			-- a back view in a field of red spider lilies framed by red brush arcs with a line of text, a white flash to
			-- the hand reaching for the butterfly, a hard cut to black. Ours: the moth drawn to the lamp (Lampwick Lane).
			local MOTH, ARC, DOT = "rbxassetid://86247178900555", "rbxassetid://80931642223090", "rbxassetid://74135098013493"
			local _, msize = model:GetBoundingBox()
			local h = msize.Y
			local WIDE = vcam.CFrame
			local saved = { vpf.Ambient, vpf.LightColor, vpf.LightDirection }
			local page = new("Frame", { Name = "Page", BackgroundColor3 = Color3.fromRGB(248, 245, 238), BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 16 }, revealGui)
			local tone = new("ImageLabel", { BackgroundTransparency = 1, Image = DOT, ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.fromOffset(9, 9), ImageColor3 = Color3.fromRGB(40, 36, 40), ImageTransparency = 0.9, Size = UDim2.fromScale(1, 1), ZIndex = 18 }, revealGui)
			local iris = new("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 21 }, revealGui)
			new("UIGradient", { Rotation = 25, Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 140, 220)), ColorSequenceKeypoint.new(0.35, Color3.fromRGB(150, 220, 255)), ColorSequenceKeypoint.new(0.7, Color3.fromRGB(255, 240, 200)), ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 150, 255)) }) }, iris)
			-- abstract pass (2026-10-28): the moth is an ink point with two line wings that open and close (no moth art)
			local INK = Color3.fromRGB(40, 36, 40)
			local moth = new("Frame", { Name = "AF_moth", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(110, 58), ZIndex = 20, Visible = false }, revealGui)
			local body = new("Frame", { BackgroundColor3 = INK, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(12, 12), ZIndex = 21 }, moth)
			new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, body)
			local wings = {}
			for i, sgn in { -1, 1 } do -- each wing is a line on one half of a pivot frame, so rotating the pivot swings it from the body
				local pivot = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(96, 3), ZIndex = 20 }, moth)
				new("Frame", { BackgroundColor3 = INK, BorderSizePixel = 0, Position = UDim2.fromScale(sgn > 0 and 0.5 or 0, 0), Size = UDim2.fromScale(0.5, 1), ZIndex = 20 }, pivot)
				wings[i] = pivot
			end
			local function wingbeat(open) -- open 0..1: 0 = wings folded up, 1 = spread flat
				wings[1].Rotation = 70 * (1 - open)
				wings[2].Rotation = -70 * (1 - open)
			end
			-- echo trail: three fainter copies replay where the moth was 2, 4 and 6 frames ago (a drawn smear / motion blur)
			local echoes, hist = {}, {}
			for k = 1, 3 do
				local g = moth:Clone()
				for _, d in g:GetDescendants() do
					if d:IsA("Frame") and d.BackgroundTransparency < 1 then d.BackgroundTransparency = 0.45 + k * 0.15; d.ZIndex = 19 end
				end
				g.Name, g.Parent = "AF_mothEcho", revealGui
				echoes[k] = g
			end
			local function echo(show)
				for k, g in echoes do
					local h = hist[#hist - k * 2]
					g.Visible = show and h ~= nil
					if h then
						g.Position, g.Rotation = h[1], h[2]
						local piv = {}
						for _, c in g:GetChildren() do if c.Size.Y.Offset == 3 then table.insert(piv, c) end end
						if piv[1] then piv[1].Rotation, piv[2].Rotation = h[3], -h[3] end
					end
				end
			end
			local line = label(revealGui, "", 84, Color3.fromRGB(70, 58, 56), Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.45), UDim2.fromOffset(1100, 110))
			line.ZIndex = 19
			line.TextScaled = false
			line.TextStroke.Transparency = 1
			vpf.Ambient, vpf.LightColor, vpf.LightDirection = Color3.fromRGB(215, 210, 210), Color3.fromRGB(255, 250, 240), Vector3.new(-0.2, -1, -0.3)
			model.Parent = nil -- hidden during the title page
			local function mothPath(p0, p1, t, wobble)
				moth.Visible = true
				animate(t, function(a)
					local e = ease(a, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
					moth.Position = UDim2.fromScale(p0.X + (p1.X - p0.X) * e, p0.Y + (p1.Y - p0.Y) * e + math.sin(a * 9) * wobble)
					wingbeat(math.abs(math.cos(a * 22)))
					moth.Rotation = math.sin(a * 13) * 8 -- no heading tilt: it turned the line-wing V lopsided
					table.insert(hist, { moth.Position, moth.Rotation, wings[1].Rotation })
					echo(true)
				end)
				table.clear(hist)
				echo(false)
			end
			-- 1. iridescent flash into the white page; the name drifts in
			FXK.play("summon")
			line.Text = string.upper(Config.PETS[pet].name)
			line.TextTransparency = 1
			tween(iris, 0.6, { BackgroundTransparency = 1 })
			tween(line, 0.8, { TextTransparency = 0.05 })
			tween(line, 2.4, { Position = UDim2.fromScale(0.53, 0.45) }, Enum.EasingStyle.Linear)
			task.wait(0.6)
			-- 2. the moth crosses the page and wipes the name
			task.delay(0.55, function() tween(line, 0.35, { TextTransparency = 1 }) end)
			mothPath(Vector2.new(1.08, 0.62), Vector2.new(-0.08, 0.36), 1.4, 0.03)
			moth.Visible = false
			-- 3. close panel: slow push-in on the face, screentone, gold sparks
			model.Parent = vpf
			placePetVp(1.5, 0.15)
			local face0 = CFrame.lookAt(Vector3.new(0.4, h * 0.85, h * 2.1), Vector3.new(0, h * 0.72, 0)) -- head and shoulders, not wings filling the frame
			sparkBurst(Color3.fromRGB(255, 205, 110), 10, 260)
			animate(1.5, function(a)
				vcam.CFrame = face0 * CFrame.new(0, 0, -0.5 * a)
				placePetVp(1.5, 0.15)
			end)
			-- 4. back view in a field of red spider lilies, red brush arcs, one line of text
			screenFlash(Color3.new(1, 1, 1), 0.5)
			local field = Instance.new("Model")
			field.Parent = vpf
			local rng = Random.new(11)
			for i = 1, 55 do
				local c = Vector3.new(rng:NextNumber(-9, 9), 0, rng:NextNumber(-12, 2))
				for k = 0, 5 do
					local a = k / 6 * math.pi * 2
					local p = Instance.new("Part")
					p.Anchored, p.Material, p.Color = true, Enum.Material.Neon, Color3.fromRGB(215, 30, 45)
					p.Size = Vector3.new(0.08, 0.08, 0.7)
					p.CFrame = CFrame.lookAt(c + Vector3.new(0, 0.55, 0), c + Vector3.new(math.cos(a), 1.1, math.sin(a)))
					p.Parent = field
				end
			end
			local arcs = {}
			for i, spec in { { 0.18, 0.2, -30 }, { 0.82, 0.24, 30 } } do
				arcs[i] = new("ImageLabel", { BackgroundTransparency = 1, Image = ARC, ImageColor3 = Color3.fromRGB(225, 60, 60), ImageTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(spec[1], spec[2]), Size = UDim2.fromOffset(300, 300), Rotation = 180 + spec[3], ZIndex = 19 }, revealGui)
				tween(arcs[i], 0.5, { ImageTransparency = 0.15 })
				tween(arcs[i], 1.9, { Position = UDim2.fromScale(spec[1] + (i == 1 and -0.03 or 0.03), spec[2] - 0.02) }, Enum.EasingStyle.Linear)
			end
			line.Text = "...the lamp has a new keeper."
			line.TextSize = 46
			line.Position = UDim2.fromScale(0.5, 0.2)
			tween(line, 0.6, { TextTransparency = 0.05 })
			local back0 = CFrame.lookAt(Vector3.new(0.8, h * 0.9, h * 1.9), Vector3.new(0, h * 0.7, -h * 6)) -- behind the familiar, looking past it over the lilies
			animate(1.9, function(a)
				vcam.CFrame = back0 * CFrame.new(0, a * 0.3, 0.6 * a)
				placePetVp(1.5, math.pi)
			end)
			-- 5. white flash: the familiar turns, the moth lands beside it
			screenFlash(Color3.new(1, 1, 1), 0.7)
			tween(line, 0.2, { TextTransparency = 1 })
			for _, a in arcs do a:Destroy() end
			local front0 = CFrame.lookAt(Vector3.new(h * 0.9, h * 0.75, h * 1.8), Vector3.new(0, h * 0.6, 0))
			task.spawn(function() mothPath(Vector2.new(0.95, 0.15), Vector2.new(0.6, 0.42), 1.1, 0.02) end)
			animate(1.3, function(a)
				vcam.CFrame = front0 * CFrame.new(-0.4 * a, 0, -0.3 * a)
				placePetVp(1.5, 0.35)
			end)
			-- 6. hard cut to black, then the usual title card
			page.BackgroundColor3 = Color3.new(0, 0, 0)
			moth.Visible, line.Visible, tone.Visible = false, false, false
			model.Parent = nil
			field.Parent = nil
			page.ZIndex = 22 -- above the viewport for the black beat
			task.wait(0.3)
			field:Destroy()
			for _, g in { page, tone, iris, moth, line, echoes[1], echoes[2], echoes[3] } do g:Destroy() end
			model.Parent = vpf
			vpf.Ambient, vpf.LightColor, vpf.LightDirection = saved[1], saved[2], saved[3]
			vcam.CFrame = WIDE
			screenFlash(Color3.fromRGB(255, 220, 140), 0.5)
		end
		if order == 3 and not ctx.quick() and not (ctx.cineLite and ctx.cineLite()) then
			-- hero cuts: face, low angle, side; each pushes in a little, white flash between (Anime Vanguards intro)
			local _, size = model:GetBoundingBox()
			local h = size.Y
			local WIDE = vcam.CFrame
			for _, cut in {
				{ Vector3.new(0.6, h * 0.8, h * 1.5), Vector3.new(0, h * 0.72, 0) },
				{ Vector3.new(-h * 0.9, h * 0.15, h * 1.4), Vector3.new(0, h * 0.4, 0) },
				{ Vector3.new(h * 1.6, h * 0.6, h * 0.6), Vector3.new(0, h * 0.55, 0) },
			} do
				screenFlash(Color3.new(1, 1, 1), 0.35)
				FXK.play("ring", { pitch = 1.3 })
				local cf = CFrame.lookAt(cut[1], cut[2])
				animate(0.3, function(a)
					vcam.CFrame = cf * CFrame.new(0, 0, -0.35 * a)
					placePetVp(1.5, 0)
				end)
			end
			screenFlash(Color3.new(1, 1, 1), 0.45)
			vcam.CFrame = WIDE
		end

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

		-- close: the familiar becomes a streak of light that flies down to its pad, while the summon scene fades away
		revealState.phase = "idle"
		for _, l in { revealTitle, revealName, revealOdds, revealHint } do
			fadeLabel(l, 0.2)
		end
		local okP, pad = pcall(function() local v, on = camera:WorldToViewportPoint(groundOf(slot)) return on and Vector2.new(v.X, v.Y) or nil end)
		local vs = camera.ViewportSize
		local comet = new("ImageLabel", { BackgroundTransparency = 1, Image = ART.glow or "", ImageColor3 = rcolor:Lerp(Color3.new(1, 1, 1), 0.5), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(160, 160), ZIndex = 22 }, revealGui.Parent)
		local tail = new("Frame", { BackgroundColor3 = rcolor:Lerp(Color3.new(1, 1, 1), 0.6), BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.fromOffset(0, 4), ZIndex = 22 }, comet)
		new("UIGradient", { Transparency = NumberSequence.new(0, 1) }, tail)
		local to = (okP and pad) and UDim2.fromOffset(pad.X, pad.Y) or UDim2.fromScale(0.5, 0.9)
		local dir = ((okP and pad) or Vector2.new(vs.X / 2, vs.Y * 0.9)) - vs / 2
		tail.Position, tail.Rotation = UDim2.fromScale(0.5, 0.5), math.deg(math.atan2(-dir.Y, -dir.X))
		tween(vcam, 0.25, { CFrame = vcam.CFrame * CFrame.new(0, 0, 6) }) -- the familiar shrinks away
		tween(scene, 0.3, { ImageTransparency = 1 })
		tween(shade, 0.3, { BackgroundTransparency = 1 })
		tween(clockRing, 0.3, { ImageTransparency = 1, Size = UDim2.fromScale(0.3, 0.3) })
		tween(revealGui, 0.3, { BackgroundTransparency = 1 })
		tween(revealGlow, 0.25, { BackgroundTransparency = 1 })
		tween(tail, 0.2, { Size = UDim2.fromOffset(math.min(260, dir.Magnitude), 4) })
		tween(comet, 0.42, { Position = to, Size = UDim2.fromOffset(60, 60) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.delay(0.42, function() tween(comet, 0.2, { ImageTransparency = 1, Size = UDim2.fromOffset(140, 140) }); Debris:AddItem(comet, 0.25) end)
		task.wait(0.4)
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
