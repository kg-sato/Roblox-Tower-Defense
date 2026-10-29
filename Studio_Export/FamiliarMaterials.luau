--!nonstrict
-- FamiliarMaterials (T105): the material library for the familiars, one recipe each: brass, bone, glass, stone, ember, frost, ink, starDust.
-- A recipe is plain data (Roblox built-in material, colour, reflectance, transparency) plus, for the glowing ones, a light and a small particle emitter.
-- FamiliarMaterials.apply(part, name) sets the part to the recipe and returns the extras it added (they are named "FM_Light" and "FM_Emitter", so a second
-- apply replaces the first). The colours come from the cast: brass = Lantern Keepers and Clockwork Guild metal, bone = Mourner and Archivist paper, glass = Ward and
-- the Moth-Lantern wings, stone = Gargoyle, ember = Ember, frost = Frostling, ink = Mourner veil and Wraith cloth, starDust = Star Drake and Mirror Chorister.
-- Source of the look rules: Roblox Dev/Design/Material Library.md. Installed as ReplicatedStorage.Shared.FamiliarMaterials.
local M = {}

local SPARK = "rbxasset://textures/particles/sparkles_main.dng"

M.recipes = {
	brass = { material = Enum.Material.Metal, color = Color3.fromRGB(201, 162, 75), reflectance = 0.35, transparency = 0, use = "oil lamps, lanterns, Guild plates" },
	bone = { material = Enum.Material.Limestone, color = Color3.fromRGB(232, 224, 200), reflectance = 0, transparency = 0, use = "veils, paper, ledgers, masks" },
	glass = { material = Enum.Material.Glass, color = Color3.fromRGB(190, 225, 235), reflectance = 0.2, transparency = 0.45, use = "lantern panes, wings, mirror faces" },
	stone = { material = Enum.Material.Slate, color = Color3.fromRGB(100, 104, 118), reflectance = 0, transparency = 0, use = "the Gargoyle, plinths, cathedral" },
	ember = { material = Enum.Material.Neon, color = Color3.fromRGB(255, 118, 40), reflectance = 0, transparency = 0,
		light = { color = Color3.fromRGB(255, 140, 60), brightness = 1.6, range = 9 },
		emitter = { color = Color3.fromRGB(255, 170, 70), rate = 9, lifetime = NumberRange.new(0.6, 1.1), speed = NumberRange.new(1.5, 3), size = 0.22, texture = SPARK, lightEmission = 0.9 },
		use = "Ember's flame, lamp cores" },
	frost = { material = Enum.Material.Ice, color = Color3.fromRGB(158, 212, 240), reflectance = 0.12, transparency = 0.12,
		emitter = { color = Color3.fromRGB(220, 244, 255), rate = 5, lifetime = NumberRange.new(1.0, 1.8), speed = NumberRange.new(0.5, 1.2), size = 0.18, texture = SPARK, lightEmission = 0.5 },
		use = "Frostling, icicles, cold breath" },
	ink = { material = Enum.Material.Glass, color = Color3.fromRGB(12, 10, 20), reflectance = 0.18, transparency = 0, use = "veils, wet cloth, shadow" },
	starDust = { material = Enum.Material.Neon, color = Color3.fromRGB(70, 90, 210), reflectance = 0, transparency = 0.15,
		light = { color = Color3.fromRGB(150, 170, 255), brightness = 1.1, range = 10 },
		emitter = { color = Color3.fromRGB(235, 240, 255), rate = 14, lifetime = NumberRange.new(1.2, 2.2), speed = NumberRange.new(0.4, 1.4), size = 0.16, texture = SPARK, lightEmission = 1 },
		use = "Star Drake, Mirror Chorister, orbiting stars" },
}
M.order = { "brass", "bone", "glass", "stone", "ember", "frost", "ink", "starDust" }

-- Apply a recipe to a BasePart; returns { light = PointLight?, emitter = ParticleEmitter? }. Errors on an unknown recipe name.
function M.apply(part: BasePart, name: string)
	local r = M.recipes[name]
	assert(r, "FamiliarMaterials: unknown recipe " .. tostring(name))
	part.Material = r.material
	part.Color = r.color
	part.Reflectance = r.reflectance
	part.Transparency = r.transparency
	local old = part:FindFirstChild("FM_Light")
	if old then
		old:Destroy()
	end
	old = part:FindFirstChild("FM_Emitter")
	if old then
		old:Destroy()
	end
	local extras = {}
	if r.light then
		local l = Instance.new("PointLight")
		l.Name = "FM_Light"
		l.Color, l.Brightness, l.Range = r.light.color, r.light.brightness, r.light.range
		l.Parent = part
		extras.light = l
	end
	if r.emitter then
		local e = Instance.new("ParticleEmitter")
		e.Name = "FM_Emitter"
		e.Color = ColorSequence.new(r.emitter.color)
		e.Rate = r.emitter.rate
		e.Lifetime = r.emitter.lifetime
		e.Speed = r.emitter.speed
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, r.emitter.size), NumberSequenceKeypoint.new(1, 0) })
		e.Texture = r.emitter.texture
		e.LightEmission = r.emitter.lightEmission
		e.SpreadAngle = Vector2.new(60, 60)
		e.EmissionDirection = Enum.NormalId.Top
		e.Parent = part
		extras.emitter = e
	end
	return extras
end

return M
