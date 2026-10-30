--!nocheck
-- BossFx (T148, 2026-10-29): the look, sound and cut of a boss phase change, next to BossBar (which keeps the pips, banner and status notes).
-- On the server event BossPhase { id, boss, phase, phases, banner, hpFrac }:
--   visual: a PhaseGlow highlight on the boss in the phase colour (violet, amber, crimson; crimson pulses), a ground ring, and a tint on the screen edge.
--   cut (phases 2 and later): black bars slide in for about 1.2 s, the lens punches in (FXK.fovOverride) and the camera shakes; with Reduced Motion
--     only the bars and the glow remain, no lens or shake.
--   sound: cues from PHASE_CUES through SoundCues.fire (logged in SoundCues.log) and a music duck. All cues are existing files (no new audio was made).
-- Test hook: M.log = { { boss, phase, glow, cues } } mirrored to the script attribute "Log". Look and sound are UNVERIFIED (no human judged them).
return function(env)
	local hud, enemies, FXK, SETTINGS, new, tween, shake, ring, screenFlash = env.hud, env.enemies, env.FXK, env.SETTINGS, env.new, env.tween, env.shake, env.ring, env.screenFlash
	local RS = game:GetService("ReplicatedStorage")
	local RunService = game:GetService("RunService")
	local okC, Cues = pcall(function() return require(RS:WaitForChild("SoundCues", 5)) end)
	local okS, SoundFX = pcall(function() return require(RS:WaitForChild("SoundFX", 5)) end)
	local okM, Music = pcall(function() return require(RS:WaitForChild("MusicFX", 5)) end)
	local M = { log = {} }
	M.GLOW = { Color3.fromRGB(170, 130, 255), Color3.fromRGB(255, 170, 70), Color3.fromRGB(255, 60, 50) }
	-- { cue, pitch, volume, delay } per boss and phase; "default" fills any boss without a row
	M.PHASE_CUES = {
		default = { [2] = { { "bell_toll", 0.85, 0.7, 0 } }, [3] = { { "iron_clank", 0.7, 0.8, 0 }, { "glass_crack", 0.75, 0.6, 0.15 } } },
		Unbound = { [2] = { { "ink", 1.1, 0.5, 0 } }, [3] = { { "glass_crack", 0.7, 0.7, 0 }, { "bell_toll", 0.6, 0.6, 0.2 } } },
		Automaton = { [2] = { { "iron_clank", 0.9, 0.7, 0 }, { "clock_tick", 0.8, 0.6, 0.3 } }, [3] = { { "iron_clank", 0.6, 0.85, 0 }, { "surge", 1.0, 0.5, 0.2 } } },
		Echo = { [2] = { { "echo", 0.8, 0.7, 0 }, { "echo", 1.2, 0.5, 0.25 } }, [3] = { { "echo", 0.7, 0.8, 0 }, { "surge", 1.1, 0.5, 0.25 } } },
		Regent = { [2] = { { "bell_toll", 0.8, 0.75, 0 } }, [3] = { { "bell_toll", 0.6, 0.85, 0 }, { "glass_crack", 0.8, 0.6, 0.6 } } },
		Clockmaker = { [2] = { { "clock_tick", 0.7, 0.8, 0 }, { "iron_clank", 0.8, 0.6, 0.2 } }, [3] = { { "clock_tick", 0.5, 0.9, 0 }, { "bell_toll", 0.55, 0.7, 0.3 } } },
	}

	-- black bars + edge tint
	local topBar = new("Frame", { Name = "BossCutTop", BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 0), Size = UDim2.fromScale(1, 0.11), ZIndex = 40, Active = false }, hud)
	local botBar = new("Frame", { Name = "BossCutBottom", BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 0), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, 0.11), ZIndex = 40, Active = false }, hud)
	local token = 0

	local function glowOn(e, phase)
		local h = e.model:FindFirstChild("PhaseGlow")
		if not h then
			h = new("Highlight", { Name = "PhaseGlow", FillTransparency = 0.7, OutlineTransparency = 0.2, DepthMode = Enum.HighlightDepthMode.Occluded }, e.model)
		end
		local c = M.GLOW[math.clamp(phase, 1, 3)]
		h.FillColor, h.OutlineColor = c, c
		if phase >= 3 and not SETTINGS.reducedMotion then
			task.spawn(function() -- crimson pulse until the boss is gone
				while h.Parent do
					h.FillTransparency = 0.55 + 0.2 * math.sin(os.clock() * 5)
					task.wait(0.05)
				end
			end)
		end
		return h
	end

	local function cut(phase)
		token += 1
		local mine = token
		tween(topBar, 0.25, { Position = UDim2.fromScale(0, 0.11) })
		tween(botBar, 0.25, { Position = UDim2.fromScale(0, 0.89) })
		if not SETTINGS.reducedMotion then
			FXK.fovOverride = 52
			task.delay(0.25, function() if mine == token then FXK.fovOverride = 56 end end)
			task.delay(0.9, function() if mine == token then FXK.fovOverride = nil end end)
			shake.t, shake.amp = 0.5, 1.5 + phase * 0.4
		end
		task.delay(1.2, function()
			if mine ~= token then return end
			tween(topBar, 0.3, { Position = UDim2.fromScale(0, 0) })
			tween(botBar, 0.3, { Position = UDim2.fromScale(0, 1) })
		end)
	end

	function M.phase(data, retried)
		local e = enemies[data.id]
		if not e or not e.model.Parent then
			if not retried then task.delay(0.3, M.phase, data, true) end -- the Spawn event can land a frame after the first BossPhase
			return
		end
		local phase = data.phase or 1
		glowOn(e, phase)
		local fired = {}
		if phase > 1 then
			local p = e.model:GetPivot().Position
			ring(Vector3.new(p.X, 0.3, p.Z), M.GLOW[math.clamp(phase, 1, 3)], 26 + phase * 6, 0.9)
			if SETTINGS.flashes ~= false then
				screenFlash(M.GLOW[math.clamp(phase, 1, 3)], 0.25)
			end
			cut(phase)
			local set = M.PHASE_CUES[data.boss] or M.PHASE_CUES.default
			for _, c in set[phase] or M.PHASE_CUES.default[phase] or {} do
				table.insert(fired, c[1])
				task.delay(c[4], function()
					if okC and okS then Cues.fire(SoundFX, c[1], { pitch = c[2], volume = c[3] }) end
				end)
			end
			if okM and Music then Music.duck(0.4, 2.2) end
		end
		table.insert(M.log, { data.boss, phase, M.GLOW[math.clamp(phase, 1, 3)]:ToHex(), table.concat(fired, ",") })
		script:SetAttribute("Log", game:GetService("HttpService"):JSONEncode(M.log))
	end

	RS:WaitForChild("Remotes"):WaitForChild("Event").OnClientEvent:Connect(function(kind, data)
		if kind == "BossPhase" and type(data) == "table" then
			M.phase(data)
		elseif kind == "Spawn" and type(data) == "table" and data.boss then
			M.phase({ id = data.id, boss = data.boss, phase = 1 }) -- the server sends BossPhase only for later phases: phase 1 is the spawn itself
		end
	end)

	return M
end
