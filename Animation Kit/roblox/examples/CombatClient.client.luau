--!nocheck
-- CombatClient (LocalScript in StarterPlayer > StarterCharacterScripts). Method by fwjelaa (FWJ STUDIOS).
-- Battlegrounds-style M1 combo + dash, for R6 or R15 (it picks the matching set by the character's rig):
--   click   -> <rig>_M1_1..4 (the chain resets after COMBO_RESET seconds without a click)
--   Q       -> <rig>_Dash (the push happens on its DashStart marker, so it lines up with the pose)
-- Hits are detected HERE, on the client that plays the track, at the animation's "Hit" marker (markers can
-- arrive late on the server). On a hit the track freezes for HITSTOP frames, then the server is told.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local AnimLoader = require(ReplicatedStorage:WaitForChild("AnimLoader"))
local CombatHit = ReplicatedStorage:WaitForChild("CombatHit")

local HITSTOP = { 5, 5, 6, 12 } -- frames at 60 fps (snappy preset)
local COMBO_RESET = 1.2 -- seconds
local CHAIN_AFTER_HIT = 6 / 60 -- the next click is accepted this long after the contact frame
local FINISHER_COOLDOWN = 0.8
local HITBOX_SIZE = Vector3.new(4.6, 4, 5.75)
local HITBOX_OFFSET = CFrame.new(0, 0, -3)
local DASH_SPEED, DASH_TIME = 50, 0.22

local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
local root = character:WaitForChild("HumanoidRootPart")

-- the R6 or R15 set, whichever rig this character is (R6_M1_1... or R15_M1_1...)
local RIG = humanoid.RigType == Enum.HumanoidRigType.R15 and "R15" or "R6"
local COMBO = { RIG .. "_M1_1", RIG .. "_M1_2", RIG .. "_M1_3", RIG .. "_M1_4" }
local DASH = RIG .. "_Dash"

local comboIndex, lastClick, busyUntil = 0, 0, 0

local function hitbox()
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	local victims = {}
	for _, part in ipairs(workspace:GetPartBoundsInBox(root.CFrame * HITBOX_OFFSET, HITBOX_SIZE, params)) do
		local model = part:FindFirstAncestorOfClass("Model")
		local hum = model and model:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 and not table.find(victims, model) then
			table.insert(victims, model)
		end
	end
	return victims
end

local function hitstop(track, frames)
	track:AdjustSpeed(0)
	task.delay(frames / 60, function()
		track:AdjustSpeed(1)
	end)
end

local function attack()
	local now = os.clock()
	if now < busyUntil then
		return
	end
	comboIndex = (now - lastClick > COMBO_RESET or comboIndex >= #COMBO) and 1 or comboIndex + 1
	lastClick = now
	local n = comboIndex
	local track = AnimLoader.load(humanoid, COMBO[n])
	busyUntil = now + track.Length -- until the Hit marker shortens it
	local conn
	conn = track:GetMarkerReachedSignal("Hit"):Connect(function()
		conn:Disconnect()
		local victims = hitbox()
		if #victims > 0 then
			hitstop(track, HITSTOP[n])
			CombatHit:FireServer(victims, n)
		end
		local extra = #victims > 0 and HITSTOP[n] / 60 or 0
		busyUntil = os.clock() + extra + (n == #COMBO and FINISHER_COOLDOWN or CHAIN_AFTER_HIT)
	end)
	track:Play(0.05)
end

local function dash()
	local now = os.clock()
	if now < busyUntil then
		return
	end
	local track = AnimLoader.load(humanoid, DASH)
	busyUntil = now + track.Length
	local conn
	conn = track:GetMarkerReachedSignal("DashStart"):Connect(function()
		conn:Disconnect()
		local look = root.CFrame.LookVector * Vector3.new(1, 0, 1) -- flat, so the dash never drifts up or down
		local attachment = Instance.new("Attachment", root)
		local push = Instance.new("LinearVelocity")
		push.Attachment0 = attachment
		push.MaxForce = math.huge
		push.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
		push.PrimaryTangentAxis, push.SecondaryTangentAxis = Vector3.xAxis, Vector3.zAxis
		push.PlaneVelocity = Vector2.new(look.Unit.X, look.Unit.Z) * DASH_SPEED
		push.Parent = root
		task.delay(DASH_TIME, function()
			push:Destroy()
			attachment:Destroy()
		end)
	end)
	track:Play(0.05)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or humanoid.Health <= 0 then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.ButtonR2 then
		attack()
	elseif input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.ButtonB then
		dash()
	end
end)

humanoid.Died:Connect(function()
	busyUntil = math.huge
end)
