---
date: 2026-10-27
tags: [research, vfx, ui, roblox, flipbook]
---
# ParticleFX Studio and Flipbook VFX

Priority source: [particlefx.studio/roblox](https://particlefx.studio/roblox) (opened in full: the Roblox setup, tower defense, UI effects, anime, slash, explosion, simulator, MCP, pricing and rarity-frames pages), plus six DevForum threads and two items that could not be read. Written 2026-10-27. Related: [[Research/VFX and Animation/Community VFX Techniques|Community VFX Techniques]], [[Research/VFX and Animation/Beam and Impact VFX Recipes|Beam and Impact VFX Recipes]], [[Research/UI/Community UI Approaches|Community UI Approaches]], [[Research/UI/UI Art Pipeline|UI Art Pipeline]], `Overnight/TODO.md` (tasks T16 to T23), [[Research/Index]].

Labels: **Fact** = read on the page. **Vendor claim** = the seller says it. **Inference** = our reading. **Unverified** = not tested in our game.

## The core idea (Fact)
ParticleFX Studio ships each effect as **one flipbook PNG** (2x2, 4x4 or 8x8 grid; 1024 px default, 512 or 256 for small effects) played by **a single particle**. The whole animated effect is one `ParticleEmitter` particle stepping through the grid. That is why it is cheap: a full wave of enemy deaths is one particle each, and it works on phones. The texture is the main cost.

## Exact emitter recipe (Fact, from the Roblox setup page)
`Texture` = the uploaded sheet; `FlipbookLayout` = the grid; `FlipbookMode` = `OneShot`; `Lifetime` Min and Max = the effect length; `Rate` 0; Speed, SpreadAngle, Rotation, RotSpeed, Acceleration, Drag, Squash, Transparency, ZOffset 0; `Size` about 6 to start (side of the whole square frame; the picture fills at most 7/8 of it); `Color` white; `LightEmission` 1 for glow, **0 for smoke, dust or dark ink effects** (they vanish otherwise); `LightInfluence` 0 (new emitters default to 1, so set it); `Orientation` FacingCamera (**FacingCameraWorldUp** for tall blasts so they stay upright from above); `LockedToPart` on; `FlipbookBlendFrames` on for HD, off for pixel art. Emit with `emitter:Clear()` then `emitter:Emit(1)`; a loop does that every `Lifetime` seconds. Clean up one-shots with `Debris:AddItem(fx, ceil(lifetime) + 1)`.
- Rules of thumb: effects up to 0.2 s use 2x2, up to 0.75 s use 4x4, longer use 8x8. Roblox caps `Lifetime` at 20 s. Wrong speed means Lifetime is not set on both Min and Max. Several copies means Rate is not 0. Dark at night means LightInfluence is not 0. A new image waits for Roblox's review before it shows in game; a Decal id has to be pasted into the Texture field in Studio to convert.

## Trigger pattern (Fact, matches the DevForum "correct way" thread)
Server confirms the event, then `FireAllClients(effectName, position)`; each client clones the effect from `ReplicatedStorage.Effects`, `PivotTo`s it, parents it to `workspace`, and removes it with Debris. The server does no visual work. Personal rewards (coins, level up) play from a LocalScript on the owner only. Rate-limit the remote; send only a name and a position. We already work this way (the server decides, clients render).

## Tower defense (Fact; our genre)
- **Camera is far, so effects must be bigger and bolder**; bright, high-contrast shapes read best from above. Use 512 px textures for enemy effects.
- **Tower Placement:** a ring snaps around a turning sigil; start Size about twice the tower's width, drawn as an ellipse seen at an angle.
- **Tower Upgrade:** gold chevrons climb a column of light; recolour bronze, silver, gold per level.
- **Splash Damage Ring:** Size = the splash diameter in studs, tuned until the circle matches the damaged area (towers with the same radius share the Size).
- **Enemy Defeat Coin Drop:** 1.3 s one-shot showing the coins earned.
- Status loops on enemies (Slowed), Frost Nova, EMP Blast, Orbital Strike exist as ideas. The page gives no firing or boss guidance: **draw projectiles with a `Beam`** (a flipbook bolt has one fixed length) and play an impact at the enemy.

## Rarity and rewards (Fact)
Pet Egg Hatch: wobble, crack, burst, then **Loot Beams for the rarity reveal**; rare hatches are shown server-wide; weld a small aura to the pet with a positive ZOffset so it draws in front. Rebirth: gold ring plus pillar of light plus rainbow rings. Coins: a 3 to 4 stud dust puff at the pickup (512 px) just before the coin is removed; Gem Shower for big payouts. The page gives no full tier system (**Inference:** escalate from small personal effects to larger shared ones). **Rarity Frames** (effect page): four item-frame styles with their own motion (drifting dust, pulsing glints, orbiting comet trails, flames on the border), 2 s seamless loop, 11 emitters, 8x8 grid; additive, so it glows on dark panels.

## UI effects (Fact)
Flipbooks also play in UI: an `ImageLabel` with `ImageRectSize` = one frame and `ImageRectOffset` stepping through the grid row by row. Keep the label square (`UIAspectRatioConstraint` 1, background transparent); wide banners use only a strip; ImageLabels cannot add light, so **glow effects need a dark panel**; pixel art uses `ResampleMode = Pixelated`; the same works in Billboard and SurfaceGui. Their `UIFlipbook.luau` does `play(imageLabel, { grid, seconds, loop, ... })` and returns a `stop()`. Ideas listed: Achievement Unlocked, Quest Complete, Rarity Frames, Claim Button, Notification Badge Pop, Cooldown Ready, Tap Glitter Ripple, New Item Sparkle.
- **Inference, important for us:** this needs only an `ImageLabel` and a sprite sheet. Our `FrameArt` already paints images at runtime into `EditableImage`, and `ImageContent` accepts them. So **UI flipbooks can be drawn by us with no upload.** Whether a world `ParticleEmitter.Texture` can use an EditableImage is **Unverified** (spike T18).

## Combat and impact (Fact)
- A default character is about 5 studs tall; hits 6 to 8 studs, ultimates 15 to 25. Keep light hits under 1 s. Additive effects fade on bright backgrounds. `ZOffset` 1 or 2 so a flash centred on a character is not hidden by it. Recolour with `Color` (multiplies the texture, so white and pale sheets tint best).
- **Slash arcs:** place `root.CFrame * CFrame.new(0, 0, -3)` (front is -Z); rotate per swing with the emitter's Rotation (their combo uses 0, 160 and -35 degrees so swings differ); one-handed 6 to 10 studs, big weapons 12+; slow a heavy swing with `TimeScale` 0.5. The flipbook is flat and shows the cut, so pair it with a **Trail** on the blade for the path.
- Explosions: one flipbook for fire, smoke and debris; lift it by half its Size so the base sits on the ground; use an `Explosion` with `Visible = false` only if physics is wanted (we do not use physics). Sizes: grenades 8 to 12, vehicles 15 to 20, set pieces 30+. The page gives no layer-by-layer recipe, so it does not replace our layered beam and impact kit.

## DevForum threads (all opened)
- **[Advanced VFX plugin, 10,000 assets](https://devforum.roblox.com/t/advanced-vfx-plugin-library-of-10000-assets-add-ons/3547230):** emitters carry **`EmitCount`, `EmitDelay`, `EmitDuration` attributes**; one `emit()` on the parent plays the whole stack; helper functions `resize(vfx, 2)` and `recolor()`; sliders that scale Size, Squash and Rate past Roblox limits; random picks; impact frames and camera shake; add-ons. Price about 4 to 8 USD (the author discusses 3,000 Robux). Vendor claim on asset count. **Inference:** the attribute convention is worth copying so effects are authored as instance trees and played by one function.
- **[Mesh flipbooks](https://devforum.roblox.com/t/what-are-mesh-flipbooks/2656999):** thin thread. Roblox has particle flipbooks but no built-in mesh flipbook; people script one by cycling mesh ids or textures. No Blender or performance detail.
- **[Optimize VFX at low graphics](https://devforum.roblox.com/t/how-to-optimize-vfx-and-retain-quality-at-low-graphics/2804870):** the poster's effect used Rate 50 to 100 with Lifetime 0.2 to 1 s and avoids long lifetimes with low rates (they look empty at low quality). At graphics level 1 it was "basically not usable", 2 acceptable, 3 to 5 good. A reply suggested `Rate = Rate * 10 / QualityLevel`; **Unverified** (no evidence given). Nothing on textures, overdraw or LOD.
- **[Breakdown on how VFX work](https://devforum.roblox.com/t/breakdown-on-how-vfx-work/1827443):** effects are a mix of particles, beams and trails; set Rate to 0 and call `Emit(count)` at chosen moments; tune Lifetime; study existing effects by inspecting them; principles named: timing, anticipation, arcs, staging.
- **[Correct way of scripting VFX](https://devforum.roblox.com/t/correct-way-of-scripting-vfx/2439994):** server validates, clients render; never animate effect parts on the server; rate-limit the remote. No pooling or Debris advice in it.
- **[Yuruzuu's open-source VFX](https://devforum.roblox.com/t/yuruzuus-open-source-vfx/1840021):** nine free effects (Galaxy Orb, Lightning Blade, Pyronado, Lightning Strike, Arrow Rain, Healing Effect, Thunder Spear, Hollow Purple, Scorched Earth) as `.rbxl` files on Discord links; credit appreciated, no named licence; the post documents no technique. Only useful by opening the files. **Not downloaded.**

## Could not be read
- **Reddit thread** "Roblox VFX are so hard": blocked by the fetch tool and by the browser pane's safety list. **Not read.**
- **Instagram reel:** login wall, no content. **Not read.**
- **[ArtStation Ry8Kly](https://www.artstation.com/artwork/Ry8Kly)** ("Roblox VFX/Particle" by SewerDog): images only, no text. From one screenshot: a character inside **gold orbiting rings with four-point sparkles and a title banner**, and a **glowing rune circle on water**. This matches our Orrery and ground-sigil direction; no technique notes.

## ParticleFX Studio facts you need before using it
- **Free:** the 780+ effect library (about 784 premade), PNG download for Roblox **without an account**, studio export 3 per day after Google sign-in, commercial use allowed on every plan with no credit (a few library effects need credit to the sprite author under CC BY 4.0; check each page). **Not allowed:** reselling the library or packs. Paid plans start at 7.99 USD a month ("Opening soon" on the page).
- **Agent and MCP (Vendor):** tools `list_presets`, `create_effect`, `edit_effect`, `render_preview`, `analyze_effect`, `export_effect`; new effect costs 1 build; free accounts get 20 builds at sign-up then 3 a day; build packs 4.99 USD for 150. **The MCP export list has no Roblox entry** (Godot, Unity, Phaser, PixiJS, GameMaker, Aseprite, images, video); Roblox flipbooks come from the website. Needs an account and an API key; not set up, not tested.
- **To use their sheets in our game, a person has to download a PNG, upload it to Roblox (Asset Manager) and send us the asset id.** That is an upload and a download, so the user decides. See Section B of `Overnight/TODO.md`.

## What we take (suggestions; tasks T16 to T23 in the overnight list)
1. A small **FlipbookFX kit** (world one-shot and loop, UI player, attribute-driven emitters, resize and recolor, effect budget) with an `Effects` registry that works with either their sheets or our procedural ones.
2. **UI flipbooks painted by FrameArt** for rarity frames, claim sparkle and achievement bursts (no upload).
3. A **tower-defense feedback set** (placement, upgrade, range and splash ring, coin drop) sized for our far camera.
4. **Rarity-escalated reveal accents** (loot beam, pet aura) in the shared-versus-personal pattern.
5. A **slash-arc hit style** with per-hit angles and a Trail.
6. An **effect budget and low-graphics fallback**.
7. Wire their sheets later if the user chooses to download and upload a short list.

## Not verified
Everything above is from pages, not from our game. Not tested in Studio: any emitter setting, EditableImage as a flipbook texture, the quality-scaling formula, frame cost on a phone, and whether Roblox's image review accepts these sheets.
