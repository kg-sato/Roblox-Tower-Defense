-- BossBar (T149, 2026-10-29): client feedback for the boss framework (see Boss Framework note). Phase pips under the boss plate,
-- a banner per phase, a red flicker and "SILENCED" on a denied familiar, a cold overlay with a countdown while the boss freezes
-- everything, and short notes for regen and summon. Driven by the server events BossPhase and BossFx and the snapshot field boss.
-- GameClient calls this once with the outside locals it needs and forwards the events: BossBar.event(kind, data), BossBar.snap(snapshot.boss).
return function(env)
	local hud, plate, STYLE, new, tween = env.hud, env.bossBarBg, env.STYLE, env.new, env.tween
	local showBanner, showToast, floatText, petParts, groundOf, FXK, SETTINGS = env.showBanner, env.showToast, env.floatText, env.petParts, env.groundOf, env.FXK, env.SETTINGS
	local M = { phase = 0, phases = 3 }
	local LIT, DIM, ICE = Color3.fromRGB(255, 120, 95), Color3.fromRGB(70, 40, 44), Color3.fromRGB(150, 210, 255)

	-- phase strip: hangs under the plate, so it shows and hides with it
	local strip = new("Frame", { Name = "PhaseStrip", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 1, 3), Size = UDim2.fromOffset(240, 22), ZIndex = 6 }, plate)
	local pips = {}
	for i = 1, 3 do
		pips[i] = new("Frame", { Name = "Pip" .. i, BackgroundColor3 = DIM, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new((i - 0.5) / 3, 0, 0, 0), Size = UDim2.new(1 / 3, -6, 0, 8), ZIndex = 6 }, strip)
		new("UIStroke", { Color = Color3.fromRGB(190, 140, 60), Thickness = 1 }, pips[i])
	end
	local cap = new("TextLabel", { Name = "Phase", BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Color3.fromRGB(255, 225, 200), Text = "",
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 9), Size = UDim2.new(1, 0, 0, 13), ZIndex = 6 }, strip)
	new("UIStroke", { Color = Color3.fromRGB(30, 8, 8), Thickness = 1.2 }, cap)

	local function setPhase(phase, phases, text)
		M.phase, M.phases = phase, phases or 3
		for i, p in pips do
			p.Visible = i <= M.phases
			tween(p, 0.25, { BackgroundColor3 = i <= phase and LIT or DIM })
		end
		cap.Text = text or string.format("PHASE %d / %d", phase, M.phases)
	end

	-- freeze overlay (everything is frozen): cold tint plus a countdown, one at a time
	local ov = new("Frame", { Name = "BossFreeze", BackgroundColor3 = ICE, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 30, Visible = false, Active = false }, hud)
	new("UIStroke", { Color = ICE, Thickness = 6, Transparency = 0.35 }, ov)
	local ovText = new("TextLabel", { BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, TextSize = 30, TextColor3 = Color3.fromRGB(235, 248, 255), Text = "", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromOffset(300, 40), ZIndex = 31 }, ov)
	new("UIStroke", { Color = Color3.fromRGB(10, 40, 80), Thickness = 2 }, ovText)
	local freezeToken = 0
	local function freeze(dur)
		freezeToken += 1
		local tok = freezeToken
		ov.Visible = true
		tween(ov, 0.12, { BackgroundTransparency = 0.82 })
		FXK.play("glass_crack", { pitch = 0.7, volume = 0.5 })
		task.spawn(function()
			local untilT = os.clock() + dur
			while tok == freezeToken and os.clock() < untilT do
				ovText.Text = string.format("FROZEN  %.1f", math.max(0, untilT - os.clock()))
				task.wait(0.1)
			end
			if tok == freezeToken then
				tween(ov, 0.25, { BackgroundTransparency = 1 })
				task.wait(0.26)
				if tok == freezeToken then ov.Visible = false end
			end
		end)
	end

	-- denied familiar: red highlight that flickers (steady when reduced motion is on) for the denial time
	local function deny(slot, dur)
		local entry = petParts[slot]
		if not entry then return end
		local h = new("Highlight", { FillColor = Color3.fromRGB(255, 60, 50), OutlineColor = Color3.fromRGB(255, 200, 190), FillTransparency = 0.55, DepthMode = Enum.HighlightDepthMode.Occluded }, entry.model)
		floatText(groundOf(slot) + Vector3.new(0, 7, 0), "SILENCED", Color3.fromRGB(255, 110, 100), 22)
		FXK.play("merge_fail", { pitch = 0.8, volume = 0.5 })
		task.spawn(function()
			local untilT = os.clock() + (dur or 1.5)
			while os.clock() < untilT and h.Parent do
				h.FillTransparency = SETTINGS.reducedMotion and 0.55 or (math.floor(os.clock() * 8) % 2 == 0 and 0.35 or 0.75)
				task.wait(0.06)
			end
			h:Destroy()
		end)
	end

	function M.event(kind, data)
		if type(data) ~= "table" then return end
		if kind == "BossPhase" then
			setPhase(data.phase, data.phases, string.format("PHASE %d / %d  -  %s", data.phase, data.phases or 3, string.upper(tostring(data.banner or ""))))
			if data.phase > 1 then -- phase 1 is the spawn itself; the BOSS! banner covers it
				showBanner("PHASE " .. data.phase, Color3.fromRGB(255, 90, 80), tostring(data.banner or ""))
				FXK.play("anticipation", { pitch = 0.8 })
			end
		elseif kind == "BossFx" then
			if data.kind == "deny" then deny(data.slot, data.dur)
			elseif data.kind == "freeze" then freeze(data.dur or 3)
			elseif data.kind == "summon" then showToast("The boss calls reinforcements!")
			elseif data.kind == "regen" then showToast("The boss mends itself")
			end
		end
	end

	function M.snap(boss) -- snapshot.boss: nil when no boss lives
		if boss then
			if boss.phase ~= M.phase or boss.phases ~= M.phases then setPhase(boss.phase, boss.phases) end
		else
			if M.phase ~= 0 then -- the boss just died or left: clear its state
				setPhase(0, 3, "")
				freezeToken += 1
				ov.Visible = false
			end
		end
	end

	setPhase(0, 3, "")
	return M
end
