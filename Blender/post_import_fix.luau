-- Run in Studio (Edit mode, execute_luau) after importing an FBX from Blender/import_ready via Asset Manager.
-- Fixes the two known import bugs: (1) the root pose must be named like the MeshPart, (2) the AnimationController needs
-- an Animator. Usage: set NAME to the imported model's name. Prints what it changed.
local NAME = "Frostling"
local model = workspace:FindFirstChild(NAME) or game.ReplicatedStorage:FindFirstChild(NAME)
assert(model, "model not found: " .. NAME)
local out = {}
local mesh = model:FindFirstChildWhichIsA("MeshPart", true)
local ctrl = model:FindFirstChildWhichIsA("AnimationController", true)
if ctrl and not ctrl:FindFirstChildOfClass("Animator") then
	Instance.new("Animator", ctrl); out[#out+1] = "added Animator"
end
for _, d in model:GetDescendants() do
	if d:IsA("Bone") or d:IsA("Motor6D") then
		if mesh and d.Name ~= mesh.Name and d.Parent == mesh then out[#out+1] = "bone " .. d.Name end
	end
end
return table.concat(out, ", ") .. " | mesh=" .. (mesh and mesh.Name or "nil")
