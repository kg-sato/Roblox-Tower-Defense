# Video Reference Analysis

Analysed 2026-10-25 from 10 screen recordings the user added to `Research/` (1920x1080, 30 fps). Method: frames pulled with OpenCV (`tools/video_sheets.py`), contact sheets with timestamps in `Research/Video Frames/`, plus a measured **sharpness curve** (variance of the Laplacian, every 0.2 s) to time blur ramps. Related: [[Smooth Motion and Blur Playbook]], [[Loading and Reveal Spec]], [[Magical Roll Animation Playbook]], [[Screenshot Analysis]], [[UI Generator Method]]

**Limits:** I read still frames, not motion. Timings come from frame timestamps and the sharpness numbers; "feel" (easing curve shape, sound) is inferred and not heard. Sharpness is affected by any text or UI on screen, so treat the numbers as indicative.

Sheets (open in Obsidian): `Video Frames/Rivals_Loading_Screen_sheet_1.jpg`, `zoom/Rivals_Loading_open.jpg`, `zoom/Rivals_Loading_close.jpg`, `Rivals_Battle_Pass_sheet_1/2.jpg`, `Rivals_Weapon_UI_sheet_1.jpg`, `Rivals_Match_Screen_sheet_1.jpg`, `Sols_Rng_Loading_Screen_1_sheet_1.jpg`, `Sols_Rng_Loading_Screen_2_sheet_1/2.jpg`, `Rolling_Animations_sheet_1/2.jpg`, `Vibe_Coded_Game_Intro_sheet_1.jpg`, `Vibe_Coded_Game_Animations_sheet_1.jpg`, `Vibe_coded_game_2_sheet_1.jpg`.

## 1. Rivals loading screen (23.3 s) — the blur the user likes
Beats (from frames and the sharpness curve):
| Time | What happens |
|---|---|
| 0.0 to 0.3 s | Roblox's own game-launch card (update notes) still showing |
| 0.3 to 0.9 s | Cross-fade to a heavily blurred, enlarged game thumbnail (red and purple), which **darkens to black** by 0.9 s (sharpness falls 2161 → 63) |
| 1.0 s | Cut to the loading backdrop: a **heavily blurred dark-green scene**, slowly drifting clouds of light; bottom-left a small chicken mascot with a speech bubble "Arena is being deleted on February 30th" (joke tip); bottom-right **"Loading" with a counter** that counts 0, 1, 2 … 18 (about one step per second) |
| 4.5 to 16.5 s | A big blocky white **3D-looking logo/lettering** sits centre; the letters change in steps (it reads like a rotating or cycling mark). Everything else is calm; the blur never changes during the wait |
| 18.0 s | Backdrop clears of the logo for a beat |
| 19.5 s | **"RIVALS" logo glows in** (green, bevelled), counter at 18 |
| 20.0 to 21.0 s | **The handoff:** the lobby HUD (task list, bottom bar, leaderboard) is already on screen while the world behind is still blurred; the RIVALS logo stays centred, then **shrinks and fades** (visible 20.0 to 20.9 s) as the **blur clears in about 0.8 to 1.0 s** (sharpness 683 → 1270 → 2027 → 2795 → 3559 → 4133 at 20.0 / .2 / .4 / .6 / .8 / 1.0 s: rises steadily, flattening at the end, i.e. an ease-out) |

What to take from it: the *wait* is a still, blurred, low-motion scene so nothing competes; the *payoff* is the blur resolving **while the HUD is already visible** and the logo easing away. The reveal feels smooth because three things overlap (HUD in, logo out, blur out) instead of happening one after another.

## 2. Rivals UI videos (battle pass, weapon UI, match screen)
- **Battle pass** (8.4 s): from the lobby, the world **blurs and dims to green** while a full-screen panel pops in: two reward rows with level numbers and a slim progress bar, two big bundle cards (gold "Prime Bundle", purple "Contraband Bundle") with a strike-through old price and a green price button, red X top-right, arrows to page through levels. Content pages left/right (levels 1 to 7, 8 to 14 …). On close, blur and panel fade together.
- **Weapon UI** (5.5 s): lobby → **fade through black (0.35 to 0.7 s) → a 3D weapon showcase on a plain backdrop** with a small left list, right stats panel, bottom buttons. Leaving does the reverse and a green "hacker" cosmetic pops in.
- **Match screen** (9.5 s): mode picker with five picture tiles (1v1 … 5v5) plus a locked "Ranked" tile ("Unlocked at Level 100"); sliding list of limited-time modes with banner art, timers ("New gamemodes in 8h 51m"); **a backpack grid** of item icons. Panels slide/fade in over the blurred green world.
- Pattern: every full-screen menu **blurs the world, tints it (green) and dims**, so UI sits on a calm layer; icons are crisp art on dark tiles.

