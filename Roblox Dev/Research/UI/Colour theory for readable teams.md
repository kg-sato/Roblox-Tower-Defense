# Colour theory for readable teams: ten hues, colour-blind safe (T030)

Question: can we get ten distinct team or element colours that stay readable for colour-blind players?

## Facts (sourced)
- The Okabe and Ito palette (Masataka Okabe, Jikei Medical School; Kei Ito, University of Tokyo; both protanopes) names vermilion as the red (protanopes still recognise it), bluish green instead of plain green, reddish purple instead of violet (violet looks like blue), sky blue and blue (separated by brightness and saturation), yellow and orange. Guidance: add shape differences, label directly, use thicker lines and bigger symbols, use brightness and saturation contrast, alternate warm and cool colours. [Okabe and Ito, Color Universal Design](https://jfly.uni-koeln.de/color/) (fetched 2026-10-28; the exact hex values live in an image on the page).
- The eight-colour set popularised by Wong in Nature Methods 8(6), 441 (2011, doi 10.1038/nmeth.1618) is: #E69F00 orange, #56B4E9 sky blue, #009E73 bluish green, #F0E442 yellow, #0072B2 blue, #D55E00 vermilion, #CC79A7 reddish purple, #000000 black. These hex codes come from a search summary of third-party pages (ConceptViz and a package doc), not the paper; check the paper before citing. [ConceptViz, Okabe-Ito hex codes](https://conceptviz.app/blog/okabe-ito-palette-hex-codes-complete-reference) (snippet only).
- About 8% of males and 0.5% of females of Northern European descent have red-green colour blindness; design advice is shape plus colour, brightness contrast, and testing with a simulator at least for deuteranopia. [Wikipedia, Color blindness](https://en.wikipedia.org/wiki/Color_blindness) (fetched 2026-10-28).

## Check I ran (machine check)
Script: `Overnight/evidence/T030_cvd.py`. It simulates protanopia, deuteranopia and tritanopia on linear RGB with Machado-style 3x3 matrices that I wrote from memory (unverified against the paper) and reports the smallest CIE76 colour distance (delta E) between any two colours in a set. Results (smallest three pairs per set; a delta E near 10 or below is hard to tell apart in small areas, my rule of thumb, not a standard):
- Seven Okabe-Ito hues alone: smallest pairs about 26 (sky blue and blue, normal vision), 17 (orange and yellow, deutan), 16 (sky blue and green, tritan).
- Adding light grey #7F7F7F, near-white #F2F2F2 and near-black #1A1A1A as hues 8 to 10: normal vision stays at 26, but deuteranopia drops to 9.7 (bluish green vs grey) and 12.1 (reddish purple vs grey), protanopia to 17.9.
- So seven hues are safe-ish by hue; reaching ten by adding neutrals breaks for deuteranopes unless a second cue (shape, glyph, pattern) is added.

## Not found
- No source gave a rule for exactly ten team colours, and I did not verify the simulation matrices. Treat the numbers as indicative.

## Recommendation (not a sourced rule)
1. Use the seven Okabe-Ito hues for the seven most important categories (for example element or faction colours) and give every category a glyph (alchemical symbol, [[Occult and alchemy symbol language]]) so colour is never the only cue.
2. For ten categories, add three by shape and lightness, not by more hues: the same hue at light and dark values plus distinct badge shapes. Re-run the script with the real colours and fix any pair under about 15 for any simulation.
3. Keep rarity on shape and border style as well as colour (T088, T099).
4. Do not use pure #FF0000 for enemy marks; use vermilion (#D55E00 family) as Okabe and Ito advise.
5. Add a colour-blind check to the automated tests (T233 family) using the script as a starting point.

## Sources
| # | Source | Date | Note |
|---|---|---|---|
| 1 | https://jfly.uni-koeln.de/color/ | fetched 2026-10-28 | read; undated |
| 2 | https://conceptviz.app/blog/okabe-ito-palette-hex-codes-complete-reference | undated | snippet; hex codes |
| 3 | https://en.wikipedia.org/wiki/Color_blindness | fetched 2026-10-28 | partly read |
| 4 | https://doi.org/10.1038/nmeth.1618 | 2011 | not visited |
| 5 | Overnight/evidence/T030_cvd.py | 2026-10-28 | my script, rerunnable |
