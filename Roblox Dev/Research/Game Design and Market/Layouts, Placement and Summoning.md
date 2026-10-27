---
date: 2026-10-27
tags: [research, layout, placement, gacha, icons, pets]
---
# Layouts, Placement and Summoning

Questions: how do good TD and Roblox games lay out maps and HUDs, how does Bloons-style free placement work, and what makes a rolling animation, an icon and a pet feel good? Builds on [[Research/3D and Art/Backgrounds and Enemies - Mystic Victorian|Backgrounds and Enemies - Mystic Victorian]].

## Findings (sourced)
| Topic | Finding | Source |
|---|---|---|
| Placement | In BTD6 most towers have a circular **footprint**; a tower can only be placed if its footprint doesn't overlap other towers or unplaceable terrain | [Bloons wiki: Footprint](https://www.bloonswiki.com/Footprint) (403 to direct fetch; search snippet) |
| Range | BTD6 shows range separately from footprint; areas with blocked line of sight are shaded red; detection range and projectile range can differ | [Bloons wiki: Range](https://www.bloonswiki.com/Range) (snippet) |
| Map difficulty | Difficulty comes from path length (shortest beginner map is hardest), line-of-sight blockers and spread-out layouts; long single lanes and a central chokepoint make maps easier | [Middle of the Road](https://www.bloonswiki.com/Middle_of_the_Road), [Town Center](https://www.bloonswiki.com/Town_Center), [End Of The Road](https://www.bloonswiki.com/End_Of_The_Road), [Downstream](https://www.bloonswiki.com/Downstream_(BTD6)), [Enchanted Glade](https://www.bloonswiki.com/Enchanted_Glade) (fan wiki) |
| Roblox HUD layout | Keep UI inside the safe area (`ScreenGui.ScreenInsets`, CoreUISafeInsets by default); test with the Device Emulator; small screens have least room | [Roblox docs: HUD meters tutorial](https://create.roblox.com/docs/tutorials/use-case-tutorials/ui/create-hud-meters) |
| HUD content | Persistent values (health, currency) small in the top corners; show only essential info | [creation.dev: Roblox UI best practices](https://www.creation.dev/blog/roblox-ui-design-best-practices) (third party) |
| Roll reveal | Colour, motion and sound together signal rarity and build anticipation; a shared grammar: cool and quiet = low, warm = mid, gold/rainbow burst = top; colour registers before the item renders | [TMU Visual Culture ch. 6](https://pressbooks.library.torontomu.ca/visualculture-howtosee/chapter/chapter-6/), [hostedgg blog](https://hostedgg.com/blog/gacha-pull-reveal-color-culture) |
| Roll reveal | Wuthering Waves: the wish colour sets the maximum rarity; ZZZ: blue B, purple A, gold S; HSR 5-star differs by a faded ticket and colour glitching | [Samurai Gamers](https://samurai-gamers.com/wuthering-waves/wuwa-wish-rarity-indicator-guide/), [GameWith](https://gamewith.net/zenless-zone-zero/46255), [GINX](https://www.ginx.tv/en/4-star-5-star-warp-animation-differences) |
| Icons | One concept, strong silhouette that works at 32 px, no text, high contrast, consistent style across the set; judge at the smallest size | [mobilegamer.biz](https://mobilegamer.biz/how-to-make-an-iconic-icon/), [Game Developer](https://www.gamedeveloper.com/design/icon-design-rules-you-should-know), [madegooddesigns](https://madegooddesigns.com/?p=5494) |
| Pets | Rarity ladders (Common to Mythic/Exclusive) with visual escalation: variants (golden, crystal, shadow) and more glow, particles, aura at higher tiers | [BuiltByBit pet pack](https://builtbybit.com/resources/124-roblox-pets-icons-pack.112028/), [creation.dev pet sim guide](https://www.creation.dev/learn/how-to-make-pet-simulator-roblox) (vendor and third party) |
| Adding units | TD templates put all unit numbers in one config ModuleScript; one vendor claims new towers need only a config entry (unverified) | [Coddy TD course](https://coddy.tech/learn/courses/roblox_game_tower_defense/the_defense_script), [BuiltByBit TD template](https://builtbybit.com/resources/tower-defense-template.117231/) |

## What was built (2026-10-27)
- **Character registry:** `ReplicatedStorage.Characters/<id>` folders drive stats, model, effects and clips. See [[How to Add a Character]].
- **Free placement:** no pads. Pets stand anywhere on the street inside the fence, off the path, footprints not overlapping (`Config.canPlace`, shared by server and client). Max 12 pets. Rolls auto-place at a free spot; drag to move. Merges keep the rule "two touching + drag a third", with touching = footprints within 2.5 studs.
- **Range display:** a soft circle with a crisp edge, white for a legal spot, red for illegal, green for a valid merge; shown while dragging and when a pet is tapped. Each pet stands on a brass footprint plate rimmed in its rarity colour.
- **Summoning card:** the egg is replaced by a sealed violet card with a gold edge and an eye sigil; it sways like a shuffled card, its edge warms to the rarity colour (the tell), Epic+ edges glow, then it bursts. ROLL shows a painted card icon. Wording: hatch → summon.

## Checks
- Headless sim: legal/illegal moves refused with reasons; merge needs a touching pair; cap 12; all auto spots legal; pets shoot from positions; registry loads 7 pets in order.
- Play (real mouse): drag shows white circle, red over the path, green with highlighted partners over a valid merge; release moved the pet and merged three Embers to tier 2; card reveal and icon render; no errors.
- No-code test: a folder with only attributes joined the Rare pool and built with the fallback look and its cloned effect.

## Reveal staging, second pass (2026-10-27, after the user said the gold beams cheapened it)
| Game | What its top reveal does | Source |
|---|---|---|
| Sol's RNG | Rare rolls get a multi-stage cutscene: screen goes dark, fog covers and lifts, stars rotate before the aura; 10k+ rarities get a star pull whose colour hints the result; low tiers can be skipped | [itemlevel.net](https://itemlevel.net/sols-rng-all-star-pull-animation/), [Twinfinite: Atlas aura](https://twinfinite.net/guides/how-to-get-atlas-aura-in-sols-rng/) (guides, not dev sources) |
| Honkai: Star Rail | 5-star cues are subtle: the ticket blurs with a rainbow shimmer, and a different, more upbeat track plays | [GINX](https://www.ginx.tv/en/4-star-5-star-warp-animation-differences) |
| Genshin Impact | No breakdown of the wish meteor found; only general studies of its visual consistency | [Anima Rupa study](https://jurnal2.isi-dps.ac.id/index.php/animarupa/article/view/6882) |
| Pet Simulator 99 | No source on the hatch screen itself; huge pets tie to milestone and golden/rainbow eggs | [BIG Games update 61](https://www.biggames.io/post/pet-simulator-99-update-61) |

Built: flat sunburst bars removed. The reveal now darkens into drifting violet fog, a painted **magic circle** (three rings, 36 ticks, eight diamond runes, hexagram; `FrameArt.sigil`) draws in from 60% and turns slowly in the rarity colour behind the card, the burst is a **shockwave ring** with a softer flash (Legendary 0.9 to 0.55), and the pet's flat neon rarity disc is removed inside the reveal. Checked in Play (Legendary and Epic): circle, shockwave and no disc; no errors. The circle paints in 263 ms once at load.

## Gaps
- Pets themselves are not restyled yet (still the old cute shapes plus two meshes); a familiar-themed roster is a next step.
- Card does not flip to show the pet's silhouette yet; no sound for the reveal.
- Map layout variety (multiple paths, blockers) not built; one map only.
- Phone drag and range ring not tested; a Model-type character (not a MeshPart) path is untested.
