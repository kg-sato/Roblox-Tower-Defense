--!strict
-- Server owns every run. Clients only send intents; the sim decides.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local ActionArgs = require(Shared:WaitForChild("ActionArgs"))
local MatchSim = require(Shared:WaitForChild("MatchSim"))
local SettingsDefaults = require(Shared:WaitForChild("SettingsDefaults"))
local Gacha = require(Shared:WaitForChild("Gacha")) -- P3 roll floor and P2 Lantern Oil state (saved as profile.gacha; each feature behind its own Config flag)
local ProgressHooks = require(Shared:WaitForChild("ProgressHooks")) -- T652: achievements, quests, bond, leaderboard (each behind a Config flag, default OFF)

local ProfileStore = require(ServerScriptService:WaitForChild("ProfileStore")) :: any -- vendor/ProfileStore.luau (MadStudioRoblox, session-locked saving)

-- What is saved between visits (see MatchSim.meta / loadMeta). Only account-level progress: the pets on the board
-- and the current stage belong to a single run and are not saved.
local TEMPLATE = { version = 2, level = 1, xp = 0, sp = 0, gems = 0, tree = { Start = 1 }, bestStage = 1, lastStage = 1, tutorialDone = false, settings = SettingsDefaults.copyDefaults(), seen = {}, collection = {}, difficulty = "Normal", gacha = Gacha.new() }
for k, v in ProgressHooks.fields() do
	TEMPLATE[k] = v -- achievements, quests, bond (T652)
end
local store = ProfileStore.New("PlayerData_v1", TEMPLATE)
local profiles: { [Player]: any } = {}

-- Collection (T103): the familiars a player has pulled. The server decides; the client only reads the player attribute SeenPets (comma list).
local seenCache: { [Player]: { [string]: boolean } } = {}
local function publishSeen(player: Player)
	local ids = {}
	for id in seenCache[player] or {} do
		table.insert(ids, id)
	end
	table.sort(ids)
	player:SetAttribute("SeenPets", table.concat(ids, ","))
end
local function markSeen(player: Player, pet: any)
	if type(pet) ~= "string" or not Config.PETS[pet] then
		return
	end
	local seen = seenCache[player]
	if not seen then
		seen = {}
		seenCache[player] = seen
	end
	if seen[pet] then
		return
	end
	seen[pet] = true
	local profile = profiles[player]
	if profile and type(profile.Data.seen) == "table" then
		profile.Data.seen[pet] = true
	end
	publishSeen(player)
end

local TICK = 0.1
local MIN_ACTION_GAP = 0.05
local ACTION_KINDS = { Roll = true, Drop = true, Move = true, Recycle = true, Upgrade = true, Ult = true, StartWave = true, AutoWave = true, Skill = true, Respec = true, EndTutorial = true, Difficulty = true, Pause = true, Lantern = true, Guarantee = true }
local lastStart: { [Player]: number } = {}

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage

local function makeRemote(name: string): RemoteEvent
	local r = Instance.new("RemoteEvent")
	r.Name = name
	r.Parent = remotes
	return r
end

local toServer = makeRemote("Action") -- client -> server: (kind: string, a: any, b: any)
local toClient = makeRemote("Event") -- server -> client: (kind: string, payload: table)

type Session = {
	sim: MatchSim.Sim,
	hooks: any, -- ProgressHooks run state (nil in the tutorial)
	accum: number,
	lastAction: number,
	snapTimer: number,
	speed: number, -- game speed 1, 2 or 3 (setting)
	gclock: number, -- game clock: real seconds times speed; enemy spawn times use it so clients can place enemies at any speed
}

local sessions: { [Player]: Session } = {}
local lastSetting: { [Player]: number } = {} -- settings saves, 1 per second per player
local lastSkip: { [Player]: number } = {} -- survives startRun, which resets the session's own throttle

-- Snapshot plus the game clock line (g at server time `at`, advancing `speed` per second) so clients can follow it.
local function snap(session: Session): { [string]: any }
	local s = session.sim:snapshot()
	s.gclock, s.gat, s.gspeed = session.gclock, workspace:GetServerTimeNow(), session.sim.userPaused and 0 or session.speed
	return s
