--!nocheck
-- UIValidate: run after every build. Flags anything that would break on another screen size.
-- Adapted from the validator in xtrair/figma-to-roblox-ui (MIT licence, credit: xtrair).
-- Usage: local problems = require(UIValidate)(screenGui)  -- returns a list of strings (empty = pass)

local function udim(v)
	return typeof(v) == "UDim" and v.Offset ~= 0
end
local function udim2(v)
	return typeof(v) == "UDim2" and (v.X.Offset ~= 0 or v.Y.Offset ~= 0)
end

return function(root)
	local bad = {}
	local center = Vector2.new(0.5, 0.5)
	for _, d in ipairs(root:GetDescendants()) do
		local p = d:GetFullName()
		if d:IsA("GuiObject") then
			if udim2(d.Size) then
				table.insert(bad, p .. " Size has an Offset")
			end
			if udim2(d.Position) then
				table.insert(bad, p .. " Position has an Offset")
			end
			if d.AnchorPoint ~= center and not d:GetAttribute("AnchorReason") then
				table.insert(bad, p .. " AnchorPoint is not centered and has no AnchorReason")
			end
			if (d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox")) and d.Text ~= "" and not d.TextScaled then
				table.insert(bad, p .. " TextScaled is off")
			end
			if (d:IsA("ImageLabel") or d:IsA("ImageButton")) and d.Image == "" then
				table.insert(bad, p .. " has no Image")
			end
		elseif d:IsA("UIStroke") then
			if d.StrokeSizingMode ~= Enum.StrokeSizingMode.ScaledSize then
				table.insert(bad, p .. " stroke is not ScaledSize")
			end
			if d.Thickness > 1 then
				table.insert(bad, p .. " stroke Thickness > 1 (looks like pixels)")
			end
		elseif d:IsA("UICorner") then
			if udim(d.CornerRadius) then
				table.insert(bad, p .. " CornerRadius has an Offset")
			end
		elseif d:IsA("UIListLayout") then
			if udim(d.Padding) then
				table.insert(bad, p .. " list Padding has an Offset")
			end
		elseif d:IsA("UIGridLayout") then
			if udim2(d.CellSize) or udim2(d.CellPadding) then
				table.insert(bad, p .. " grid cell has an Offset")
			end
		elseif d:IsA("UIPadding") then
			for _, k in ipairs({ "PaddingLeft", "PaddingRight", "PaddingTop", "PaddingBottom" }) do
				if udim(d[k]) then
					table.insert(bad, p .. " " .. k .. " has an Offset")
				end
			end
		end
	end
	return bad
end
