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

local pg = player.PlayerGui
local MODALS = { "Dialogs", "Results", "Screens" } -- a ScreenGui in this list with a visible button owns focus while open

local function shown(g, top)
	local n = g
	while n and n ~= top do
		if n:IsA("GuiObject") and not n.Visible then
			return false
		end
		n = n.Parent
	end
	return true
end

local function collect(top)
	local out = {}
	for _, g in top:GetDescendants() do
		if g:IsA("GuiButton") and g.AbsoluteSize.X > 4 and g.AbsoluteSize.Y > 4 and shown(g, top) then
			table.insert(out, g)
		end
	end
	return out
end

local function buttons()
	for _, name in MODALS do
		local m = pg:FindFirstChild(name)
		if m and m:IsA("ScreenGui") and m.Enabled then
			local list = collect(m)
			if #list > 0 then
				return list
			end
		end
	end
	return collect(hudGui) -- the settings panel lives inside the HUD gui, so it is included once open
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
	-- reading order (top to bottom, then left to right); fills any direction the nearest-button search left empty, so
	-- Right/Down from the first button and Left/Up from the last always walk through every button
	local order = table.clone(list)
	table.sort(order, function(a, b)
		local ca, cb = center(a), center(b)
		if math.abs(ca.Y - cb.Y) > 8 then
			return ca.Y < cb.Y
		end
		return ca.X < cb.X
	end)
	local index = {}
	for i, b in order do
		index[b] = i
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
			local i = index[a]
			if not best then
				best = (dir == "Right" or dir == "Down") and order[i + 1] or ((dir == "Left" or dir == "Up") and order[i - 1] or nil)
			end
			a["NextSelection" .. dir] = best
		end
	end
	-- repair: anything the four-way walk from the first button cannot reach gets a link from the nearest reached button with a free direction
	local reached, queue = { [order[1] or false] = true }, { order[1] }
	local function walk()
		local qi = 1
		while queue[qi] do
			local a = queue[qi]
			qi += 1
			for dir in DIRS do
				local n = a["NextSelection" .. dir]
				if n and not reached[n] then
					reached[n] = true
					table.insert(queue, n)
				end
			end
		end
	end
	walk()
	for _, x in order do
		if not reached[x] then
			local best, bestDir, bestD = nil, nil, math.huge
			for r in reached do
				if r then
					for dir in DIRS do
						local d = (center(r) - center(x)).Magnitude
						if r["NextSelection" .. dir] == nil and d < bestD then
							best, bestDir, bestD = r, dir, d
						end
					end
				end
			end
			if best then
				best["NextSelection" .. bestDir] = x
				reached[x] = true
				table.insert(queue, x)
				walk()
			end
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
