# Beam and Impact VFX Recipes (for STARFALL and the other cutscenes)

Why: the user said STARFALL feels low effort because the beams are plain cylinders (`VFX/CutsceneFX.luau` line 357 `column`, 576 `pillar`) with no effects. This note turns the reference videos and Roblox docs into a build recipe. Labels: **Seen** = in the video frames; **Docs** = Roblox/web source; **Inference** = my reading, untested in Studio.

Related: [[Research/VFX and Animation/Reference Video Study 2 - Priority Links]], [[Research/VFX and Animation/TikTok VFX Reference Study]], [[User Inputs]], [[Feature Pipeline]]

## What the best clips do that a cylinder does not
Seen in sixervfx, blovica, syuaey_ (Lunar Judgment, spear strike):
1. **A beam is several layers, not one shape:** a thin white-hot core, a wider coloured glow, then long streak lines around it. The core is near-white, the glow is the ability colour.
2. **Energy moves along the beam:** streaks and sparkles travel down its length (scrolling texture), so it never looks static.
3. **Charge, then fire, then aftermath:** a small bright orb with rings charges first (Lunar Judgment), a hard white or colour flash marks the fire, then an impact ring + debris + a lingering glow. A second smaller detonation follows.
4. **Impact has its own layers:** flat ring on the ground, expanding shockwave ring, upward column of light, debris chunks, dust, then a soft glow that fades. Screen blur/zoom pulse on the hit.
5. **Density of small particles:** sparkles, motes, butterflies/petals, streak lines everywhere around the main shape (blovica). Dark scene makes glows readable.
6. **Stylised 2D shapes:** hand-drawn-looking slash ribbons and colour floods (sixervfx) rather than literal 3D slashes.
7. **Text and timing:** bracketed stage captions per phase (Lunar Judgment).

## Roblox tools for it (Docs, [Beam reference](https://create.roblox.com/docs/reference/engine/classes/Beam))
- **Beam** between two Attachments: `LightEmission = 1` gives additive blending (glow). `TextureMode = Wrap`, `TextureLength` sets tile size, `TextureSpeed` scrolls the texture along the beam. `Width0`/`Width1` taper the ends (a beam that starts narrow and widens reads as a strike). `FaceCamera = true` keeps it visible from every angle. `CurveSize0/1` + `Segments` bend it.
- **Layering with Beams:** stack 2 to 3 Beams on the same attachments: core (width small, near-white, fast scroll), glow (wide, coloured, soft texture, low transparency), streaks (wide, streak texture, faster scroll).
- **Texture needed:** scrolling beam textures need an uploaded image (a soft gradient strip and a streak strip). Our `FrameArt` EditableImage module can draw these at runtime without upload (Inference: EditableImage works as a Beam Texture only if assigned via a Content value; check in Studio).
- **ParticleEmitter** flipbooks (grid 2x2, 4x4, 8x8) give animated sparks and smoke; preload with `ContentProvider:PreloadAsync` ([third-party skill guide](https://skillselion.com/skills/nonlooped/roblox-suite/roblox-vfx), verify against Roblox docs).
- **Trail** for streaks following stars (STARFALL already uses a Trail at line 412).
- **Mesh VFX:** 3D meshes (cones, rings, spirals) with a scrolling or additive material are common for shockwaves and swirls ([DevForum thread](https://devforum.roblox.com/t/how-to-create-vfx/4029502)); Blender procedural masks (goodgood3d tutorial) are the route for dome shields.
- **Curves:** Bezier path from two lerps (pr0_devv) for arcing sparks and homing: `lerp(lerp(p1,p2,a), lerp(p2,p3,a), a)`.
- **Gaps in sources:** I found no Roblox-specific tutorial for mesh beams or shockwave rings; the Beam and ParticleEmitter docs are the verified part. Textured-beam results are Inference until tried in Studio.

## Concrete STARFALL upgrade (suggestion for the main session)
Replace the plain `column` cylinder with:
1. **Charge:** gold orb at the drake's mouth with 2 counter-rotating thin rings (Orrery style), motes streaming in, a short rising whine.
2. **Fire flash:** one frame of white at 0.7 alpha, then a hard cut to the impact view (respect Flashes setting; existing impact-frame tool in `ImpactFX`).
3. **Beam stack:** core Beam (near-white, Width0 0.3 to Width1 1.2, fast scrolling streak texture) + glow Beam (gold, 3x wider, LightEmission 1) + 2 thin streak Beams offset sideways + a ParticleEmitter of sparks along it. Keep the mesh cylinder only as an invisible hit volume if needed.
4. **Impact set per star:** ground ring (flat, additive, fades), expanding shockwave ring, short upward light column (additive cone mesh), debris, dust puff, lingering glow that fades over 1 s, 1 to 2 camera blur pulses.
5. **Aftershock:** second smaller detonation 0.4 s later (Lunar Judgment).
6. **Caption:** bracketed stage text ("[ STARS GATHER ]", "[ STARFALL ]", "[ IMPACT CONFIRMED ]") in the cutscene letterbox.
7. Same pattern for the violet pillars in GRAND ARCANA (line 576) and the frost sheet in WINTER'S HUSH.
Budget: touch particle cap (100/s), Flashes setting, reduced-motion variant stay as they are.

## Other videos (all 10 now looked at; most are tools, not VFX)
- **remonbiz (46 s):** "LLM council" prompt: ask the model to answer as five advisors (contrarian, assumption ripper, expansionist, outsider, executor), cross-review, then a chairman verdict. Use for design decisions, not VFX.
- **smudger13030 (101 s):** BloxFig: designs UI in Figma and exports animated Roblox UI with no scripting (hover sweep, sparkle, click). Seen: gradient rectangle, texture overlay, export code pasted in Studio. Possible UI workflow tool; Figma needs login.
- **ashenbot (34 s):** list of tools for making games with AI (plugins, CLI tools, mesh generation, image generation); spoken only, no on-screen names readable.
- **vinallac (37 s):** announces a free VFX tutorial series (TikTok + YouTube), "coming soon". Nothing to learn yet; follow later.
- **solodev_t (32 s):** "Week 4 of making abilities with Opus + VFX Studio": a dark red/black dragon-like ability with lava-textured smoke clouds, ground sigil, and a thick black-and-red cloud wave with glowing cracks. Lava-crack texture on smoke is the trick.
- **deadj.rodev 7698101726175350038 (68 s):** map-making prompt method: identify style, gather matching reference images, write a prompt with what/where/why/how, do not over-detail.
- **deadj.rodev 7701021888679808279 (16 s):** forgeGUI + Claude, one prompt: orbiting gold and dark rings with wings and an eye (armillary look). Close to our Orrery; shows rings built from parts with square window cut-outs.
- **vos_studiostt (484 s):** a creator on camera using Claude Design and 3D previews (a rotating sigil, a red dragon on a ring platform); spoken, so content beyond the visuals is not known.
- **iag0d_ (59 s):** "Hellfire Horse" showcase: Blender idle/run/jump/land clips, glowing lava-crack texture, ember particles, trail ribbons, scripting; segment labels Blender+Animation, Textures, VFX, Scripting. Glowing emissive cracks on a dark body is the look; our Gargoyle or Star Drake could take it.
- **lihfolk (897 s):** a 15 minute on-camera Shop UI build in Studio with ChatGPT/Claude: shop button, red panel, rainbow gradient item area, Shop title, bundles; spoken, so steps beyond what the frames show are not known.

## Not verified
No audio or transcripts were read. Nothing here has been built or tested in Studio.
