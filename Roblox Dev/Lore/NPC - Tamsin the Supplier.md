# NPC: Tamsin, the Lantern Keeper who sells supplies (T070)

Status: draft written overnight 2026-10-28. The task asks for a Lantern Keeper who sells supplies with lore-driven shop text. I reuse **Tamsin, keeper of the Seventh Lamp**, who already appears in [[Chapter 1 - Lampwick Lane]] and [[Chapter 2 - Harbour of Brass]], so the lobby shop has a face the player has met. The shop does not exist in code yet (the Systems note lists "Shop / purchases" as an idea only), so this page writes the voice and the flavour text, not the item list or prices. Items and prices belong to a design task. Rules follow [[Monetisation players accept vs hate]] and [[Tone Guide]].

## Who Tamsin is
- **Role:** the lobby shopkeeper. She sells cosmetics for Robux and, in fiction, sells the same coin sinks the game already has (rolls and upgrades). She never sells power for Robux.
- **Faction:** Lantern Keepers. **Look:** a stooped keeper in a long lamp-oil coat with a ring of keys, a stall built from a lamp post, and a tray of wicks. Colour: orange and gold with the fire glyph ([[Factions]]).
- **Voice (3 words):** dry, kindly, unhurried. Lines are 16 words or fewer.
- **Gesture and flaw:** she trims a wick whenever she thinks. She is bad with names and calls every customer "dear".

## Rules for shop text
1. Prices are plain numbers shown by the UI, never in the dialogue; Tamsin never mentions Robux, discounts, timers or "limited".
2. Nothing is described as random-for-money. If paid random items are ever added, Roblox requires every outcome and odds before purchase ([[Monetisation players accept vs hate]]).
3. Each cosmetic text names a place or object and is no longer than 20 words ([[Short lore writing references]]).
4. Failure and refusals are gentle and blame-free.
5. Item names, prices and effects are proposals until a design task fixes them.

## Shop text
### Greetings and goodbyes
| id | use | text |
|---|---|---|
| SH-01 | greeting | Mind the wicks, dear. They are sharp and they remember. |
| SH-02 | greeting | Welcome to the Seventh Lamp's second stall. First is out of oil. |
| SH-03 | greeting | Ah, the walking lantern. What does it need today? |
| SH-04 | farewell | Off you go, dear. Light the corners first. |
| SH-05 | farewell | Come back when the glass is thirsty. I will be trimming. |

### Category names (UI headings)
| id | use | text |
|---|---|---|
| SH-06 | category, coins | Wicks and Oil |
| SH-07 | category, cosmetics | Coats and Frames |
| SH-08 | category, trail | Glass and Glow |

### Coin sinks (flavour for actions that exist)
| id | use | text |
|---|---|---|
| SH-09 | roll, button note | A fresh wick. Sometimes it lights something old. |
| SH-10 | upgrade, button note | A thimble of oil. It teaches a familiar to burn longer. |
| SH-11 | luck, button note | Polish for the glass. Clearer glass, kinder hours. |

### Cosmetic items (proposals)
| id | item | text |
|---|---|---|
| SH-12 | Plain Brass frame | The first lantern frame, worn smooth by a hundred hands. |
| SH-13 | Verdigris frame | A frame left by the harbour tide. Green where the water touched it. |
| SH-14 | Moonsilver frame | Cold metal from the cathedral roof. It hums when it is watched. |
| SH-15 | Starlit frame | A frame that remembers the sky. Wear it where the fog is thin. |
| SH-16 | Lamp-oil coat | A keeper's long coat. Smells of smoke and a little of home. |
| SH-17 | Harbour coat | Sea-grey wool with brass buttons. The salt never quite comes out. |
| SH-18 | Cathedral coat | Black, with a hood for the quiet hours. Soft as a hymn. |
| SH-19 | Foundry coat | A scorched apron coat. It still holds a little warmth. |
| SH-20 | Amber wick | A flame the colour of a lit window. Warm to look at. |
| SH-21 | Moon-pale wick | A flame the colour of milk and moonlight. Kind to the eyes. |
| SH-22 | Star-white wick | A wick that burns white. Do not ask where it came from. |

### Purchase flow
| id | use | text |
|---|---|---|
| SH-23 | confirm | Shall I wrap it? It is no trouble. |
| SH-24 | bought | There. Look after it, and it will look after you. |
| SH-25 | not enough coins | A little short, dear. The lane pays in time. Come back. |
| SH-26 | already owned | You have that one already. Even I forget, and it is my stall. |
| SH-27 | sold out, cosmetic returns | Put away for now. It will come round again, I promise. |
| SH-28 | error | The stall is jammed. Give me a moment. Nothing is lost. |
| SH-29 | idle | Another wick, another street. That is how the Lane is lit. |
| SH-30 | idle | I knew a Keeper who sold bells. She is somewhere in the fog. |

## Checks
- `Overnight/evidence/T070_check.py` checks 30 texts: lines of 16 words or fewer (item texts 20), no price or currency words in dialogue, no pressure or banned words. Output in `Overnight/evidence/T070.txt`.
- Voice and the reuse of Tamsin are proposals; UNVERIFIED by a human.

## Open questions for the user
1. Is Tamsin right as the shopkeeper, or should the lobby shop be a new Keeper?
2. Which of the 11 cosmetics should exist in v1? Prices, tiers and the actual item list are for the shop design task (T061 in the UI list).
3. Should "Glass and Glow" cover trails or be removed?
