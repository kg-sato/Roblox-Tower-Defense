--!nocheck
-- FontPass (LocalScript, StarterPlayerScripts, 2026-10-28). One house type across every screen, whatever font the
-- script that made a label picked. The user asked for Beyond Wonderland's smeared, inky Victorian look everywhere:
--   * key titles are images rendered in Beyond Wonderland (UI Kit/art/render_title.py; Roblox can't load the font)
--   * headings and button words (30 px and up): Fondamento, the closest built-in calligraphic face
--   * everything else: Accanthis (Enum.Font.Bodoni), an old-style book serif like the HUD reference; bold, so it
--     stays readable at small sizes
-- A label opts out with the attribute KeepFont = true. Roblox's own top-bar UI is CoreGui and is never touched.
local Players = game:GetService("Players")

local HEAD = Font.new("rbxasset://fonts/families/Fondamento.json", Enum.FontWeight.Regular)
local BODY = Font.new("rbxasset://fonts/families/AccanthisADFStd.json", Enum.FontWeight.Bold)
local BODY_ITALIC = Font.new("rbxasset://fonts/families/AccanthisADFStd.json", Enum.FontWeight.Bold, Enum.FontStyle.Italic)

local function pick(t)
	local h = t.TextScaled and t.AbsoluteSize.Y or t.TextSize
	if h >= 30 then return HEAD end
	return t.FontFace.Style == Enum.FontStyle.Italic and BODY_ITALIC or BODY
end

local function apply(t)
	if t:GetAttribute("KeepFont") then return end
	local want = pick(t)
	if t.FontFace ~= want then t.FontFace = want end
end

local function watch(t)
	if not (t:IsA("TextLabel") or t:IsA("TextButton") or t:IsA("TextBox")) then return end
	task.defer(apply, t) -- after the maker has set its own font and size
	t:GetPropertyChangedSignal("FontFace"):Connect(function() apply(t) end)
	t:GetPropertyChangedSignal("TextSize"):Connect(function() apply(t) end)
end

local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
for _, d in pg:GetDescendants() do watch(d) end
pg.DescendantAdded:Connect(watch)
