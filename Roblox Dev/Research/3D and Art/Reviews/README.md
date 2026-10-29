---
date: 2026-10-28
tags: [3d, art, review, harsh-grading]
---
# 3D art replacement: blind reviews

Method: [[Research/Harsh Grading]]. Each piece is graded by a fresh reviewer subagent on unlabelled sheets (reference vs ours, random order) built from Play recordings at fixed camera moves. Scores are out of 10; any item under 7 fails.

## Ward crystal (pilot)
Reference: the user's fxroxx TikTok crystal core (an in-engine Roblox hero object). Ours: `Blender/crystal.py` (baked PBR, uploaded) + `Studio_Export/WardFX.luau` (rings, shards, pulse, rune base, light column) + MapBuilder placement.

| Version | Shape | Material | Colour | Motion | Board | Verdict | Main fixes asked |
|---|---|---|---|---|---|---|---|
| v4 lantern | 6 | 4 | 5 | 3 | 4 | FAIL | add motion; facet colour + accent; bigger, glowing base |
| v6 + WardFX | 5 | 5 | 6 | 5 | 3 | FAIL | the cage hides it; crystal 2-3x; bright rings; base light |
| v7 hero crystal | 6 | 5 | 6 | 6 | 6 | FAIL | unique silhouette (wings, crown, heart); glowing pool base instead of block; inner pulsing core, thicker ribbons |

Side by side for the user: `ward/ward_before_after_v7.jpg`.

Lessons: Blender colour ramps take linear values (sRGB 150 = 0.30); bake metals' colour through an Emission node (DIFFUSE bakes black); add a constant metal map or the importer drops metalness; low-poly crystals with Pointiness turn white. Studio `generate_mesh` fails ("should only be called from the server"); `GenerationService:GenerateModelAsync` from the Play server works but returns untextured geometry that cannot be saved to the place.

## Path
`LampwickCobble` MaterialVariant (Studio `generate_material`) on the lanes, darker tint. Not reviewed yet (the dolly recording went under the ground).

## Lampwick lantern (steampunk, the Lampwick Lane protected item)
Reference: FLUX concept `UI Kit/art/comfy_out/ref_steamlantern_s22.png` (made locally; the Creator Store "steampunk lanterns" were spam). Ours: `Blender/lantern.py` + MapBuilder (`WardStyle` = Lampwick) + WardFX flicker and warm light.
| Version | Shape | Material | Colour | Motion | Board | Verdict | Main fixes asked |
|---|---|---|---|---|---|---|---|
| v3 | 7 | 4 | 6 | 5 | 6 | FAIL | smooth ribbed bronze, canopy ledge, finial + hook, filigree, real gauges, flicker, warm light |
| v4 | 7 | 4 | 5 | 4 | 4 | FAIL | dome still flat orange (no sheen); base reads as planks, needs riveted stone + 3 gauges; glass cream not teal; flicker not visible in stills; too small at board |
Bugs met: Roblox importer gives a material with no metal map a white (fully metal) map, and a shared metal image across materials; SurfaceAppearance maps need the Image id, not the Decal id an upload returns.

## Brass Sentinel (Tank enemy)
Reference: FLUX concept `ref_sentinel_s33.png`. Ours: `Blender/sentinel.py` + `Models.buildEnemy` mesh path.
| Version | Shape | Material | Colour | Motion | Board | Verdict | Main fixes asked |
|---|---|---|---|---|---|---|---|
| v2 | 5 | 4 | 4 | 4 | 3 | FAIL | the eye light washed the body red (fixed after: range 3.5); gunmetal + brass split; domed diving-helmet head and porthole eye; walk cycle + steam (steam added after, not reviewed) |

## Round 2026-10-28 night: Hunyuan3D shape + concept painting (the user: "utilize both at once")
Method: Hunyuan3D-2 makes the shape from the concept image (about 30 s, 15k tris); `Blender/sentinel_hy.py` maps the concept painting onto it from the front (UVs = front projection, no baking; baking to auto-UVs gave thousands of islands that blurred to grey), adds a separate glowing part (eye / crystal), uploads.
| Piece | Version | Shape | Material | Colour | Motion | Board | Verdict |
|---|---|---|---|---|---|---|---|
| Lantern | v5 (Blender primitives) | 6 | 4 | 5 | 3 | 3 | FAIL |
| Lantern | **v6 (Hunyuan + paint)** | **8** | **7** | 6 | 5 | 6 | FAIL (closest yet) |
| Sentinel | v3 (Hunyuan + paint) | 6 | 5 | 4 | 4 | 3 | FAIL |
| Sentinel | v4 (paint lifted, pink steam fixed) | 6 | 4 | 4 | 4 | 3 | FAIL |
Remaining asks, lantern: translucent darker glass so the crystal shows from all sides; cyan light on the ground; visible pulse (the pulse exists but reviewers only get stills: send a frame strip next time); dark iron base + stepped plinth. Sentinel: slate steel + bright brass instead of speckled brown (the concept's painted noise), crisper limbs with a leg gap, rim light or outline at night, bigger sway.
Note: "motion" keeps failing because reviewers see stills; future reviews get a 6-frame strip at 0.15 s spacing.
| Lantern | v7 (on the stone plinth, fainter outline; reviewers now get a 6-frame strip) | 8 | 7 | 7 | 5 | 6 | FAIL: only motion and board readability left |
| Sentinel | v5 (slate + brass repaint) | 5 | 3 | 3 | 4 | 2 | FAIL: still speckled, near-black at the test spot, no gait |
Lantern next (written, not yet in Studio): WardFX pulse 0.8 s +-25% with flicker on both lights, glow range 30-36, crystal colour teal to white-hot. Sentinel next: the painted concept texture keeps reading as noise on the Hunyuan surface; try flat material colours by region (slate / brass / red) instead of the painting, a real walk in GameClient's mover (owned by menu-tree-rework's file set: needs a hand-off), and test where the street is lit.
| Lantern | v8 (WardFX pulse 0.5-3.5 brightness, range 24-38) | 8 | 6 | 7 | 6 | 8 | FAIL: needs an inner core with depth in the glass and a pulse on the glass itself, not only the dome bloom |
| Sentinel | v7c (flat paint: dark slate, deep brass, small specks removed; metal 0.1; 1.4x scale, brighter eye) | 5 | 3 | 4 | 4 | 4 | FAIL: "90% grey, not brass", front projection smears on the sides, no gait |

Sentinel v6 (flat colours, metal 0.6) rendered sky-blue in Studio: metal mirrors the blue night sky, so keep metal low on painted meshes. Next: either a brass-dominant repaint (user call: flat colours were chosen) or a texture made from several views instead of one front projection; the walk needs a hand-off for GameClient's mover.
| Sentinel | v8 (brass-dominant flat paint, metal 0.35, roughness 0.5) | 5 | 3 | 4 | 4 | 5 | FAIL: reads as brass now, but the Hunyuan surface is lumpy ("clay golem"), the front projection leaves blotches, no gait. The paint route has hit its ceiling: next needs a hard-surface rebuild or a multi-view texture |
