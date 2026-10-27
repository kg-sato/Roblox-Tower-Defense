---
date: 2026-10-27
tags: [research, art-direction, enemies, environment]
---
# Backgrounds and Enemies: Mystic Victorian

Question: what should our stages and enemies look like if the game matches a *Lord of the Mysteries*-like theme, while staying a readable tower defense? Builds on [[Research/UI/UI Methods and Magic Effects|UI Methods and Magic Effects]] (glass UI, blur, motes).

## 1. The theme, from sources
| Pillar | What sources say | Source |
|---|---|---|
| Era | "a world reminiscent of late Victorian England"; genre mix of "steampunk, Lovecraftian horror, and Xuanhuan" | [Wikipedia: Lord of the Mysteries](https://en.wikipedia.org/wiki/Lord_of_the_Mysteries) |
| City | Tingen resembles 19th-century London with steampunk and Cthulhu elements; steam engines, warships, early industry | [Asia News Network](https://asianews.network/diving-into-the-mysteries-of-hit-chinese-animation/), [Soap Central](https://www.soapcentral.com/anime/after-link-click-lord-the-mysteries-shows-anime-fans-give-chinese-donghua-respect-deserve) |
| Mood | Muted colours, "murkiness" (fan comment); Backlund "rendered in such oppressive beauty" (review) | [ANN forum](https://www.animenewsnetwork.com/bbs/phpBB2/viewtopic.php?p=5541402), [IMDb](https://imdb.com/title/tt28618556) |
| The fog realm | Members are summoned by "grey fogs in another dimension"; a palace above the fog; tarot code names | [Wikipedia](https://en.wikipedia.org/wiki/Lord_of_the_Mysteries), [publisher blurb](https://www.hachetteukdistribution.co.uk/titles/cuttlefish-that-loves-diving/lord-of-mysteries-vol-2/9798855414271) |
| Monsters | Mages who "lose control" of their power turn into creatures shaped by their path (hallucination, erratic behaviour, full breakdown); seeing high beings drives people mad | [Games Wiki (fan)](https://thegameswiki.com/lord-of-mysteries/wiki/beyonder-monsters), [LotM fan wiki](https://lordofthemysteries.fandom.com/wiki/Mythical_Creature_Form) (fan sources: treat as flavour) |
| Production | Donghua by B.CMAY PICTURES, S1 June to Sept 2025, more seasons planned | [Wikipedia](https://en.wikipedia.org/wiki/Lord_of_the_Mysteries) |

**IP rule for us:** adapt the mood and ideas, never the names, symbols or characters (no "Beyonder", "Tarot Club", "The Fool", Klein, Tingen, Backlund, the Evernight crest). Tarot as a general motif is public domain; the novel's specific cards and pathways are not ours.

The fandom wiki returned HTTP 402 to direct fetches; fan-wiki claims above come from search snippets.

## 2. Backgrounds: how strong games do it
| Finding | Source | Use for us |
|---|---|---|
| Gothic city as the "body", cosmic horror growing out of it; familiar Victorian Gothic parts bent into illogical shapes (Mannerism): spires in wrong places, a clocktower leaning further out as it rises | [Killscreen: sublime architecture of Bloodborne](https://killscreen.com/understanding-sublime-architecture-bloodborne), [Wikipedia: Yharnam](https://en.wikipedia.org/wiki/Yharnam) | Start normal at the board, get stranger toward the horizon and in later stages |
| "a spiny bed of superimposed structures": dense, layered, vertical skyline | [Killscreen](https://killscreen.com/understanding-sublime-architecture-bloodborne) | Tall layered silhouettes ring the board; cheap because they are far and dark |
| Narrow alleys, abandoned carriages, coffins, arched doors; gloomy cobbles; a sliver of light under a shutter suggests life | [Press Start paper](https://press-start.gla.ac.uk/press-start/article/download/76/59), [GameBanshee preview](https://www.gamebanshee.com/k3dw9) | Prop list; warm windows as the only warm light |
| TD clarity: clear paths, visible build slots, range and placement indicators | [Oliver Andersson portfolio](https://se.linkedin.com/in/oliver-lo-andersson), [ModDB: no-build zones](https://www.moddb.com/news/designing-levels-for-def-no-build-zones) | Path and pads stay the clearest things on screen |
| A colour-blind player couldn't tell the yellow path from green ground | [itch.io comment](https://mikalagrand.itch.io/key-defence/devlog/97895/level-walkthrough) | Separate path from ground by brightness, not hue |
| Arknights tiles carry gameplay meaning (ground vs elevated) | [Wikipedia: Arknights](https://en.wikipedia.org/wiki/Arknights) | Pads must read as pads at a glance |
| Roblox map advice: never empty walls or dead space; a map is "more than a gray area" | [Roblox map-design skill guide](https://playbooks.com/skills/taozhuo/game-dev-skills/map-design), [TD map tutorial](https://videohighlight.com/v/4OxHc6w9ooI) | Fill outside the board with scenery |
| Roblox Atmosphere: Density obstructs, Haze is the fog look, Color tints it, Offset decides silhouette vs blend into sky, Glare/Decay colour the sun side | [Roblox docs: Atmosphere](https://create.roblox.com/docs/environment/atmosphere) | Our fog recipe below |
| `LightingStyle` Realistic gives the best shadows; `PrioritizeLightingQuality` keeps lighting when the device scales down | [Roblox docs: Lighting](https://create.roblox.com/docs/environment/lighting) | Gaslamp shadows matter to the mood |

### Recommended stage look: three rings
1. **Board (bright, calm):** cobblestone path as the lightest value on screen; pads as polished brass discs with a faint rune ring; no busy texture near the path.
2. **Mid ring (props, warm points):** wrought-iron fences, gas lamps (warm PointLights, the only warm colour), abandoned carriages, crates, a broken fountain. Low and not blocking the camera.
3. **Far ring (silhouettes in fog):** layered rooftops, chimneys, spires, a leaning clocktower, factory stacks with steam. Dark, mostly flat colour, swallowed by fog. Later stages bend them (tilted spires, a giant eye in the clouds, stairs to nowhere).

Fog and light recipe (starting values, untested): Atmosphere Density 0.35, Offset 0.25, Haze 2, Color cold grey-blue (150, 160, 180), Decay deep violet (70, 50, 100), Glare 0.3; ClockTime about 18.5 (dusk) or a dim moon; ColorCorrection Saturation -0.25, slight cool tint; Bloom low so gaslamps and runes glow. Drifting fog sheets: big transparent particle emitters along the board edges.

### Stage set (original names)
| Stages | Setting | Signature |
|---|---|---|
| 1 to 5 | **Lampwick Lane**: gaslit market street at dusk | warm lamps, wet cobbles, newspapers blowing |
| 6 to 10 | **Harbour of Brass**: foggy docks, steamships, cranes | horn sounds, steam, rope and chain props |
| 11 to 15 | **The Silent Cathedral**: moonlit gothic nave | stained glass, candles, statues with covered faces |
| 16 to 20 | **Clockwork Foundry**: furnaces, gears, rails | orange furnace glow, sparks, moving gears |
| boss stages | **Above the Grey Veil**: a stone hall floating on a sea of grey fog under red stars | the most magical stage; huge empty space, long table, high-backed chairs as silhouettes |

## 3. Enemies: rules from sources
| Rule | Source |
|---|---|
| Players recognise outline before colour; if two threats share a silhouette, players confuse them; test as solid black shapes | [Bugnet: readable game art](https://bugnet.io/blog/readable-game-art-why-clarity-beats-detail), [itch.io](https://itch.io/post/7243401) |
| States should change shape (wind-up, scale, spikes), not just flash a colour | [Bugnet: character design basics](https://bugnet.io/blog/character-design-basics-for-indie-devs) |
| Squares read stable and heavy, triangles dangerous | [RocketBrush: shape language](https://rocketbrush.com/blog/shape-language-in-game-character-design-how-to-make-characters-readable-and-consistent) |
| Most readability failures are value failures; audit in greyscale | [Bugnet: readable game art](https://bugnet.io/blog/readable-game-art-why-clarity-beats-detail) |
| Darktide: a unique palette per enemy made crowds "noisy and even more unreadable"; fixed with a readability priority per enemy *layer* (horde, roamer, elite, special, monstrosity); head and shoulders matter most; long-range elites always have a back attachment; elites get uniform and accent colours; a fake rim light fades in with distance | [Darktide enemy art dev blog](https://devtrackers.gg/darktide/p/67a2496a-darktide-101-enemy-character-art-dev-blog) |
| Eldritch wrongness: anatomy that fits no known animal, no clear front or back, lit by a sickly glow in fog; a monster is only as scary as its setting | [Concept art style guide](https://www.thepromptindex.com/skill/1518-concept-art-eldritch-organic), [Morphic](https://morphic.com/resources/images/eldritch-creature-images), [Autodesk](https://origin-exchange.autodesk.com/scary-monster-drawings) (low-authority; principles only) |

### Proposed roster (maps to our current Grunt, Swift, Tank, Boss)
| Layer | Our slot | Design | Silhouette cue | Colour layer |
|---|---|---|---|---|
| Horde | Grunt | **Hollow Parishioner**: hooded cultist, hunched, lantern in hand | round hood, small lantern glow | muted grey-violet |
| Fast | Swift | **Fog Wisp**: torn cloak with no body, glides low, trails mist | long trailing tail, no legs | pale cold blue |
| Heavy | Tank | **Brass Sentinel**: steam automaton, boxy torso, chimney on its back | square shoulders + back chimney (Darktide back-attachment rule) | dark brass, red eye slit |
| Boss | Boss | **The Unbound**: a mage who lost control; top hat and coat, upper body splitting into too many arms and one huge eye | tall, top hat, crown of arms | black with a sickly green or crimson glow |
| Elite marker | any | a floating tarot-style card with an original symbol circles the enemy | adds a shape above the head | gold rim |

Variation without noise (Darktide): small tint shifts, wear and props within one layer, never a new palette per enemy.

### Fit with our pets
Our pets are cute familiars; Lord of the Mysteries is grim. Keep pets as warm, bright "lanternbound familiars" against cold, grey enemies. Value contrast does the work, and Roblox's audience stays comfortable (eerie, no gore).

## 4. Checklist before building a stage or enemy
- Greyscale screenshot: path, pads, enemies and pets each still separate.
- Enemies as black silhouettes at game distance: four distinct shapes.
- Only lamps, runes and pets are warm; enemies and fog are cold.
- Phone: Atmosphere and particles at the Low budget still read.

## Gaps
- No primary art-direction interview for the LotM donghua found; mood claims come from reviews and fan comments.
- Fan wiki blocked (HTTP 402); monster lore is from fan sources.
- No Tower Defense Simulator or Arknights art-direction source found; TD readability guidance is from indie devlogs and portfolios.
- Fog recipe values are starting points, not tested in our place yet.
