--!strict
-- Stage sets as data (T08). One entry per set: which stages it covers, the workspace.StageSets child that holds its
-- props (built by a server script per set), and its light and fog. After the last set the order repeats.
-- Plan: [[Research/3D and Art/Backgrounds and Enemies - Mystic Victorian]] (sets of five stages).

export type StageSet = {
	id: string,
	name: string,
	stages: number,
	music: string, -- a MusicFX state name (Music.states); a set change crossfades to it
	lighting: { ClockTime: number, Brightness: number, Ambient: Color3, OutdoorAmbient: Color3, FogColor: Color3, AtmosphereColor: Color3, AtmosphereDecay: Color3, Density: number, Haze: number },
}

local StageSets = {}

StageSets.list = {
	{
		id = "LampwickLane",
		name = "Lampwick Lane",
			music = "play",
		stages = 5,
		lighting = { ClockTime = 17.9, Brightness = 1.6, Ambient = Color3.fromRGB(64, 66, 84), OutdoorAmbient = Color3.fromRGB(96, 98, 118), FogColor = Color3.fromRGB(120, 116, 140), AtmosphereColor = Color3.fromRGB(150, 160, 182), AtmosphereDecay = Color3.fromRGB(72, 54, 104), Density = 0.36, Haze = 2.2 }, -- the values Backdrop sets
	},
	{
		id = "HarbourOfBrass",
		name = "Harbour of Brass",
			music = "harbour",
		stages = 5,
		lighting = { ClockTime = 18.6, Brightness = 1.2, Ambient = Color3.fromRGB(56, 70, 78), OutdoorAmbient = Color3.fromRGB(84, 104, 110), FogColor = Color3.fromRGB(100, 122, 128), AtmosphereColor = Color3.fromRGB(130, 156, 160), AtmosphereDecay = Color3.fromRGB(80, 104, 112), Density = 0.46, Haze = 2.8 },
	},
	{
		id = "SilentCathedral",
		name = "The Silent Cathedral",
			music = "cathedral",
		stages = 5,
		lighting = { ClockTime = 0.5, Brightness = 0.9, Ambient = Color3.fromRGB(58, 60, 84), OutdoorAmbient = Color3.fromRGB(70, 76, 110), FogColor = Color3.fromRGB(60, 62, 90), AtmosphereColor = Color3.fromRGB(110, 116, 160), AtmosphereDecay = Color3.fromRGB(70, 60, 110), Density = 0.42, Haze = 1.8 },
	},
	{
		id = "ClockworkFoundry",
		name = "Clockwork Foundry",
		stages = 5,
		music = "play",
		lighting = { ClockTime = 22, Brightness = 0.8, Ambient = Color3.fromRGB(60, 40, 36), OutdoorAmbient = Color3.fromRGB(90, 60, 50), FogColor = Color3.fromRGB(110, 70, 50), AtmosphereColor = Color3.fromRGB(170, 120, 90), AtmosphereDecay = Color3.fromRGB(120, 70, 40), Density = 0.5, Haze = 2.4 },
	},
	{
		id = "AboveTheGreyVeil",
		name = "Above the Grey Veil",
		stages = 5,
		music = "veil",
		lighting = { ClockTime = 0, Brightness = 0.7, Ambient = Color3.fromRGB(28, 34, 64), OutdoorAmbient = Color3.fromRGB(52, 66, 118), FogColor = Color3.fromRGB(24, 30, 58), AtmosphereColor = Color3.fromRGB(150, 170, 230), AtmosphereDecay = Color3.fromRGB(60, 60, 120), Density = 0.18, Haze = 0.6 },
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
