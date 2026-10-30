# t076 UI review (scores: a shape/layout, b texture, c colour/light, d readability, e polish)

## cap_hud_idle: FAIL
Scores: a5, b5, c6, d4, e4
1. Left rail (x0-130, y70-545): tiny labels (COINS, GEMS, SKILL TREE, PROGRESSION, SETTINGS) about 10px, thin serif on busy brick; unreadable on a phone. Icons are thin line art, inconsistent weights. Red "II" badge overlaps GEMS label.
2. Bottom bar (y680-760): ROLL, AUTO, QUICK, "20 gems" float with no panels or buttons; ROLL gem cost is cyan on dark purple, tiny; ODDS eye is a faint sliver. Looks like unstyled text, not tappable controls. BEGIN THE WAVE is a flat orange triangle plus plain text, with no button body.
3. Board (y170-630): huge dead black centre; HUD top (stage 3, "20 HP" with a bare blue dot) is wire-thin and nearly invisible. Floor and brick are noisy, and the stage ring is lost against the buildings. ULT dotted ring at the right is faint. "FAMILIARS" is a dim chip with no icon.

## cap_hud_wave: FAIL
Scores: a5, b5, c6, d3, e4
1. Enemies (x855-990, y155-205): three tiny dark blobs on dark cobble, low contrast; one lone tower (x745-800, y225-270) is also tiny. Gameplay is unreadable at this camera.
2. RUNNING state (x1365-1580, y715-740): grey text and hollow chevron look disabled, no progress or wave counter. ULT ring is the only strong cyan element, with no clear meaning.
3. Same left-rail and bottom-bar flaws as idle. The coin count changed, but nothing marks it as live. No enemy HP bars or wave number.

## cap_reveal: FAIL
Scores: a4, b4, c5, d5, e3
1. Centre card (x750-885, y115-585): a flat, dark, perspective-skewed rectangle with a cyan border and a blurry two-ring glyph. It looks like a placeholder, with no familiar, rarity or name.
2. Clock and plinth (x610-1055, y180-700): washed-out, translucent, low-res; the Roman numerals are ghosted and overlap the card. The base ring's glow is smeared.
3. Dim photographic skybox (Big Ben, moon) clashes with the 3D props. HUD is ghosted and the stage ring is faintly visible behind. The lone FAMILIARS chip is stray. Nothing says "reveal"; no text, no particles or rarity colour in this frame.

## cap_collection: FAIL
Scores: a6, b6, c6, d5, e5
1. Detail panel body (x1080-1370, y390-600): about 9px serif lore text in a dense block on dark gold. Unreadable on a phone. The big EMBER title bar is orange against the gold frame, which is loud.
2. Grid (x155-905): silhouettes are near-black on dark navy, so locked and unlocked read alike. Rarity labels (COMMON, RARE) are about 9px. Grid is cut off at the bottom with no fade. A big empty gap sits between grid and detail (x905-1040). Scrollbar is a thin grey line.
3. Modal collides with the HUD: the left rail icons and the bottom ROLL/AUTO bar show through and under the panel edge, and "4/20" floats centred with no styling. Tabs are flat, identical rectangles. "Details" button is dull olive-gold, low contrast.

Overall: layout skeleton is fine, but text is too small and thin for mobile, controls lack material and button bodies, and the reveal is placeholder quality. No screen reaches top-tier mobile polish.
