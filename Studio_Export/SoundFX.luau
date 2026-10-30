--!nocheck
-- SoundFX: plays the VFX cue sounds. Standalone, client-side. Source: VFX/SoundFX.luau (+ generated VFX/SoundCatalog.luau),
-- installed as ReplicatedStorage.SoundFX / SoundCatalog. The sounds are synthesized by VFX/sfx/make_sfx.py and loaded from
-- rbxasset://sounds/vfx/<name>.wav (dev preview only; a published game needs them uploaded, then SoundFX.base swapped for ids).
--
--   local SoundFX = require(game.ReplicatedStorage.SoundFX)
--   SoundFX.attach(require(...RevealFX))          -- every effect module now plays its cues (RevealFX.defaultSfx)
--   SoundFX.play("ultimate_impact")               -- or by hand: name, { volume, pitch, length, delay }
--   SoundFX.setVolumes({ master = 1, sfx = 0.8 }) -- from the Settings screen (Music is a separate group, not used here)
--   SoundFX.audit()                               -- in-engine check: every file loads and its TimeLength matches the catalog
-- Rules: one SoundGroup for all effect sounds; at most 8 sounds at once (6 on touch), UI sounds are dropped first, and a new sound
-- of lower priority than every playing one is dropped instead of stopping a higher one; `length`
-- trims a long sound (the 4 s anticipation riser is cut at the reveal's own anticipation length with a 0.25 s fade);
-- every sound destroys itself when it ends; nothing loops.

local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local SoundFX = {}
SoundFX.base = "rbxasset://sounds/vfx/"
SoundFX.catalog = require(script.Parent:WaitForChild("SoundCatalog"))
SoundFX.catalogOld = SoundFX.catalog -- files that always exist; SoundCues adds the overnight cue set on top (T630)
local idsModule = script.Parent:FindFirstChild("AudioIds")
SoundFX.ids = idsModule and require(idsModule).sfx or {}
local cuesModule = script.Parent:FindFirstChild("SoundCues")
local Cues = cuesModule and require(cuesModule)
if Cues then
	SoundFX.catalog = table.clone(SoundFX.catalogOld)
	SoundFX.ids = table.clone(SoundFX.ids)
	for k, v in Cues.catalog do
		SoundFX.catalog[k] = v
	end
	for k, v in Cues.ids do
		SoundFX.ids[k] = v
	end
end

-- uploaded asset id when there is one, else the local Studio preview file
function SoundFX.soundId(name)
	local id = SoundFX.ids[name]
	return id and ("rbxassetid://" .. tostring(id)) or (SoundFX.base .. name .. ".wav")
end
SoundFX.volumes = { master = 1, sfx = 1, ui = 1 } -- ui scales the UI cues only (SoundCues.isUI), T605
SoundFX.log = nil -- set to {} to record every play { name, t, ok }

local active = {}
local group

local function getGroup()
	if group and group.Parent then
		return group
	end
	group = SoundService:FindFirstChild("VFX_SFX")
	if not group then
		group = Instance.new("SoundGroup")
		group.Name = "VFX_SFX"
		group.Volume = 1
		group.Parent = SoundService
	end
	return group
end

local function maxConcurrent(force)
	local touch = force
	if touch == nil then
		touch = UserInputService.TouchEnabled
	end
	return touch and 6 or 8
end

function SoundFX.setVolumes(v)
	for k, x in pairs(v) do
		SoundFX.volumes[k] = math.clamp(x, 0, 1)
	end
	getGroup().Volume = SoundFX.volumes.master * SoundFX.volumes.sfx
end

function SoundFX.play(name, o)
	o = o or {}
	if Cues then
		local origName = name
		name = Cues.resolve(name, SoundFX.catalogOld) -- alias to a new cue, or an existing one when the new cue is not uploaded
		if not name then
			if SoundFX.log then
				table.insert(SoundFX.log, { name = tostring(origName), t = os.clock(), ok = false, why = "no asset for this cue" })
			end
			return nil
		end
	end
	local e = SoundFX.catalog[name]
	if not e then
		warn("SoundFX: unknown sound " .. tostring(name))
		return nil
	end
	-- concurrency cap: drop the new sound if it is UI and we are full; otherwise stop the oldest lowest-priority one
	local cap = maxConcurrent(o.forceTouch)
	if #active >= cap then
		if e.pri <= 1 then
			if SoundFX.log then
				table.insert(SoundFX.log, { name = name, t = os.clock(), ok = false, why = "dropped (cap)" })
			end
			return nil
		end
		local worst, wi
		for i, a in ipairs(active) do
			if not worst or a.pri < worst.pri then
				worst, wi = a, i
			end
		end
		if worst and worst.pri > e.pri then
			-- a lower priority never stops a higher one: the new sound is the one dropped
			if SoundFX.log then
				table.insert(SoundFX.log, { name = name, t = os.clock(), ok = false, why = "dropped (lower priority)" })
			end
			return nil
		end
		if worst then
			worst.sound:Stop()
			worst.sound:Destroy()
			table.remove(active, wi)
		end
	end
	local s = Instance.new("Sound")
	s.Name = "VFX_" .. name
	s.SoundId = SoundFX.soundId(name)
	s.Volume = e.vol * (o.volume or 1) * ((Cues and Cues.isUI(name)) and SoundFX.volumes.ui or 1)
	s.PlaybackSpeed = (o.pitch or 1) * (1 + (math.random() - 0.5) * 2 * e.jit)
	s.RollOffMaxDistance = 0
	s.SoundGroup = getGroup()
	s.Parent = SoundService
	local rec = { sound = s, pri = e.pri, name = name }
	table.insert(active, rec)
	local function remove()
		for i, a in ipairs(active) do
			if a == rec then
				table.remove(active, i)
				break
			end
		end
		if s.Parent then
			s:Destroy()
		end
	end
	s.Ended:Connect(remove)
	task.delay((o.delay or 0), function()
		if not s.Parent then
			return
		end
		s:Play()
		if SoundFX.log then
			table.insert(SoundFX.log, { name = name, t = os.clock(), ok = true })
		end
		-- trim: fade out over 0.25 s ending at `length`
		if o.length and o.length < e.dur then
			task.delay(math.max(0, o.length - 0.25), function()
				if s.Parent then
					local t = TweenService:Create(s, TweenInfo.new(0.25, Enum.EasingStyle.Sine), { Volume = 0 })
					t:Play()
					t.Completed:Once(remove)
				end
			end)
		end
	end)
	-- safety net: never leave a sound behind if Ended does not fire (for example if the asset failed to load)
	task.delay(e.dur / math.max(0.25, s.PlaybackSpeed) + (o.delay or 0) + 2, remove)
	return s
end

-- makes every effect module play its cues. Each module calls RevealFX.defaultSfx(name, length, pitch) at its cue points.
function SoundFX.attach(RevealFX)
	RevealFX.defaultSfx = function(name, length, pitch)
		SoundFX.play(name, { length = length, pitch = pitch })
	end
end

-- In-engine check (needs a client or Studio edit session with audio content): every file exists, loads, and has the
-- duration the analysis measured. Returns (report, failures).
function SoundFX.audit()
	local lines, fails = {}, 0
	local names = {}
	for n in pairs(SoundFX.catalog) do
		table.insert(names, n)
	end
	table.sort(names)
	for _, n in ipairs(names) do
		local e = SoundFX.catalog[n]
		if Cues and Cues.catalog[n] and not Cues.ids[n] then
			continue -- new cue with no upload yet: SoundCues resolves it to an existing cue
		end
		local s = Instance.new("Sound")
		s.SoundId = SoundFX.soundId(n)
		s.Parent = SoundService
		local ok = pcall(function()
			ContentProvider:PreloadAsync({ s })
		end)
		local t0 = os.clock()
		while not s.IsLoaded and os.clock() - t0 < 3 do
			task.wait(0.05)
		end
		local len = s.TimeLength
		if not ok or not s.IsLoaded then
			fails += 1
			table.insert(lines, "FAIL " .. n .. ": did not load")
		elseif math.abs(len - e.dur) > math.max(0.03, e.dur * 0.03) then
			fails += 1
			table.insert(lines, string.format("FAIL %s: TimeLength %.3f vs catalog %.3f", n, len, e.dur))
		end
		s:Destroy()
	end
	table.insert(lines, fails == 0 and string.format("SOUND AUDIT PASS (%d files load, lengths match the analysis)", #names) or ("SOUND AUDIT FAILURES: " .. fails))
	return table.concat(lines, "\n"), fails
end

return SoundFX
