--!nocheck
-- ActionCuts (2026-10-28): the per-action cutscenes (defeat, upgrade maxed, farewell, stage clear, streak broken, boss
-- arrival, level up, start-wave bell). Split out of GameClient when it reached Roblox's 200,000-character script limit.
-- GameClient: require(script.Parent.ActionCuts)(env) after the world exists; the functions land on FXK.
return function(env)
	local FXK, SETTINGS, Config, Path, GROUND, camera = env.FXK, env.SETTINGS, env.Config, env.Path, env.GROUND, env.camera
	local enemies, petParts, groundOf, STYLE, floatText, rarityColor = env.enemies, env.petParts, env.groundOf, env.STYLE, env.floatText, env.rarityColor
	local TweenService, RunService = game:GetService("TweenService"), game:GetService("RunService")
	local new = env.new

-- DEFEAT cutscene "Lamps Out" (2026-10-28) for Overrun and Boss Escaped: from beside the crystal looking up the lane,
-- the street lamps go out one by one from the gate toward you, the crystal flickers and dims, the caption says what was
-- lost; then the lamps relight from the crystal outward (you keep going). 2.6 s. None at 2x or with Reduced Motion.
do
	function FXK.darkCut(caption)
		if not FXK.cut or FXK.cineOff() or FXK.cineShort() or FXK.busy() or not env.crystal() then return end
		local K = FXK.cut.kit
		local cctx = { gameCamera = function() return FXK.gameCF or camera.CFrame end, setCamera = function(cf) FXK.camOverride = cf end, settings = SETTINGS }
		local stageF = K.stage()
		local ov = K.overlay()
		ov.open(0.14)
		local cam = K.camera(cctx)
		local cc = Instance.new("ColorCorrectionEffect")
		cc.Name, cc.Parent = "CutsceneGrade", game:GetService("Lighting")
		TweenService:Create(cc, TweenInfo.new(1.2), { Brightness = -0.15, Saturation = -0.6, TintColor = Color3.fromRGB(200, 205, 255) }):Play()
		local cp = env.crystal().Position
		local gate = Path.positionAt(0)
		local lamps = {}
		for _, d in workspace:GetDescendants() do
			if d:IsA("PointLight") and d.Parent:IsA("BasePart") and d.Parent.Parent and d.Parent.Parent.Name == "Street" then
				table.insert(lamps, { l = d, b = d.Brightness, c = d.Parent.Color, m = d.Parent.Material })
			end
		end
		table.sort(lamps, function(x, y) return (x.l.Parent.Position - gate).Magnitude < (y.l.Parent.Position - gate).Magnitude end)
		local look = Vector3.new(gate.X, GROUND + 2, gate.Z)
		local away = (Vector3.new(cp.X, 0, cp.Z) - Vector3.new(gate.X, 0, gate.Z)).Unit
		-- in front of the crystal on the lane side, looking up the street (v1 sat behind the crystal's canopy)
		cam.to(CFrame.lookAt(cp - away * 9 + Vector3.new(0, 5, 0), look), 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		FXK.play("anticipation", { pitch = 0.45 })
		task.spawn(function()
			for i, L in lamps do -- darkness creeps down the street toward the crystal
				task.delay(0.25 + i * 0.09, function()
					TweenService:Create(L.l, TweenInfo.new(0.12), { Brightness = 0 }):Play()
					L.l.Parent.Color = Color3.fromRGB(40, 36, 44)
					L.l.Parent.Material = Enum.Material.SmoothPlastic
				end)
			end
			task.wait(0.3 + #lamps * 0.09)
			-- the crystal flickers
			local base = env.crystal().Transparency
			for k = 1, 4 do
				env.crystal().Transparency = 0.6
				task.wait(0.05)
				env.crystal().Transparency = base
				task.wait(0.07)
			end
			K.caption(ov, caption, Color3.fromRGB(255, 150, 150))
			FXK.play("ultimate_fall", { pitch = 0.6 })
			cam.to(CFrame.lookAt(cp - away * 6 + Vector3.new(0, 4, 0), look), 0.9, Enum.EasingStyle.Sine)
			task.wait(0.7)
			-- relight from the crystal outward
			FXK.play("load_resolve", { pitch = 0.9 })
			for i = #lamps, 1, -1 do
				local L = lamps[i]
				task.delay((#lamps - i) * 0.04, function()
					if L.l.Parent then
						L.l.Parent.Color, L.l.Parent.Material = L.c, L.m
						TweenService:Create(L.l, TweenInfo.new(0.2), { Brightness = L.b }):Play()
					end
				end)
			end
			TweenService:Create(cc, TweenInfo.new(0.5), { Brightness = 0, Saturation = 0, TintColor = Color3.new(1, 1, 1) }):Play()
			task.wait(0.4)
			ov.close()
			cam.done(0.4)
			task.wait(0.6)
			cc:Destroy()
			stageF:Destroy()
		end)
	end
end

-- UPGRADE MAXED "Ascension" (2026-10-28): when an upgrade reaches its last level, the camera pushes in on that
-- familiar, gold chevrons climb a light column around it, it rises a little and settles with a ring. 1.6 s.
-- FAREWELL (recycle) (2026-10-28): releasing an Epic+ or tier 3+ familiar: close shot, it floats up turning, dissolves
-- into a shower of gold coins that pour into the purse. 1.6 s. Lower familiars keep the quick burst.
do
	local function canCut()
		return FXK.cut and not FXK.cineOff() and not FXK.cineShort() and not FXK.busy()
	end
	local function shot(pos, dist)
		local K = FXK.cut.kit
		local cctx = { gameCamera = function() return FXK.gameCF or camera.CFrame end, setCamera = function(cf) FXK.camOverride = cf end, settings = SETTINGS }
		local stageF = K.stage()
		local ov = K.overlay()
		ov.open(0.09)
		local cam = K.camera(cctx)
		local side = Vector3.new(1, 0, 0.6).Unit
		cam.to(CFrame.lookAt(pos + side * dist + Vector3.new(0, dist * 0.45, 0), pos + Vector3.new(0, 2.5, 0)), 0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		return K, cctx, stageF, ov, cam, side
	end
	local function ball(parent, pos, color, size)
		local m = Instance.new("Part")
		m.Shape, m.Anchored, m.CanCollide, m.CanQuery, m.Material = Enum.PartType.Ball, true, false, false, Enum.Material.Neon
		m.Color, m.Size, m.Position, m.Parent = color, Vector3.one * size, pos, parent
		return m
	end
	function FXK.maxCut(data)
		if not canCut() then return end
		local slot, entry
		for sl, e in petParts do
			if e.pet == data.pet then slot, entry = sl, e break end
		end
		if not entry then return end
		local g = groundOf(slot)
		local K, cctx, stageF, ov, cam, side = shot(g, 11)
		local GOLD = STYLE.gold
		FXK.play("legendary_gather")
		task.spawn(function()
			task.wait(0.3)
			if FXK.td then FXK.td.upgrade(g, GOLD, 2) end -- tier 4 column blew out white under bloom
			for k = 1, 5 do -- chevrons climb
				task.delay(k * 0.1, function()
					local c = Instance.new("Part")
					c.Anchored, c.CanCollide, c.CanQuery, c.Material, c.Color = true, false, false, Enum.Material.Neon, GOLD
					c.Size = Vector3.new(1.6, 0.25, 0.25)
					c.CFrame = CFrame.new(g + Vector3.new(0, 1, 0)) * CFrame.Angles(0, 0, math.rad(35))
					c.Parent = stageF
					local c2 = c:Clone()
					c2.CFrame = CFrame.new(g + Vector3.new(0, 1, 0)) * CFrame.Angles(0, 0, math.rad(-35))
					c2.Parent = stageF
					for _, x in { c, c2 } do
						TweenService:Create(x, TweenInfo.new(0.7, Enum.EasingStyle.Quad), { CFrame = x.CFrame + Vector3.new(0, 7, 0), Transparency = 1 }):Play()
					end
					FXK.play("ring", { pitch = 1 + k * 0.08 })
				end)
			end
			entry.kick = 5
			K.caption(ov, "[ " .. string.upper(tostring(data.kind)) .. " MASTERED ]", Color3.fromRGB(255, 230, 160))
			FXK.play("milestone")
			cam.to(CFrame.lookAt(g + side * 8 + Vector3.new(0, 3, 0), g + Vector3.new(0, 3, 0)), 0.8, Enum.EasingStyle.Sine)
			task.wait(0.8)
			K.shockwave(stageF, g, GOLD, 9, 0.4)
			cam.shake(0.3, 0.2)
			task.wait(0.25)
			ov.close()
			cam.done(0.35)
			task.wait(0.6)
			stageF:Destroy()
		end)
	end
	function FXK.recycleCut(data)
		local entry = petParts[data.slot]
		if not entry or not canCut() then return false end
		local rar = Config.PETS[entry.pet] and Config.RARITIES[Config.PETS[entry.pet].rarity]
		if not ((rar and rar.order >= 3) or (entry.tier or 1) >= 3) then return false end
		petParts[data.slot] = nil
		local model = entry.model
		local g = groundOf(data.slot)
		local K, cctx, stageF, ov, cam, side = shot(g, 10)
		local color = rarityColor(entry.pet)
		FXK.play("anticipation", { pitch = 1.2 })
		K.caption(ov, "[ FAREWELL, " .. string.upper(Config.PETS[entry.pet].name) .. " ]", Color3.fromRGB(235, 225, 255))
		FXK.play("echo", { pitch = 0.8 })
		task.spawn(function()
			local base = model:GetPivot()
			local t0 = os.clock()
			while os.clock() - t0 < 0.9 do -- it rises, turning, and fades
				local k = (os.clock() - t0) / 0.9
				model:PivotTo(base * CFrame.new(0, 3 * k, 0) * CFrame.Angles(0, k * 4, 0))
				for _, d in model:GetDescendants() do
					if d:IsA("BasePart") then d.LocalTransparencyModifier = k * k end
				end
				if math.random() < 0.4 then
					local m = ball(stageF, model:GetPivot().Position + Vector3.new(math.random() * 2 - 1, math.random() * 2, math.random() * 2 - 1), color, 0.25)
					TweenService:Create(m, TweenInfo.new(0.6), { Position = m.Position + Vector3.new(0, 3, 0), Transparency = 1 }):Play()
				end
				RunService.RenderStepped:Wait()
			end
			local top = model:GetPivot().Position
			model:Destroy()
			-- coin shower
			for k = 1, 14 do
				local c = Instance.new("Part")
				c.Shape, c.Anchored, c.CanCollide, c.CanQuery, c.Material = Enum.PartType.Cylinder, true, false, false, Enum.Material.Metal
				c.Color, c.Reflectance, c.Size = STYLE.gold, 0.3, Vector3.new(0.15, 0.8, 0.8)
				c.CFrame = CFrame.new(top) * CFrame.Angles(math.random() * 6, math.random() * 6, 0)
				c.Parent = stageF
				local to = g + Vector3.new(math.random() * 6 - 3, 0.2, math.random() * 6 - 3)
				TweenService:Create(c, TweenInfo.new(0.5 + math.random() * 0.2, Enum.EasingStyle.Bounce), { CFrame = CFrame.new(to) * CFrame.Angles(0, 0, math.pi / 2) }):Play()
			end
			FXK.play("ring", { pitch = 1.4 })
			K.flash(ov, cctx, color, 0.3, 0.2)
			floatText(g + Vector3.new(0, 4, 0), "+" .. data.coins, STYLE.gold, 24)
			task.wait(0.55)
			ov.close()
			cam.done(0.35)
			task.wait(0.6)
			stageF:Destroy()
		end)
		return true
	end
end

-- STAGE CLEAR cutscene "Victory Round" (2026-10-28): only for big clears (a boss stage, or every 5th perfect stage in a
-- streak) so it stays special. The camera circles the board low; the familiars hop in turn; gold motes rise off them;
-- the street lamps warm to gold; a caption names the feat. 2.2 s. None at 2x or with Reduced Motion.
-- STREAK BROKEN cutscene (2026-10-28): when a leak breaks a streak of 3 or more, a 1.3 s snap to the crystal: the
-- intruder strikes, the crystal cracks red, the world drains of colour, "[ STREAK x7 LOST ]". None at 2x / Reduced Motion.
do
	local function canCut()
		return FXK.cut and not FXK.cineOff() and not FXK.cineShort() and not FXK.busy()
	end
	local function boardCenter()
		local sum, n = Vector3.zero, 0
		for slot in petParts do
			sum += groundOf(slot)
			n += 1
		end
		return n > 0 and sum / n or Vector3.new(0, GROUND, 5)
	end
	function FXK.clearCut(data)
		local boss = Config.isBossStage(data.stage)
		local milestone = data.perfect and (data.combo or 0) > 0 and data.combo % 5 == 0
		if not canCut() or not (boss or milestone) then return end
		local K = FXK.cut.kit
		local cctx = { gameCamera = function() return FXK.gameCF or camera.CFrame end, setCamera = function(cf) FXK.camOverride = cf end, settings = SETTINGS }
		local stageF = K.stage()
		local ov = K.overlay()
		ov.open(0.1)
		local cam = K.camera(cctx)
		local GOLD = Color3.fromRGB(255, 205, 110)
		local c = boardCenter()
		local lamps = {}
		for _, d in workspace:GetDescendants() do
			if d:IsA("PointLight") and d.Parent:IsA("BasePart") and d.Parent.Parent and d.Parent.Parent.Name == "Street" then
				lamps[d] = { d.Color, d.Brightness }
				TweenService:Create(d, TweenInfo.new(0.5), { Color = GOLD, Brightness = d.Brightness * 2 }):Play()
			end
		end
		FXK.play("legendary_gather")
		K.caption(ov, boss and "[ BOSS DEFEATED ]" or ("[ PERFECT  x" .. data.combo .. " ]"), Color3.fromRGB(255, 230, 170))
		FXK.play(boss and "legendary_burst" or "milestone")
		local i = 0
		for slot, entry in petParts do
			i += 1
			task.delay(0.15 + i * 0.12, function()
				entry.kick = 4 -- the familiar's own hop (about 1.4 studs)
				local g = groundOf(slot)
				for k = 1, 6 do
					local m = Instance.new("Part")
					m.Shape, m.Anchored, m.CanCollide, m.CanQuery, m.Material = Enum.PartType.Ball, true, false, false, Enum.Material.Neon
					m.Color, m.Size = GOLD, Vector3.one * 0.35
					m.Position = g + Vector3.new(math.random() * 3 - 1.5, 1, math.random() * 3 - 1.5)
					m.Parent = stageF
					TweenService:Create(m, TweenInfo.new(1.2, Enum.EasingStyle.Sine), { Position = m.Position + Vector3.new(0, 8 + math.random() * 4, 0), Transparency = 1 }):Play()
				end
				FXK.play("ring", { pitch = 1.1 + i * 0.05 })
			end)
		end
		task.spawn(function()
			local t0, T = os.clock(), 1.8
			while os.clock() - t0 < T do
				local k = (os.clock() - t0) / T
				local a = math.rad(-60 + 100 * k)
				local pos = c + Vector3.new(math.sin(a) * 26, 13 - 3 * k, math.cos(a) * 26) -- higher: v1 sat below the familiars' pads
				cam.to(CFrame.lookAt(pos, c + Vector3.new(0, 2.5, 0)), 0)
				RunService.RenderStepped:Wait()
			end
			for l, v in lamps do
				if l.Parent then TweenService:Create(l, TweenInfo.new(0.6), { Color = v[1], Brightness = v[2] }):Play() end
			end
			ov.close()
			cam.done(0.45)
			task.wait(1.2)
			stageF:Destroy()
		end)
	end
	function FXK.leakCut(data)
		local streak = env.snap() and env.snap().combo or 0
		if RunService:IsStudio() and workspace:GetAttribute("QAStreak") then streak = workspace:GetAttribute("QAStreak") end -- Studio QA only
		if not canCut() or data.streakKept ~= false or streak < 3 or not env.crystal() then return end
		local K = FXK.cut.kit
		local cctx = { gameCamera = function() return FXK.gameCF or camera.CFrame end, setCamera = function(cf) FXK.camOverride = cf end, settings = SETTINGS }
		local stageF = K.stage()
		local ov = K.overlay()
		ov.open(0.14)
		local cam = K.camera(cctx)
		local cc = Instance.new("ColorCorrectionEffect")
		cc.Name, cc.Parent = "CutsceneGrade", game:GetService("Lighting")
		TweenService:Create(cc, TweenInfo.new(0.25), { Saturation = -0.85, Contrast = 0.2, TintColor = Color3.fromRGB(255, 200, 200) }):Play()
		local cp = env.crystal().Position
		local last = Config.PATH[#Config.PATH]
		local from = Vector3.new(last.X, GROUND, last.Z)
		local dir = (Vector3.new(cp.X, GROUND, cp.Z) - from)
		dir = dir.Magnitude > 0.1 and dir.Unit or Vector3.new(0, 0, 1)
		local side = dir:Cross(Vector3.yAxis)
		-- snap to a low shot past the crystal toward the street the intruder came from
		cam.to(CFrame.lookAt(cp + dir * 15 + side * 5 + Vector3.new(0, 3.5, 0), cp + Vector3.new(0, 1.5, 0)), 0) -- v1 at 9 studs the crystal filled the frame
		FXK.play("anticipation", { pitch = 0.5 })
		task.spawn(function()
			task.wait(0.25)
			-- the strike: red flash, cracks, shake
			K.flash(ov, cctx, Color3.fromRGB(255, 40, 40), 0.45, 0.25)
			FXK.play("merge_fail", { pitch = 0.6 })
			cam.shake(1.2, 0.4)
			env.hitCrystal()
			for k = 1, 7 do
				local a = k / 7 * math.pi * 2
				local crack = Instance.new("Part")
				crack.Anchored, crack.CanCollide, crack.CanQuery, crack.Material = true, false, false, Enum.Material.Neon
				crack.Color, crack.Size = Color3.fromRGB(255, 50, 60), Vector3.new(0.12, 0.12, 0.1)
				local d = Vector3.new(math.cos(a), math.sin(a) * 0.8, 0.3).Unit
				crack.CFrame = CFrame.lookAt(cp, cp + d)
				crack.Parent = stageF
				local len = 2.5 + math.random() * 1.5
				TweenService:Create(crack, TweenInfo.new(0.15, Enum.EasingStyle.Quint), { Size = Vector3.new(0.12, 0.12, len), CFrame = CFrame.lookAt(cp + d * len / 2, cp + d * len) }):Play()
			end
			K.shockwave(stageF, Vector3.new(cp.X, GROUND, cp.Z), Color3.fromRGB(255, 60, 60), 12, 0.5)
			K.caption(ov, "[ STREAK x" .. streak .. " LOST ]", Color3.fromRGB(255, 140, 140))
			FXK.play("ultimate_fall", { pitch = 0.7 })
			cam.to(CFrame.lookAt(cp + dir * 19 + side * 7 + Vector3.new(0, 5, 0), cp + Vector3.new(0, 1.5, 0)), 0.8, Enum.EasingStyle.Sine)
			task.wait(0.85)
			TweenService:Create(cc, TweenInfo.new(0.4), { Saturation = 0, Contrast = 0, TintColor = Color3.new(1, 1, 1) }):Play()
			ov.close()
			cam.done(0.35)
			task.wait(0.5)
			cc:Destroy()
			stageF:Destroy()
		end)
	end
end

-- BOSS ARRIVAL cutscene (2026-10-28): the gate darkens, red fog and a ring of red light burst from the ground, the camera
-- sits low on the cobbles looking up as the boss strides out, slow dolly in, red grade, the boss's title in the
-- letterbox, a heavy step shakes the frame. 2.6 s, every boss; none with Reduced Motion. At 2x a 1.3 s cut.
do
	local TITLES = { "THE GASLIGHT WARDEN", "THE BRASS LEVIATHAN", "THE HOLLOW BISHOP" }
	function FXK.bossCut(data)
		if not FXK.cut or FXK.cineOff() then return end
		local short = FXK.cineShort()
		if not FXK.waitFree(3) then return end -- after the bell or a reveal, not on top of them
		local e = enemies[data.id]
		if not e then return end
		local K = FXK.cut.kit
		local cctx = { gameCamera = function() return FXK.gameCF or camera.CFrame end, setCamera = function(cf) FXK.camOverride = cf end, settings = SETTINGS }
		local stageF = K.stage()
		local ov = K.overlay()
		ov.open(0.13)
		local ungrade = K.grade(STYLE.red)
		local cam = K.camera(cctx)
		local RED = Color3.fromRGB(255, 60, 60)
		local gate = Path.positionAt(0)
		local ahead = Path.positionAt(math.min(Path.length, 14))
		local dir = Vector3.new(ahead.X - gate.X, 0, ahead.Z - gate.Z).Unit
		local side = dir:Cross(Vector3.yAxis)
		-- fog and a ring of red light at the gate
		local g0 = Vector3.new(gate.X, GROUND, gate.Z)
		K.shockwave(stageF, g0, RED, 14, 0.8)
		FXK.play("ultimate_fall", { pitch = 0.55 })
		local fogPart = Instance.new("Part")
		fogPart.Anchored, fogPart.CanCollide, fogPart.CanQuery, fogPart.Transparency, fogPart.Size = true, false, false, 1, Vector3.new(8, 1, 8)
		fogPart.Position, fogPart.Parent = g0 + Vector3.new(0, 0.5, 0), stageF
		local fog = Instance.new("ParticleEmitter")
		fog.Texture = "rbxasset://textures/particles/smoke_main.dds"
		fog.Color = ColorSequence.new(Color3.fromRGB(120, 20, 30), Color3.fromRGB(40, 10, 20))
		fog.LightEmission, fog.LightInfluence = 0.2, 0
		fog.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, 9) })
		fog.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1) })
		fog.Lifetime, fog.Rate, fog.Speed = NumberRange.new(1.5, 2.5), 40, NumberRange.new(2, 5)
		fog.SpreadAngle = Vector2.new(60, 60)
		fog.Parent = fogPart
		local holdT = short and 1.0 or 2.1
		-- red key light in front of the boss: v1 showed a black silhouette against the lit street
		local keyLight = Instance.new("Part")
		keyLight.Anchored, keyLight.CanCollide, keyLight.CanQuery, keyLight.Transparency, keyLight.Size, keyLight.Parent = true, false, false, 1, Vector3.one, stageF
		local kl = Instance.new("PointLight")
		kl.Color, kl.Brightness, kl.Range, kl.Shadows = Color3.fromRGB(255, 130, 110), 10, 34, false
		kl.Parent = keyLight
		local t0 = os.clock()
		local conn
		conn = RunService.RenderStepped:Connect(function()
			local k = math.clamp((os.clock() - t0) / holdT, 0, 1)
			-- the boss alone on the street: minions fade out of this shot only (v2 they crowded the foreground)
			for id, other in enemies do
				if id ~= data.id and other.model.Parent then
					for _, d in other.model:GetDescendants() do
						if d:IsA("BasePart") then d.LocalTransparencyModifier = 1 elseif d:IsA("BillboardGui") or d:IsA("Highlight") then d.Enabled = false end
					end
				end
			end
			local bp = e.model.Parent and e.model:GetPivot().Position or g0
			-- low on the cobbles ahead of the boss, looking up at it; slow dolly in and a little arc
			-- v2: further out and to the side so the minions in front do not fill the frame
			local camPos = bp + dir * (24 - 7 * k) + side * (9 - 4 * k) + Vector3.new(0, 2.6 + 0.8 * k, 0)
			cam.to(CFrame.lookAt(camPos, bp + Vector3.new(0, 5, 0)), 0)
			keyLight.Position = bp + dir * 6 + side * 4 + Vector3.new(0, 7, 0)
			FXK.fovOverride = 58 - 10 * k
		end)
		FXK.play("anticipation", { pitch = 0.6 })
		task.spawn(function()
			task.wait(short and 0.3 or 0.6)
			local stage = env.snap() and env.snap().stage or 5
			K.caption(ov, "[ " .. TITLES[math.clamp(math.ceil(stage / 5), 1, #TITLES)] .. " ]", Color3.fromRGB(255, 170, 160))
			FXK.play("surge", { pitch = 0.7 })
			for i = 1, short and 1 or 2 do -- heavy steps
				task.wait(short and 0.3 or 0.55)
				cam.shake(0.8, 0.25)
				K.shockwave(stageF, e.model.Parent and (e.model:GetPivot().Position * Vector3.new(1, 0, 1) + Vector3.new(0, GROUND, 0)) or g0, Color3.fromRGB(120, 90, 80), 7, 0.4)
				FXK.play("ring", { pitch = 0.5 })
			end
			task.wait(math.max(0, holdT - (os.clock() - t0)))
			conn:Disconnect()
			for _, other in enemies do
				for _, d in other.model:GetDescendants() do
					if d:IsA("BasePart") then d.LocalTransparencyModifier = 0 elseif d:IsA("BillboardGui") or d:IsA("Highlight") then d.Enabled = true end
				end
			end
			fog.Enabled = false
			FXK.fovOverride = nil
			ungrade()
			ov.close()
			cam.done(0.45)
			task.wait(2)
			stageF:Destroy()
		end)
	end
end

-- LEVEL UP cutscene "The Lamplighter" (2026-10-28): the camera rises from the crystal over the street while every gas
-- lamp along the lane flares violet one after another toward it; the crystal pulses, a ring of light sweeps the board,
-- and the new level is carved into the letterbox. 2.4 s; none at 2x or with Reduced Motion (banner only).
do
	function FXK.levelCut(data)
		if not FXK.cut or FXK.cineOff() or FXK.cineShort() or not env.crystal() then return end
		if not FXK.waitFree(2.5) then return end
		local K = FXK.cut.kit
		local cctx = { gameCamera = function() return FXK.gameCF or camera.CFrame end, setCamera = function(cf) FXK.camOverride = cf end, settings = SETTINGS }
		local stageF = K.stage()
		local ov = K.overlay()
		ov.open(0.12)
		local cam = K.camera(cctx)
		local VIOLET = Color3.fromRGB(190, 130, 255)
		local cp = env.crystal().Position
		local lamps = {}
		for _, d in workspace:GetDescendants() do
			if d:IsA("PointLight") and d.Parent:IsA("BasePart") and d.Parent.Parent and d.Parent.Parent.Name == "Street" then
				table.insert(lamps, d)
			end
		end
		table.sort(lamps, function(x, y) return (x.Parent.Position - cp).Magnitude > (y.Parent.Position - cp).Magnitude end)
		local saved = {}
		for _, l in lamps do saved[l] = { l.Color, l.Brightness, l.Range, l.Parent.Color } end
		-- 1. low on the crystal, then rise and pull back over the street
		local back = (Vector3.new(0, 0, 5) - cp)
		back = Vector3.new(back.X, 0, back.Z).Unit
		cam.to(CFrame.lookAt(cp - back * 17 + Vector3.new(0, 5, 0), cp + Vector3.new(0, 2, 0)), 0) -- outside the crystal's canopy (v1 started inside it)
		cam.to(CFrame.lookAt(cp - back * 30 + Vector3.new(0, 26, 0), Vector3.new(0, 0, 5)), 1.9, Enum.EasingStyle.Sine)
		FXK.play("legendary_gather")
		task.spawn(function()
			-- 2. the lamps flare violet in a wave toward the crystal
			for i, l in lamps do
				task.delay(0.12 + i * 0.09, function()
					l.Color, l.Range = VIOLET, 22
					TweenService:Create(l, TweenInfo.new(0.15), { Brightness = 6 }):Play()
					l.Parent.Color = VIOLET:Lerp(Color3.new(1, 1, 1), 0.3)
					K.shockwave(stageF, l.Parent.Position - Vector3.new(0, l.Parent.Position.Y - GROUND, 0), VIOLET, 4, 0.4)
					FXK.play("ring", { pitch = 0.9 + i * 0.04 })
				end)
			end
			task.wait(0.12 + #lamps * 0.09 + 0.1)
			-- 3. the crystal answers: pulse, ring over the board, the level carved in the letterbox
			K.flash(ov, cctx, VIOLET, 0.35, 0.3)
			FXK.play("milestone", { pitch = 1.1 })
			K.shockwave(stageF, Vector3.new(cp.X, GROUND, cp.Z), VIOLET, 60, 0.9)
			-- (crystal tint left alone)
			local pulse = Instance.new("Part")
			pulse.Shape, pulse.Anchored, pulse.CanCollide, pulse.CanQuery, pulse.Material = Enum.PartType.Ball, true, false, false, Enum.Material.Neon
			pulse.Color, pulse.Transparency, pulse.Size, pulse.Position, pulse.Parent = VIOLET, 0.3, Vector3.one * 4, cp, stageF
			TweenService:Create(pulse, TweenInfo.new(0.7, Enum.EasingStyle.Quint), { Size = Vector3.one * 16, Transparency = 1 }):Play()
			K.caption(ov, "[ LEVEL " .. data.level .. "  ·  LUCK +" .. math.floor(data.luck * 100 + 0.5) .. "% ]", Color3.fromRGB(225, 200, 255))
			cam.shake(0.3, 0.3)
			task.wait(0.8)
			-- 4. lamps settle back to gaslight, back to the board
			for l, v in saved do
				if l.Parent then
					TweenService:Create(l, TweenInfo.new(0.6), { Color = v[1], Brightness = v[2], Range = v[3] }):Play()
					TweenService:Create(l.Parent, TweenInfo.new(0.6), { Color = v[4] }):Play()
				end
			end
			ov.close()
			cam.done(0.45)
			task.wait(0.5)
			stageF:Destroy()
		end)
	end
end

-- START WAVE cutscene (2026-10-28, user: "every action a cutscene"): first person in a bell tower over the lane,
-- you ring the bronze bell (it swings, sound rings ripple out over the street), then the camera dives off the tower and
-- races down the lane from the gate to the crystal as the first enemies come in. Full (2.6 s) for the first two waves
-- of a session and every boss stage; otherwise no cutscene (the HUD bell still swings). Skipped with Reduced Motion,
-- at 2x speed and by tap (CutsceneFX overlay).
do
	local waves = 0
	function FXK.bellCut(stage)
		waves += 1
		if not FXK.cut or FXK.cineOff() or FXK.cineShort() then return end
		local boss = Config.isBossStage(stage)
		if waves > 2 and not boss then return end
		if FXK.busy() then return end
		local K = FXK.cut.kit
		local cctx = { gameCamera = function() return FXK.gameCF or camera.CFrame end, setCamera = function(cf) FXK.camOverride = cf end, settings = SETTINGS }
		local stageF = K.stage()
		local ov = K.overlay()
		ov.open(0.1)
		local cam = K.camera(cctx)
		local gate = Path.positionAt(0)
		local second = Path.positionAt(math.min(12, Path.length * 0.1))
		local inward = Vector3.new(second.X - gate.X, 0, second.Z - gate.Z)
		inward = inward.Magnitude > 0.1 and inward.Unit or Vector3.new(0, 0, -1)
		-- the tower stands behind the gate, the bell hangs at its top
		local towerBase = Vector3.new(gate.X, GROUND, gate.Z) - inward * 10
		local bellPos = towerBase + Vector3.new(0, 16, 0)
		local function bp(props)
			local x = Instance.new("Part")
			x.Anchored, x.CanCollide, x.CanQuery, x.CastShadow = true, false, false, false
			for k, v in props do x[k] = v end
			x.Parent = stageF
			return x
		end
		for _, off in { Vector3.new(-3, 0, -3), Vector3.new(3, 0, -3), Vector3.new(-3, 0, 3), Vector3.new(3, 0, 3) } do
			bp({ Material = Enum.Material.Brick, Color = Color3.fromRGB(86, 64, 60), Size = Vector3.new(1.2, 19, 1.2), CFrame = CFrame.new(towerBase + off + Vector3.new(0, 9.5, 0)) })
		end
		bp({ Material = Enum.Material.Slate, Color = Color3.fromRGB(40, 36, 46), Size = Vector3.new(8.5, 1, 8.5), CFrame = CFrame.new(towerBase + Vector3.new(0, 19.5, 0)) })
		bp({ Material = Enum.Material.Wood, Color = Color3.fromRGB(70, 48, 34), Size = Vector3.new(7, 0.5, 0.5), CFrame = CFrame.new(bellPos + Vector3.new(0, 2.6, 0)) })
		-- the bell: stacked bronze rings from crown to lip, swung from a pivot at the beam
		local bell = Instance.new("Model")
		bell.Parent = stageF
		-- 16 thin slices along a bell profile (narrow crown, waist, flared lip) so it reads as a cast bell, not a stack
		for k = 0, 15 do
			local t = k / 15
			local r = 0.75 + 0.35 * t + 0.9 * t ^ 3.2
			local shade = Color3.fromRGB(150, 104, 44):Lerp(Color3.fromRGB(205, 160, 80), 0.5 + 0.5 * math.sin(t * 5))
			local seg = bp({ Shape = Enum.PartType.Cylinder, Material = Enum.Material.Metal, Color = shade, Reflectance = 0.25, Size = Vector3.new(0.24, r * 2, r * 2), CFrame = CFrame.new(bellPos + Vector3.new(0, 1.95 - t * 3.4, 0)) * CFrame.Angles(0, 0, math.pi / 2) })
			seg.Parent = bell
		end
		local cap = bp({ Shape = Enum.PartType.Ball, Material = Enum.Material.Metal, Color = Color3.fromRGB(160, 112, 50), Reflectance = 0.25, Size = Vector3.new(1.6, 1, 1.6), CFrame = CFrame.new(bellPos + Vector3.new(0, 2.05, 0)) })
		cap.Parent = bell
		local clapper = bp({ Shape = Enum.PartType.Ball, Material = Enum.Material.Metal, Color = Color3.fromRGB(90, 70, 50), Size = Vector3.one * 0.7, CFrame = CFrame.new(bellPos + Vector3.new(0, -1.6, 0)) })
		clapper.Parent = bell
		local pivot = CFrame.new(bellPos + Vector3.new(0, 2.4, 0))
		local rel = {}
		for _, x in bell:GetChildren() do rel[x] = pivot:ToObjectSpace(x.CFrame) end
		local function swing(angle)
			local cf = pivot * CFrame.fromAxisAngle(inward:Cross(Vector3.yAxis), angle)
			for x, r in rel do x.CFrame = cf * r end
		end
		-- 1. first person in the tower, the bell close in frame, the lane below
		local eye = bellPos + inward * 8 + Vector3.new(0, -0.3, 0) + inward:Cross(Vector3.yAxis) * 2 -- far enough to see the whole bell and the street
		cam.to(CFrame.lookAt(eye, bellPos - Vector3.new(0, 0.6, 0)), 0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		task.spawn(function()
			task.wait(0.35)
			-- 2. ring it: three swings, each strike sends a ripple ring over the street
			for k, ang in { 0.55, -0.45, 0.3 } do
				local t0, from = os.clock(), (k == 1 and 0 or -({ 0.55, -0.45, 0.3 })[k - 1])
				while os.clock() - t0 < 0.22 do
					local e = (os.clock() - t0) / 0.22
					swing(from + (ang - from) * math.sin(e * math.pi / 2))
					RunService.RenderStepped:Wait()
				end
				FXK.play("ring", { pitch = 0.7 + k * 0.05 })
				K.shockwave(stageF, Vector3.new(gate.X, GROUND, gate.Z), Color3.fromRGB(255, 210, 140), 10 + k * 5, 0.6) -- ripples on the street below, not at eye level (v1 flooded the frame)
				cam.shake(0.25, 0.15)
				if boss and k == 3 then K.flash(ov, cctx, Color3.fromRGB(255, 80, 80), 0.35, 0.3) end
			end
			swing(0)
			if boss then K.caption(ov, "[ THE BOSS APPROACHES ]", Color3.fromRGB(255, 150, 140)) else K.caption(ov, "[ STAGE " .. stage .. " ]", Color3.fromRGB(255, 230, 180)) end
			FXK.play(boss and "surge" or "spotlight", { pitch = boss and 0.65 or 0.9 })
			-- 3. dive off the tower and race down the lane to the crystal
			local runT = 1.1
			local t0 = os.clock()
			while os.clock() - t0 < runT do
				local k = (os.clock() - t0) / runT
				local e = k < 0.5 and 2 * k * k or 1 - (-2 * k + 2) ^ 2 / 2
				local d = Path.length * e * 0.85
				local here = Path.positionAt(d)
				local ahead = Path.positionAt(math.min(Path.length, d + 10))
				local h = 16 * (1 - e) + 4.5
				local pos = Vector3.new(here.X, GROUND + h, here.Z) - (ahead - here).Unit * 4
				cam.to(CFrame.lookAt(pos, Vector3.new(ahead.X, GROUND + 1.5, ahead.Z)), 0)
				FXK.fovOverride = 70 + 18 * math.sin(k * math.pi)
				RunService.RenderStepped:Wait()
			end
			FXK.fovOverride = nil
			ov.close()
			cam.done(0.45)
			task.wait(0.5)
			stageF:Destroy()
		end)
	end
end

end
