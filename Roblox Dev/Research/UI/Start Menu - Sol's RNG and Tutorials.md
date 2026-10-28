---
date: 2026-10-28
tags: [ui, menu, research]
---
# Start Menu: Sol's RNG and Tutorials

The user asked how Sol's RNG made its start menu, and how to build that kind of menu with Claude. Labels: **Wiki** = fan wiki (read in the browser pane, not official), **Tutorial** = video captions read as text, **Ours** = built and checked in Play. Related: [[Research/UI/UI Rework 2026-10-28]].

## Sol's RNG's flow (Wiki)
- **Loading screen** with tips and, since Eon 1-4 (2025), a **skip button**; on weak devices the load visibly slows ([Updates/Eons](https://sol-rng.fandom.com/wiki/Updates/Eons); the April Fools 2026 aura parodies it with a fake skip button and joke tips: [A Fool's Experience](https://sol-rng.fandom.com/wiki/A_Fool%27s_Experience)).
- **Title:** after loading, the "Sol's RNG" title with a subtitle, a **changelog** panel and a **play** button; it ends **with a flash** into the game (same page; the parody copies the real structure).
- **Title scenes change per season** (a title screen featuring EQUINOX is mentioned in [Updates](https://sol-rng.fandom.com/wiki/Updates)); our reference screenshot of the loading screen: `Reference Screens/sols-loading-screen.png` (emblem, thin line, "Loading Complete. Welcome, <name>.", tip line).
- Eon 1 (10 Nov 2024) reworked the main menu to cut clutter: one menu button opens a list (Season Pass, Achievements, Fishing, Settings, Robux Shop, Developers) ([Settings](https://sol-rng.fandom.com/wiki/Settings), [allthings.how](https://allthings.how/sol-s-rng-how-to-change-settings-and-redeem-codes-in-roblox/)).
- No developer write-up of how they built it was found; the techniques below are the common Roblox ones.

## How menus like this are built (Tutorial, DevForum)
1. **A real 3D scene behind the menu**, not a flat image: a camera Part placed and aimed in the world; on join the camera goes `Scriptable` and sits there ([Make a dynamic Main Menu, YouTube gtt1r46Rejg](https://www.youtube.com/watch?v=gtt1r46Rejg); [Dynamic main menu FAST, uO5O64n2sMw](https://www.youtube.com/watch?v=uO5O64n2sMw): car + posed NPC with an idle animation).
2. **Mouse parallax:** each frame, the mouse's distance from the screen centre times a move factor, `math.clamp`ed to a maximum, offsets the camera (gtt1r46Rejg); the older [Start Screen Module](https://devforum.roblox.com/t/start-screen-module/1315640) tweens 5 studs left or right with mouse direction.
3. **Buttons** in a left-side frame with a UIListLayout (spacing "space around"), Scale sizes, a UIAspectRatioConstraint; hover makes buttons grow from their left edge (gtt1r46Rejg).
4. **Blur** (BlurEffect 15 in the module) while the menu is up, tweened to 0 on Play ([DevForum blur threads](https://devforum.roblox.com/t/how-can-i-improve-my-menuclosedopened-blur-effect/2299747)).
5. **Play:** UI fades, a black or white frame covers and fades out, camera back to `Custom` (or the game camera), core GUI back on; a BindableEvent links the menu script to the camera script (gtt1r46Rejg; [Help fixing main menu effects](https://devforum.roblox.com/t/help-fixing-main-menu-effects/1405713)).

## Doing it with Claude (what we already have)
Claude drives Studio through the Roblox Studio MCP server (official; [connect Claude to Studio](https://www.thespike.gg/roblox/beginner-guides/how-to-connect-claude-to-roblox-studio), [open-source origin](https://devforum.roblox.com/t/introducing-the-open-source-studio-mcp-server/3649365)); third-party bridges ([Studio Bridge](https://glama.ai/mcp/servers/JuanArtxz/studio-bridge), WEPPY) advertise UI building from prompts. No published Claude menu prompt was found. What their docs agree on: state the screen's purpose, target devices, visual style and ask for a test in Studio. Our own loop is stronger than a single prompt: build in Studio, capture with `tools/ui_compare.py`, compare with a reference, fix, repeat ([[Research/VFX and Animation/Effect Recreation 1to1 - Index]]).

## Applied to our menu (Ours, 2026-10-28)
- Loading screen gained a **SKIP** button after 2 s (ends the wait once the game has loaded).
- Start menu now sits over a **street-level shot of Lampwick Lane** (camera at -58, 9, 62 looking at 4, 3, -2) with **clamped mouse parallax** (3 studs at the screen edge, smoothed).
- **What's New** panel beside PLAY (Sol's changelog idea).
- PLAY gives a **white flash** and a **1.2 s ease-out camera sweep** from the street into the board view (`1to1`-style evidence: `UI Rework 2026-10-28/start_v4_street_camera.png`, `play_sweep_sheet.jpg`).
- Not done: seasonal title scenes, a menu button list like Sol's (we only have PLAY), blur on the street shot (the shot is sharp on purpose so the lane reads), phone check.
