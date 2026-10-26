--!nocheck
-- MovementAnims (Script in ServerScriptService). Method by fwjelaa (FWJ STUDIOS).
-- Swaps the default Animate script's idle / walk / run / jump / fall for yours, on every character.
-- Needs PUBLISHED ids (the Animate script can't use Studio-only test animations), set in AnimationIds.
--
-- R6 gotcha (measured from the R6 Animate source): it only ever plays "walk", never "run", and it does not
-- speed a custom walk up with WalkSpeed. Battleground games run at WalkSpeed 16+, so put your RUN in the walk
-- slot (that's what R6_WALK below does by default).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ids = require(ReplicatedStorage:WaitForChild("AnimationIds"))

local R6_WALK = "R6_Run" -- or "R6_Walk" for a slow game
local SLOTS = {
	R6 = { idle = { "Animation1", "R6_Idle" }, walk = { "WalkAnim", R6_WALK }, run = { "RunAnim", "R6_Run" },
		jump = { "JumpAnim", "R6_Jump" }, fall = { "FallAnim", "R6_Fall" } },
	R15 = { idle = { "Animation1", "R15_Idle" }, run = { "RunAnim", "R15_Run" } },
}

local function apply(character)
	local hum = character:WaitForChild("Humanoid")
	local animate = character:WaitForChild("Animate", 10)
	if not animate then
		return
	end
	local rig = hum.RigType == Enum.HumanoidRigType.R6 and "R6" or "R15"
	for slot, info in pairs(SLOTS[rig]) do
		local folder = animate:FindFirstChild(slot)
		local anim = folder and folder:FindFirstChild(info[1])
		local id = ids[info[2]]
		if anim and id then
			anim.AnimationId = id
			if slot == "idle" then -- one idle only: drop the default's rare second idle
				local second = folder:FindFirstChild("Animation2")
				if second then
					second:Destroy()
				end
			end
		end
	end
	-- restart whatever is playing so the new ids take over at once
	local animator = hum:FindFirstChildOfClass("Animator")
	if animator then
		for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
			track:Stop(0)
		end
	end
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAppearanceLoaded:Connect(apply)
end)
for _, player in ipairs(Players:GetPlayers()) do
	if player.Character then
		task.spawn(apply, player.Character)
	end
	player.CharacterAppearanceLoaded:Connect(apply)
end
