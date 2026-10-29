-- Loading screen layout audit (bug 5 in Roblox Dev/Bug Log.md). Read-only: run in a Play session (Client datamodel) with execute_luau while the loading screen is showing.
-- Reports, for every visible GuiObject under the loading ScreenGui that is not a full-screen layer: its centre offset from the viewport centre (in percent of the viewport) and every pair
-- of parts that overlap by more than 3 percent of the smaller part. Parts are skipped when fully transparent, hidden, or covering at least 95 percent of the viewport (fog, vignette).
-- Usage: paste the file into execute_luau; optional first line `local GUI_NAME = "LoadingScreen"` is already set below. Returns a text report.
local GUI_NAME = "LoadingScreen"
local pg = game.Players.LocalPlayer:WaitForChild("PlayerGui")
local gui = pg:FindFirstChild(GUI_NAME)
if not gui then
	local names = {}
	for _, g in pg:GetChildren() do table.insert(names, g.Name) end
	return "no ScreenGui named " .. GUI_NAME .. "; PlayerGui has: " .. table.concat(names, ", ")
end
local cam = workspace.CurrentCamera
local vp = cam.ViewportSize
-- the gui may use IgnoreGuiInset: its AbsolutePosition is then offset by the top inset (58 px), so add it back before comparing with the viewport
local inset = gui.IgnoreGuiInset and game:GetService("GuiService"):GetGuiInset().Y or 0
local parts = {}
local function visibleChain(o)
	local cur = o
	while cur and cur ~= gui do
		if cur:IsA("GuiObject") and not cur.Visible then return false end
		cur = cur.Parent
	end
	return gui.Enabled
end
for _, o in gui:GetDescendants() do
	if o:IsA("GuiObject") and visibleChain(o) then
		local size, pos = o.AbsoluteSize, o.AbsolutePosition
		local drawn = false
		if o:IsA("ImageLabel") or o:IsA("ImageButton") then
			drawn = o.ImageTransparency < 0.98 and o.Image ~= ""
		elseif o:IsA("TextLabel") or o:IsA("TextButton") then
			drawn = o.TextTransparency < 0.98 and o.Text ~= ""
		end
		if o.BackgroundTransparency < 0.98 then drawn = true end
		if drawn and size.X > 1 and size.Y > 1 then
			local full = size.X >= vp.X * 0.95 and size.Y >= vp.Y * 0.95
			if not full then
				table.insert(parts, { name = o:GetFullName():gsub("^.-" .. GUI_NAME .. "%.", ""), cls = o.ClassName, x0 = pos.X, y0 = pos.Y + inset, x1 = pos.X + size.X, y1 = pos.Y + inset + size.Y,
					cx = pos.X + size.X / 2, cy = pos.Y + inset + size.Y / 2, rot = o.AbsoluteRotation })
			end
		end
	end
end
local out = { string.format("viewport %dx%d, %d parts (full-screen layers skipped)", vp.X, vp.Y, #parts), "-- centre offset from the viewport centre, percent of viewport (x, y) --" }
for _, p in parts do
	table.insert(out, string.format("%-46s %-10s centre %+5.1f%%, %+5.1f%%  size %4.0fx%-4.0f rot %4.0f", string.sub(p.name, 1, 46), p.cls, (p.cx - vp.X / 2) / vp.X * 100, (p.cy - vp.Y / 2) / vp.Y * 100, p.x1 - p.x0, p.y1 - p.y0, p.rot))
end
table.insert(out, "-- overlaps above 3 percent of the smaller part --")
local n = 0
for i = 1, #parts do
	for j = i + 1, #parts do
		local a, b = parts[i], parts[j]
		local w = math.min(a.x1, b.x1) - math.max(a.x0, b.x0)
		local h = math.min(a.y1, b.y1) - math.max(a.y0, b.y0)
		if w > 0 and h > 0 then
			local smaller = math.min((a.x1 - a.x0) * (a.y1 - a.y0), (b.x1 - b.x0) * (b.y1 - b.y0))
			local frac = w * h / smaller
			if frac > 0.03 then
				n += 1
				table.insert(out, string.format("%5.1f%%  %s  X  %s", frac * 100, string.sub(a.name, 1, 40), string.sub(b.name, 1, 40)))
			end
		end
	end
end
table.insert(out, n .. " overlapping pairs")
return table.concat(out, "\n")
