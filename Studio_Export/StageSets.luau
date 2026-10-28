--!strict
-- Stage sets as data (T08). One entry per set: which stages it covers, the workspace.StageSets child that holds its
-- props (built by a server script per set), and its light and fog. After the last set the order repeats.
-- Plan: [[Research/3D and Art/Backgrounds and Enemies - Mystic Victorian]] (sets of five stages).

export type StageSet = {
	id: string,
	name: string,
	stages: number,
	lighting: { ClockTime: number, Brightness: number, Ambient: Color3, OutdoorAmbient: Color3, FogColor: Color3, AtmosphereColor: Color3, AtmosphereDecay: Color3, Density: number, Haze: number },
}

local StageSets = {}

StageSets.list = {
	{
		id = "LampwickLane",
		name = "Lampwick Lane",
		stages = 5,
		lighting = { ClockTime = 17.9, Brightness = 1.6, Ambient = Color3.fromRGB(64, 66, 84), OutdoorAmbient = Color3.fromRGB(96, 98, 118), FogColor = Color3.fromRGB(120, 116, 140), AtmosphereColor = Color3.fromRGB(150, 160, 182), AtmosphereDecay = Color3.fromRGB(72, 54, 104), Density = 0.36, Haze = 2.2 }, -- the values Backdrop sets
	},
	{
		id = "HarbourOfBrass",
		name = "Harbour of Brass",
		stages = 5,
		lighting = { ClockTime = 18.6, Brightness = 1.2, Ambient = Color3.fromRGB(56, 70, 78), OutdoorAmbient = Color3.fromRGB(84, 104, 110), FogColor = Color3.fromRGB(100, 122, 128), AtmosphereColor = Color3.fromRGB(130, 156, 160), AtmosphereDecay = Color3.fromRGB(80, 104, 112), Density = 0.46, Haze = 2.8 },
	},
	{
		id = "SilentCathedral",
		name = "The Silent Cathedral",
		stages = 5,
		lighting = { ClockTime = 0.5, Brightness = 0.9, Ambient = Color3.fromRGB(58, 60, 84), OutdoorAmbient = Color3.fromRGB(70, 76, 110), FogColor = Color3.fromRGB(60, 62, 90), AtmosphereColor = Color3.fromRGB(110, 116, 160), AtmosphereDecay = Color3.fromRGB(70, 60, 110), Density = 0.42, Haze = 1.8 },
	},
} :: { StageSet }

-- Which set a stage belongs to: stages 1-5 the first set, 6-10 the second, then the order repeats.
function StageSets.forStage(stage: number): StageSet
	local total = 0
	for _, s in StageSets.list do
		total += s.stages
	end
	local n = ((math.max(1, math.floor(stage)) - 1) % total) + 1
	for _, s in StageSets.list do
		if n <= s.stages then
			return s
		end
		n -= s.stages
	end
	return StageSets.list[1]
end

return StageSets
