-- GCUpgradeRows (T198, 2026-10-29): block moved out of GameClient to stay under the 200,000-character script limit. Called once by GameClient with the outside locals it needs.
return function(env)
local UI, deleteBtn, glowStroke, new, round, upRows = env.UI, env.deleteBtn, env.glowStroke, env.new, env.round, env.upRows
-- familiar panel as a keeper's ledger (2026-10-28, /make-creative): each upgrade's level is a row of five little lamps
-- that light one by one; the price is a brass coin plate; Delete becomes "Release" under a wax seal
do
	for _, r in upRows do
		for _, pip in r.pips do
			pip.Size = UDim2.fromOffset(14, 14)
			pip.Position = pip.Position + UDim2.fromOffset(0, -4)
			pip.BackgroundColor3 = Color3.fromRGB(40, 30, 24)
			for _, c in pip:GetChildren() do if c:IsA("UICorner") or c:IsA("UIGradient") then c:Destroy() end end
			round(pip, 7)
			glowStroke(pip, Color3.fromRGB(150, 110, 50), 1.5, 0)
			local fl = new("ImageLabel", { Name = "Flame", BackgroundTransparency = 1, Image = "rbxassetid://108574647086501", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.75), Size = UDim2.fromOffset(14, 18), ZIndex = pip.ZIndex + 1, Visible = false }, pip)
		end
		UI.objectify(r.buy)
		UI.objImg(r.buy, "plaque", UDim2.new(1, 10, 1, 6), UDim2.fromScale(0.5, 0.5), nil, 7, Enum.ScaleType.Stretch)
		local coin = new("ImageLabel", { BackgroundTransparency = 1, Image = "rbxassetid://93007984461409", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 6, 0.5, 0), Size = UDim2.fromOffset(24, 24), ZIndex = 9 }, r.buy)
		coin:SetAttribute("Tint", true)
		new("UIPadding", { PaddingLeft = UDim.new(0, 26) }, r.buy)
		local t = r.buy:FindFirstChild("Txt")
		if t then t.ZIndex = 9 end
	end
	UI.objectify(deleteBtn)
	UI.objImg(deleteBtn, "plaque", UDim2.new(1, 12, 1, 8), UDim2.fromScale(0.5, 0.5), nil, 7, Enum.ScaleType.Stretch)
	local seal = UI.objImg(deleteBtn, "seal", UDim2.fromOffset(40, 40), UDim2.new(0, 22, 0.5, 0), nil, 9)
	local t = deleteBtn:FindFirstChild("Txt")
	if t then t.ZIndex = 9 end
end
end
