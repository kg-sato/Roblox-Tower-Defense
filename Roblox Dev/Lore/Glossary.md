# Glossary: places, currencies, factions, rarities, status effects (T058)

Status: draft written overnight 2026-10-28. Each entry is marked **In game** (read from `Studio_Export/Config.luau` and the task list), **Task list** (named in the plan but not built) or **Proposal** (my wording). Use these terms in all captions, cards and UI text; the tone rules are in [[Tone Guide]]. Changing a term in code needs a task of its own.

## Places
| Term | Meaning | Status |
|---|---|---|
| Lampwick Lane | The oldest street; stages 1 to 5; gaslit market at dusk | In game (stage set 1) |
| Harbour of Brass | Quays, cranes and a steamship; stages 6 to 10 | In game (stage set 2) |
| Silent Cathedral | Moonlit nave with covered statues; stages 11 to 15 | In game (stage set 3) |
| Clockwork Foundry | Rails, furnaces, gears; stages 16 to 20 | In game (set 4 built in Edit; Play check pending, see Backlog) |
| Above the Grey Veil | The roof of the city above the fog; stages 21 to 25 | Task list (T154) |
| The Fog | Spilled lost time; the thing the lantern holds back | Proposal ([[World Bible]]) |
| The Great Clock | The stopped clock at the centre of the city | Proposal ([[World Bible]]) |

Long place lore: [[Stage Set Lore]].

## Currencies and resources
| Term | Meaning | Status |
|---|---|---|
| Coins | Earned from enemies and merges; spent on rolls and upgrades | In game (`coins` in Config) |
| Gems | Earned from enemies and trainer level-ups; spent on luck and upgrades | In game (`gems` in Config) |
| XP and Luck | Trainer progression; each level pays gems and adds Luck for better rarities | In game (Config trainer progression) |
| Shards | Duplicate conversion currency for the collection | Task list (T186); not built |

The server decides all currency, rewards and purchases (project rule).

## Factions
| Term | Meaning | Status |
|---|---|---|
| Lantern Keepers | Hold the dusk; the player is one | Proposal |
| Clockwork Guild | Restart the Great Clock | Proposal |
| Hollow Court | Let the fog finish | Proposal |
| Star Choir | End the clock and open the sky | Proposal |
| Unaligned | The Grey Veil Wraith and any familiar outside the four factions | Proposal |

Detail: [[Factions]].

## Familiars and units
| Term | Meaning | Status |
|---|---|---|
| Familiar | A being made from a kept hour; the unit the player summons and merges | Proposal (code calls them pets/characters) |
| Lantern | The player's brass lantern, the protected item in the first set | In game (per the decided theme arc in the Game Design Doc) |
| Summon / roll | Spending coins for a random familiar | In game (roll) |
| Merge / tier | Combining equal familiars into a higher tier | In game (merge, tier) |
| Slot | A tile where a familiar stands | In game (`Config.SLOTS`) |
| Enemy types | Grunt, Swift, Tank, Boss (current code names) | In game; the six families and names are in the plan (T133) |

## Familiar rarities
| Term | Colour (current code) | Roll odds weight | Damage multiplier | Status |
|---|---|---|---|---|
| Common | grey-white | 60 | 1 | In game |
| Rare | blue | 28 | 2.2 | In game |
| Epic | purple | 10 | 5 | In game |
| Legendary | gold | 2 | 12 | In game |

These four come straight from `Config.RARITIES`. Mythic appears in some task text but does not exist yet. A possible display ladder from the alchemy note (black, white, yellow, red) is only a proposal; if adopted, colours must still pass the colour-blind check ([[Colour theory for readable teams]]).

## Status effects
All are planned in T194 and none exists in `Config.luau` today.
| Term | Meaning | Status |
|---|---|---|
| Burn | Damage over time | Task list |
| Chill | Slows movement | Task list |
| Stun | Stops movement briefly | Task list |
| Mark | Target takes extra damage | Task list |
| Lantern-bright | Lit by the lantern; buffed or revealed | Task list |

Durations and stacking rules are decided in T194.

## Writing rules for the glossary
- One spelling per term, capitalised as above.
- Add new terms here before using them in text.
- Retire a term by crossing it out here and noting the replacement.