end

local hookFlags = ProgressHooks.flagsFrom(Config)

-- Pays what a hook earned into the run and tells the client (T652).
local function deliver(player: Player, sim: any, out: any)
	if out.gems > 0 then
		sim.gems += out.gems
	end
	if out.sp > 0 then
		sim.sp += out.sp
	end
	for _, e in out.events do
		toClient:FireClient(player, e.kind, e.payload)
	end
end

-- Copy the run's account-level progress into the profile (ProfileStore writes it to the DataStore every 30 s and on leave).
-- Not while in the tutorial: that run starts everyone at the same defaults.
local function syncProfile(player: Player)
	local profile, session = profiles[player], sessions[player]
	if not profile or not session or session.sim.tutorial then
		return
	end
	local meta = session.sim:meta()
	for k, v in meta do
		profile.Data[k] = v
	end
	profile.Data.tutorialDone = true
end

local function startRun(player: Player, tutorial: boolean)
	local old = sessions[player]
	if old and old.hooks then
		deliver(player, old.sim, ProgressHooks.flush(old.hooks, os.time())) -- bond xp of the run being replaced
		syncProfile(player)
	end
	local simRef: any = nil
	local hooks: any = nil
	local sim = MatchSim.new(Random.new(), function(kind: string, payload: any)
		if kind == "Pace" then
			local s = sessions[player]
			payload.t = s and s.gclock or payload.t -- the client follows the game clock, not the sim clock
		end
		if kind == "Spawn" then
			local s = sessions[player]
			payload.spawnTime = s and s.gclock or 0
		end
		if kind == "Roll" then
			markSeen(player, payload.pet)
			local profile = profiles[player]
			if profile and not tutorial and type(profile.Data.collection) == "table" and type(payload.pet) == "string" and Config.PETS[payload.pet] then
				Config.collectionAdd(profile.Data.collection, payload.pet) -- duplicates and shards (T186)
			end
		end
		-- a Legendary pull is the one shared moment: other players in the server get a short banner (T20)
		if kind == "Roll" and payload.rarity == "Legendary" and not payload.bonus then
			for _, other in Players:GetPlayers() do
				if other ~= player then
					toClient:FireClient(other, "SharedSummon", { name = player.DisplayName, pet = payload.pet })
				end
			end
		end
		toClient:FireClient(player, kind, payload)
		if hooks and simRef then
			deliver(player, simRef, ProgressHooks.event(hooks, kind, payload, os.time(), tutorial))
		end
	end, tutorial)
	simRef = sim
	-- returning players continue their saved progress; the tutorial run always starts fresh
	local profile = profiles[player]
	if profile and not tutorial then
		sim:loadMeta(profile.Data)
	end
	if profile and not tutorial and (hookFlags.achievements or hookFlags.quests or hookFlags.bond or hookFlags.leaderboard) then
		hooks = ProgressHooks.start(profile.Data, hookFlags, os.time(), { userId = player.UserId, petFaction = function(pet: string): string?
			local def = Config.PETS[pet]
			return def and def.faction
		end })
	end
	local speed = profile and profile.Data.settings and profile.Data.settings.gameSpeed or 1
	sessions[player] = { sim = sim, hooks = hooks, accum = 0, lastAction = 0, snapTimer = 0, speed = speed, gclock = 0 }
	toClient:FireClient(player, "Begin", { snapshot = snap(sessions[player]) })
	if profile then
		toClient:FireClient(player, "Settings", profile.Data.settings)
	end
end

