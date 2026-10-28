--!nocheck
-- TrainerRoad (2026-10-28): opening Progression walks you, in first person, along a lamplit road of stone milestones,
-- one per trainer level. Passed milestones burn with violet lanterns; the next one glows gold; later ones are dark.
-- The camera glides from level 1 to your level and stops facing the next milestone, then the progression panel opens
-- over it. Client only, visual only. Same shape as SkillGrove:
--   local Road = require(script.Parent.TrainerRoad)({ Config = Config, setCamera = fn, setFov = fn, settings = SETTINGS, sfx = FXK.play })
--   Road.open(snap, onArrive)   Road.close(onDone)
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local O = Vector3.new(420, 0, 0) -- far from the board, the skyline and the grove
local GAP = 9

return function(ctx)
	local Config = ctx.Config
	local M = {}
	local folder, stones, opens, camConn, fade = nil, {}, 0, nil, nil

	local function part(props, parent)
		local p = Instance.new("Part")
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
		for k, v in props do p[k] = v end
		p.Parent = parent or folder
		return p
	end
	-- 2026-10-28, the user: "an infinite path where you can't see the end; as you level up your setting is always
	-- evolving", themed parts tied to world themes (Game Design Doc "Theme arc": steampunk -> magical -> cosmic).
	-- Three sections along the road; in the cosmic one the road lifts off the ground and climbs like a stair.
	local SECTIONS = {
		{ from = 1, name = "LAMPWICK LANE", line = "where it begins", color = Color3.fromRGB(255, 196, 120) },
		{ from = 9, name = "THE THINNING VEIL", line = "the magic shows itself", color = Color3.fromRGB(170, 120, 255) },
		{ from = 17, name = "THE STARWARD STAIR", line = "beyond the sky", color = Color3.fromRGB(150, 220, 255) },
	}
	local function at(lv) -- nearly straight (2026-10-28 night, the user: "a little more straight"); past the cosmic gate it climbs
		local z = -(lv - 1) * GAP
		local rise = math.max(0, lv - SECTIONS[3].from + 1) ^ 1.25 * 1.6
		return O + Vector3.new(math.sin(lv * 0.3) * 0.8, rise, z)
	end
	-- a painted horizon for each section (the user: "a better background for that progression menu"): a matte painting
	-- stands ahead of where the walk stops, half sunk below the ground line so only its sky and skyline show
	local okA, A = pcall(function() return require(game:GetService("ReplicatedStorage"):WaitForChild("ArtIds", 2)) end)
	local HORIZON = { "road_lane", "road_veil", "road_stars" }
	local horizon, horizonImg

	local function build()
		folder = Instance.new("Folder")
		folder.Name = "TrainerRoad"
		folder.Parent = workspace
		-- abstract pass (2026-10-28): no slate, cobbles or carved stones. The road is one gold line over dark ground; each
		-- milestone is its numeral floating in a thin ring, with a point of light on a faint line beside it.
		local SERIF = Font.fromName("Merriweather", Enum.FontWeight.Bold)
		local max = Config.LEVEL_MAX
		if okA and A and A.road_lane then
			horizon = part({ Transparency = 1, Size = Vector3.new(300, 150, 0.1) })
			local sg = Instance.new("SurfaceGui")
			sg.Face, sg.LightInfluence, sg.Brightness, sg.CanvasSize, sg.Enabled = Enum.NormalId.Back, 0, 1.15, Vector2.new(1024, 512), false
			sg.Parent = horizon
			horizonImg = Instance.new("ImageLabel")
			horizonImg.BackgroundTransparency, horizonImg.Size = 1, UDim2.fromScale(1, 1)
			horizonImg.Parent = sg
		end
		part({ Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(14, 12, 22), Size = Vector3.new(60, 1, max * GAP + 60), CFrame = CFrame.new(O + Vector3.new(0, -0.47, -(max * GAP) / 2)) }) -- top sits just above the baseplate (they z-fought)
		for lv = 0, max do
			local a, b = at(math.max(lv, 0.5)), at(lv + 1)
			local mid = a:Lerp(b, 0.5)
			part({ Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 214, 130), Transparency = 0.3, Size = Vector3.new(0.12, 0.05, (b - a).Magnitude + 0.1), CFrame = CFrame.lookAt(mid + Vector3.new(0, 0.05, 0), b + Vector3.new(0, 0.05, 0)) })
		end
		for lv = 1, max do
			local p = at(lv)
			local side = (lv % 2 == 0) and 1 or -1
			local base = p + Vector3.new(side * 4.2, 0, 0)
			local stone = part({ Transparency = 1, Size = Vector3.new(2.2, 3.2, 0.9), CFrame = CFrame.new(base + Vector3.new(0, 1.6, 0)) * CFrame.Angles(0, -side * 0.5, 0) })
			local sg = Instance.new("SurfaceGui")
			sg.Face, sg.LightInfluence, sg.CanvasSize = Enum.NormalId.Back, 0, Vector2.new(220, 320) -- the walker comes from +Z, so the back face greets them
			sg.Parent = stone
			local ringF = Instance.new("Frame")
			ringF.BackgroundTransparency, ringF.AnchorPoint, ringF.Position, ringF.Size = 1, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.3), UDim2.fromOffset(170, 170)
			Instance.new("UICorner", ringF).CornerRadius = UDim.new(0.5, 0)
			local ringS = Instance.new("UIStroke")
			ringS.Thickness = 4
			ringS.Parent = ringF
			ringF.Parent = sg
			local t = Instance.new("TextLabel")
			t.BackgroundTransparency, t.AnchorPoint, t.Position, t.Size, t.Text, t.TextScaled = 1, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.3), UDim2.fromOffset(120, 110), tostring(lv), true
			t.FontFace, t.TextColor3 = SERIF, Color3.fromRGB(240, 230, 210)
			t.Parent = sg
			local r = Instance.new("TextLabel")
			r.BackgroundTransparency, r.Position, r.Size, r.TextScaled = 1, UDim2.fromScale(0.05, 0.62), UDim2.fromScale(0.9, 0.3), true
			r.FontFace, r.TextColor3 = SERIF, Color3.fromRGB(150, 220, 255)
			r.Text = "+" .. Config.levelGems(lv) .. " gems" .. (lv == 3 and "\nAUTO ROLL" or (lv % 5 == 0 and "\nMILESTONE" or ""))
			r.Parent = sg
			-- a point of light on a faint line beside the numeral
			part({ Material = Enum.Material.Neon, Color = Color3.fromRGB(110, 100, 140), Transparency = 0.6, Size = Vector3.new(0.06, 4.6, 0.06), CFrame = CFrame.new(base + Vector3.new(side * 1.6, 2.3, 0)) })
			local lamp = part({ Shape = Enum.PartType.Ball, Material = Enum.Material.Neon, Color = Color3.fromRGB(60, 50, 60), Size = Vector3.one * 0.5, CFrame = CFrame.new(base + Vector3.new(side * 1.6, 4.9, 0)) })
			local l = Instance.new("PointLight")
			l.Range, l.Brightness, l.Shadows = 12, 0, false
			l.Parent = lamp
			stones[lv] = { stone = stone, lamp = lamp, light = l, text = t, ring = ringS }
		end
		-- the road never ends: it runs on past the last level, fading out, so the end is never in sight
		for k = 1, 14 do
			local a, b = at(max + k - 0.5), at(max + k + 0.5)
			part({ Material = Enum.Material.Neon, Color = SECTIONS[3].color, Transparency = 0.3 + k * 0.05, Size = Vector3.new(0.12, 0.05, (b - a).Magnitude + 0.1), CFrame = CFrame.lookAt(a:Lerp(b, 0.5), b) })
		end
		-- each section's look and a title where it starts
		local rng = Random.new(5)
		for i, sec in SECTIONS do
			local last = SECTIONS[i + 1] and SECTIONS[i + 1].from - 1 or max + 14
			local gate = at(sec.from - 0.6)
			local sign = part({ Transparency = 1, Size = Vector3.new(14, 3, 0.2), CFrame = CFrame.new(gate + Vector3.new(0, 7, 0)) })
			local sg = Instance.new("SurfaceGui")
			sg.Face, sg.LightInfluence, sg.CanvasSize = Enum.NormalId.Back, 0, Vector2.new(700, 150)
			sg.Parent = sign
			local tl = Instance.new("TextLabel")
			tl.BackgroundTransparency, tl.Size, tl.TextScaled, tl.Text, tl.FontFace, tl.TextColor3 = 1, UDim2.fromScale(1, 0.62), true, sec.name, SERIF, sec.color
			tl.Parent = sg
			local sl = Instance.new("TextLabel")
			sl.BackgroundTransparency, sl.Position, sl.Size, sl.TextScaled, sl.Text, sl.FontFace, sl.TextColor3 = 1, UDim2.fromScale(0, 0.66), UDim2.fromScale(1, 0.3), true, sec.line, SERIF, Color3.fromRGB(220, 215, 235)
			sl.Parent = sg
			for lv = sec.from, last do
				local p = at(lv)
				if i == 1 then -- steampunk street: tall gas lamps both sides, brick walls behind
					for _, side in { -1, 1 } do
						local base = p + Vector3.new(side * 9, 0, 0)
						part({ Material = Enum.Material.Metal, Color = Color3.fromRGB(40, 36, 34), Size = Vector3.new(0.25, 6, 0.25), CFrame = CFrame.new(base + Vector3.new(0, 3, 0)) })
						local head = part({ Shape = Enum.PartType.Ball, Material = Enum.Material.Neon, Color = sec.color, Size = Vector3.one * 0.45, CFrame = CFrame.new(base + Vector3.new(0, 6.2, 0)) })
						local pl = Instance.new("PointLight")
						pl.Color, pl.Range, pl.Brightness, pl.Shadows = sec.color, 10, 0.8, false
						pl.Parent = head
						part({ Material = Enum.Material.Brick, Color = Color3.fromRGB(58, 40, 40), Size = Vector3.new(1, 8 + rng:NextNumber() * 6, GAP), CFrame = CFrame.new(p + Vector3.new(side * 16, 5, 0)) })
					end
				elseif i == 2 then -- the veil thins: violet mist and stones drifting up off the ground
					for _ = 1, 3 do
						local off = Vector3.new(rng:NextNumber(-14, 14), rng:NextNumber(1, 9), rng:NextNumber(-4, 4))
						if math.abs(off.X) > 5 then
							local stone = part({ Material = Enum.Material.Slate, Color = Color3.fromRGB(70, 60, 90), Size = Vector3.new(rng:NextNumber(0.6, 1.6), rng:NextNumber(0.4, 1), rng:NextNumber(0.6, 1.6)), CFrame = CFrame.new(p + off) * CFrame.Angles(rng:NextNumber() * 6, rng:NextNumber() * 6, 0) })
							local rune = part({ Shape = Enum.PartType.Ball, Material = Enum.Material.Neon, Color = sec.color, Size = Vector3.one * 0.18, CFrame = CFrame.new(stone.Position + Vector3.new(0, 1, 0)) })
						end
					end
					if lv % 2 == 0 then -- low mist: sparse and faint (one slab per level stacked into visible blocks)
						part({ Material = Enum.Material.Neon, Color = sec.color, Transparency = 0.965, Size = Vector3.new(36, 1.2, GAP * 2), CFrame = CFrame.new(p + Vector3.new(0, 0.4, 0)) })
					end
				else -- cosmic: the road floats as glowing steps, rune rings hang in the air, stars all around
					part({ Material = Enum.Material.Neon, Color = sec.color, Transparency = 0.55, Size = Vector3.new(5, 0.25, 2.2), CFrame = CFrame.new(p) })
					if lv % 3 == 0 then
						local ring = part({ Transparency = 1, Size = Vector3.new(12, 12, 0.05), CFrame = CFrame.new(p + Vector3.new(0, 6, 0)) }) -- a thin rune ring (SurfaceGui: a neon cylinder read as a solid disc)
						local rg = Instance.new("SurfaceGui")
						rg.Face, rg.LightInfluence, rg.CanvasSize = Enum.NormalId.Back, 0, Vector2.new(400, 400)
						local rf = Instance.new("Frame")
						rf.BackgroundTransparency, rf.Size = 1, UDim2.fromScale(1, 1)
						Instance.new("UICorner", rf).CornerRadius = UDim.new(0.5, 0)
						local rs = Instance.new("UIStroke")
						rs.Color, rs.Thickness, rs.Transparency = Color3.fromRGB(235, 240, 255), 4, 0.25
						rs.Parent = rf
						rf.Parent = rg
						rg.Parent = ring
					end
					for _ = 1, 8 do
						part({ Shape = Enum.PartType.Ball, Material = Enum.Material.Neon, Color = Color3.fromRGB(235, 240, 255), Size = Vector3.one * rng:NextNumber(0.1, 0.3), CFrame = CFrame.new(p + Vector3.new(rng:NextNumber(-30, 30), rng:NextNumber(-6, 22), rng:NextNumber(-5, 5))) })
					end
				end
			end
		end
	end

	function M.refresh(snap)
		for lv, s in stones do
			local done, nextUp = lv <= snap.level, lv == snap.level + 1
			local color = done and Color3.fromRGB(190, 130, 255) or (nextUp and Color3.fromRGB(255, 205, 110) or Color3.fromRGB(60, 50, 60))
			s.lamp.Color = color
			s.light.Color = color
			s.light.Brightness = (done or nextUp) and 1.8 or 0
			s.text.TextColor3 = nextUp and Color3.fromRGB(255, 220, 140) or (done and Color3.fromRGB(220, 200, 255) or Color3.fromRGB(140, 130, 140))
			s.ring.Color = s.text.TextColor3
			s.ring.Transparency = (done or nextUp) and 0 or 0.6
		end
	end

	local function fadeTo(alpha, t)
		if not fade then
			local sg = Instance.new("ScreenGui")
			sg.Name, sg.IgnoreGuiInset, sg.DisplayOrder, sg.ResetOnSpawn = "RoadFade", true, 60, false
			sg.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
			fade = Instance.new("Frame")
			fade.BackgroundColor3, fade.BorderSizePixel, fade.Size, fade.BackgroundTransparency = Color3.new(0, 0, 0), 0, UDim2.fromScale(1, 1), 1
			fade.Parent = sg
		end
		local x = TweenService:Create(fade, TweenInfo.new(t), { BackgroundTransparency = 1 - alpha })
		x:Play()
		return x
	end

	-- scene lighting while the road is open (2026-10-28 texture pass): night, fog that hides the far end, bloom and a
	-- colour grade in the section's hue. Lighting post-effects only work on 3D scenes, which is why the road gets them
	-- and the 2D screens get painted textures instead. Everything is saved and restored on close.
	local Lighting = game:GetService("Lighting")
	local saved
	local function sceneLight(level)
		local sec = SECTIONS[1]
		for _, s2 in SECTIONS do if level >= s2.from then sec = s2 end end
		if not saved then
			saved = { ClockTime = Lighting.ClockTime, Brightness = Lighting.Brightness, Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient, ExposureCompensation = Lighting.ExposureCompensation }
			local atm = Lighting:FindFirstChildOfClass("Atmosphere")
			if atm then saved.atm = { atm, atm.Density, atm.Color, atm.Decay, atm.Glare, atm.Haze, atm.Offset } end
			local bl = Lighting:FindFirstChildOfClass("BloomEffect")
			if bl then saved.bloom = { bl, bl.Intensity, bl.Size, bl.Threshold, bl.Enabled } end
		end
		Lighting.ClockTime, Lighting.Brightness, Lighting.ExposureCompensation = 0, 1.5, 0.3
		Lighting.Ambient, Lighting.OutdoorAmbient = Color3.fromRGB(30, 28, 40), Color3.fromRGB(40, 38, 60)
		if saved.atm then
			local atm = saved.atm[1]
			atm.Density, atm.Offset, atm.Haze, atm.Glare = 0.42, 0.25, 1.5, 0.4
			atm.Color = sec.color:Lerp(Color3.fromRGB(20, 20, 30), 0.6)
			atm.Decay = sec.color:Lerp(Color3.new(0, 0, 0), 0.75)
		end
		if saved.bloom then
			local bl = saved.bloom[1]
			bl.Enabled, bl.Intensity, bl.Size, bl.Threshold = true, 1.4, 36, 0.85
		end
		local cc = Lighting:FindFirstChild("RoadGrade") or Instance.new("ColorCorrectionEffect")
		cc.Name, cc.TintColor, cc.Contrast, cc.Saturation, cc.Brightness = "RoadGrade", Color3.new(1, 1, 1):Lerp(sec.color, 0.18), 0.12, 0.1, 0.02
		cc.Parent = Lighting
	end
	local function restoreLight()
		if not saved then return end
		for k, v in saved do
			if k ~= "atm" and k ~= "bloom" then Lighting[k] = v end
		end
		if saved.atm then
			local a = saved.atm
			a[1].Density, a[1].Color, a[1].Decay, a[1].Glare, a[1].Haze, a[1].Offset = a[2], a[3], a[4], a[5], a[6], a[7]
		end
		if saved.bloom then
			local b = saved.bloom
			b[1].Intensity, b[1].Size, b[1].Threshold, b[1].Enabled = b[2], b[3], b[4], b[5]
		end
		local cc = Lighting:FindFirstChild("RoadGrade")
		if cc then cc:Destroy() end
		saved = nil
	end

	function M.open(snap, onArrive)
		if not folder then build() end
		M.refresh(snap)
		opens += 1
		local short = opens > 1 or ctx.settings.gameSpeed == 2 or ctx.settings.reducedMotion or (ctx.short and ctx.short())
		local target = math.clamp(snap.level + 1, 1, Config.LEVEL_MAX)
		local fromLv = short and math.max(1, target - 2) or 0.2
		local walkT = short and 0.8 or math.clamp(0.5 + target * 0.18, 1.2, 3.2)
		fadeTo(1, 0.2).Completed:Wait()
		sceneLight(math.clamp(snap.level + 1, 1, Config.LEVEL_MAX))
		if horizon then -- this section's painting, ~13 milestones ahead of the stop, its lower half below the ground
			local si = 1
			for i, sec in SECTIONS do if target >= sec.from then si = i end end
			horizonImg.Image = A[HORIZON[si]] or ""
			local p = at(target + 13)
			horizon.CFrame = CFrame.new(Vector3.new(O.X, p.Y + 22, p.Z))
			horizon:FindFirstChildOfClass("SurfaceGui").Enabled = true
		end
		ctx.sfx("anticipation", { pitch = 0.8 })
		local t0 = os.clock()
		if camConn then camConn:Disconnect() end
		local lastPassed = 0
		camConn = RunService.RenderStepped:Connect(function()
			local k = math.clamp((os.clock() - t0) / walkT, 0, 1)
			local e = 1 - (1 - k) ^ 3
			local lv = fromLv + (target - 1.5 - fromLv) * e -- stop short of the next stone so it reads
			local here, ahead = at(lv), at(lv + 1.2)
			local bob = (ctx.settings.reducedMotion or k >= 1) and 0 or math.sin((os.clock() - t0) * 10) * 0.12 * (1 - e)
			ctx.setCamera(CFrame.lookAt(here + Vector3.new(0, 5.2 + bob, 0), ahead + Vector3.new(0, 3.2, 0)))
			ctx.setFov(70 - 8 * e)
			local passed = math.floor(lv)
			if passed > lastPassed and passed >= 1 and passed <= snap.level then -- each passed milestone flares as you go by
				lastPassed = passed
				local s = stones[passed]
				if s then
					s.light.Brightness = 5
					TweenService:Create(s.light, TweenInfo.new(0.4), { Brightness = 1.8 }):Play()
				end
			end
		end)
		fadeTo(0, 0.3)
		task.wait(walkT + (short and 0.15 or 0.4))
		if onArrive then onArrive() end
	end

	function M.close(onDone)
		fadeTo(1, 0.2).Completed:Wait()
		if camConn then camConn:Disconnect() camConn = nil end
		ctx.setCamera(nil)
		ctx.setFov(nil)
		restoreLight()
		if horizon then horizon:FindFirstChildOfClass("SurfaceGui").Enabled = false end -- it showed in the Skill Grove's sky
		if onDone then onDone() end
		fadeTo(0, 0.3)
	end

	return M
end