## 3. Sol's RNG loading screens (two recordings, 13.7 s and 21 s)
- Almost entirely **black**, with a thin white **sun/compass emblem** centred, a hairline progress rule, a tiny monospace line ("Loading Assets | n / m") and a **tip** underneath. Faint, dark, slowly shifting 3D art behind it (chains, shards) at very low brightness.
- **"SYNCED" beat:** the screen **lifts to light grey / near white** (0.5 to 1 s), the text "SYNCED" appears inside **four corner brackets** with an underline, then it **fades back to black**. (A flash: ours must honour the Flashes setting.)
- **Title and Play:** on black, the game name "Sol's RNG" with the emblem appears top-left; **a bracketed "Play" button** (green) and a small "Changelogs" button bottom-left.
- **Backdrop reveal:** the cinematic 3D scene (galaxy, glowing rings, the player's avatar from behind) **fades up from black** under the title (7 to 18 s) with slow camera drift, then back to black and into the game world.
- Style: monospace, hairlines, corner brackets, no rounded blobs, no gradients on buttons. Opposite of Rivals' chunky look.

## 4. Sol's RNG rolling animations (50 s, 8 cutscenes)
Observed pattern per aura (see `Rolling_Animations_sheet_1/2.jpg`):
1. **Anticipation is long and tiny:** a single point of light (a star flare with a few spikes) on a dark, streaky background. It sits there and slowly changes (0 to 8 s in the first one). The slow start is what makes the burst land.
2. **Colour = identity:** blue star with brown bands; gold swirl; green ink splashes with a thin ring of runes; red corrupted glitch ("[OVERDRIVE]" text, scan lines, a triangle); purple/blue lyric-like words ("WAKE", "AWAY", "STAY", "THERE") drifting around a blue star.
3. **The star grows and flares** (gold at 17.6 s), then **cuts to the aura viewer** for the result.
4. Each cutscene is a **different idea**, not a recolour (ink, glitch, typography, swirl). That variety is the "high quality" feeling.
5. Soft focus and **bloom** everywhere; hard edges only on the text and runes.

## 5. The vibe-coded game ("Universe Clicker": three recordings)
User's description: low effort, **terrible UI, good animations to copy**. It is a space clicker: a glowing sun in the middle, planets to discover.
What the animations do well (frames at the times shown):
- **Menu:** blue ringed planet with a halo, slow nebula drift, a small orbiting ring (0 to 3 s); buttons are tiny and dull (the UI problem).
- **Into the game (3 to 4.5 s):** menu fades, **camera pushes into the sun**, panels slide in.
- **A living background:** a large nebula/milky way smear behind a soft **bloom-heavy sun** with a thin light streak across it; stars twinkle; slow parallax. Nothing is still.
- **Click feedback:** floating **"COMBO x10 +92%"** text with small lightning icons rising from the button, a **ring pulse** around the click point, a **tint flash of the whole screen edge** (yellow-green at 12.0 s of the intro video) on combo milestones.
- **Discovery moments:** a planet **flies in** with a thin glowing orbit line; a big **name title fades in** ("VENUS") behind a huge bright planet that fills the top of the screen, then everything settles; short banners ("STELLAR! YOU'RE A NATURAL!", "SUPERB!", "GREAT JOB!", "GUIDE COMPLETE!").
- **Tutorial highlight:** the rest of the screen **dims**, the target gets a **gold outline** and a pointing-hand cursor (11.9 s).
- **Particles converge** onto the planet in a swirl (13.6 s of the second video).
- **Panels fade in with a dim** behind them; closing fades the same way.
What it does badly: dark grey panels, tiny text, thin borders, low contrast, dense lists. Do not copy any of that.
For us: **this is the baseline for motion**: every screen should at least have a living background, click feedback text and rings, milestone banners and a dimmed highlight tutorial. Our UI (Candy/Pixel/Aura themes) should be the part that is clearly better.

## 6. Takeaways for our game
1. Loading and menus: **blur + dim + tint the world behind a calm UI**, resolve the blur while the HUD and logo overlap.
2. Reveals: **long tiny anticipation, colour identity, a different idea per rarity**, then a burst and cut to the result card.
3. Feedback: **combo text, ring pulses, milestone banners, edge tints (soft)**.
4. Flashes: Sol's "SYNCED" white lift and Rivals' black fades are fine as slow ramps; hard flashes need the no-flash variant.
5. Style split: Rivals-like chunky art for menus, Sol's-like hairline brackets for system moments (loading, "SYNCED", reveal title).
Full build plan: [[Loading and Reveal Spec]].

## Gaps
- No audio, no motion, no easing curves actually seen; sampled at 0.35 to 1.7 s steps outside the zoomed ranges.
- Rivals' logo animation (blocky letters cycling) is only partly legible in stills.
- The Sol's "Play" button and Rivals' mascot are their art/IP: we copy structure and timing, not assets or logos.
