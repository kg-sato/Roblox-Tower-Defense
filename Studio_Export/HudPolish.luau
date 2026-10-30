--!nocheck
-- StarterPlayerScripts.HudPolish (ModuleScript, T640, 2026-10-30): contrast plates behind the HUD's own controls, drawn in a ScreenGui under the HUD
-- (DisplayOrder -5), so GameClient stays untouched; nothing is parented into the HUD.
--   require(script.Parent.HudPolish).init()  -- called once by the UILane2 LocalScript
local Players = game:GetService("Players")
local M = {}
local INK, BRASS = Color3.fromRGB(16, 12, 20), Color3.fromRGB(214, 170, 96)

function M.init()
	local player = Players.LocalPlayer
	task.spawn(function()
		local hud = player:WaitForChild("PlayerGui"):WaitForChild("HUD", 30)
		local h = hud and hud:WaitForChild("Hud", 30)
		if not h then return end
		local gui = Instance.new("ScreenGui")
		gui.Name, gui.ResetOnSpawn, gui.DisplayOrder, gui.IgnoreGuiInset = "HudPolish", false, -5, hud.IgnoreGuiInset
		gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		gui.Parent = player.PlayerGui
		-- fixed scale rects: the HUD's visible art is drawn by dressing layers, so the controls' own AbsoluteSize does not match what is seen
		for _, r in {
			{ 0.002, 0.18, 0.066, 0.53, 0.3 }, -- left rail: coins, gems, skill tree, progression, settings
			{ 0.285, 0.875, 0.43, 0.115, 0.2 }, -- ROLL / AUTO / QUICK bar
			{ 0.835, 0.885, 0.16, 0.105, 0.2 }, -- BEGIN THE WAVE
		} do
			local f = Instance.new("Frame")
			f.Name, f.BackgroundColor3, f.BackgroundTransparency, f.BorderSizePixel = "Plate", INK, r[5], 0
			f.Position, f.Size = UDim2.fromScale(r[1], r[2]), UDim2.fromScale(r[3], r[4])
			Instance.new("UICorner", f).CornerRadius = UDim.new(0, 12)
			local s = Instance.new("UIStroke")
			s.Color, s.Thickness, s.Transparency = BRASS, 1.5, 0.3
			s.Parent = f
			f.Parent = gui
		end
		-- legibility pass: the dock and currency captions were 14 px thin serif; bigger, bold, cream with a dark outline. Re-applied each second because the HUD rebuilds labels.
		local BOLD = Font.fromName("Merriweather", Enum.FontWeight.Bold)
		task.spawn(function()
			while gui.Parent do
				for _, l in h:GetDescendants() do
					local n = l.Name
					if l:IsA("TextLabel") and (n == "AF_name" or (l.Parent.Parent == h:FindFirstChild("Dock") and l.Parent:IsA("Frame"))) then
						l.FontFace, l.TextSize, l.TextColor3 = BOLD, n == "AF_name" and 17 or 18, Color3.fromRGB(255, 236, 190)
						l.TextStrokeColor3, l.TextStrokeTransparency = Color3.new(0, 0, 0), 0.3
					end
				end
				task.wait(1)
			end
		end)
	end)
end
return M
