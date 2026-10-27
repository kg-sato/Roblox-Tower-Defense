---
date: 2026-10-27
tags: [research, vfx, plan, flipbook]
---
# Free VFX Sources and Paid-Quality Build Plan

Independent research on free effects (not based on particlefx.studio), what "paid quality" means in measurable terms, and the pipeline we are building to reach it with original art. Written 2026-10-27. Related: [[Research/VFX and Animation/ParticleFX Studio and Flipbook VFX|ParticleFX Studio and Flipbook VFX]], [[Research/VFX and Animation/Community VFX Techniques|Community VFX Techniques]], [[Research/VFX and Animation/Beam and Impact VFX Recipes|Beam and Impact VFX Recipes]], [[Research/VFX and Animation/VFX Verification Report|VFX Verification Report]], [[Research/Index]]. Overnight tasks T24 to T26 are in `Overnight/TODO.md`.

Labels: **Fact** = read on the page or run here. **Listing** = seen only in a search result. **Inference** = our reading. **Unverified** = not tested.

## 1. Free sources, with licences (nothing downloaded yet)
| Source | What | Licence | Fit for us |
|---|---|---|---|
| [Unity Labs free VFX image sequences](https://unity.com/blog/engine-platform/free-vfx-image-sequences-flipbooks) | **Fact (page read):** 22 Houdini-made sets: smoke (candle, disc, wispy x4), clouds x4, explosions x7, fireballs x4, flames x7; each as a pre-built flipbook zip, EXR frames and TGA frames; hosted at unity3d.com/files/labs/downloads/vfx/assets01/ | CC0 (page says so) | **Best base layer** for smoke, fireball and flame. Realistic, not painted; we recolour and stylise (section 3). The page gives no resolution or frame counts. Old (2016 era), so check files after download. |
| [CodeManu VFX pack, OpenGameArt](https://opengameart.org/content/free-vfx-asset-pack) | **Fact:** 22 pixel-art effects, 30 and 60 fps versions, PNG sheets and frames, 94.6 MB | CC0, no credit needed | Wrong style for the world; maybe UI sparkles. Particlefx lists a few of its own effects under CC BY 4.0 from this author, so check each page. |
| Aim Studios explosions, Reactorcore fire/smoke and explosion packs (itch.io, OpenGameArt) | pixel-art sheets | **Listing**: CC0 | Pixel style; skip. |
| Ardes particle pack (Gumroad), Tornado Games magic sparks (itch.io) | smoke, fire, fireball, trail sheets | **Listing**: CC0, "do not resell as is" | Verify the licence on the download page before use. |
| ambientCG, Poly Haven | CC0 textures | CC0 (search summary) | Noise and gradient sources for masks; not VFX sheets. |
| [Yuruzuu open-source VFX](https://devforum.roblox.com/t/yuruzuus-open-source-vfx/1840021) | 9 Roblox effects as `.rbxl` | "free", credit appreciated, no named licence | Study only (open the files, inspect the emitters). |
| ParticleFX Studio free library | 780+ sheets | see [[Research/VFX and Animation/ParticleFX Studio and Flipbook VFX|that note]] | Optional extra. |

- **No free Roblox VFX pack on the Creator Store was found** by search; results were paid packs. Free models are a known way to smuggle scripts, so scan any `.rbxm` for scripts before inserting.
- **No dedicated open-source Roblox VFX module** turned up on GitHub searches (results were about Luau itself). Our own kit (`CutsceneFX`, `ProjectileFX`, T16 `FlipbookFX`) is the realistic route.
- **Rule for us:** CC0 or our own art only; record every source in `VFX/ASSETS.md` (file, URL, licence, date). Downloads need the user's OK.

## 2. What the paid packs are (the target)
- **Listing, BuiltByBit (pages blocked by Cloudflare, so only titles and prices seen):** Ultimate VFX Pack, BeamPack "Animated VFX Beams", White Fire + Energy VFX Pack 1 to 23, Level Up, Money, Confetti and Onomatopoeia packs, "Roblox 15+ HQ Aura VFX" (1.99 USD), "45+ Roblox RNG Aura VFX" (149.99 USD, one `.rbxm` per aura, commercial use allowed, no resale). **Inference:** even the cheap ones sell *finished, recolourable, animated stacks*, not single sprites.
- **Fact (read earlier):** Sine VFX and the Advanced VFX plugin define the feature bar: one `emit()` plays a whole stack; attributes `EmitCount`, `EmitDelay`, `EmitDuration`; `resize()` and `recolor()`; mesh flipbooks and 3D mesh particles; trail lightning; impact frames and camera shake; a 14,000 or 10,000 asset library; a runtime module.
- **Fact (DevForum Blender tutorial):** the classic Roblox mesh-VFX recipe is a Blender cylinder with a vertex-weight, cloud-texture **Mask** modifier (threshold about 0.42), Smooth, and Simple Deform 360 degrees about Z, exported as OBJ into a MeshPart; it says nothing about animating it (no tween or UV scroll), and users asked without an answer. Blender 2.79 lacks the threshold.
- **Listing:** VFX Mesh Generator Pro (Blender add-on, paid) makes slash arcs and shockwave rings with UV-direction and vertex-alpha previews; its documented exports are Unity and Unreal.

### The bar, as checks we can run (Inference, built from the above plus game-feel guides)
A paid-quality effect is not one pretty texture. It is **all of these**:
1. **Layers, at least five:** hot core flash, coloured glow, shaped element (ring, arc, beam, sigil), moving particles (sparks, motes), aftermath (smoke or embers), plus a light pulse. The prototype has core, halo, two rings, streaks, 26 sparks and smoke.
2. **A timeline with three beats:** anticipation (charge, gather), hit (a pop that peaks within about 12% of the clip), aftermath (decays to clean). Overshoot and a faster-than-linear fall make it read as impact.
3. **Animation curves, not constants:** size, transparency and colour all change over life (ease-out on expansion, exponential falloff on brightness).
4. **Hit-stop and shake scaled to importance:** guides quote 50 to 100 ms (about 2 to 5 frames) of freeze on heavy hits, shake about 2 frames light and 8 frames heavy, once per impact, small amplitude (nausea). Community rules of thumb, not measured.
5. **Colour ramp, not a flat tint:** violet, gold, white-hot, driven per rarity.
6. **No square haze:** transparent margins, edge alpha 0.
7. **Cheap:** one-shot, cleaned up at lifetime plus 1, effect budget and a Low tier.
8. **Recolourable and resizable at runtime** with one call.
`tools/fx_sheet.py verify` already checks 2 (hit early, no growth after the hit, clean end), 6 (edge alpha) and loop seams; the rest are Studio-side checks (T22, T26).

## 3. How we get from free to paid quality (pipeline)
1. **Base layer, own art (done as a prototype):** `tools/fx_sheet.py` paints 64-frame sheets from noise, signed distance shapes and a gradient map. **Fact (run 2026-10-27):** `arcane_burst_8x8.png` (charge, flash, two rings, streaks, sparks, smoke, 0.9 s) and `ground_sigil_8x8.png` (pentagram, rune ticks, 3 s seamless loop) build in 6 s and **PASS** the checks; hit frame 8 of 64, edge alpha 0, loop seam 0.97 of a normal step. Output is a coloured sheet and a white `_mono` sheet that tints with `ParticleEmitter.Color` (Reddit advice and the particlefx page agree: grayscale or white sheets tint best).
2. **Free CC0 layers as ingredients:** after the user OKs the download, run Unity Labs smoke, fireball and flame sequences through the same gradient map and posterise step so they match our violet-gold palette, and composite them under or over our shapes (smoke aftermath, fire for ember-themed familiars).
3. **Blender (installed here) for what noise cannot do:** mesh VFX (slash crescents, shockwave and column meshes with UV scroll) and Mantaflow smoke or fire baked to frames. **Listing only:** tutorials for Mantaflow exist but none we found packs a flipbook; we would render frames headless and pack them with the same PIL code.
4. **Compose and animate in Luau (T16, T25):** each effect is a recipe: sheets plus beams plus a light pulse plus camera shake plus hit-stop plus impact frame, driven by one timeline, recolourable by rarity.
5. **Gate:** sheets must pass `verify-all`; Studio checks capture freeze frames at the three beats and count live emitters.
6. **Upload (needs the user):** world flipbooks must be uploaded as images (Asset Manager; Roblox reviews them). UI flipbooks can use FrameArt painting at runtime with no upload (T17). Whether a world emitter can use an EditableImage is untested (T18).

## 4. Honest status
- **Done:** one generator, two sheets, one verifier, an animated preview. The preview is a starting layer; parity with a 150 USD aura pack needs the stack, the curves, the shake and hit-stop, and the rarity ramps, which are tasks T24 to T26, and a human eye.
- **Not verified:** how the sheets look in Roblox (blend, filtering, whether a coloured sheet should be mono), frame cost on a phone, image review acceptance, and whether the prototype's look suits the mystic-Victorian art direction (the pentagram in particular is a design choice for the user).
- **Reddit thread** (pasted by the user, 2 years old): mostly beginner advice. Useful points: sprite sheets are how most Roblox VFX are made; use grayscale PNGs with a particle Color; "combine and make it glow"; take a good free model apart and rebuild it; improvise with blocks plus particles (rocks and dust); Photoshop, After Effects, Affinity, Blender or IbisPaint to author. Nothing here changes the plan.
- **Instagram reel** and **BuiltByBit pages**: not readable (login wall, Cloudflare).

## 5. Tools like particlefx.studio (searched 2026-10-27)
Labels as above. Prices and limits are from each vendor's own page, so treat them as claims. **None of these exports for Roblox by name; all export a regular PNG grid, which is what Roblox flipbooks need** (set frames to 4, 16 or 64 so the grid is 2x2, 4x4 or 8x8).

| Tool | What it is | Cost and licence (as stated) | Fit |
|---|---|---|---|
| [AnnoMotion Particle Lab](https://annomotion.studio/ai/particle-lab) | **Fact (page read):** browser editor, up to 6 emitter layers (decal, blend mode, gravity, turbulence, colour ramp, lifetime each), bakes a packed transparent PNG sheet or a numbered PNG sequence; loop mode makes first and last frames match; same seed gives identical frames | Simulate, preview and bake are free with no credits; sign-in offered (Google); exports have no watermark and "yours to ship"; only AI-generated decals cost credits | **Best browser alternative.** HD, not pixel-only. Needs an account step the user would do (we do not create accounts). |
| [CrunchyVFX](https://crunchyvfx.com/) | **Fact:** pixel-art sprite generator (randomize, breed, variations, match a sound, palette and era limits) | Exports CC0, no attribution; app code is all rights reserved; GIF export named, no sheet format named | Pixel only; not our style. |
| [PHOSPHOR VFX](https://sinopskyd.itch.io/phosphor) | **Fact:** pixel-art VFX and physics simulator, 72 presets, emitters with curves, PNG frames, sheet, GIF, engine ZIP; ships CLI scripts (`render.js`, `validate.js`, `inspect.js`) and a `SKILL.md` for AI agents | Free, MIT code, no account, no watermark | Pixel only, but the **agent-drivable CLI** is the interesting part. |
| Sprite Dust, Pixel ability-fx forge, MR Effects to SpriteSheet (itch.io) | **Listing:** procedural or layer-based sheet makers | Sprite Dust MIT; others free or pay-what-you-want | Pixel-leaning; skip. |
| Pixel FX Designer, SpriteMancer, TimelineFX | **Fact (particlefx's own comparison page, a competitor):** desktop apps; Pixel FX Designer about 10 to 20 USD one time, PNG and GIF only | Paid | Pixel; skip. |
| Effekseer | **Fact (same page):** free open-source realtime 3D effects through engine plugins | Free | No Roblox plugin; skip. |
| GlueIT | **Fact (VFX Apprentice article):** popular tool for assembling flipbooks and sprite sheets | not stated | Useful only if we hand-assemble frames. |
| Roblox **VFX Studio** plugin | **Unverified:** one DevForum poster calls it free with many flipbooks and textures; the Creator Store page did not load for us | unknown | **Roblox-native:** its assets are already uploaded, so no upload step. Check the listing, permissions and licence before use; user installs it. |
| Sine VFX, Advanced VFX plugin, Zonito Visuals | **Fact / listing:** paid plugins with large libraries and runtime modules (see the Community VFX note) | about 4 to 10 USD | Already-uploaded assets plus a runtime; the cheap route to "paid look" if the user chooses to buy. |
| AI sprite MCPs (GameLabs Studio, PixelForge, God Mode, Layer.ai, Aseprite MCP) | **Listing:** text or image to sprite sheet through MCP; need API keys; free tiers not confirmed | Paid or keyed | Skip for now. |
| [Free realistic flipbook explosions](https://devforum.roblox.com/t/2-free-realistic-flipbook-particle-explosions/3035597) (DevForum) | **Fact:** two Blender-Cycles explosions, 8x8, 512 px frames, about 15 fps, "no credit required"; author says quality is not great and artifacts remain | free, any project | Study the method (Blender render, crop square, sheet plugin; avoid tools that trim transparent pixels or the effect pops and shrinks). |

**Biggest advantages, ranked (Inference):**
1. **Our own generator at scale** (T24): no accounts, no downloads, runs overnight, machine-checked, matches our palette.
2. **Unity Labs CC0 realistic smoke, fire and explosion sets as ingredient layers** (needs the user's OK to download; sizes in the TODO note) run through our gradient map locally, so they look painted rather than photo-real.
3. **AnnoMotion** for hand-tuned one-offs when the user is awake (account step is theirs).
4. **An existing Roblox plugin library** only if the user wants to pay or confirm VFX Studio is free; its advantage is no upload and a runtime.

## 6. What the user downloaded (2026-10-27) and what it teaches
**Files (Fact, catalogued by `tools/fx_catalog.py` and `tools/rbxl_emitters.py`):** 44 particlefx flipbooks (38 unique; 6 byte-identical `(1)` duplicates; all 8x8 on 1024 px except Katana Combo 4x4), the CodeManu pixel pack (CC0), AnnoMotion's 48 fantasy item icons (CC0), and seven Yuruzuu `.rbxl` effect files. Records and licences are in `VFX/ASSETS.md`; the machine catalogue is `VFX/flipbooks/particlefx_catalog.json`. The user's rule for the sheets: `FlipbookLayout = Grid8x8`, `FlipbookMode = OneShot`, `Lifetime` per effect (table below; parsed from each effect page, **unverified** against the GIFs).
- Catalogue checks: one sheet flags edge alpha (Anime Impact Frame fills the whole frame on purpose, a screen flash). "Loop" or "one-shot" in the catalogue is a heuristic from first versus last frame, not a fact from the vendor.
- **They cannot be used in Roblox until uploaded** (Asset Manager, then Roblox's image review). Upload list: `VFX/flipbooks/upload_list.txt`.

**Fit to our game (Inference; Lifetime in seconds):**
| Our need | Sheet(s) | Lifetime |
|---|---|---|
| Familiar placed | `tower-upgrade` (as a placement ring at low brightness), `win-pad` | 1.6, 2 |
| Merge or tier up | `tower-upgrade`, `rebirth-burst` | 1.6, 2 |
| Enemy defeated | `enemy-defeat-coin-drop`, `coin-magnet-collect` | 1.3, 1.5 |
| Range and splash ring | `splash-damage-ring` (size to the range in studs) | 1.1 |
| Summon reveal accents | `pet-egg-hatch`, `new-item-sparkle`, `rarity-frames`, `blessed`, `angelic-wings` | 2.4, 2, 2, 3, 1.2 |
| Hit styles | `anime-impact-frame`, `katana-combo`, `twin-fang-x`, `shadow-flurry`, `blazing-combo`, `reaper-s-harvest`, `whirlwind` | 1, 0.6, 0.85, 1.2, 1, 1.4, 0.8 |
| Status on enemies | `slowed`, `frost-nova`, `emp-blast` | 3, 1.6, 1.6 |
| Dark or boss mood | `dark-pact-aura`, `umbral-flame`, `demonic-possession`, `floating-ghost` | 2, 2, 3, 4 |
| UI flourishes | `claim-button`, `cooldown-ready`, `notification-badge-pop`, `tap-glitter-ripple`, `rarity-frames` | 1.8, 2.2, 2.6, 0.8, 2 |
| Beams and ultimates | `beam-clash`, `orbital-strike`, `lightning-charge-aura`, `battle-fury` | 1.2, 2.4, 1.6, 1.6 |

Most are bright and additive, so use `LightEmission 1` on dark Lampwick Lane and `LightInfluence 0`. Recolour with the emitter `Color` to our rarity ramp (pale sheets tint best).

**Layer taxonomy from the Yuruzuu files (Fact: parsed with our reader; texture ids are strings in the files):** a single named effect is a **stack of 4 to 34 ParticleEmitters**, each with a role. Hollow Purple has 10: Lightning x3, Middle, Specs, Smoke, Main, Shockwave, Crescents x2. Healing has 4: Shards, Plus, ShardsBigger, Specs. Lightning Blade has 14, including Main, Outline, Spark, Gradient, Specs, Lightning x4, ExplosionBrightspot, GlareEmitter, PlasmaEmitter. Arrow Rain repeats a 17-emitter stack twice (Middle, Smoke, Gradient, GradientSecondary, Specs, Crescents, Glow, MainProjectile, Rays, Spinny, Shards). The most common roles across the seven files are Lightning, Specs (small sparks), Shards, Crescents, Smoke, Gradient (a soft colour wash), Plasma, Brightspot and Glare. **This is the paid look in plain form: many small single-purpose layers, a few of them flipbooks, the rest simple textures, each with its own size, transparency and colour curve.** What we cannot read yet is their size, transparency, colour and speed curves (only string properties are parsed): task T30.