local function loadProfile(player: Player)
	local profile = store:StartSessionAsync("Player_" .. player.UserId, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})
	if not profile then
		if player.Parent == Players then
			player:Kick("Your data could not be loaded. Please rejoin.")
		end
		return
	end
	if player.Parent ~= Players then
		profile:EndSession()
		return
	end
	profile:AddUserId(player.UserId) -- GDPR: lets the data be found and deleted for this user
	profile:Reconcile() -- fill in any fields added to TEMPLATE after this player's first save
	profile.Data.settings = SettingsDefaults.sanitize(profile.Data.settings) -- a damaged or edited save cannot hold bad values
	-- security audit (T124): every other saved field is clamped too, and the version is stamped after any migration
	local d = profile.Data
	local function count(v: any, fallback: number, max: number): number
		if type(v) ~= "number" or v ~= v or v < 0 then
			return fallback
		end
		return math.min(math.floor(v), max)
	end
	d.level = math.max(1, count(d.level, 1, 999))
	d.xp = count(d.xp, 0, 1e12)
	d.sp = count(d.sp, 0, 9999)
	d.gems = count(d.gems, 0, 1e12)
	d.bestStage = math.max(1, count(d.bestStage, 1, 1000))
	d.lastStage = math.max(1, count(d.lastStage, 1, 1000))
	d.bestStage = math.max(d.bestStage, d.lastStage)
	d.tutorialDone = d.tutorialDone == true
	local tree = {}
	if type(d.tree) == "table" then
		for id, lvl in d.tree do
			if type(id) == "string" and Config.TREE_BY_ID[id] ~= nil and id ~= "Start" then
				tree[id] = count(lvl, 0, 99)
			end
		end
	end
	tree.Start = 1
	d.tree = tree
	-- collection (T103): keep only real familiar ids, then merge with what was pulled before the profile finished loading
	local seen = {}
	if type(d.seen) == "table" then
		for id, v in d.seen do
			if type(id) == "string" and Config.PETS[id] ~= nil and v == true then
				seen[id] = true
			end
		end
	end
	for id in seenCache[player] or {} do
		seen[id] = true
	end
	d.seen = seen
	d.collection = Config.sanitizeCollection(d.collection, seen) -- T186: counts and shards; the older `seen` list gives one copy each
	d.difficulty = (type(d.difficulty) == "string" and Config.DIFFICULTY[d.difficulty] and d.bestStage >= Config.DIFFICULTY[d.difficulty].unlockStage) and d.difficulty or "Normal"
	ProgressHooks.sanitize(d) -- T652: achievements, quests and bond are clamped even with the flags off
	seenCache[player] = table.clone(seen)
	publishSeen(player)
	d.gacha = Gacha.load(d.gacha) -- version 2 added `gacha`: older profiles get a fresh state, a damaged one is clamped
	d.version = TEMPLATE.version -- the only migration so far is the gacha field above; add the next one here before bumping TEMPLATE.version
	profile.OnSessionEnd:Connect(function()
		profiles[player] = nil
		player:Kick("Your data was loaded in another server. Please rejoin.")
	end)
	profiles[player] = profile
end

Players.PlayerAdded:Connect(function(player)
	task.spawn(loadProfile, player)
end)
for _, player in Players:GetPlayers() do
	task.spawn(loadProfile, player)
end

-- Unit ids are positive integers handed out by the sim (the client calls them slots).
-- the pure rules live in Shared.ActionArgs, with headless tests (T125)
local isSlot = ActionArgs.isSlot
local isCoord = ActionArgs.isCoord

