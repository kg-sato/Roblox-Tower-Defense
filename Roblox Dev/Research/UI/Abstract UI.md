---
date: 2026-10-28
tags: [ui, research, abstract, art-direction]
---
# Abstract UI

User request (2026-10-28): "fix the UI, research more on abstract works and how to make it abstract". Direction chosen by the user: **Blend**. Keep the brass and tarot objects from [[Research/UI/Creative Fix Method]], and make everything around them abstract. Built in `Studio_Export/AbstractLayer.luau`. The art is `UI Kit/art/abstract_shapes.py`.

## What the research says
| Source | Idea we took | Evidence |
|---|---|---|
| Hilma af Klint, temple paintings (1906 on) | A personal symbol system: spirals = evolution, circles = completion, two overlapping circles (vesica piscis) = growth toward unity, blue/yellow with green as their union. Abstract shapes that still *mean* something mystic fit our fortune-teller theme. | [Royal Academy](https://royalacademy.org.uk/article/hilma-af-klint), [AnOther](https://anothermag.com/art-photography/8490/decoding-the-spiritual-symbolism-of-artist-hilma-af-klint), [The Art Story](https://theartstory.org/amp/artist/af-klint-hilma/) |
| Kandinsky, *Point and Line to Plane* (Bauhaus Book 9, 1926) | Point, line and plane are the basic elements. A shape placed off-centre creates "tension". A triangle reads hot and sharp, a circle reads calm. Primary colours plus black, white and grey. | [Internet Archive (full text)](https://ia800506.us.archive.org/16/items/pointlinetoplane00kand/pointlinetoplane00kand.pdf), [Getty: Bauhaus primary forms](https://www.getty.edu/research/exhibitions_events/exhibitions/bauhaus/new_artist/form_color/form/) |
| Bauhaus graphic design | Few shapes, few colours, an asymmetric grid, no ornament. | [Univ. of Tehran study](https://jfava.ut.ac.ir/article_73197.html?lang=en), [Design Shack](https://designshack.net/articles/trends/bauhaus-graphic-design/) |
| Mini Metro, Monument Valley, GRIS | Flat colour fields, restricted palettes, lots of empty space, side information pushed to the edges and grouped. | [GDC: Mini Metro, When Less Is More](https://gdcvault.com/play/1024250/-Mini-Metro-When-Less), [Mechanics of Magic: Mini Metro](https://mechanicsofmagic.com/2023/04/22/visual-design-of-games-mini-metro/) |
| Persona 5 / Metaphor: ReFantazio | One black base with one strong accent; asymmetric, angular, emotional menus. **Warnings**: some players find P5 hard to read, and some complain that everything in Metaphor moves and blinks. So keep text plain and let only a few things move. | [Mechanics of Magic: P5](https://mechanicsofmagic.com/?p=7280), [Source Gaming: Sakurai column](https://sourcegaming.info/2016/11/24/the-aims-of-ui-sakurais-famitsu-column-vol-515/), [Push Square: Metaphor menus](https://www.pushsquare.com/news/2024/10/making-metaphor-refantazio-personas-immaculate-menus-is-really-annoying-says-director) |

Caveat: the af Klint symbol meanings come from curators' readings of her notebooks, and the Kandinsky summaries come from secondary sources. Use them as inspiration, not as rules.

## Our rules (how to make a screen abstract)
1. **One big calm shape per screen**, behind the main action (ROLL gets the violet disc). Everything else stays small.
2. **Shape = meaning**: circle/orbit = the cosmic and the lasting (ROLL, ULT); triangle = go, heat, action (START WAVE); line + points = things that belong together (AUTO and QUICK, the left column); vesica/eye = the seer, odds, fate.
3. **Palette**: ink base `14,9,26`, one violet field `96,56,190`, one amber accent `255,176,70`, gold lines `255,214,130`, cyan only for ULT/crystal. No new colours.
4. **Flat fields instead of boxes**: gradients only to fade a field out, never as decoration.
5. **Off-centre tension**: shapes are offset from the control they serve (the disc sits left of ROLL's text; the triangle rises left of START WAVE).
6. **Motion budget**: at most two slow rotations on screen (90 s and 70 s per turn), and none with Reduced Motion.
7. **Text stays plain and readable**: no abstract shape ever sits on top of text.

## What was built
| Before | After |
|---|---|
| Mahogany desk slab across the whole bottom | Ink field fading up into the board, gold horizon line |
| ROLL on the desk | Violet disc + turning amber orbits + faint rays (the one big shape) |
| AUTO / QUICK floating | Hung on one gold line with points at the ends |
| START WAVE on the desk | Amber triangle rising behind the bell |
| ULT watch overlapping the desk | Cyan orbits turning behind the watch |
| ODDS plain purple ball | The seer's eye |
| Coin / gem boxed brass plates | Flat ink bands with a coloured point behind each icon |
| Left column of separate parts | Gold spine with a point at each item over a violet corner field |
| Stage sign | Faint vesica behind it |

Images: ![[Creative Fixes/abstract_before.png]] ![[Creative Fixes/abstract_after.png]] Shapes: ![[Creative Fixes/abstract_shapes.png]]

Asset ids (in `UI Kit/art/ids.json`): abs_vesica 140628629392455, abs_spiral 128142388272489 (not used yet), abs_orbits 133077605323965, abs_eye 137981105271928, abs_rays 106824495648529.

## Panels (built 2026-10-28, second session)
Each panel gets one big shape under its glass that spills past one edge, plus the same gold edge line with two points on its left:
| Panel | Shape | Why |
|---|---|---|
| Trainer Progression | af Klint spiral, violet | growth / evolution |
| Roll Odds | vesica, amber | fate, where two chances meet |
| Settings | orbits, cyan | the mechanism |
| Familiar ledger | violet disc | the calm "this one" shape |
Fixed on the way: closing Settings used to bring the old desk back, and the roll-bar shapes stayed on screen while Settings hid the roll bar. Only panel-sized frames are decorated (the Dock's captions also say PROGRESSION and SETTINGS). Images: `Creative Fixes/panels_abstract_before.jpg`, `panel_*_abstract_after.png`.

## Progression road as a constellation (built 2026-10-28)
The level cards lost their boxes. The road line now runs through one point per level: claimed = filled green point, next = gold ring with an amber orbit and a small moon, locked = faint ring. Rewards float underneath. The line is gold up to your level (the existing fill). It keeps working because it follows the colours `updateProgress` already sets. Image: `Creative Fixes/prog_constellation_after.png`.

## Start menu (built 2026-10-28)
The featured familiar gets the one big calm shape: a violet disc with amber orbits turning slowly, centred on the familiar's body so the orbit's centre point hides behind it, and faint rays behind. A faint vesica sits behind the title. A gold spine with points at the crown, the rule, the lamp button and the flashes plate ties the left column together. First pass fixed: the orbit's centre dot sat on the familiar's platform, the rays crowded its name, and the vesica rings cut through the title. Images: `Creative Fixes/start_abstract_before.png`, `start_abstract_after.png`.

## Next ideas (not built)
The skill tree (first-person grove) and the reveal could use the vesica as a frame; the reveal still uses plain frames.
