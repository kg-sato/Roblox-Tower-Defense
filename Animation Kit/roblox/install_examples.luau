-- Play-test kit: puts the M1 combo, dash and hit reactions into THIS place so you can press Play and try them.
-- Method by fwjelaa (FWJ STUDIOS).
-- 1. Run `python kit/serve.py` in the pack folder.  2. Paste this into Studio's command bar (Edit mode).
-- It adds: ServerStorage.AnimKit, ReplicatedStorage.AnimLoader + AnimationSources (Studio-only test copies of the
-- animations, R6 and R15), StarterCharacterScripts.CombatClient, ServerScriptService.CombatServer, a
-- TrainingDummy, and a test StarterCharacter. Click to punch, Q to dash. CombatClient plays the R6 or R15 set,
-- whichever rig you spawn as. Publish the animations before using them in a live game.
local RIG = "R15" -- "R6" or "R15": the test character and the TrainingDummy
local TEST_CHARACTER = true -- false: play as your own avatar (set Game Settings > Avatar to match RIG)

local HttpService = game:GetService("HttpService")
local PORT = 8765
local ANIMS = {}
for _, rig in ipairs({ "R6", "R15" }) do
	for _, move in ipairs({ "M1_1", "M1_2", "M1_3", "M1_4", "Dash", "HitReact", "Idle", "Run" }) do
		table.insert(ANIMS, rig .. "_" .. move)
	end
end

local function get(path)
	local was = HttpService.HttpEnabled
	HttpService.HttpEnabled = true
	local ok, res = pcall(HttpService.GetAsync, HttpService, ("http://127.0.0.1:%d/%s"):format(PORT, path), true)
	HttpService.HttpEnabled = was
	assert(ok, "start the server first: python kit/serve.py  (" .. tostring(res) .. ")")
	return res
end

local function put(class, name, parent, source)
	local old = parent:FindFirstChild(name)
	if old then
		old:Destroy()
	end
	local s = Instance.new(class)
	s.Name = name
	s.Source = source
	s.Parent = parent
	return s
end

put("ModuleScript", "AnimKit", game.ServerStorage, get("roblox/AnimKit.luau"))
local AnimKit = require(game.ServerStorage.AnimKit)
put("ModuleScript", "AnimLoader", game.ReplicatedStorage, get("roblox/examples/AnimLoader.luau"))
put("LocalScript", "CombatClient", game.StarterPlayer.StarterCharacterScripts, get("roblox/examples/CombatClient.client.luau"))
put("Script", "CombatServer", game.ServerScriptService, get("roblox/examples/CombatServer.server.luau"))

local sources = game.ReplicatedStorage:FindFirstChild("AnimationSources") or Instance.new("Folder")
sources.Name = "AnimationSources"
sources.Parent = game.ReplicatedStorage
local missing = {}
for _, name in ipairs(ANIMS) do
	local ok, data = pcall(function()
		return HttpService:JSONDecode(get("out/" .. name .. ".json"))
	end)
	if ok then
		local kfs = AnimKit.save(AnimKit.fromData(data))
		local old = sources:FindFirstChild(name)
		if old then
			old:Destroy()
		end
		kfs:Clone().Parent = sources
	else
		table.insert(missing, name)
	end
end

-- a character that physics can stand up: unanchored, colliding only where a real one does
local function playable(model)
	model.HumanoidRootPart.Anchored = false
	for _, p in ipairs(model:GetChildren()) do
		if p:IsA("BasePart") then
			p.CanCollide = p.Name == "Torso" or p.Name == "Head" or p.Name == "UpperTorso" or p.Name == "LowerTorso"
		end
	end
	return model
end

local old = workspace:FindFirstChild("TrainingDummy")
if old then
	old:Destroy()
end
local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
local at = (spawn and spawn.CFrame.Position or Vector3.zero) * Vector3.new(1, 0, 1) + Vector3.new(0, 0.5, -8)
local dummy = playable(AnimKit.dummy(RIG, CFrame.new(at) * CFrame.Angles(0, math.pi, 0), nil, "TrainingDummy"))
dummy.Humanoid.MaxHealth, dummy.Humanoid.Health = 100, 100

-- A StarterCharacter overrides the avatar (scripts can't change Game Settings > Avatar). Delete
-- StarterPlayer.StarterCharacter when you're done testing, and set the avatar type in Game Settings.
local oldChar = game.StarterPlayer:FindFirstChild("StarterCharacter")
if oldChar then
	oldChar:Destroy()
end
if TEST_CHARACTER then
	local char = playable(AnimKit.dummy(RIG, CFrame.new(0, 0, 0), nil, "StarterCharacter"))
	char.Parent = game.StarterPlayer
end
local wanted = {}
for _, name in ipairs(missing) do
	if name:sub(1, #RIG + 1) == RIG .. "_" then
		table.insert(wanted, name)
	end
end
print(("Play-test kit installed (%s): press Play, click to punch the TrainingDummy, Q to dash. %s"):format(
	RIG, #wanted > 0 and ("Not exported yet: " .. table.concat(wanted, ", ")) or "All animations loaded."
))
