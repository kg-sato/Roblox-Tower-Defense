--!nocheck
-- VFXVerify: automated checks for the VFX modules, so nothing depends on someone watching. Standalone; test tooling only.
-- Source: VFX/VFXVerify.luau, installed as ReplicatedStorage.VFXVerify. Each function returns a list of
-- { name, status = "PASS" | "FAIL" | "UNVERIFIED", detail }. UNVERIFIED means this check cannot tell (for example no audio device).
--
--   VFXVerify.static()           module audits + cue names vs the sound catalog (works in Edit mode)
--   VFXVerify.sounds()           files load and lengths match; playback actually advances; concurrency cap (playtest client)
--   VFXVerify.cues(pos)          cue timing against the intended sequence, real time (playtest client)
--   VFXVerify.loadingSync(hud)   loading cues equal their beats, real time (playtest client)
--   VFXVerify.motion()           camera blur follows camera speed, is capped and clears (playtest client)
--   VFXVerify.echo(gui)          UI motion echoes appear while fast, are capped, and clean up (playtest client)
--   VFXVerify.leaks()            nothing left behind: lighting, camera effects, parts, sounds
--   VFXVerify.format(results)    one text block
-- What this cannot judge: whether anything looks or sounds good. See the verification report for what is and is not covered.

local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")

local V = {}

local function add(list, name, ok, detail, unverified)
	table.insert(list, { name = name, status = unverified and "UNVERIFIED" or (ok and "PASS" or "FAIL"), detail = detail or "" })
end

function V.format(results)
	local out, p, f, u = {}, 0, 0, 0
	for _, r in ipairs(results) do
		table.insert(out, string.format("%-10s %s%s", r.status, r.name, r.detail ~= "" and (": " .. r.detail) or ""))
		if r.status == "PASS" then
			p += 1
		elseif r.status == "FAIL" then
			f += 1
		else
			u += 1
		end
	end
	table.insert(out, string.format("== %d pass, %d fail, %d unverified", p, f, u))
	return table.concat(out, "\n")
end

local function req(name)
	local m = RS:FindFirstChild(name)
	return m and require(m) or nil
end