toServer.OnServerEvent:Connect(function(player: Player, kind: any, a: any, b: any)
	if type(kind) ~= "string" then
		return
	end
	local session = sessions[player]
	if kind == "Start" then
			-- security audit (T123): one Start per second, so spam cannot pile up waiting threads
			if os.clock() - (lastStart[player] or 0) < 1 then
				return
			end
			lastStart[player] = os.clock()
		if not session then
			task.spawn(function()
				local t0 = os.clock()
				while not profiles[player] and player.Parent == Players and os.clock() - t0 < 15 do
					task.wait(0.1)
				end
				local profile = profiles[player]
				if player.Parent == Players and not sessions[player] and profile then
					-- a returning player skips the tutorial
					startRun(player, not profile.Data.tutorialDone)
				end
			end)
		end
		return
	end
	-- Skipping only replaces a tutorial run; mid-run it would wipe progress (and it was unthrottled).
	if kind == "SkipTutorial" then
		if os.clock() - (lastSkip[player] or 0) < 1 then
			return
		end
		lastSkip[player] = os.clock()
		if not profiles[player] then
			return -- data still loading
		end
		if session and not session.sim.tutorial then
			return
		end
		startRun(player, false)
		return
	end
	-- A settings change needs only the profile, not a run. Validated and rate limited on the server.
	if kind == "Setting" then
		local profile = profiles[player]
		if not profile or not SettingsDefaults.allowSave(lastSetting, player, os.clock()) then
			return
		end
		-- one key (a = key, b = value) or a batch (a = { key = value }, at most 16 keys); each value is validated on its own
		-- security audit (T123): a missing key used to throw inside the table constructor
			local changes = ActionArgs.settingChanges(a, b) -- shape rules in Shared.ActionArgs (T125)
			if not changes then
				return
			end
		local count, changed = 0, false
		local speedBefore = profile.Data.settings.gameSpeed
		for key, value in changes do
			count += 1
			if count > 16 then
				break
			end
			local valid, clean = SettingsDefaults.validate(key, value)
			if valid then
				profile.Data.settings[key] = clean
				changed = true
			end
		end
		if changed then
			toClient:FireClient(player, "Settings", profile.Data.settings)
			local running = sessions[player]
			if running and profile.Data.settings.gameSpeed ~= speedBefore then
				running.speed = profile.Data.settings.gameSpeed -- the new clock line goes to the client at once
				toClient:FireClient(player, "State", snap(running))
			end
		end
		return
	end
	-- T652: claim a finished quest (only with Config.QUESTS_ON); the server checks everything
	if kind == "Quest" then
		if not (session and session.hooks and Config.QUESTS_ON) or os.clock() - session.lastAction < MIN_ACTION_GAP then
			return
		end
		session.lastAction = os.clock()
		local ok, reason, out = ProgressHooks.claimQuest(session.hooks, a)
		if ok then
			deliver(player, session.sim, out)
		else
			toClient:FireClient(player, "Denied", { reason = reason })
		end
		toClient:FireClient(player, "State", snap(session))
		return
	end
	local now = os.clock()
	-- security audit (T123): unknown kinds no longer use up the gap, so spam cannot block a real action
		if not ACTION_KINDS[kind] or not session or now - session.lastAction < MIN_ACTION_GAP then
		return
	end
	session.lastAction = now
	local sim = session.sim
	local ok, reason: string? = false, "Unknown action"
	if kind == "Roll" then
		ok, reason = sim:roll()
	elseif kind == "Drop" then
		if not (isSlot(a) and isSlot(b)) then
			return
		end
		ok, reason = sim:drop(a, b)
	elseif kind == "Move" then
		-- a = unit id, b = { x, z } target; legality is checked by the sim (Config.canPlace)
		if not (isSlot(a) and type(b) == "table" and isCoord(b.x) and isCoord(b.z)) then
			return
		end
		ok, reason = sim:move(a, b.x, b.z)
	elseif kind == "Recycle" then
		if not isSlot(a) then
			return
		end
		ok, reason = sim:recycle(a)
	elseif kind == "Upgrade" then
		ok, reason = sim:upgrade(a, b)
	elseif kind == "Ult" then
		ok, reason = sim:castUlt()
	elseif kind == "StartWave" then
		ok, reason = sim:startWave()
	elseif kind == "AutoWave" then
		ok, reason = sim:setAuto(a)
	elseif kind == "Skill" then
		ok, reason = sim:skill(a)
	elseif kind == "Respec" then
		ok, reason = sim:respec()
	elseif kind == "Difficulty" then
		ok, reason = sim:setDifficulty(a) -- T004: the sim checks stage, unlock and tutorial
	elseif kind == "Pause" then
		ok, reason = sim:pause(a) -- T006
	elseif kind == "Lantern" then
		if not (type(a) == "table" and isCoord(a.x) and isCoord(a.z)) then
			return
		end
		ok, reason = sim:lantern(a.x, a.z) -- T011
	elseif kind == "Guarantee" then
		ok, reason = sim:claimGuarantee(a) -- P2: the sim checks the flag, the oil, the rarity and the room
	elseif kind == "EndTutorial" then
		sim:endTutorial()
		ok = true
	else
		return
	end
	if not ok then
		toClient:FireClient(player, "Denied", { reason = reason })
	end
	toClient:FireClient(player, "State", snap(session))
end)

