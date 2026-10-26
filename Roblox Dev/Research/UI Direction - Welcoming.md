# UI Direction: Making It Welcoming

Written 2026-10-26 after the user said the dark UI "doesn't look that welcoming" and pointed at the fishing game ([[fishing-hud-start.png]], [[fishing-upgrades-rods-stalls.png]], [[fishing-catch-celebration.png]], [[fishing-minigame.png]], [[fishing-title-depth-meter.png]], [[fishing-portal-halloween-event.png]]). Related: [[Image Generation Workflow]], [[UI Recreation Coverage]]

## What the fishing game does (read from the screenshots)
- **The world is the UI.** The HUD is tiny: level and money bottom-left, a two-slot hotbar bottom-centre, one timer top-centre, two round buttons top-right. Everything else lives in the world.
- **Big diegetic signs** over each stall ("UPGRADES", "RODS", "PORTAL", "BOATS"), in bright colours with a thick dark outline, plus an NPC behind each stall. Nothing to read in a menu to know where to go.
- **One short instruction line**, with one word highlighted in yellow ("Head to the **Pier**", "Catch fish as your **bait** floats **UP**"), plus a white chevron trail on the ground. Guidance is always one thing at a time.
- **Warm, bright, saturated palette** in the world (sunny sand, green hills, blue sea). Dark is used only for the underwater screens and the title card.
- **Chunky rounded type with thick outlines**, large, short words, colour-coded rarity (UNCOMMON green, COMMON white) and green money ($15).
- **Celebration:** the catch screen holds the big golden fish above the head with a flash and black cinematic bars; no menu.
- **Short, plain loading and title cards**: logo, one friendly line ("Tap the fish to boop them!").

## Why our UI felt cold
Near-black navy panels, thin pale frames, thin serif text with a faint outline, small price tags, long text blocks, no character or NPC, no world signs, no celebration. It looks like a dark dashboard, not a game.

## Direction (proposed, in progress)
1. **Warm skin ("Hearth")**: wooden panels, gold trim, bright jewel-tone buttons with a thick brown outline, cream text with a thick outline, chunky rounded font. Built as a second theme next to the dark one; switch with `K.skin = "Hearth"` or `"Sols"`. Generator: `UI Kit/art/make_chrome_hearth.py` (dark chrome backup in `UI Kit/art/out_sols_chrome_backup`). Shop render: `UI Kit Renders/Shop_hearth.jpg`.
2. Fantasy mood comes from the art (the dark-fantasy icons and pets, gold trim, glows), not from a dark, thin UI.
3. Still to do if the user picks Hearth: swap the hand-set navy fills in the screens to theme tokens, add world-space signs and NPC stalls, one-line guidance with chevrons, a catch-style reveal for rolls.

## Lessons
- Studio caches textures by path, and a re-synced sprite can show stale art even in a new Play session; always bump the folder (`textures/uikit_vN`) after any chrome change (needed v3 to v6 here).

## Status
2026-10-26: Hearth work paused by the user until the other chat finishes the HUD and fonts. Dark chrome restored (sprites in 	extures/uikit_v7); the default skin is still Sols. To resume: run python UI Kit/art/make_chrome_hearth.py (then bump the sprite folder), set K.skin = "Hearth", and convert the hand-set navy fills in UIScreens2 to theme tokens.

## Status
2026-10-26: Hearth work paused by the user until the other chat finishes the HUD and fonts. Dark chrome restored: sprites in 	extures/uikit_v7, and copied into uikit_v6 too because the open Studio place still pointed at v6 (its UIArt module could not be re-synced while Studio was in Play, started by the other chat). Default skin is still Sols. Pending: re-sync UIArt (v7) into Studio when Play ends. To resume Hearth: run python UI Kit/art/make_chrome_hearth.py, bump the sprite folder, set K.skin = "Hearth", and convert the hand-set navy fills in UIScreens2 to theme tokens.
