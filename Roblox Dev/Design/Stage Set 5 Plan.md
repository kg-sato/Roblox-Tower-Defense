# Stage set 5, Above the Grey Veil: design, lighting, props, music (T154)
Design only; nothing is built. The code has no fifth set: `StageSets.list` ends at the Clockwork Foundry and repeats, so stages 21 to 25 currently reuse Lampwick Lane (`python tools/check_stages_complete.py` fails for exactly these five stages). Lore: [[Stage Set Lore]] section 5, [[Chapter 5 - Above the Grey Veil]], [[The Clockmaker]] act 5.

## Look
The fog has lifted and the sky is open: the roof of the city, a ring of stair and bridge above the fog, with the Great Clock's face mounted behind. Deep blue and white on black; lamp orange appears only at the player's lantern and on the apprentice's lamp, so the lantern is the warmest thing on screen (this is the game's cosmic end, [[The Cosmic Turn]]). Fog is thin and low, so the board reads clearly and the sky does the work.

## Lighting data (ready to add to `StageSets.list`; PROPOSAL, tune in Studio)
```lua
{
	id = "AboveTheGreyVeil",
	name = "Above the Grey Veil",
	stages = 5,
	music = "veil", -- needs a new state in MusicFX.states (see Music below)
	lighting = { ClockTime = 0, Brightness = 0.7, Ambient = Color3.fromRGB(28, 34, 64), OutdoorAmbient = Color3.fromRGB(52, 66, 118), FogColor = Color3.fromRGB(24, 30, 58), AtmosphereColor = Color3.fromRGB(150, 170, 230), AtmosphereDecay = Color3.fromRGB(60, 60, 120), Density = 0.18, Haze = 0.6 },
},
```
Compared with the other sets: density 0.18 (the others 0.42 to 0.5) and haze 0.6 (1.8 to 2.4), the darkest ambient, the coldest hue.

## Props (three landmarks plus dressing, from the lore)
1. The clock face seen from behind: a huge brass disc with a back frame and gears, mounted behind the board; the apprentice's lamp glows inside it (the act 5 clue).
2. A staircase that climbs and returns (task T171): the path's stair section, with brass rails.
3. Rune circles on the ground, drawn as thin glowing rings that pulse slowly.
Dressing: a ring of broken bridge arches, floating star-dust specks, mirror-cat statues (the Star Choir's cats) at the board edge, two or three dark "eyes" in the far background that open over the five stages, a thin cloud floor far below instead of fog.

## Music
No track exists for this set; the available ones are artifact_room, chill_lofi, iremos_forest, rising_moon and shinsei (the first two are used by the harbour and play states). Proposal: a new state `veil = { "rising_moon" }`, the longest (224 s) and the most "open sky"; or commission a track in the project's synthesis tools. Boss stings for the Clockmaker: [[Boss Music Stings]]. Ambient sound: wind and a very slow clock tick (T166).

## Enemies and boss
Hollow Court and Star Choir remnants plus Grey Veil Wraiths; enemy variants per [[Stage Set Plans]] (cold, starlit rim light). Boss at stage 25: the Clockmaker ([[Boss Designs]]).

## Not done
Backdrop script (like `BackdropFoundry.luau`), the set entry, the music state, the props, a path shape (see [[Stage Set Plans]] shapes S5 A to C), and a Play check.
