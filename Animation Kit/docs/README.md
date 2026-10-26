# Roblox Animations with Claude: start here

**Method by fwjelaa (FWJ STUDIOS).** Free to use; please credit fwjelaa. See `CREDITS.md`.

Tell Claude the move and get back a finished Roblox animation (R6 or R15) that plays in your game exactly as it
looked when it was made: runs, M1 combos, sword attacks, blocks, dashes, ultimates.

## Quick start

1. Install **Blender** (4.2+, free at blender.org), **Python 3** and **Roblox Studio**.
2. Connect Claude to Blender and Studio (the two MCPs): see **Setup** in `GUIDE.md`.
3. **Open this folder in Claude Code** (the Code tab in the Claude desktop app, or run `claude` in this folder).
4. **Drag in a reference clip** (screen-recorded from a game, a GIF or screenshots) and say **"make this
   animation"**, or just describe it: **"make an R6 sprint, snappy"**, `/make-anim R6 uppercut, weighty`.
5. Claude reads the clip's timing, animates it in Blender, compares it with your reference frame by frame,
   checks every frame, loads it into Studio and proves it matches. Open it in **Moon Animator 2** with
   File → Import, or publish it with right-click → Save to Roblox.

👉 **Read `GUIDE.md` for the full guide**: both ways of working, Moon Animator 2, using the animations in your game
(combo, dash, hit-stop, movement scripts), automatic uploads, and how it works.

👉 **Just want the prompt?** `fwjelaa animation method.md` turns any Claude into a Roblox combat animator.

Never share the `.secrets` folder (an optional Roblox API key goes there).
