--!nocheck
-- Roster: the eight characters of the merge chain (tier 1 to 8), as data. Source: VFX/Roster.luau, installed as ReplicatedStorage.Roster.
-- All original; humanoid or magical creatures. Design: Roblox Dev/Planning/Game Redesign - Merge Academy.md. Each character has ONE visual hook
-- (colour + a signature prop), one voice (the pentatonic note its merge sound is built on), one catchphrase and one idle gesture:
-- enough for a unique identity without stats, skills or lore to learn on day one. Tier stats later derive from the tier alone.
-- Portraits: Roblox Dev/Assets/Characters/ (generated locally with ComfyUI, not uploaded).

local R = {}

R.list = {
	{ tier = 1, id = "pip", name = "Pip", title = "Ember Wisp", kind = "magical creature", color = Color3.fromRGB(255, 150, 40), accent = Color3.fromRGB(255, 220, 90),
		hook = "a living flame with a tiny face and a spark on its head", note = "C5", line = "Hi! Hi! Hi!", idle = "bobs and flickers like a candle in a draught" },
	{ tier = 2, id = "moss", name = "Moss", title = "Leaf Pixie", kind = "magical creature", color = Color3.fromRGB(90, 200, 90), accent = Color3.fromRGB(255, 90, 80),
		hook = "leaf wings and a red mushroom-cap hat", note = "D5", line = "Shh, the flowers are sleeping.", idle = "hovers and shakes pollen from her wings" },
	{ tier = 3, id = "lumo", name = "Lumo", title = "Lantern Imp", kind = "magical creature", color = Color3.fromRGB(150, 90, 230), accent = Color3.fromRGB(80, 230, 220),
		hook = "little horns and a lantern that glows brighter when he is happy", note = "E5", line = "Oops. Was that mine?", idle = "swings his lantern and grins" },
	{ tier = 4, id = "rook", name = "Rook", title = "Apprentice", kind = "humanoid", color = Color3.fromRGB(70, 130, 240), accent = Color3.fromRGB(255, 255, 255),
		hook = "a pointed hat three sizes too big and a spellbook he can barely carry", note = "G5", line = "Page forty... I think!", idle = "pushes his hat up, then it slides back down" },
	{ tier = 5, id = "vesper", name = "Vesper", title = "Storm Witch", kind = "humanoid", color = Color3.fromRGB(85, 65, 195), accent = Color3.fromRGB(255, 220, 40),
		hook = "a lightning-bolt streak on her hat and a staff with a tiny thundercloud", note = "A5", line = "Let it rain.", idle = "twirls the staff; the cloud grumbles" },
	{ tier = 6, id = "aurel", name = "Sir Aurel", title = "Star Knight", kind = "humanoid", color = Color3.fromRGB(235, 225, 190), accent = Color3.fromRGB(110, 190, 255),
		hook = "white and gold armour with a star-shaped shield and a long plume", note = "C6", line = "For the little lights.", idle = "raises the shield; the star pulses" },
	{ tier = 7, id = "mirelle", name = "Mirelle", title = "Moon Sage", kind = "humanoid", color = Color3.fromRGB(30, 50, 130), accent = Color3.fromRGB(200, 210, 235),
		hook = "a silver beard, a crescent-moon staff and an owl called Tock on her shoulder", note = "D6", line = "Patience. The moon is never late.", idle = "the owl turns its head; she smiles without looking" },
	{ tier = 8, id = "solenne", name = "Solenne", title = "Dawn Archmage", kind = "humanoid", color = Color3.fromRGB(245, 120, 165), accent = Color3.fromRGB(255, 205, 80),
		hook = "a floating golden halo crown and rose-gold robes with a sun on the back", note = "E6", line = "Every night ends.", idle = "light gathers in her open hands" },
}

R.byTier = {}
R.byId = {}
for _, c in ipairs(R.list) do
	R.byTier[c.tier] = c
	R.byId[c.id] = c
end

-- tests: eight characters, tiers 1..8 in order, unique names and ids and notes, clearly different main colours, every field filled
function R.test()
	local lines, fails = {}, 0
	local function check(ok, msg)
		if not ok then
			fails += 1
			table.insert(lines, "FAIL " .. msg)
		end
	end
	check(#R.list == 8, "roster must have 8 characters")
	local names, ids, notes = {}, {}, {}
	for i, c in ipairs(R.list) do
		check(c.tier == i, "tier order broken at " .. c.name)
		check(not names[c.name] and not ids[c.id] and not notes[c.note], "duplicate name, id or note at " .. c.name)
		names[c.name], ids[c.id], notes[c.note] = true, true, true
		for _, f in ipairs({ "title", "kind", "hook", "line", "idle" }) do
			check(type(c[f]) == "string" and #c[f] > 3, c.name .. " is missing " .. f)
		end
		check(c.kind == "humanoid" or c.kind == "magical creature", c.name .. " must be humanoid or a magical creature")
		check(#c.line <= 40, c.name .. " catchphrase too long for a speech bubble")
	end
	-- distinct main colours: a minimum distance in RGB between every pair
	local minDist, pair = 1e9, ""
	for i = 1, #R.list do
		for j = i + 1, #R.list do
			local a, b = R.list[i].color, R.list[j].color
			local d = math.sqrt(((a.R - b.R) * 255) ^ 2 + ((a.G - b.G) * 255) ^ 2 + ((a.B - b.B) * 255) ^ 2)
			if d < minDist then
				minDist, pair = d, R.list[i].name .. "/" .. R.list[j].name
			end
		end
	end
	check(minDist >= 60, string.format("colours too similar: %s (%.0f)", pair, minDist))
	table.insert(lines, fails == 0 and string.format("ROSTER TESTS PASS (8 characters, unique names/notes, closest colour pair %s at distance %.0f)", pair, minDist) or ("ROSTER TEST FAILURES: " .. fails))
	return table.concat(lines, "\n"), fails
end

return R
