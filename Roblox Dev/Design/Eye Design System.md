# Eye Design System (T111)

The eye shape reads the personality. Each familiar's eyes come from its three tone words (the voice line in `Lore/Familiars/<Name>.md`), written as parameters and drawn by `tools/eye_system.py` on a plain face disc in the identity colour. Sheets: `Assets/Characters/Eyes/_eye_sheet.png` (256 px) and `_eye_sheet_small.png` (48 px, the size on a card). Concept drawings: the real eyes are on the model textures, and only Ember, Frostling, Brass Hound and Gargoyle have drawn faces today (see [[Expressions]]). Look UNVERIFIED by the user.

## Rules
1. **Size reads age and openness:** large = young or earnest (Ember, Frostling, Moth-Lantern), small = old, far or guarded (Ward, Star Drake).
2. **Spacing reads trust:** wide = open and naive, close = loyal and focused.
3. **Lids read mood:** open = alert, heavy top lid = dreamy or weary, flat-bottom half lid = deadpan.
4. **Highlights read warmth:** one big highlight = eager, two = dreamy, none = guarded or mechanical.
5. **Shape reads species of mind:** round and oval = living and soft, almond = clever, slit and lens = mechanical, point and hollow = otherworldly, none = a mask.
6. **One look per familiar:** no two share more than six of the eight parameters, and no two look alike at 48 px.

| Familiar | Eyes | Why |
|---|---|---|
| [[Ember]] | round, large, gap wide, lid open, pupil dot, 1 highlight(s) | eager, earnest, small: large, round, wide-set, one highlight |
| [[MothLantern]] | round, large, gap normal, lid half-top, pupil high, 2 highlight(s), soft lashes | dreamy, drifting, kind: heavy top lid, pupils drifting up, two highlights |
| [[BrassHound]] | round, medium, gap close, lid open, pupil dot, 1 highlight(s), big shine | loyal, cheerful, literal: plain round eyes, close together, one big shine |
| [[Sentinel]] | slit, medium, gap normal, lid open, pupil none, 0 highlight(s), visor glow | stiff, polite, literal: two vertical visor slits, perfectly straight |
| [[Frostling]] | oval, large, gap wide, lid open, pupil dot, 1 highlight(s), pink cheeks | cheerful, blunt, childlike: tall ovals, wide apart, cheeks |
| [[Gargoyle]] | half, medium, gap normal, lid flat-bottom, pupil dot, 0 highlight(s), pale blue | gruff, deadpan, loyal: flat-bottom half lids, pale, no highlight |
| [[Ward]] | almond, small, gap normal, lid half-top, pupil dot, 1 highlight(s), crow's feet, one raised brow | patient, wry, weathered: narrow almonds, crow's feet, one raised brow |
| [[Archivist]] | lens, large, gap normal, lid open, pupil dot, 0 highlight(s), tick marks | precise, dry, tidy: concentric lens rings with tick marks |
| [[Mourner]] | none, none, gap none, lid veiled, pupil none, 0 highlight(s), veil seam, two lash marks | soft, formal, faceless: no eyes, a veil seam and two lash marks |
| [[MirrorChorister]] | almond, medium, gap normal, lid open, pupil dot, 1 highlight(s), mirror-white, shard highlight | sly, curious, kind: almonds tilted up, mirror white, a shard highlight |
| [[StarDrake]] | point, small, gap wide, lid open, pupil none, 0 highlight(s), halo | remote, grand, lonely: small distant star points with a halo |
| [[GreyVeilWraith]] | hollow, unequal, gap normal, lid open, pupil none, 0 highlight(s), two unequal pale voids | sparse, echoing, unmoored: two pale voids of unequal size |

Checks (`Overnight/evidence/T111.txt`): all 12 parameter sets differ in at least two parameters; every pair differs at 48 px (smallest mean difference 6.9 on a 0 to 255 scale, Gargoyle / MirrorChorister, limit 6); eyes visible at 48 px.
