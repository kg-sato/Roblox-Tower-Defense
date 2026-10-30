# HUD rework brief (user feedback, 2026-10-30)

Owner direction after the overnight run. Replaces earlier T640 / T076 attempts. Read [[Known Issues]], `UI Kit/README.md`, `.claude/skills/make-ui/` and `Roblox Dev/Research/UI/UI Art Pipeline.md` first.

## What the user said (verbatim points)
- Left bar is badly made; fonts are bad for UI; the MENU is lodged in the middle of the screen.
- Coins and gems overlap other objects. The "TRAINER" text means nothing. The eclipsed moons with the 8 in the middle make no sense.
- Roll button is very ugly and did not follow the UI instructions.
- Ultimate button is weak and ugly: every character needs a unique, cool-looking ultimate button, and the button shown is the one for the currently equipped character.
- Top bar with level and HP covers a lot of the screen and explains nothing.
- The lamps glowing nonstop in the background take away from gameplay (calm them: no constant glow/flicker on the board).
- Indicators for menu, settings, auto, quick and roll are all bad.
- Remove the odds popup (it is overlapped).
- Whole HUD needs a rework.
- Levelling / Trainer Progression window: borders stay but the buttons vanish; remove the stray items around the window (big glow beam, stray orb, empty frames behind it); look at vault examples or find new ones.
- Settings UI still needs work.
- The skill tree cutscene and the skill tree UI do not match: KEEP the actual UI, change the cutscene to match it.

## Reference pins (user's taste target; Pinterest, open in the built-in browser; save viewed images under `Roblox Dev/Research/UI/Refs 2026-10-30/` and measure colours/strokes before matching)
- https://ca.pinterest.com/pin/411023903489028594/
- https://ca.pinterest.com/pin/476044623104519413/
- https://ca.pinterest.com/pin/383017143283246353/
- https://ca.pinterest.com/pin/517984394618154718/
- https://ca.pinterest.com/pin/389279961536840780/
- https://ca.pinterest.com/pin/1120481582320150051/
- https://ca.pinterest.com/pin/442549100878546910/

## Done means
1. HUD rebuilt in Studio (Scale-only, UI Kit validator clean) following the references; every item above addressed, listed with PASS/FAIL.
2. Flags `RESULTS_SCREEN` and `PAUSE_MENU` and the new HUD pieces stay behind flags until a blind review (max 3 rounds) scores HUD, collection, results and reveal at 7/10 or better; honest scores in `Overnight/evidence/`.
3. Screenshots in Play at 1920x1080 and a phone size; no overlapping elements; text readable.
4. Per-character ultimate button art (20 familiars) after the base HUD works; uploads are pre-approved.
5. Build the achievements and quests screens only AFTER all of the above (user: "after everything else is done").
