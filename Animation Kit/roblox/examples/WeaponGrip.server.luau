--!nocheck
-- WeaponGrip (Script inside your weapon Tool). Method by fwjelaa (FWJ STUDIOS).
-- The default Tool grip is a Weld called RightGrip, which animations can't move. This swaps it for the
-- Motor6D the kit's weapon animations drive: named "Handle", Part1 = the Tool's Handle, with the exact C0/C1
-- the animations were made with. Set WEAPON to the prop the animations used. Keep the Handle part's business
-- end along its +Y axis, with the grip GRIP studs below its centre (or change GRIP to match your mesh).

local WEAPON = "Sword" -- "Sword", "Spear", "Dagger" or "Axe"
local GRIP = { Sword = 1.3, Spear = 2.2, Dagger = 0.55, Axe = 1.2 }

local tool = script.Parent
local handle = tool:WaitForChild("Handle")

local HAND = {
	R6 = { "Right Arm", CFrame.new(0, -1, 0) * CFrame.Angles(math.rad(-90), 0, 0) },
	R15 = { "RightHand", CFrame.new(0, -0.15, 0) * CFrame.Angles(math.rad(-90), 0, 0) },
}
local motor

tool.Equipped:Connect(function()
	local character = tool.Parent
	local hum = character and character:FindFirstChildOfClass("Humanoid")
	if not hum then
		return
	end
	local grip = HAND[hum.RigType == Enum.HumanoidRigType.R6 and "R6" or "R15"]
	local hand = character:FindFirstChild(grip[1])
	if not hand then
		return
	end
	local weld = hand:WaitForChild("RightGrip", 1)
	if weld then
		weld:Destroy()
	end
	motor = Instance.new("Motor6D")
	motor.Name = "Handle"
	motor.Part0, motor.Part1 = hand, handle
	motor.C0, motor.C1 = grip[2], CFrame.new(0, -GRIP[WEAPON], 0)
	motor.Parent = hand
end)

tool.Unequipped:Connect(function()
	if motor then
		motor:Destroy()
		motor = nil
	end
end)
