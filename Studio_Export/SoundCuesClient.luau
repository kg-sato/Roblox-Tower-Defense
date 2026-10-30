--!nocheck
-- SoundCuesClient (T630, T605, T603 wiring): LocalScript in StarterPlayer.StarterPlayerScripts. Listens to the server's Event remote
-- next to GameClient (no GameClient edit) and fires the event driven cues through SoundCues: enemy hits, boss intro per boss,
-- reveal cue per rarity (only for uploaded cues, so the old reveal cue is never doubled), level up, skill buy; ducks the music
-- under a reveal and applies the saved master/interface volumes. Cue log: SoundCues.log.
local RS = game:GetService("ReplicatedStorage")
local Cues = require(RS:WaitForChild("SoundCues"))
local SoundFX = require(RS:WaitForChild("SoundFX"))
local okM, Music = pcall(function()
	return require(RS:WaitForChild("MusicFX", 5))
end)
Music = okM and Music or nil

local remotes = RS:WaitForChild("Remotes")
local kinds = {} -- enemy id -> kind
local lastHit = 0

remotes:WaitForChild("Event").OnClientEvent:Connect(function(kind, data)
	if type(data) ~= "table" then
		return
	end
	if kind == "Spawn" then
		kinds[data.id] = data.kind
		if data.boss then
			Cues.fire(SoundFX, Cues.bossCue(data.boss), { volume = 0.9 })
		end
	elseif kind == "Shot" then
		local now = os.clock()
		if kinds[data.id] and now - lastHit > 0.07 then -- a swarm must not machine-gun the hit cue
			lastHit = now
			Cues.fire(SoundFX, Cues.hitCue(kinds[data.id]), { volume = data.crit and 1 or 0.7 })
		end
	elseif kind == "Kill" or kind == "Leak" then
		kinds[data.id] = nil
	elseif kind == "Roll" then
		local rc = Cues.revealCue(data.rarity)
		if Cues.native(rc) then -- an uploaded rarity cue layers over the reveal; otherwise the old reveal cue stands alone
			Cues.fire(SoundFX, rc, { delay = 0.3 })
		end
		local d = Music and Cues.revealDuck[data.rarity]
		if d then
			Music.duck(d[1], d[2])
			table.insert(Cues.log, { cue = "duck:" .. tostring(data.rarity), played = string.format("%.2f/%.1fs", d[1], d[2]), native = false, t = os.clock() })
		end
	elseif kind == "Stage" then
		if Music then
			Music.setTension(Music.tensionFor(data.stage, data.boss)) -- eerie bed climbs through the set, full on a boss stage
			table.insert(Cues.log, { cue = "tension:stage" .. tostring(data.stage), played = string.format("%.2f", Music.tensionFor(data.stage, data.boss)), native = false, t = os.clock() })
		end
	elseif kind == "Clear" then
		if Music then
			Music.setTension(0.1)
		end
	elseif kind == "Merge" then
		Cues.fire(SoundFX, Cues.mergeCue(data.tier), { delay = 0.9 }) -- lands with the new familiar
	elseif kind == "LevelUp" then
		Cues.fire(SoundFX, "ui_levelup")
	elseif kind == "SkillBought" then
		Cues.fire(SoundFX, "ui_buy")
	elseif kind == "Settings" then
		Cues.applyMix(data, SoundFX, Music) -- the saved sliders arrive here when the session starts
	end
end)

-- Studio only: publish the cue log (SoundCues.log + every SoundFX.play) as the CueLog attribute so a test run can read it
-- (execute_luau runs in its own module context and cannot see this script's tables). Capped, one write per second.
if game:GetService("RunService"):IsStudio() then
	SoundFX.log = SoundFX.log or {}
	if Music then
		Music.log = Music.log or {}
	end
	task.spawn(function()
		local lastN = -1
		while true do
			task.wait(1)
			local n = #Cues.log + #SoundFX.log + (Music and Music.log and #Music.log or 0)
			if n ~= lastN then
				lastN = n
				local cues, plays = {}, {}
				for i = math.max(1, #Cues.log - 150), #Cues.log do
					local r = Cues.log[i]
					table.insert(cues, { r.cue, r.played or false, r.native })
				end
				for i = math.max(1, #SoundFX.log - 250), #SoundFX.log do
					local r = SoundFX.log[i]
					table.insert(plays, { r.name, r.ok, r.why })
				end
				local xf = {}
				for _, r in Music and Music.log or {} do
					table.insert(xf, { r.from, r.to, r.state })
				end
				script:SetAttribute("CueLog", game:GetService("HttpService"):JSONEncode({ cues = cues, plays = plays, music = xf }))
			end
		end
	end)
end
