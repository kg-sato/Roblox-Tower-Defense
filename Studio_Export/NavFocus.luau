--!nocheck
-- NavFocus (StarterPlayerScripts, LocalScript), T121: arrow keys and a gamepad move between the visible HUD buttons.
-- Client-only: every visible GuiButton under the HUD is made Selectable, and its NextSelection links point at the
-- nearest button in each direction, rebuilt every 2 s from on-screen positions. Kept out of GameClient (200,000-character
-- limit). Settings panel buttons are found the same way once that panel is open.

local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local player = game:GetService("Players").LocalPlayer

local hudGui = player:WaitForChild("PlayerGui"):WaitForChild("HUD", 15)
if not hudGui then
	return
end

local function shown(g)
	local n = g
	while n and n ~= hudGui do
		if n:IsA("GuiObject") and not n.Visible then
			return false
		end
		n = n.Parent
	end
	return true
end

local function buttons()
	local out = {}
	for _, g in hudGui:GetDescendants() do
		if g:IsA("GuiButton") and g.AbsoluteSize.X > 4 and g.AbsoluteSize.Y > 4 and shown(g) then
			table.insert(out, g)
		end
	end
	return out
end

local function center(g)
	return g.AbsolutePosition + g.AbsoluteSize / 2
end

local DIRS = {
	Up = Vector2.new(0, -1),
	Down = Vector2.new(0, 1),
	Left = Vector2.new(-1, 0),
	Right = Vector2.new(1, 0),
}

local function link()
	local list = buttons()
	for _, b in list do
		b.Selectable = true
	end
	for _, a in list do
		local ca = center(a)
		for dir, v in DIRS do
			local best, bestD = nil, math.huge
			for _, b in list do
				if b ~= a then
					local d = center(b) - ca
					local along = d:Dot(v)
					local across = math.abs(d.X * v.Y - d.Y * v.X)
					if along > 1 and across <= along * 0.8 and along + across < bestD then
						best, bestD = b, along + across
					end
				end
			end
			a["NextSelection" .. dir] = best
		end
	end
end

task.spawn(function()
	while hudGui.Parent do
		link()
		task.wait(2)
	end
end)

-- with nothing selected, the first arrow key picks the first visible button so the chain can start
UserInputService.InputBegan:Connect(function(input, processed)
	if processed or GuiService.SelectedObject ~= nil then
		return
	end
	local k = input.KeyCode
	if k == Enum.KeyCode.Up or k == Enum.KeyCode.Down or k == Enum.KeyCode.Left or k == Enum.KeyCode.Right
		or k == Enum.KeyCode.DPadUp or k == Enum.KeyCode.DPadDown or k == Enum.KeyCode.DPadLeft or k == Enum.KeyCode.DPadRight then
		local list = buttons()
		if list[1] then
			GuiService.SelectedObject = list[1]
		end
	end
end)
