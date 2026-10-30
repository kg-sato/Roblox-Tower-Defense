--!strict
-- Stage sets as data (T08). One entry per set: which stages it covers, the workspace.StageSets child that holds its
-- props (built by a server script per set), and its light and fog. After the last set the order repeats.
-- Plan: [[Research/3D and Art/Backgrounds and Enemies - Mystic Victorian]] (sets of five stages).

export type StageSet = {
	id: string,
	name: string,
	stages: number,
	music: string, -- a MusicFX state name (Music.states); a set change crossfades to it
	sky: { cycle: number, night: { number }?, weather: { { kind: string, at: number, dur: number } }? }?, -- day and night window and weather events (T009): fractions of the cycle, seconds; effects in Config.SKY_EFFECTS
	lighting: { ClockTime: number, Brightness: number, Ambient: Color3, OutdoorAmbient: Color3, FogColor: Color3, AtmosphereColor: Color3, AtmosphereDecay: Color3, Density: number, Haze: number },
}

local StageSets = {}

StageSets.list = {
	{
		id = "LampwickLane",
		sky = { cycle = 80, night = { 0.65, 1 }, weather = { { kind = "Fog", at = 0.2, dur = 14 } } },
		name = "Lampwick Lane",
			music = "play",
		stages = 5,
		lighting = { ClockTime = 17.9, Brightness = 1.6, Ambient = Color3.fromRGB(64, 66, 84), OutdoorAmbient = Color3.fromRGB(96, 98, 118), FogColor = Color3.fromRGB(120, 116, 140), AtmosphereColor = Color3.fromRGB(150, 160, 182), AtmosphereDecay = Color3.fromRGB(72, 54, 104), Density = 0.36, Haze = 2.2 }, -- the values Backdrop sets
	},
	{
		id = "HarbourOfBrass",
		sky = { cycle = 90, night = { 0.7, 1 }, weather = { { kind = "Rain", at = 0.1, dur = 20 }, { kind = "Fog", at = 0.5, dur = 12 } } },
		name = "Harbour of Brass",
			music = "harbour",
		stages = 5,
		lighting = { ClockTime = 18.6, Brightness = 1.2, Ambient = Color3.fromRGB(56, 70, 78), OutdoorAmbient = Color3.fromRGB(84, 104, 110), FogColor = Color3.fromRGB(100, 122, 128), AtmosphereColor = Color3.fromRGB(130, 156, 160), AtmosphereDecay = Color3.fromRGB(80, 104, 112), Density = 0.46, Haze = 2.8 },
	},
	{
		id = "SilentCathedral",
		sky = { cycle = 100, night = { 0.2, 1 }, weather = { { kind = "Fog", at = 0.6, dur = 15 } } },
		name = "The Silent Cathedral",
			music = "cathedral",
		stages = 5,
		lighting = { ClockTime = 0.5, Brightness = 0.9, Ambient = Color3.fromRGB(58, 60, 84), OutdoorAmbient = Color3.fromRGB(70, 76, 110), FogColor = Color3.fromRGB(60, 62, 90), AtmosphereColor = Color3.fromRGB(110, 116, 160), AtmosphereDecay = Color3.fromRGB(70, 60, 110), Density = 0.42, Haze = 1.8 },
	},
	{
		id = "ClockworkFoundry",
		sky = { cycle = 90, night = { 0.5, 1 }, weather = { { kind = "Embers", at = 0.3, dur = 18 } } },
		name = "Clockwork Foundry",
		stages = 5,
		music = "play",
		lighting = { ClockTime = 22, Brightness = 0.8, Ambient = Color3.fromRGB(60, 40, 36), OutdoorAmbient = Color3.fromRGB(90, 60, 50), FogColor = Color3.fromRGB(110, 70, 50), AtmosphereColor = Color3.fromRGB(170, 120, 90), AtmosphereDecay = Color3.fromRGB(120, 70, 40), Density = 0.5, Haze = 2.4 },
	},
	{
		id = "AboveTheGreyVeil",
		sky = { cycle = 120, night = { 0, 1 }, weather = { { kind = "Storm", at = 0.5, dur = 15 } } },
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
