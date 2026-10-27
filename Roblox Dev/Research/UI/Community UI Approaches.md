---
date: 2026-10-27
tags: [research, ui, roblox]
---
# Community UI Approaches

What other Roblox developers use to build and animate UI, found 2026-10-27, compared with our own stack (UI Kit tokens, FrameArt painted art, glass style, `GameClient` UI table). Related: [[Research/UI/UI Design Playbook|UI Design Playbook]], [[Research/UI/UI Art Pipeline|UI Art Pipeline]], [[Research/UI/GUI Maker Tools Review|GUI Maker Tools Review]], [[Research/UI/UI Methods and Magic Effects|UI Methods and Magic Effects]], [[Research/UI/bbstudios UI Reference|bbstudios UI Reference]], [[Research/Index]].

Labels: **Fact** = read on the page. **Inference** = our reading. **Unverified** = only in a search listing.

## Headline
No source describes a modern "dark glass" Roblox UI. The community splits into (a) **code frameworks** for state and animation and (b) **visual styling layers**. Our painted-art approach (FrameArt) is outside both and is the reason our UI looks more like a finished game than a stock kit. The useful things to take are the *animation* and *theming* ideas.

## Code frameworks
| Tool | What it is | Fact / note |
|---|---|---|
| [Fusion](https://elttob.uk/Fusion/0.3/) | Reactive UI library (MIT) | State objects (`Value`, `Computed`), `New` builds instances with properties, events and children in one place; **`Tween` and `Spring` are state objects**, so any value can be animated. |
| React-Lua | Roblox-maintained React port | DevForum post says most Studio plugins and the Roblox app use it ([How To: React + Roblox](https://devforum.roblox.com/t/2964543)). Unverified beyond that post. |
| Luix | Editor tooling for React-Luau, Roact, Fusion, Vide | [GitHub](https://github.com/ericplane/Luix); listing only. |
| Vide, Roact, Rodux | Other UI and state libraries | Mentioned in directories; not read. |

**Inference:** a framework would shrink `GameClient` (3,110 lines at Luau's 200-local limit) but means a rewrite of working screens. Not worth it this month. The idea to copy without the library: *UI as a function of state*, so panels stop hand-wiring many connections.

## Styling and theming
- **[Sculpt](https://github.com/ImAvafe/sculpt)** (MIT, 26 commits, last update date not shown): declarative style sheets whose values can point at **theme tokens** (`"$Primary"`), values computed by functions, a per-property `Transition` block mapped to `TweenInfo`, defaults like `AutoButtonColor = false` so custom hover effects stay consistent. A 9-slice `skin` package is described as "entirely conceptual". README advises copying the source because the API may change. **Inference:** our UI Kit design tokens already do the token part; the *per-property transition table* is a tidy idea for hover and press states.
- **[Glass UI kit](https://github.com/satyanto/rblxGlassUI)** (despite the name): scrolling menu bars and lists, highlight-and-enlarge the focused item; **no blur, translucency or glow**; the author calls the code "quite inefficient". **Inference:** nothing to copy beyond the focus-enlarge idea. Our own glass look (FrameArt panels, vignette, BlurEffect behind screens) is ahead of it.
- Commercial packs (BuiltByBit "Vault UI System", "Ultimate UI Animation Pack") only seen as paid listings with no detail. **Unverified**, skip.

## Animation: springs beat tweens for interactive UI
- **[spr](https://devforum.roblox.com/t/spring-driven-motion-spr/714728)** (Fractality): single-module spring animator that interpolates each datatype in its natural space. A DevForum post argues tweens cause problems when a button switches state many times mid-animation, and recommends springs ([Spring UI thread](https://devforum.roblox.com/t/spring-ui-tester/1639289)). SpringV2 uses duration and bounce as its two parameters.
- **Flipper** and **Ripple** (`@rbxts/ripple`, a Flipper alternative inspired by roact-spring): spring and tween "motors" for UI (Ripple page read only as a listing).
- **Inference, useful for us:** our hover, press and tab-switch animations use `TweenService`; a tween restarted mid-way jumps, a spring keeps velocity. For a mobile game with fast taps this reads smoother. Suggested trial: replace press and hover scale on the HUD buttons with a small spring helper inside the `UI` table (no new local).

## Workflow tips from the sources
- Design in Figma at 1920x1080, then build with **scale-based** sizing (one guide; matches our "Scale-only" rule in the UI Kit and the validator).
- UI/UX skill pages for Roblox repeat: scale over offset, safe-area insets, TweenService for UI motion, layouts via UIListLayout and UIGridLayout ([taozhuo skill page](https://playbooks.com/skills/taozhuo/game-dev-skills/ui-ux) returned 404 when opened, so this is from the search snippet only).
- Icon packs (Lucide, Phosphor) for Roblox: **searched, nothing found.** Our icons come from the Blender and ComfyUI pipeline ([[Research/UI/UI Art Pipeline|UI Art Pipeline]]).

## Suggested next steps (not started)
1. Spring helper for button press and hover; compare feel against tweens in Play (judge by eye, so the user decides).
2. Per-property transition table in the UI Kit styles.
3. Keep FrameArt; do not adopt a framework this month.

## Not verified
Maintenance status of Fusion 0.3, Sculpt, Ripple and Luix; every commercial pack; whether springs feel better in our game (untested).
