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
	path: { { number } }?, -- lane waypoints { x, z } (T167)
	place: { noBuild: { { x: number, z: number, r: number } }, decor: { { x: number, z: number, r: number } } }?,
	blockers: { { id: string, kind: string, at: number, hp: number?, breakDps: number?, open: number?, closed: number? } }?,
	lighting: { ClockTime: number, Brightness: number, Ambient: Color3, OutdoorAmbient: Color3, FogColor: Color3, AtmosphereColor: Color3, AtmosphereDecay: Color3, Density: number, Haze: number },
}

local StageSets = {}

StageSets.list = {
	{
		id = "LampwickLane",
		path = { { -44, -20 }, { 24, -20 }, { 24, 8 }, { -30, 8 }, { -30, 22 }, { 40, 22 } }, -- waypoints { x, z }; used only with Config.PATH_PER_SET (T167), Lampwick Lane equals today's Config.PATH
		place = { noBuild = {}, decor = { { x = -12, z = -2, r = 2 }, { x = 34, z = -4, r = 2 } } }, -- T177: no-build circles { x, z, r }; decor never blocks placement
		sky = { cycle = 80, night = { 0.65, 1 }, weather = { { kind = "Fog", at = 0.2, dur = 14 } } },
		name = "Lampwick Lane",
			music = "play",
		stages = 5,
		lighting = { ClockTime = 17.9, Brightness = 1.6, Ambient = Color3.fromRGB(64, 66, 84), OutdoorAmbient = Color3.fromRGB(96, 98, 118), FogColor = Color3.fromRGB(120, 116, 140), AtmosphereColor = Color3.fromRGB(150, 160, 182), AtmosphereDecay = Color3.fromRGB(72, 54, 104), Density = 0.36, Haze = 2.2 }, -- the values Backdrop sets
	},
	{
		id = "HarbourOfBrass",
		path = { { -44, 0 }, { -24, 0 }, { -24, -20 }, { 20, -20 }, { 20, 10 }, { -4, 10 }, { -4, 22 }, { 40, 22 } }, -- waypoints { x, z }; used only with Config.PATH_PER_SET (T167), Lampwick Lane equals today's Config.PATH
		place = { noBuild = { { x = -2, z = -6, r = 5 } }, decor = { { x = -12, z = -10, r = 2 }, { x = 34, z = -6, r = 2 } } }, -- T177: no-build circles { x, z, r }; decor never blocks placement
		blockers = { { id = "QuayGate", kind = "gate", at = 0.55, open = 7, closed = 4 } }, -- T157: fence { hp, breakDps } stops enemies until broken; gate { open, closed } seconds; at = fraction of the lane
		sky = { cycle = 90, night = { 0.7, 1 }, weather = { { kind = "Rain", at = 0.1, dur = 20 }, { kind = "Fog", at = 0.5, dur = 12 } } },
		name = "Harbour of Brass",
			music = "harbour",
		stages = 5,
		lighting = { ClockTime = 18.6, Brightness = 1.2, Ambient = Color3.fromRGB(56, 70, 78), OutdoorAmbient = Color3.fromRGB(84, 104, 110), FogColor = Color3.fromRGB(100, 122, 128), AtmosphereColor = Color3.fromRGB(130, 156, 160), AtmosphereDecay = Color3.fromRGB(80, 104, 112), Density = 0.46, Haze = 2.8 },
	},
	{
		id = "SilentCathedral",
		path = { { -44, -21 }, { 0, -21 }, { 0, -7 }, { -36, -7 }, { -36, 7 }, { 10, 7 }, { 10, 21 }, { 40, 21 } }, -- waypoints { x, z }; used only with Config.PATH_PER_SET (T167), Lampwick Lane equals today's Config.PATH
		place = { noBuild = { { x = 28, z = -2, r = 6 } }, decor = { { x = 20, z = -12, r = 2 }, { x = -18, z = 0, r = 2 } } }, -- T177: no-build circles { x, z, r }; decor never blocks placement
		blockers = { { id = "PewBarrier", kind = "fence", at = 0.4, hp = 80, breakDps = 8 } }, -- T157: fence { hp, breakDps } stops enemies until broken; gate { open, closed } seconds; at = fraction of the lane
		sky = { cycle = 100, night = { 0.2, 1 }, weather = { { kind = "Fog", at = 0.6, dur = 15 } } },
		name = "The Silent Cathedral",
			music = "cathedral",
		stages = 5,
		lighting = { ClockTime = 0.5, Brightness = 0.9, Ambient = Color3.fromRGB(58, 60, 84), OutdoorAmbient = Color3.fromRGB(70, 76, 110), FogColor = Color3.fromRGB(60, 62, 90), AtmosphereColor = Color3.fromRGB(110, 116, 160), AtmosphereDecay = Color3.fromRGB(70, 60, 110), Density = 0.42, Haze = 1.8 },
	},
	{
		id = "ClockworkFoundry",
		path = { { -44, -20 }, { -10, -20 }, { 10, -4 }, { -20, 6 }, { 0, 22 }, { 40, 22 } }, -- waypoints { x, z }; used only with Config.PATH_PER_SET (T167), Lampwick Lane equals today's Config.PATH
		place = { noBuild = { { x = 30, z = -8, r = 6 } }, decor = { { x = -36, z = -6, r = 2 }, { x = 36, z = 6, r = 2 } } }, -- T177: no-build circles { x, z, r }; decor never blocks placement
		blockers = { { id = "SteamGate", kind = "gate", at = 0.35, open = 6, closed = 5 }, { id = "SlagFence", kind = "fence", at = 0.75, hp = 100, breakDps = 8 } }, -- T157: fence { hp, breakDps } stops enemies until broken; gate { open, closed } seconds; at = fraction of the lane
		sky = { cycle = 90, night = { 0.5, 1 }, weather = { { kind = "Embers", at = 0.3, dur = 18 } } },
		name = "Clockwork Foundry",
		stages = 5,
		music = "play",
		lighting = { ClockTime = 22, Brightness = 0.8, Ambient = Color3.fromRGB(60, 40, 36), OutdoorAmbient = Color3.fromRGB(90, 60, 50), FogColor = Color3.fromRGB(110, 70, 50), AtmosphereColor = Color3.fromRGB(170, 120, 90), AtmosphereDecay = Color3.fromRGB(120, 70, 40), Density = 0.5, Haze = 2.4 },
	},
	{
		id = "AboveTheGreyVeil",
		path = { { -44, 0 }, { -30, -15 }, { -6, -20 }, { 18, -14 }, { 24, 6 }, { 10, 22 }, { 40, 22 } }, -- waypoints { x, z }; used only with Config.PATH_PER_SET (T167), Lampwick Lane equals today's Config.PATH
		place = { noBuild = { { x = -5, z = 2, r = 7 } }, decor = { { x = -30, z = 14, r = 2 }, { x = 38, z = -12, r = 2 } } }, -- T177: no-build circles { x, z, r }; decor never blocks placement
		blockers = { { id = "CloudFence", kind = "fence", at = 0.5, hp = 120, breakDps = 8 } }, -- T157: fence { hp, breakDps } stops enemies until broken; gate { open, closed } seconds; at = fraction of the lane
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
