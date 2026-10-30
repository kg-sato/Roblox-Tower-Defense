--!nocheck
-- EnemyTelegraph (T138, 2026-10-29): a one second warning before an enemy special. Sentinel plant comes from the server event
-- Telegraph { id, kind = "plant", delay = 1 }. The Thief steal (at 30% of the lane) and the Crow perch (at 50%) have no server warning, so the
-- client predicts them from the enemy's lane distance and speed (simNow - spawnTime) * speed and warns when the special is 1 s away (once per enemy).
-- Look: a ground ring that shrinks onto the enemy plus a "!" tag above it, in a colour per special, and a soft cue. Reduced motion: no shrink, tag only.
-- Installed as StarterPlayerScripts.EnemyTelegraph; GameClient makes it with one line (FXK.telegraph = require(...)({...})) and it listens to the Event remote itself.
-- Test log: M.log = { { special, id, t (sim seconds), eta } }. Look and sound are UNVERIFIED (no human judged them).
return function(env)
	local enemies, new, tween, SETTINGS, FXK, Path, ring = env.enemies, env.new, env.tween, env.SETTINGS, env.FXK, env.Path, env.ring
	local RS = game:GetService("ReplicatedStorage")
	local RunService = game:GetService("RunService")
	local LEAD = 1
	local M = { log = {}, actual = {}, LEAD = LEAD }
	local function publish() -- Studio test: warnings and the real events, JSON in the script attribute "Log"
		script:SetAttribute("Log", game:GetService("HttpService"):JSONEncode({ warn = M.log, actual = M.actual }))
	end
	-- special -> colour, tag text, cue pitch
	M.LOOK = {
		plant = { Color3.fromRGB(255, 150, 60), "!", 0.8 },
		perch = { Color3.fromRGB(150, 190, 255), "!", 1.3 },
		steal = { Color3.fromRGB(210, 120, 255), "!", 1.1 },
	}
	-- kind -> { special, lane fraction where it happens }
	M.PREDICT = { Thief = { "steal", 0.3 }, Crow = { "perch", 0.5 } }

	function M.warn(special, id)
		local e = enemies[id]
		local look = M.LOOK[special]
		if not e or not look or not e.model.Parent then return end
		table.insert(M.log, { special, id, FXK.simNow(), os.clock() })
		publish()
		local root = e.model:FindFirstChild("Root") or e.model.PrimaryPart
		if root then
			local bb = new("BillboardGui", { Name = "Telegraph", Size = UDim2.fromOffset(40, 40), AlwaysOnTop = true, Adornee = root, StudsOffset = Vector3.new(0, 5, 0) }, root)
			local l = new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Font = Enum.Font.GothamBlack, TextScaled = true, Text = look[2], TextColor3 = look[1] }, bb)
			new("UIStroke", { Color = Color3.fromRGB(20, 10, 10), Thickness = 2 }, l)
			if not SETTINGS.reducedMotion then
				l.TextTransparency = 0
				tween(bb, LEAD, { StudsOffset = Vector3.new(0, 6.5, 0) })
			end
			task.delay(LEAD, function() if bb.Parent then bb:Destroy() end end)
		end
		if not SETTINGS.reducedMotion then
			local p = e.model:GetPivot().Position
			local r = new("Part", { Shape = Enum.PartType.Cylinder, Anchored = true, CanCollide = false, CanQuery = false, Material = Enum.Material.Neon, Color = look[1], Transparency = 0.45,
				Size = Vector3.new(0.2, 14, 14), CFrame = CFrame.new(p.X, 0.3, p.Z) * CFrame.Angles(0, 0, math.pi / 2) }, workspace)
			tween(r, LEAD, { Size = Vector3.new(0.2, 2, 2), Transparency = 0.1 })
			task.delay(LEAD + 0.05, function() r:Destroy() end)
		end
		FXK.play("anticipation", { pitch = look[3], volume = 0.35 })
	end

	local seen = {} -- enemy id -> true once its predicted special was warned
	RunService.Heartbeat:Connect(function()
		local now = FXK.simNow()
		for id, e in enemies do
			local pr = M.PREDICT[e.kind]
			if pr and not seen[id] then
				local d = math.max(now - e.spawnTime, 0) * e.speed
				local eta = (pr[2] * Path.length - d) / math.max(e.speed, 1e-3)
				if eta <= LEAD and eta > -0.2 then
					seen[id] = true
					M.warn(pr[1], id)
				elseif eta <= -0.2 then
					seen[id] = true -- already past (joined late): never warn after the fact
				end
			end
		end
	end)

	local REAL = { Plant = "plant", Perch = "perch", Steal = "steal" }
	RS:WaitForChild("Remotes"):WaitForChild("Event").OnClientEvent:Connect(function(kind, data)
		if REAL[kind] and type(data) == "table" then
			table.insert(M.actual, { REAL[kind], data.id, FXK.simNow(), os.clock() })
			publish()
		end
		if kind == "Telegraph" and type(data) == "table" and data.kind == "plant" then
			M.warn("plant", data.id)
		end
	end)

	return M
end