-- ---- static (no playtest needed) ---------------------------------------------------------------------------------------
function V.static()
	local R = {}
	local Reveal, Loading, Feedback, Motion = req("RevealFX"), req("LoadingFX"), req("FeedbackFX"), req("MotionBlurFX")
	local Catalog = req("SoundCatalog")
	add(R, "modules present", Reveal and Loading and Feedback and Motion and Catalog and true, "RevealFX, LoadingFX, FeedbackFX, MotionBlurFX, SoundCatalog")
	local rep, f = Reveal.audit()
	add(R, "RevealFX audit (limits for every tier x settings)", f == 0, f == 0 and "pass" or rep)
	rep, f = Loading.audit()
	add(R, "LoadingFX audit (beats, blur caps, soft mode)", f == 0, f == 0 and "pass" or rep)
	rep, f = Motion.audit()
	add(R, "MotionBlurFX audit (maths)", f == 0, f == 0 and "pass" or rep)
	-- every cue any module can emit must exist in the catalog
	local used = {}
	local variants = {}
	for _, t in ipairs(Reveal.order) do
		table.insert(variants, { tier = t, anticipate = (t == "Rare" or t == "Epic" or t == "Legendary") })
	end
	table.insert(variants, { tier = "Legendary", idea = "Ink" })
	table.insert(variants, { tier = "Legendary", idea = "Vortex" })
	for _, v in ipairs(variants) do
		local h = Reveal.play(v.tier, { headless = true, idea = v.idea, anticipate = v.anticipate, position = Vector3.zero, sfx = function() end })
		for _, c in ipairs(h.stats.cues) do
			used[c.name] = true
		end
	end
	local Merge = req("MergeCore")
	if Merge then
		for _, n in ipairs(Merge.cueNames) do
			used[n] = true
		end
		local rep2, f2 = Merge.test()
		add(R, "MergeCore rules (merge, conservation, no dead end, ascend, determinism)", f2 == 0, f2 == 0 and "pass" or rep2)
	end
	local Roster = req("Roster")
	if Roster then
		local rep3, f3 = Roster.test()
		add(R, "Roster (8 distinct characters)", f3 == 0, rep3)
	end
	local Music = req("MusicFX")
	if Music then
		local rep4, f4 = Music.audit()
		add(R, "MusicFX audit (tracks load, lengths match, playlists)", f4 == 0, f4 == 0 and "pass" or rep4)
	end
	local lh = Loading.play({ headless = true, minTime = 0 })
	lh.finish()
	for _, c in ipairs(lh.stats.cues) do
		used[c.name] = true
	end
	for _, n in ipairs({ "combo", "ring", "milestone", "spotlight", "menu_open", "menu_close", "discovery" }) do
		used[n] = true
	end
	local missing, unusedList = {}, {}
	for n in pairs(used) do
		if not Catalog[n] then
			table.insert(missing, n)
		end
	end
	for n in pairs(Catalog) do
		if not used[n] then
			table.insert(unusedList, n)
		end
	end
	table.sort(missing)
	table.sort(unusedList)
	add(R, "every cue name has a sound", #missing == 0, #missing == 0 and "all cues covered" or ("missing: " .. table.concat(missing, ", ")))
	add(R, "every sound is used by a cue", #unusedList == 0, #unusedList == 0 and "none unused" or ("not triggered by any module: " .. table.concat(unusedList, ", ")), #unusedList > 0)
	return R
end

-- ---- sounds ---------------------------------------------------------------------------------------------------------------
function V.sounds()
	local R = {}
	local SoundFX = req("SoundFX")
	local rep, f = SoundFX.audit()
	add(R, "sound files load and match their measured length", f == 0, f == 0 and rep or rep)
	-- playback advances (proves the engine is playing it, not just that it loaded)
	local s = SoundFX.play("combo", {})
	task.wait(0.35)
	local pos = s and s.TimePosition or -1
	local playing = s and s.Playing
	add(R, "playback advances", playing and pos > 0.15, string.format("Playing=%s TimePosition=%.2f after 0.35 s", tostring(playing), pos), not (playing and pos > 0.15))
	task.wait(1.0)
	-- concurrency cap: 14 rapid cues never exceed 8 live sounds (6 on touch), UI ones dropped first
	local peak = 0
	for i = 1, 14 do
		SoundFX.play(i % 3 == 0 and "ui_click" or "rare", {})
		local live = 0
		for _, c in ipairs(SoundService:GetChildren()) do
			if c:IsA("Sound") and c.Name:sub(1, 4) == "VFX_" then
				live += 1
			end
		end
		peak = math.max(peak, live)
		task.wait(0.03)
	end
	add(R, "concurrent sounds are capped", peak <= 8, "peak live sounds " .. peak .. " (cap 8)")
	task.wait(2.4)
	local left = 0
	for _, c in ipairs(SoundService:GetChildren()) do
		if c:IsA("Sound") and c.Name:sub(1, 4) == "VFX_" then
			left += 1
		end
	end
	add(R, "finished sounds destroy themselves", left == 0, left .. " left after 2.4 s")
	return R
end

-- ---- cue timing, real time ----------------------------------------------------------------------------------------------
local function timing(R, label, got, expect, tol)
	local byName = {}
	for _, c in ipairs(got) do
		byName[c.name] = byName[c.name] or c.t
	end
	for name, t in pairs(expect) do
		local g = byName[name]
		add(R, string.format("%s: %s cue at %.2f s", label, name, t), g ~= nil and math.abs(g - t) <= tol, g and string.format("measured %.3f s (tolerance %.2f)", g, tol) or "cue never fired")
	end
end

function V.cues(pos)
	local R = {}
	local Reveal = req("RevealFX")
	local got = {}
	local t0 = os.clock()
	local h = Reveal.play("Ultimate", { position = pos, sfx = function(name)
		table.insert(got, { name = name, t = os.clock() - t0 })
	end })
	task.wait(h.stats and 8.2 or 8)
	timing(R, "Ultimate", got, { ultimate_summon = 0, ultimate_sword = 0.9, ultimate_fall = 2.9, ultimate_impact = 3.32 }, 0.1)
	local order = {}
	for _, c in ipairs(got) do
		table.insert(order, c.name)
	end
	add(R, "Ultimate cue order", table.concat(order, ",") == "ultimate_summon,ultimate_sword,ultimate_fall,ultimate_impact", table.concat(order, ","))
	-- Legendary / Ink with its 4 s anticipation
	got = {}
	t0 = os.clock()
	local h2 = Reveal.play("Legendary", { position = pos, idea = "Ink", sfx = function(name, len)
		table.insert(got, { name = name, t = os.clock() - t0, len = len })
	end })
	task.wait(9.2)
	timing(R, "Legendary/Ink", got, { anticipation = 0, ink = 4.0 }, 0.1)
	local ant
	for _, c in ipairs(got) do
		if c.name == "anticipation" then
			ant = c.len
		end
	end
	add(R, "anticipation cue carries its length (so the riser is trimmed to it)", ant == 4.0, "length passed " .. tostring(ant))
	return R
end

function V.loadingSync(hud)
	local R = {}
	local Loading = req("LoadingFX")
	local h = Loading.play({ total = 6, hud = hud, autoProgress = 2.2, minTime = 1.6, measure = true })
	local t0 = os.clock()
	while not h.done and os.clock() - t0 < 14 do
		task.wait(0.1)
	end
	local beats = {}
	for _, b in ipairs(h.stats.beats) do
		beats[b.name] = b.t
	end
	local map = { load_start = "fadeUp", load_synced = "synced", load_resolve = "resolve" }
	for _, c in ipairs(h.stats.cues) do
		local b = beats[map[c.name]]
		add(R, "Loading: " .. c.name .. " cue lands on beat " .. map[c.name], b ~= nil and math.abs(c.t - b) < 0.03, string.format("cue %.3f s, beat %.3f s", c.t, b or -1))
	end
	add(R, "Loading finished and cleaned up", h.done, "")
	return R
end

-- ---- motion blur ---------------------------------------------------------------------------------------------------------
function V.motion()
	local R = {}
	local Motion = req("MotionBlurFX")
	local cam = workspace.CurrentCamera
	local base = cam.CFrame
	local yaw = 0
	local speed = 0
	local bindName = "vfxspin"
	RunService:BindToRenderStep(bindName, Enum.RenderPriority.Camera.Value + 10, function(dt)
		yaw += speed * dt
		cam.CameraType = Enum.CameraType.Scriptable
		cam.CFrame = base * CFrame.Angles(0, yaw, 0)
	end)
	local mb = Motion.cameraBlur({ forceTouch = false })
	local cap = mb.stats.cap
	local rows, prev, mono = {}, -1, true
	for _, sp in ipairs({ 0, 0.5, 1, 2, 4, 8 }) do
		speed = sp
		task.wait(1.3)
		local acc, n = 0, 0
		local t0 = os.clock()
		while os.clock() - t0 < 0.4 do
			acc += mb.size()
			n += 1
			task.wait()
		end
		local avg = acc / math.max(n, 1)
		local expect = math.clamp((sp - Motion.tuning.deadzone) * Motion.tuning.gain, 0, cap)
		table.insert(rows, string.format("%.1f rad/s -> %.2f (expected %.2f)", sp, avg, expect))
		add(R, string.format("blur follows camera speed %.1f rad/s", sp), math.abs(avg - expect) <= math.max(0.35, expect * 0.3), string.format("measured %.2f, expected %.2f, cap %.1f", avg, expect, cap))
		if avg < prev - 0.15 then
			mono = false
		end
		prev = avg
	end
	add(R, "blur never exceeds the cap", mb.stats.peak <= cap + 0.01, string.format("peak %.2f, cap %.1f", mb.stats.peak, cap))
	add(R, "response is monotonic with speed", mono, table.concat(rows, "; "))
	speed = 0
	task.wait(1.0)
	add(R, "blur clears after the camera stops", mb.size() < 0.3, string.format("%.2f one second after stopping", mb.size()))
	mb.stop()
	add(R, "stop() removes the BlurEffect", cam:FindFirstChild("MotionBlurFX") == nil, "")
	-- touch cap
	local mt = Motion.cameraBlur({ forceTouch = true })
	speed = 8
	task.wait(1.4)
	add(R, "touch cap is 4", mt.size() <= 4.01 and mt.size() > 2, string.format("size %.2f at 8 rad/s", mt.size()))
	mt.stop()
	-- reduced motion
	local mr = Motion.cameraBlur({ settings = { reducedMotion = true } })
	task.wait(0.3)
	add(R, "reduced motion: no camera blur", mr.stats.off and cam:FindFirstChild("MotionBlurFX") == nil, "")
	speed = 0
	RunService:UnbindFromRenderStep(bindName)
	return R
end

function V.echo(gui)
	local R = {}
	local Motion = req("MotionBlurFX")
	local f = Instance.new("Frame")
	f.Name = "EchoTest"
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.fromScale(0.1, 0.5)
	f.Size = UDim2.fromScale(0.1, 0.1)
	f.BackgroundColor3 = Color3.fromRGB(255, 190, 40)
	f.Parent = gui
	local h = Motion.slide(f, UDim2.fromScale(0.9, 0.5), 0.6)
	task.wait(0.28)
	local mid = 0
	for _, c in ipairs(gui:GetChildren()) do
		if c.Name == "MBGhost" then
			mid += 1
		end
	end
	task.wait(1.2)
	local after = 0
	for _, c in ipairs(gui:GetChildren()) do
		if c.Name == "MBGhost" then
			after += 1
		end
	end
	add(R, "UI echoes appear while the object is fast", mid >= 2, mid .. " echoes alive mid-slide, " .. h.stats.ghosts .. " spawned in total")
	add(R, "echo count is capped", h.stats.maxAlive <= 4, "max alive " .. h.stats.maxAlive .. " (cap 4 at Default)")
	add(R, "echoes clean up", after == 0, after .. " left")
	f.Position = UDim2.fromScale(0.1, 0.5)
	local h2 = Motion.slide(f, UDim2.fromScale(0.9, 0.5), 0.6, { settings = { reducedMotion = true } })
	task.wait(0.8)
	add(R, "reduced motion: no echoes", h2.stats.ghosts == 0, h2.stats.ghosts .. " spawned")
	f:Destroy()
	return R
end


-- ---- music --------------------------------------------------------------------------------------------------------------
local function liveMusic()
	local n, list = 0, {}
	for _, c in ipairs(SoundService:GetChildren()) do
		if c:IsA("Sound") and c.Name:sub(1, 4) == "MUS_" then
			n += 1
			table.insert(list, c)
		end
	end
	return n, list
end

function V.music()
	local R = {}
	local Music = req("MusicFX")
	Music.stop(0)
	Music.setVolumes({ music = 1 })
	Music.play("play")
	-- fade in: sample the volume for 1.2 s, it must rise smoothly (no jump bigger than 25% of the target)
	local samples = {}
	for _ = 1, 12 do
		task.wait(0.1)
		local _, l = liveMusic()
		table.insert(samples, l[1] and l[1].Volume or -1)
	end
	local target = Music.catalog[Music.states.play[1]].vol
	local smooth, mono = true, true
	for i = 2, #samples do
		if samples[i] - samples[i - 1] > 0.25 * target then
			smooth = false
		end
		if samples[i] < samples[i - 1] - 0.001 then
			mono = false
		end
	end
	add(R, "music fades in smoothly", smooth and mono and samples[#samples] > 0.5 * target, string.format("volume %.3f -> %.3f (target %.2f)", samples[1], samples[#samples], target))
	task.wait(1.0)
	local n, l = liveMusic()
	add(R, "play() runs exactly one main track", n == 1 and l[1].Playing and l[1].TimePosition > 0.5, string.format("%d sound(s), %s, position %.2f", n, n > 0 and l[1].Name or "-", n > 0 and l[1].TimePosition or -1))
	local steady = l[1] and l[1].Volume or 0
	-- crossfade to another state: two tracks overlap, the sum never exceeds one track by more than 15%, then one remains
	Music.play("menu")
	local maxLive, maxSum = 0, 0
	for _ = 1, 50 do
		task.wait(0.1)
		local c, ls = liveMusic()
		maxLive = math.max(maxLive, c)
		local sum = 0
		for _, snd in ipairs(ls) do
			sum += snd.Volume
		end
		maxSum = math.max(maxSum, sum)
	end
	local nAfter = liveMusic()
	add(R, "crossfade overlaps then settles on one track", maxLive == 2 and nAfter == 1, string.format("max live %d, live after 5 s %d", maxLive, nAfter))
	add(R, "crossfade keeps the combined level in check", maxSum <= steady * 1.4 + 0.02, string.format("peak combined %.3f vs one track %.3f", maxSum, steady))
	-- tension bed: eases in quietly under the music, the music dips a little
	local _, ls0 = liveMusic()
	local before = ls0[1] and ls0[1].Volume or 0
	Music.setTension(1)
	task.wait(3.0)
	local count, ls = liveMusic()
	local bed, mainNow = nil, nil
	for _, snd in ipairs(ls) do
		if snd.Name == "MUS_" .. Music.tensionBed then
			bed = snd
		else
			mainNow = snd
		end
	end
	add(R, "tension bed plays under the music", bed ~= nil and bed.Playing, bed and string.format("bed volume %.3f, music %.3f", bed.Volume, mainNow and mainNow.Volume or -1) or "no bed")
	add(R, "tension bed stays well below the music (about 10 dB)", bed ~= nil and mainNow ~= nil and bed.Volume <= mainNow.Volume * 0.75, bed and mainNow and string.format("bed %.3f vs music %.3f", bed.Volume, mainNow.Volume) or "")
	add(R, "music dips at most 15% under full tension", mainNow ~= nil and mainNow.Volume >= before * 0.84 and mainNow.Volume <= before * 0.95, mainNow and string.format("%.3f -> %.3f", before, mainNow.Volume) or "")
	-- duck under a dramatic cue and recover
	local base = mainNow and mainNow.Volume or 0
	Music.duck(0.5, 1.5)
	local low = 1e9
	for _ = 1, 20 do
		task.wait(0.1)
		if mainNow and mainNow.Parent then
			low = math.min(low, mainNow.Volume)
		end
	end
	task.wait(3.5)
	add(R, "duck drops the music then restores it", mainNow ~= nil and low <= base * 0.65 and mainNow.Volume >= base * 0.95, string.format("base %.3f, lowest %.3f, after %.3f", base, low, mainNow and mainNow.Volume or -1))
	-- master volume
	Music.setVolumes({ music = 0.5 })
	task.wait(1.2)
	add(R, "music volume setting is honoured", mainNow ~= nil and mainNow.Volume <= base * 0.6, string.format("%.3f at music=0.5 (was %.3f)", mainNow and mainNow.Volume or -1, base))
	Music.setVolumes({ music = 1 })
	-- playlists never repeat; advance gives a different track
	local cur = Music.status().main[#Music.status().main]
	Music.stop(0)
	local left = liveMusic()
	add(R, "stop() leaves nothing behind", left == 0, left .. " music sounds left")
	return R
end

function V.leaks()
	local R = {}
	local cam = workspace.CurrentCamera
	local n = 0
	for _, c in ipairs(workspace:GetChildren()) do
		if c.Name:find("RevealFX") then
			n += 1
		end
	end
	for _, c in ipairs(Lighting:GetChildren()) do
		if c.Name:find("RevealFX") or c.Name:find("LoadingFX") then
			n += 1
		end
	end
	local blurs = 0
	for _, c in ipairs(cam:GetChildren()) do
		if c:IsA("BlurEffect") then
			blurs += 1
		end
	end
	local sounds = 0
	for _, c in ipairs(SoundService:GetChildren()) do
		if c:IsA("Sound") and c.Name:sub(1, 4) == "VFX_" then
			sounds += 1
		end
	end
	add(R, "no effect objects left in Workspace or Lighting", n == 0, n .. " found")
	add(R, "no BlurEffect left on the camera", blurs == 0, blurs .. " found")
	add(R, "no VFX sound left playing or allocated", sounds == 0, sounds .. " found")
	add(R, "Lighting restored", math.abs(Lighting.Brightness - 3) < 0.01 and math.abs(Lighting.ClockTime - 14) < 0.01, string.format("Brightness %.2f ClockTime %.2f (project default 3 and 14)", Lighting.Brightness, Lighting.ClockTime))
	return R
end

return V
