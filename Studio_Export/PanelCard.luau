--!nocheck
-- PanelCard (LocalScript, StarterPlayerScripts, 2026-10-28 night). The user: "the settings menu is terrible". It was a
-- dark blob with orbit rings (AbstractLayer's panel shape) over the close button, and the tutorial note showed through.
-- Now it is the same card as the skill tree's hover popup: a solid dark panel, a brass double rule, small diamonds on
-- the corners and a pocket-watch crest on the top edge; the old shapes (pools, rings, motes, spine points, the spaced
-- tab line under the title) are hidden every time it opens, since the older layers re-apply on open.
-- Finds the panels the same way AbstractScreens does (by their sizes in HUD.Hud): settings 440 x 560, and since the
-- same night the progression (780 x 440), odds (440 x 360) and familiar (300 x 412) panels, so every panel matches.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local BRASS = Color3.fromRGB(214, 170, 96)
local hud = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("HUD"):WaitForChild("Hud")
local okA, A = pcall(function() return require(game:GetService("ReplicatedStorage"):WaitForChild("ArtIds", 5)) end)

local function new(class, props, parent)
	local i = Instance.new(class)
	for k, v in props do i[k] = v end
	i.Parent = parent
	return i
end

local function tidy(panel)
	for _, c in panel:GetChildren() do
		local n = c.Name
		if c:IsA("GuiObject") and (n == "AF_pool" or n:match("^Abs_") or n == "Mote" or n == "Glass" or n == "Emblem"
			or (c:IsA("Frame") and c.Size == UDim2.fromOffset(9, 9))) then
			c.Visible = false
		end
	end
	for _, d in panel:GetDescendants() do -- the spaced "S O U N D · D I S P L A Y" line repeats the section headers
		if d:IsA("TextLabel") and d.Text:find("S O U N D") then d.Visible = false end
	end
end

local function card(panel)
	if panel:GetAttribute("Card") then return end
	panel:SetAttribute("Card", true)
	local c = new("Frame", { Name = "Card", BackgroundColor3 = Color3.fromRGB(14, 12, 12), BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, panel.Size == UDim2.fromOffset(440, 560) and 58 or 0), ZIndex = 1 }, panel) -- settings: its last row and Reset sit below its box
	new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(30, 24, 20), Color3.fromRGB(10, 9, 10)) }, c)
	new("UICorner", { CornerRadius = UDim.new(0, 4) }, c)
	new("UIStroke", { Color = BRASS, Thickness = 1.5, Transparency = 0.1 }, c)
	local rim = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(7, 7), Size = UDim2.new(1, -14, 1, -14), ZIndex = 1 }, c)
	new("UIStroke", { Color = BRASS, Thickness = 1, Transparency = 0.6 }, rim)
	for _, v in { Vector2.new(0, 0), Vector2.new(1, 0), Vector2.new(0, 1), Vector2.new(1, 1) } do
		new("Frame", { BackgroundColor3 = BRASS, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(v.X, v.Y), Size = UDim2.fromOffset(9, 9), Rotation = 45, ZIndex = 2 }, c)
	end
	if okA and A and A.clock then
		local crest = new("ImageLabel", { Name = "Crest", BackgroundTransparency = 1, Image = A.clock, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0), Size = UDim2.fromOffset(54, 54), ZIndex = 12 }, panel)
		TweenService:Create(crest, TweenInfo.new(60, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), { Rotation = 360 }):Play()
	end
	tidy(panel)
	panel:GetPropertyChangedSignal("Visible"):Connect(function()
		if panel.Visible then task.defer(tidy, panel) task.delay(0.3, tidy, panel) end
	end)
end

local function check(f)
	local z = f:IsA("Frame") and f.Size
	if z == UDim2.fromOffset(440, 560) or z == UDim2.fromOffset(780, 440) or z == UDim2.fromOffset(440, 360) or z == UDim2.fromOffset(300, 412) then
		task.delay(1.5, card, f) -- after AbstractScreens / AbstractLayer have dressed it
	end
end
for _, f in hud:GetChildren() do check(f) end
hud.ChildAdded:Connect(check)
