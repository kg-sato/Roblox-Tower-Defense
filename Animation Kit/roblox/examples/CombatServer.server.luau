--!nocheck
-- CombatServer (Script in ServerScriptService). Method by fwjelaa (FWJ STUDIOS).
-- Receives hits from CombatClient, checks them, deals damage, plays R6_HitReact / R15_HitReact (by the victim's
-- rig) on the victim, stuns it, and launches it on the 4th hit. Creates the CombatHit RemoteEvent if missing.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimLoader = require(ReplicatedStorage:WaitForChild("AnimLoader"))

local CombatHit = ReplicatedStorage:FindFirstChild("CombatHit") or Instance.new("RemoteEvent")
CombatHit.Name = "CombatHit"
CombatHit.Parent = ReplicatedStorage

local DAMAGE = { 3, 3, 4, 5 } -- like TSB's 3/3/4/5
local STUN = { 0.5, 0.5, 0.6, 1.0 } -- seconds the victim can't move
local MAX_RANGE = 10 -- studs between attacker and victim (anti-exploit sanity check)
local KNOCKBACK = Vector3.new(0, 25, 0) -- added to the push away from the attacker on the finisher
local KNOCKBACK_SPEED = 38
local KNOCKBACK_TIME = 0.18 -- seconds the push lasts
local lastHit = {} -- player -> os.clock(), simple rate limit

CombatHit.OnServerEvent:Connect(function(player, victims, n)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or typeof(victims) ~= "table" or typeof(n) ~= "number" or not DAMAGE[n] then
		return
	end
	local now = os.clock()
	if lastHit[player] and now - lastHit[player] < 0.15 then
		return
	end
	lastHit[player] = now
	for _, model in ipairs(victims) do
		local hum = typeof(model) == "Instance" and model:FindFirstChildOfClass("Humanoid")
		local vRoot = hum and model:FindFirstChild("HumanoidRootPart")
		if vRoot and model ~= character and hum.Health > 0 and (vRoot.Position - root.Position).Magnitude <= MAX_RANGE then
			hum:TakeDamage(DAMAGE[n])
			local react = AnimLoader.load(hum, (hum.RigType == Enum.HumanoidRigType.R15 and "R15" or "R6") .. "_HitReact")
			react:Play(0) -- no fade: reactions snap
			local speed = hum.WalkSpeed
			hum.WalkSpeed = 3
			task.delay(STUN[n], function()
				if hum.Parent then
					hum.WalkSpeed = speed
				end
			end)
			if n == #DAMAGE and not vRoot.Anchored then
				-- a short forced push: a plain velocity set gets eaten by the Humanoid's ground friction
				local away = (vRoot.Position - root.Position) * Vector3.new(1, 0, 1)
				away = away.Magnitude > 0 and away.Unit or root.CFrame.LookVector
				local attachment = Instance.new("Attachment", vRoot)
				local push = Instance.new("LinearVelocity")
				push.Attachment0 = attachment
				push.MaxForce = math.huge
				push.VectorVelocity = away * KNOCKBACK_SPEED + KNOCKBACK
				push.Parent = vRoot
				task.delay(KNOCKBACK_TIME, function()
					push:Destroy()
					attachment:Destroy()
				end)
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	lastHit[player] = nil
end)
