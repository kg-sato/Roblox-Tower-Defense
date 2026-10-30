--!nocheck
-- GateFX (StarterPlayerScripts, LocalScript, T152): the spawn gate of the shown stage set opens when a wave starts spawning and an
-- enemy shadow spreads in the gateway at every spawn. The door leaves (workspace.StageSets.<set>.GateDoors.DoorL / DoorR, built by the Backdrop
-- scripts) are closed at rest and swing 90 degrees open about the arch pillars; they close again 3 s after the last spawn.
-- The sim emits "Spawn" when the enemy appears at the lane start, so the gate opens with the first spawn (0.35 s swing), not before it.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local events = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Event")
local Path = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Path"))
local setsFolder = workspace:WaitForChild("StageSets")

local lastSpawn, isOpen = -100, false
local UPCYL = CFrame.Angles(0, 0, math.rad(90))

local function leaves()
	local list = {}
	for _, set in setsFolder:GetChildren() do -- the client keeps only the shown set under workspace.StageSets
		local doors = set:FindFirstChild("GateDoors")
		if doors then
			for _, d in doors:GetChildren() do
				if d:IsA("BasePart") then
					table.insert(list, d)
				end
			end
		end
	end
	return list
end

local function swing(open, t)
	isOpen = open
	for _, d in leaves() do
		local hinge, s = d:GetAttribute("Hinge"), d:GetAttribute("Side")
		if hinge and s then
			local cf = open and CFrame.new(hinge) * CFrame.Angles(0, -s * math.rad(90), 0) * CFrame.new(0, 0, s * 2.7) or CFrame.new(hinge) * CFrame.new(0, 0, s * 2.7)
			TweenService:Create(d, TweenInfo.new(t, Enum.EasingStyle.Back, open and Enum.EasingDirection.Out or Enum.EasingDirection.In), { CFrame = cf }):Play()
		end
	end
end

local function shadow()
	local p = Path.positionAt(0)
	local s = Instance.new("Part")
	s.Name, s.Shape, s.Material, s.Color = "EnemyShadow", Enum.PartType.Cylinder, Enum.Material.SmoothPlastic, Color3.new(0, 0, 0)
	s.Size, s.CFrame, s.Transparency = Vector3.new(0.15, 3, 3), CFrame.new(p.X - 1.5, 0.35, p.Z) * UPCYL, 0.25
	s.Anchored, s.CanCollide, s.CanQuery, s.CanTouch, s.CastShadow = true, false, false, false, false
	s.Parent = workspace
	TweenService:Create(s, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(0.15, 10, 10), Transparency = 1 }):Play()
	Debris:AddItem(s, 1)
end

events.OnClientEvent:Connect(function(kind, data)
	if kind ~= "Spawn" then
		return
	end
	local now = os.clock()
	lastSpawn = now
	shadow()
	if not isOpen then
		swing(true, 0.35)
		task.spawn(function()
			while os.clock() - lastSpawn < 3 do
				task.wait(0.5)
			end
			swing(false, 0.5)
		end)
	end
end)
