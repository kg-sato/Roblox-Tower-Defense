# Credits and thanks screen, with the licence list (T073)

Status: draft written overnight 2026-10-28. The list below is built from the project's own source logs: `Audio/CREDITS.md`, `VFX/ASSETS.md`, `Vendor/README.md` and `Animation Kit/docs/CREDITS.md`, all read this session. Nothing here is legal advice. The on-screen layout is a proposal and nothing is built. Items marked **needs your decision** are things I could not settle from the files.

## What each entry needs (taken from the sources)
| Item | Used for | Licence stated by the source | Credit needed? | Source |
|---|---|---|---|---|
| Music: five tracks (Gichco "Shinsei", omfgdude "Chill lofi inspired", RandomMind "Fantasy: Rising Moon", Fupi "Artifact Room", beardalaxy "Iremos Forest Theme Loop") | menu, in-game, tension | CC0 1.0 per each OpenGameArt page, checked 2026-10-25 | No (courtesy). Project credit text exists. | `Audio/CREDITS.md` |
| VFX flipbooks from Unity Labs (13 sets) | effect sheets | CC0, Unity Labs Paris, per the source page | No (courtesy) | `VFX/ASSETS.md` |
| particlefx.studio effect sheets (44 files) | effect sheets | "any project including commercial, no credit"; no reselling the library; **a few effects carry CC BY 4.0 sprites by CodeManu, so check each effect page** | **Yes for the CC BY ones** (needs your decision which effects use them) | `VFX/ASSETS.md` |
| Free VFX pack (CodeManu, 22 pixel effects) | possible UI sparkles | CC0 per the page read earlier | No (courtesy); not yet used | `VFX/ASSETS.md` |
| Fantasy RPG item icons (AnnoMotion, 48 icons) | relic or skill icons | CC0 1.0 per `LICENCE.txt` in the pack | No (courtesy) | `VFX/ASSETS.md` |
| Yuruzuu open-source VFX layer numbers (Hollow Purple, Healing, Arrow Rain recipes) | effect recipes (numbers only, no textures taken) | "free to use", credit appreciated, no named licence | Courtesy credit recommended; **needs your decision** | `VFX/ASSETS.md` |
| ProfileStore by loleris (MAD STUDIO) | player data saving | **No licence text in the file header; licence unconfirmed** | **Needs your decision**: check the repository's licence and add its notice | `Vendor/README.md` |
| Roblox animation method by fwjelaa (FWJ STUDIOS) | animation pipeline, example emote | Free to use in your own games | **Yes**: credit fwjelaa (FWJ STUDIOS) and link back to the source video | `Animation Kit/docs/CREDITS.md` |
| Hunyuan3D-2 shapes (Tencent) | 3D mesh shapes if used in the shipped game | Tencent licence; the project notes it does not apply in the EU, UK or South Korea | **Needs your decision** | `CLAUDE.md` |
| Tools: Blender, Moon Animator 2 (xSIXx), Blender MCP (Siddharth Ahuja), Roblox Studio | making things | tools, not shipped assets | Courtesy | `Animation Kit/docs/CREDITS.md` |

The first row's courtesy credit line is already written in `Audio/CREDITS.md` and is reused below.

## On-screen credits (draft text)
Shown after the ending (see [[Ending - The Clock Turns]]) and from Settings. Static text, scrollable; with reduced motion on there is no auto-scroll.

```
THE LANTERN KEEPERS            (working title)

Made by <your name>.
Written, designed and built with Claude.            (proposal; see note below)

MUSIC (CC0)
Gichco "Shinsei"; omfgdude "Chill lofi inspired"; RandomMind "Fantasy: Rising Moon";
Fupi "Artifact Room"; beardalaxy "Iremos Forest Theme Loop". Via OpenGameArt.org.

EFFECTS AND ICONS
VFX flipbooks by Unity Labs (CC0). Effect sheets from particlefx.studio.
Fantasy item icons by AnnoMotion (CC0). Pixel effects by CodeManu (CC0 / CC BY 4.0 where noted).
Open-source VFX reference: Yuruzuu.

TECHNOLOGY
ProfileStore by loleris (MAD STUDIO).
Animation method by fwjelaa (FWJ STUDIOS): <link to source video>.
Made with Roblox Studio, Blender and Moon Animator 2 by xSIXx.

THANK YOU
To everyone who tested, and to every keeper who lit a lamp.
```
The title line and the "Made by" lines are placeholders. Whether to name Claude, and where, is your decision; some players like to know how a game was made, and some platforms ask for disclosure of AI-made content, so check Roblox's current rules before publishing (I did not read them).

## Licence list screen (second page)
A plain list titled "Licences" with one line per entry above and the licence name (CC0 1.0, CC BY 4.0, Roblox open source terms), with a short note: "CC0 needs no credit; we credit anyway." A QR or URL line for the full list on the game page is optional.

## Rules for keeping it right
1. Every new third-party asset adds a row to this page, `VFX/ASSETS.md` or `Audio/CREDITS.md` the same day.
2. No asset enters the shipped game without a recorded licence (project rule).
3. Re-check CC BY items per effect before the first public release.
4. The credits text must fit 844 x 390 at 14 px minimum with no scrolling needed for the key lines ([[Accessibility guidelines for our game]]).

## Open questions for the user
1. Your name or studio line, the game title, and whether to name Claude.
2. Which particlefx.studio effects are used, so the CC BY ones are credited.
3. ProfileStore licence and notice (check the repository).
4. Whether Hunyuan3D shapes ship (Tencent terms; your location matters).
5. Yuruzuu: credit as a courtesy?

## Checks
`Overnight/evidence/T073_check.py` verifies that each source file named above exists, that the author names in the draft credit text appear in `Audio/CREDITS.md`, and that the fwjelaa credit line is present. Output in `Overnight/evidence/T073.txt`.
