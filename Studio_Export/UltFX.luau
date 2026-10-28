--!nocheck
-- Generic ultimate cinematic (fallback when a familiar has no signature cutscene). Split out of GameClient 2026-10-27.
-- GameClient calls this with a ctx table of its shared helpers and gets playUlt back.
return function(ctx)
	local TweenService = game:GetService("TweenService")
	local RunService = game:GetService("RunService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Debris = game:GetService("Debris")
	local new, tween, visuals, dim, shake = ctx.new, ctx.tween, ctx.visuals, ctx.dim, ctx.shake
	local petParts, enemies, groundOf, GROUND = ctx.petParts, ctx.enemies, ctx.groundOf, ctx.GROUND
	local screenFlash, showBanner, ring, pillar, burst = ctx.screenFlash, ctx.showBanner, ctx.ring, ctx.pillar, ctx.burst
	local FXK, SETTINGS, STYLE, Config, Path = ctx.FXK, ctx.SETTINGS, ctx.STYLE, ctx.Config, ctx.Path

	local NEON = Enum.Material.Neon

	local function tweenNumber(from, to, time, style, dir, cb)
		local v = Instance.new("NumberValue")
		v.Value = from
		v.Changed:Connect(cb)
		local t = TweenService:Create(v, TweenInfo.new(time, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), { Value = to })
		t.Completed:Connect(function() v:Destroy() end)
		t:Play()
	end

	local function bolt(from, to, color, width)
		local pts = { from }
		for i = 1, 5 do
			pts[#pts + 1] = from:Lerp(to, i / 6) + Vector3.new((math.random() - 0.5) * 3.5, (math.random() - 0.5) * 2, (math.random() - 0.5) * 3.5)
		end
		pts[#pts + 1] = to
		for i = 1, #pts - 1 do
			local p0, p1 = pts[i], pts[i + 1]
			local len = math.max((p1 - p0).Magnitude, 0.1)
			local seg = new("Part", { Anchored = true, CanCollide = false, CanQuery = false, CastShadow = false, Material = NEON, Color = color, Size = Vector3.new(width, width, len), CFrame = CFrame.lookAt(p0:Lerp(p1, 0.5), p1) }, visuals)
			tween(seg, 0.28, { Transparency = 1, Size = Vector3.new(width * 0.2, width * 0.2, len) })
			Debris:AddItem(seg, 0.32)
		end
	end

	local function meteor(at, delay, damage, e)
		task.delay(delay, function()
			local start = at + Vector3.new(-22, 75, -12)
			local m = new("Part", { Shape = Enum.PartType.Ball, Anchored = true, CanCollide = false, CanQuery = false, Material = NEON, Color = Color3.fromRGB(255, 150, 50), Size = Vector3.one * 3.6, Position = start }, visuals)
			new("ParticleEmitter", { Color = ColorSequence.new(Color3.fromRGB(255, 190, 80), Color3.fromRGB(90, 60, 40)), Rate = 90, Lifetime = NumberRange.new(0.3, 0.6), Speed = NumberRange.new(2, 6), LightEmission = 0.8, Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2.2), NumberSequenceKeypoint.new(1, 0) }) }, m)
			local fall = TweenService:Create(m, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = at + Vector3.new(0, 1.5, 0) })
			fall.Completed:Connect(function()
				m:Destroy()
				burst(at + Vector3.new(0, 2, 0), Color3.fromRGB(255, 170, 60), 22, 30)
				ring(at, Color3.fromRGB(255, 200, 90), 16, 0.4)
				if e and e.fill and e.fill.Parent then
					e.hp -= damage
					e.fill.Size = UDim2.fromScale(math.clamp(e.hp / e.maxHp, 0, 1), 1)
				end
			end)
			fall:Play()
		end)
	end

	local function playUlt()
		local center = Vector3.new(0, GROUND, 5)
		local orbPos = center + Vector3.new(0, 15, 0)
		ctx.hold(os.clock() + 1.8)
		tween(dim, 0.25, { BackgroundTransparency = 0.4 })
		tweenNumber(1, 0.86, 0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.In, function(v) ctx.setZoom(v) end)
		shake.t, shake.amp = 0.6, 0.6

		-- rune circle on the ground
		local glyphs, rays2, spinRing = {}, {}, {}
		local all = {}
		local function addPart(props)
			props.Anchored, props.CanCollide, props.CanQuery, props.CastShadow = true, false, false, false
			props.Material = NEON
			local p = new("Part", props, visuals)
			table.insert(all, p)
			return p
		end
		local disc = addPart({ Shape = Enum.PartType.Cylinder, Color = STYLE.gold, Transparency = 0.82, Size = Vector3.new(0.15, 76, 76), CFrame = CFrame.new(center + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.pi / 2) })
		for i = 1, 40 do
			local a = i / 40 * math.pi * 2
			addPart({ Color = STYLE.gold, Size = Vector3.new(1.4, 0.2, 0.5), CFrame = CFrame.new(center + Vector3.new(math.cos(a) * 36, 0.3, math.sin(a) * 36)) * CFrame.Angles(0, -a, 0) })
		end
		for i = 1, 28 do
			spinRing[i] = addPart({ Color = Color3.new(1, 1, 1), Size = Vector3.new(1.1, 0.2, 0.4) })
		end
		for i = 1, 6 do
			rays2[i] = addPart({ Color = STYLE.gold, Transparency = 0.35, Size = Vector3.new(0.5, 0.15, 70) })
		end
		for i = 1, 8 do
			glyphs[i] = addPart({ Color = STYLE.gem, Size = Vector3.new(2, 0.5, 2) })
		end
		-- power orb with three spinning rings
		local orb = addPart({ Shape = Enum.PartType.Ball, Color = Color3.new(1, 1, 1), Size = Vector3.one * 0.5, Position = orbPos })
		local orbRings = {}
		for i = 1, 3 do
			orbRings[i] = addPart({ Shape = Enum.PartType.Cylinder, Color = i == 2 and STYLE.gem or STYLE.gold, Transparency = 0.3, Size = Vector3.new(0.4, 4, 4), Position = orbPos })
		end
		local light = new("PointLight", { Color = STYLE.gold, Range = 60, Brightness = 4 }, orb)

		local released = false
		local start = os.clock()
		local conn
		conn = RunService.RenderStepped:Connect(function()
			local t = os.clock() - start
			for i, p in spinRing do
				local a = i / 28 * math.pi * 2 + t * 1.6
				p.CFrame = CFrame.new(center + Vector3.new(math.cos(a) * 26, 0.35, math.sin(a) * 26)) * CFrame.Angles(0, -a, 0)
			end
			for i, p in rays2 do
				p.CFrame = CFrame.new(center + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, t * -0.9 + i * math.pi / 6 * 2, 0)
			end
			for i, p in glyphs do
				local a = i / 8 * math.pi * 2 - t * 1.2
				p.CFrame = CFrame.new(center + Vector3.new(math.cos(a) * 31, 0.5, math.sin(a) * 31)) * CFrame.Angles(0, t * 3, 0)
			end
			if not released then
				local k = math.clamp(t / 0.9, 0, 1)
				orb.Size = Vector3.one * (0.5 + 17 * k * k)
				light.Brightness = 4 + 10 * k
				for i, r in orbRings do
					local s = (7 + 12 * k) * (0.8 + 0.25 * i)
					r.Size = Vector3.new(0.4, s, s)
					r.CFrame = CFrame.new(orbPos) * CFrame.Angles(t * (2 + i), t * (1.3 * i), i * 1.1)
				end
			end
		end)

		-- gather: every pet feeds the orb with lightning
		for k = 0, 5 do
			task.delay(k * 0.15, function()
				for slot, entry in petParts do
					entry.kick = 1.2
					bolt(groundOf(slot) + Vector3.new(0, 4, 0), orbPos, k % 2 == 0 and STYLE.gold or Color3.new(1, 1, 1), 0.35)
				end
			end)
		end

		-- release at 0.9 s
		task.delay(0.9, function()
			released = true
			orb:Destroy()
			for _, r in orbRings do r:Destroy() end
			-- 0.7, not 0.95: the recorded motion showed a full white frame hiding the board; the impact frame now carries the hit
			screenFlash(Color3.new(1, 1, 1), 0.7)
			shake.t, shake.amp = 1.0, 3.2
			if FXK.impact then
				FXK.impact.impactFrame(SETTINGS)
				FXK.impact.scorch(center + Vector3.new(0, -0.4, 0), 16, 3)
			end
			showBanner("ULTIMATE!", STYLE.gold)
			ring(center, Color3.new(1, 1, 1), 190, 0.9)
			ring(center, STYLE.gold, 140, 0.7)
			ring(center, STYLE.gem, 100, 0.55)
			pillar(center, Color3.new(1, 1, 1), 0.9, 14)
			tweenNumber(0.86, 1, 0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, function(v) ctx.setZoom(v) end)
			local damage = Config.ULT_DAMAGE * Config.hpScale(ctx.snapStage())
			local n = 0
			for _, e in enemies do
				n += 1
				if n > 24 then
					break
				end
				meteor(e.model:GetPivot().Position, 0.04 + n * 0.035, damage, e)
			end
			for i = 1, 12 do
				meteor(Path.positionAt(math.random() * Path.length), 0.1 + i * 0.05, 0, nil)
			end
			for slot in petParts do
				pillar(groundOf(slot), STYLE.gold, 0.7, 1.4)
			end
		end)

		-- wrap up
		task.delay(1.9, function()
			tween(dim, 0.6, { BackgroundTransparency = 1 })
			for _, p in all do
				if p.Parent then
					tween(p, 0.4, { Transparency = 1 })
				end
			end
		end)
		task.delay(2.4, function()
			conn:Disconnect()
			for _, p in all do
				p:Destroy()
			end
			ctx.setZoom(1)
		end)
	end

	if RunService:IsStudio() then
		local ultEvent = Instance.new("BindableEvent")
		ultEvent.Name = "DebugUlt"
		ultEvent.Parent = ReplicatedStorage
		ultEvent.Event:Connect(playUlt)
	end

	return playUlt
end
