--!nocheck
-- MusicFX: music playback for the game. Standalone, client-side. Source: VFX/MusicFX.luau (+ generated VFX/MusicCatalog.luau),
-- installed as ReplicatedStorage.MusicFX / MusicCatalog. Tracks: Audio/CREDITS.md (all CC0). Loaded from rbxasset://sounds/music/
-- (local Studio folder, dev preview only; a published game needs uploaded assets and ids).
--
--   local Music = require(game.ReplicatedStorage.MusicFX)
--   Music.play("menu")            -- states: "menu" (Shinsei, Iremos Forest), "play" (Chill lofi, Rising Moon), "wish" (Iremos Forest)
--   Music.setTension(0.6)         -- 0..1: eases in the eerie "Artifact Room" bed under the music (tiny tension, not a horror score)
--   Music.duck(0.5, 2.5)          -- drop the music by 50% now, ease back over 2.5 s (use under big sound effects)
--   Music.setVolumes({ music = 0.8 })
--   Music.attach(RevealFX)        -- ducks automatically under reveal cues (anticipation, bursts, impacts)
--   Music.stop(1.5)
--   Music.audit()                 -- catalog + file lengths in the engine
-- Rules: at most 3 music sounds exist at once (outgoing, incoming, tension bed); every volume change is smoothed (rate 3/s),
-- so crossfades, ducks and tension never jump; tracks that do not loop crossfade into the next playlist entry 3 s before
-- they end; the same track never plays twice in a row unless the playlist has one entry; nothing is left behind after stop().

local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local ContentProvider = game:GetService("ContentProvider")

local Music = {}
Music.base = "rbxasset://sounds/music/"
Music.catalog = require(script.Parent:WaitForChild("MusicCatalog"))
local idsModule = script.Parent:FindFirstChild("AudioIds")
Music.ids = idsModule and require(idsModule).music or {}

-- uploaded asset id when there is one, else the local Studio preview file
function Music.soundId(name)
	local id = Music.ids[name]
	return id and ("rbxassetid://" .. tostring(id)) or (Music.base .. name .. ".ogg")
end
Music.states = {
	menu = { "shinsei", "iremos_forest" },
	play = { "chill_lofi", "rising_moon" },
	wish = { "iremos_forest" },
}
Music.volumes = { music = 1 }
Music.fade = 3.0 -- crossfade seconds
-- fires (name) every time a main track starts; the Now Playing popup listens to it
Music.TrackStarted = Instance.new("BindableEvent")
Music.tensionBed = "artifact_room"
Music.tensionMax = 0.55 -- the bed reaches 55% of its own trim (about 10 dB under the music) at full tension; the main music drops at most 12% with it

local group
local main = {} -- list of { sound, name, target, vol }
local tension -- { sound, target, vol }
local state, playlistIndex = nil, 0
local tensionLevel, duckMul, duckTarget, duckRate = 0, 1, 1, 3
local conn

local function getGroup()
	if group and group.Parent then
		return group
	end
	group = SoundService:FindFirstChild("VFX_Music")
	if not group then
		group = Instance.new("SoundGroup")
		group.Name = "VFX_Music"
		group.Volume = 1
		group.Parent = SoundService
	end
	return group
end

local function newSound(name, looped)
	local e = Music.catalog[name]
	local s = Instance.new("Sound")
	s.Name = "MUS_" .. name
	s.SoundId = Music.soundId(name)
	s.Looped = looped or false
	s.Volume = 0
	s.SoundGroup = getGroup()
	s.Parent = SoundService
	s:Play()
	return s, e
end

local function kill(rec)
	if rec and rec.sound and rec.sound.Parent then
		rec.sound:Stop()
		rec.sound:Destroy()
	end
end

-- picks the next track from a playlist without repeating the current one (pure: tested headless)
function Music._pick(list, lastName, index)
	if #list <= 1 then
		return list[1], 1
	end
	local i = index % #list + 1
	if list[i] == lastName then
		i = i % #list + 1
	end
	return list[i], i
