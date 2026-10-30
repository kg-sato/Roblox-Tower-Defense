--!strict
-- Balance data: Rarities (T199). Config re-exports these fields; edit the numbers here.
local D = {}

-- Orthogonal neighbours only. Built from positions so the map and the rule never disagree.
D.RARITIES = {
	Common = { order = 1, color = Color3.fromRGB(190, 196, 210), odds = 60, mult = 1 },
	Rare = { order = 2, color = Color3.fromRGB(80, 170, 255), odds = 28, mult = 2.2 },
	Epic = { order = 3, color = Color3.fromRGB(180, 100, 255), odds = 10, mult = 5 },
	Legendary = { order = 4, color = Color3.fromRGB(255, 200, 60), odds = 2, mult = 12 },
	Mythic = { order = 5, color = Color3.fromRGB(255, 90, 170), odds = 0.4, mult = 30 }, -- no familiar yet: weight is 0 until one has this rarity
	Celestial = { order = 6, color = Color3.fromRGB(150, 245, 255), odds = 0.08, mult = 80 }, -- no familiar yet
}
D.RARITY_ORDER = { "Common", "Rare", "Epic", "Legendary", "Mythic", "Celestial" }

return D
