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
	local function at(lv) -- the road winds gently
		local z = -(lv - 1) * GAP
		return O + Vector3.new(math.sin(lv * 0.45) * 4, 0, z)
	end

	local function build()
		folder = Instance.new("Folder")
		folder.Name = "TrainerRoad"
		folder.Parent = workspace
		local max = Config.LEVEL_MAX
		part({ Material = Enum.Material.Slate, Color = Color3.fromRGB(26, 24, 34), Size = Vector3.new(60, 1, max * GAP + 60), CFrame = CFrame.new(O + Vector3.new(0, -0.5, -(max * GAP) / 2)) })
		for lv = 0, max do
			local a, b = at(math.max(lv, 0.5)), at(lv + 1)
			local mid = a:Lerp(b, 0.5)
			part({ Material = Enum.Material.Cobblestone, Color = Color3.fromRGB(100, 92, 88), Size = Vector3.new(5.5, 0.2, (b - a).Magnitude + 0.4), CFrame = CFrame.lookAt(mid + Vector3.new(0, 0.05, 0), b + Vector3.new(0, 0.05, 0)) })
		end
		for lv = 1, max do
			local p = at(lv)
			local side = (lv % 2 == 0) and 1 or -1
			local base = p + Vector3.new(side * 4.2, 0, 0)
			local stone = part({ Material = Enum.Material.Slate, Color = Color3.fromRGB(110, 104, 112), Size = Vector3.new(2.2, 3.2, 0.9), CFrame = CFrame.new(base + Vector3.new(0, 1.6, 0)) * CFrame.Angles(0, -side * 0.5, 0) })
			local sg = Instance.new("SurfaceGui")
			sg.Face, sg.LightInfluence, sg.CanvasSize = Enum.NormalId.Back, 0, Vector2.new(220, 320) -- the walker comes from +Z, so the back face greets them
			sg.Parent = stone
			local t = Instance.new("TextLabel")
			t.BackgroundTransparency, t.Size, t.Text, t.TextScaled = 1, UDim2.fromScale(1, 0.6), tostring(lv), true
			t.Font, t.TextColor3 = Enum.Font.GrenzeGotisch, Color3.fromRGB(240, 230, 210)
			t.Parent = sg
			local r = Instance.new("TextLabel")
			r.BackgroundTransparency, r.Position, r.Size, r.TextScaled = 1, UDim2.fromScale(0.05, 0.62), UDim2.fromScale(0.9, 0.3), true
			r.Font, r.TextColor3 = Enum.Font.TitilliumWeb, Color3.fromRGB(150, 220, 255)
			r.Text = "+" .. Config.levelGems(lv) .. " gems" .. (lv == 3 and "\nAUTO ROLL" or (lv % 5 == 0 and "\nMILESTONE" or ""))
			r.Parent = sg
			-- lantern on a post beside the stone
			part({ Material = Enum.Material.Metal, Color = Color3.fromRGB(30, 30, 34), Size = Vector3.new(0.25, 4.6, 0.25), CFrame = CFrame.new(base + Vector3.new(side * 1.6, 2.3, 0)) })
			local lamp = part({ Material = Enum.Material.Neon, Color = Color3.fromRGB(60, 50, 60), Transparency = 0.35, Size = Vector3.new(0.4, 0.55, 0.4), CFrame = CFrame.new(base + Vector3.new(side * 1.6, 4.9, 0)) })
			local l = Instance.new("PointLight")
			l.Range, l.Brightness, l.Shadows = 12, 0, false
			l.Parent = lamp
			stones[lv] = { stone = stone, lamp = lamp, light = l, text = t }
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

	function M.open(snap, onArrive)
		if not folder then build() end
		M.refresh(snap)
		opens += 1
		local short = opens > 1 or ctx.settings.gameSpeed == 2 or ctx.settings.reducedMotion or (ctx.short and ctx.short())
		local target = math.clamp(snap.level + 1, 1, Config.LEVEL_MAX)
		local fromLv = short and math.max(1, target - 2) or 0.2
		local walkT = short and 0.8 or math.clamp(0.5 + target * 0.18, 1.2, 3.2)
		fadeTo(1, 0.2).Completed:Wait()
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
		if onDone then onDone() end
		fadeTo(0, 0.3)
	end

	return M
end