end

local function gainFor(rec)
	local mainTension = 1 - 0.12 * tensionLevel
	return rec.vol * Music.volumes.music * duckMul * mainTension
end

local function step(dt)
	local k = 1 - math.exp(-3 * dt)
	duckMul += (duckTarget - duckMul) * (1 - math.exp(-duckRate * dt))
	for i = #main, 1, -1 do
		local rec = main[i]
		rec.cur += (rec.target - rec.cur) * k
		if rec.sound.Parent then
			rec.sound.Volume = rec.cur * gainFor(rec)
		end
		if rec.target == 0 and rec.cur < 0.01 then
			kill(rec)
			table.remove(main, i)
		end
	end
	if tension then
		tension.cur += (tension.target - tension.cur) * k
		if tension.sound.Parent then
			tension.sound.Volume = tension.cur * tension.vol * Music.volumes.music
		end
		if tension.target == 0 and tension.cur < 0.01 then
			kill(tension)
			tension = nil
		end
	end
	-- queue the next track shortly before a non-looping one ends
	local cur = main[#main]
	if cur and cur.target == 1 and not cur.sound.Looped and state and cur.sound.IsLoaded then
		local len = cur.sound.TimeLength
		if len > 0 and cur.sound.TimePosition >= len - Music.fade and not cur.queued then
			cur.queued = true
			Music._advance()
		end
	end
	if #main == 0 and not tension then
		conn:Disconnect()
		conn = nil
	end
end

local function ensureLoop()
	if not conn then
		conn = RunService.Heartbeat:Connect(step)
	end
end

-- start `name` and fade the current main track out
local function startTrack(name)
	local e = Music.catalog[name]
	if not e then
		warn("MusicFX: unknown track " .. tostring(name))
		return
	end
	for _, rec in ipairs(main) do
		rec.target = 0
	end
	local s = newSound(name, e.loop)
	table.insert(main, { sound = s, name = name, cur = 0, target = 1, vol = e.vol })
	ensureLoop()
	Music.TrackStarted:Fire(name)
end

function Music._advance()
	local list = Music.states[state]
	if not list then
		return
	end
	local last = main[#main] and main[#main].name
	local name, idx = Music._pick(list, last, playlistIndex)
	playlistIndex = idx
	startTrack(name)
end

function Music.play(newState)
	if not Music.states[newState] then
		warn("MusicFX: unknown state " .. tostring(newState))
		return
	end
	if state == newState and main[#main] and main[#main].target == 1 then
		return
	end
	state = newState
	playlistIndex = 0
	Music._advance()
end

function Music.setTension(t)
	tensionLevel = math.clamp(t, 0, 1)
	local e = Music.catalog[Music.tensionBed]
	if tensionLevel > 0.02 and not tension then
		local s = newSound(Music.tensionBed, true)
		tension = { sound = s, cur = 0, target = 0, vol = e.vol }
	end
	if tension then
		tension.target = tensionLevel > 0.02 and (tensionLevel * Music.tensionMax) or 0
	end
	ensureLoop()
end

local duckToken = 0
function Music.duck(amount, duration)
	duckToken += 1
	local mine = duckToken
	duckTarget = 1 - math.clamp(amount, 0, 0.9)
	duckRate = 8
	-- hold the dip for 40% of the duration (at least 0.4 s) so it actually reaches its depth, then ease back
	task.delay(math.max(0.4, duration * 0.4), function()
		if mine ~= duckToken then
			return -- a newer duck is in charge
		end
		duckRate = 1 / math.max(duration * 0.35, 0.2)
		duckTarget = 1
	end)
	ensureLoop()
end

function Music.setVolumes(v)
	for k, x in pairs(v) do
		Music.volumes[k] = math.clamp(x, 0, 1)
	end
end

function Music.stop(fadeTime)
	state = nil
	tensionLevel = 0
	for _, rec in ipairs(main) do
		rec.target = 0
	end
	if tension then
		tension.target = 0
	end
	if (fadeTime or 0) <= 0 then
		for _, rec in ipairs(main) do
			kill(rec)
		end
		main = {}
		if tension then
			kill(tension)
			tension = nil
		end
	end
	ensureLoop()
end

-- ducks the music under big cues (hooks RevealFX.defaultSfx; chain-safe if SoundFX.attach ran first)
function Music.attach(RevealFX)
	local prev = RevealFX.defaultSfx
	local DUCK = { anticipation = { 0.3, 4 }, legendary_burst = { 0.55, 3.2 }, ultimate_impact = { 0.7, 4.0 }, ultimate_summon = { 0.35, 3 }, epic = { 0.4, 2.5 }, ink = { 0.4, 2.8 }, vortex = { 0.4, 2.8 }, milestone = { 0.25, 1.4 }, discovery = { 0.3, 2 }, merge_6 = { 0.2, 1.4 }, merge_7 = { 0.3, 2 }, merge_8 = { 0.55, 3.6 }, surge = { 0.2, 1.2 }, wish_pull = { 0.4, 1.8 } }
	RevealFX.defaultSfx = function(name, length, pitch)
		local d = DUCK[name]
		if d then
			Music.duck(d[1], d[2])
		end
		if prev then
			prev(name, length, pitch)
		end
	end
end

-- the main track that is playing now: name, its Sound (for TimePosition / TimeLength); nil when stopped
function Music.getPlaying()
	local rec = main[#main]
	if rec and rec.target == 1 and rec.sound.Parent then
		return rec.name, rec.sound
	end
	return nil
end

function Music.status()
	local names = {}
	for _, rec in ipairs(main) do
		table.insert(names, string.format("%s(%.2f)", rec.name, rec.cur))
	end
	return { main = names, tension = tension and tension.cur or 0, duck = duckMul, state = state }
end

function Music.audit()
	local lines, fails = {}, 0
	-- pick(): never repeats, covers the list
	local seen, last, idx = {}, nil, 0
	for _ = 1, 12 do
		local n
		n, idx = Music._pick({ "a", "b", "c" }, last, idx)
		if n == last then
			fails += 1
			table.insert(lines, "FAIL playlist repeated " .. n)
		end
		seen[n] = true
		last = n
	end
	if not (seen.a and seen.b and seen.c) then
		fails += 1
		table.insert(lines, "FAIL playlist does not cover every track")
	end
	local names = {}
	for n in pairs(Music.catalog) do
		table.insert(names, n)
	end
	table.sort(names)
	for _, n in ipairs(names) do
		local e = Music.catalog[n]
		local s = Instance.new("Sound")
		s.SoundId = Music.soundId(n)
		s.Parent = SoundService
		pcall(function()
			ContentProvider:PreloadAsync({ s })
		end)
		local t0 = os.clock()
		while not s.IsLoaded and os.clock() - t0 < 5 do
			task.wait(0.05)
		end
		if not s.IsLoaded then
			fails += 1
			table.insert(lines, "FAIL " .. n .. " did not load")
		elseif math.abs(s.TimeLength - e.dur) > 0.1 then
			fails += 1
			table.insert(lines, string.format("FAIL %s TimeLength %.2f vs catalog %.2f", n, s.TimeLength, e.dur))
		end
		s:Destroy()
	end
	for st, list in pairs(Music.states) do
		for _, n in ipairs(list) do
			if not Music.catalog[n] then
				fails += 1
				table.insert(lines, "FAIL state " .. st .. " names unknown track " .. n)
			end
		end
	end
	table.insert(lines, fails == 0 and string.format("MUSIC AUDIT PASS (%d tracks load, lengths match, playlists valid)", #names) or ("MUSIC AUDIT FAILURES: " .. fails))
	return table.concat(lines, "\n"), fails
end

return Music