-- QA hook, Studio only (server-side BindableEvent, not reachable by clients): give a pet and/or charge the ultimate.
if RunService:IsStudio() then
	local qa = Instance.new("BindableEvent")
	qa.Name = "QAGrant"
	qa.Parent = game:GetService("ServerStorage")
	local readProfile = Instance.new("BindableFunction")
	readProfile.Name = "QAProfile"
	readProfile.Parent = game:GetService("ServerStorage")
	readProfile.OnInvoke = function(cmd: any)
		for player, profile in profiles do
			if type(cmd) == "string" and cmd:sub(1, 6) == "stage:" and sessions[player] then -- QA: jump this run to a stage
				local st = tonumber(cmd:sub(7))
				if st then
					sessions[player].sim.stage = math.clamp(math.floor(st), 1, 1000)
					toClient:FireClient(player, "State", snap(sessions[player]))
				end
			end
			if type(cmd) == "string" and cmd:sub(1, 3) == "sp:" and sessions[player] then -- QA: set skill points (2026-10-28, skill tree tests)
				sessions[player].sim.sp = math.clamp(math.floor(tonumber(cmd:sub(4)) or 0), 0, 99)
				toClient:FireClient(player, "State", snap(sessions[player]))
			end
			if cmd == "reset" then
				-- QA: back to a brand-new player; the tutorial flag stops syncProfile overwriting it on leave
				for k, v in TEMPLATE do
					profile.Data[k] = type(v) == "table" and table.clone(v) or v
				end
				ProgressHooks.sanitize(profile.Data) -- fresh nested tables, not the ones inside TEMPLATE
				if sessions[player] then
					sessions[player].sim.tutorial = true
				end
			end
			return game:GetService("HttpService"):JSONEncode(profile.Data)
		end
		return "no profile"
	end
	qa.Event:Connect(function(pet: any, charge: any)
		for player, session in sessions do
			local sim = session.sim
			if type(pet) == "string" and Config.PETS[pet] then
				local x, z = sim:findSpot(pet)
				if x then
					local id = sim:addUnit(pet, x, z)
					toClient:FireClient(player, "Roll", { slot = id, pet = pet, rarity = Config.PETS[pet].rarity, x = x, z = z })
				end
			end
			if charge then
				sim.ult = sim:ultNeed()
			end
			toClient:FireClient(player, "State", snap(session))
		end
	end)
end

Players.PlayerRemoving:Connect(function(player)
	syncProfile(player)
	local profile = profiles[player]
	local ending = sessions[player]
	if profile and ending and ending.hooks then
		local out = ProgressHooks.flush(ending.hooks, os.time()) -- bond xp; the sim is over, so the gems go straight into the profile
		profile.Data.gems = math.min(profile.Data.gems + out.gems, 1e12)
	end
	if profile then
		profiles[player] = nil
		profile:EndSession()
	end
	sessions[player] = nil
	seenCache[player] = nil
	lastSkip[player] = nil
	lastSetting[player] = nil
end)

RunService.Heartbeat:Connect(function(dt: number)
	for player, session in sessions do
		if session.sim.userPaused then
			session.sim:tickPause(dt) -- T006: the clock stands still while paused; the pause ends by itself after Config.PAUSE_MAX
		else
			session.gclock += dt * session.speed
			local steps
			steps, session.accum = SettingsDefaults.stepsFor(session.accum, dt, session.speed, TICK)
			for _ = 1, steps do
				session.sim:step(TICK)
			end
		end
		session.snapTimer += dt
		if session.snapTimer >= 0.25 then
			session.snapTimer = 0
			syncProfile(player)
			toClient:FireClient(player, "State", snap(session))
		end
	end
end)
