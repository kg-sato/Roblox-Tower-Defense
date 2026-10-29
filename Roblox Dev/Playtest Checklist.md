# Playtest checklist (T239)
Fifteen minutes, in Studio (Play) with a phone-sized window if possible. Each step asks a question only a person can answer; write a word or two next to each. Items marked UNVERIFIED were never seen by a human before.

| # | Min | Do | Ask yourself |
|---|---|---|---|
| 1 | 1 | Press Play and watch the loading screen to the end | Is the title readable on the bottom panel, and does anything overlap or look off-centre? (Bug Log #5 was fixed by script checks and a capture) |
| 2 | 1 | Start menu: open and close the FAMILIARS button | Is the button hidden while the start menu is up, and does the collection open from the HUD? |
| 3 | 2 | Tutorial: roll, place, merge, upgrade | Does it explain itself without me? Which step confused you? |
| 4 | 2 | Drag a familiar onto a matching pair (mouse, then touch if you can) | Does the drag feel right, and does the merge happen? (UNVERIFIED with a real pointer, Bug Log #1) |
| 5 | 2 | Roll until you get three different familiars; look at each model | Do the new models (rigged, textured) look like their cards? Which one looks worst? (textures are a first-pass projection) |
| 6 | 1 | Watch a familiar attack and a unit walk (if shown) | Do they move at all, and does any limb stretch or tear? (rig deformation is UNVERIFIED in Roblox) |
| 7 | 2 | Open the collection screen | Are the silhouettes, lore cards and rarity frames clear? Is anything cut off? |
| 8 | 2 | Play stages 1 to 5 | Is it too easy, too hard or about right? Did the stage 5 boss feel like a boss? |
| 9 | 1 | Settings: change speed and a text option | Did the change apply immediately and stay after reopening? |
| 10 | 1 | Look at the console (Output) | Any red errors beyond the known "not authorized to access Asset" line? |

After the 15 minutes, answer these decisions (each is open in a design note):
1. (Answered: gold-ink on the 12 familiars, applied.) Do the gold-ink familiars look right in Play, or should the identity blend (20% of the original colour) change?
2. Keep or replace the 2x Coins pass ([[Design/Progression Rules]])?
3. Cap tier by rarity (Legendary 3, Epic 4) or keep 5 for all?
4. (Answered: faceless fog figure.)
5. Which path shapes first ([[Design/Stage Set Plans]])?

If anything fails, add a row to [[Bug Log]] with the steps. Related: [[Known Issues]].
