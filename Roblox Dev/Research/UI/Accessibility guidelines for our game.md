# Accessibility: colour, motion, text (T024)

Question: what do the Game Accessibility Guidelines say about colour-blind palettes, reduced motion and text size, and how does that map to our settings and UI?

## Facts (sourced)
Source for all guideline items: [Game Accessibility Guidelines, full list](https://gameaccessibilityguidelines.com/full-list/) and [Basic tier](https://gameaccessibilityguidelines.com/basic/) (both fetched 2026-10-28). The site is a collaborative project of studios, specialists and academics, active since 2012; it states no last-updated date. [Home page](https://gameaccessibilityguidelines.com/) (fetched 2026-10-28). The site gives no numeric thresholds (no pixel sizes, contrast ratios or flash rates).
- **Colour (Vision, Basic):** do not convey essential information by a fixed colour alone. There is no dedicated colour-blind mode guideline. Intermediate adds selectable text colours with low and high contrast options.
- **Text (Basic):** use an easily readable default font size; (Advanced) let players adjust font size.
- **Contrast (Basic):** high contrast between text/UI and background; (Intermediate) an option to adjust contrast.
- **Motion:** (Basic) avoid flickering images and repetitive patterns; (Intermediate) a setting to turn off or hide background movement; (Advanced) avoid sudden, unexpected movement. Screen shake is not mentioned directly.
- **UI size (Motor and Vision):** (Basic) large, well-spaced interactive elements, especially on touch screens; (Intermediate) resizable and rearrangeable interfaces.
- **Cognitive (Basic):** interactive tutorials; move through text prompts at your own pace. (Intermediate) contextual help and a practice mode. (Advanced, Motor) do not make precise timing essential.
- **Subtitles (Basic):** subtitles for important speech, easy to read.
- Colour vision: about 8% of males and 0.5% of females of Northern European descent have red-green colour blindness. Protan types dim reds. Advice: do not use colour alone (add shape, size, pattern, labels), use brightness contrast as well as hue, test with a simulator at least for deuteranopia, avoid red-green pairs as the only signal. [Wikipedia, Color blindness](https://en.wikipedia.org/wiki/Color_blindness) (fetched 2026-10-28; first 100,000 of 215,697 characters). It does not name the Okabe-Ito palette.

## Not found
- Numeric flash limits, contrast ratios and text sizes: none in the sources read. The 4.5:1 body-text contrast in the task list (T101) and the 14 px minimum (T082, T235) come from elsewhere (the WCAG standard and project choice), not from this site; confirm against WCAG if it matters.

## Match against what the project already has
- The settings panel already covers reduced motion, flashes, shake and UI size (run log T005, T006, T117, 2026-10-27/28). Gaps against the guidelines: text size adjustment as its own option (Advanced tier), contrast adjustment (Intermediate), and a check that no meaning rides on colour alone (rarity, faction, status icons).

## Recommendations (not sourced rules)
1. Pair every rarity and faction colour with a shape or icon (alchemical glyphs, [[Occult and alchemy symbol language]]).
2. Add a font size option and a high-contrast text option to Settings (T075, T082, T083).
3. Keep the flash reduction toggle; add no strobing at all, since no numeric limit is given here.
4. Run the colour-blind test for the 12 familiars and the status icons (T088, T139).
5. Add a pause with no precision timing needed for the tutorial (T006, T203).

## Sources and dates
| # | Source | Date | Note |
|---|---|---|---|
| 1 | https://gameaccessibilityguidelines.com/full-list/ | fetched 2026-10-28 | read |
| 2 | https://gameaccessibilityguidelines.com/basic/ | fetched 2026-10-28 | read |
| 3 | https://gameaccessibilityguidelines.com/ | fetched 2026-10-28; project since 2012 | read |
| 4 | https://en.wikipedia.org/wiki/Color_blindness | fetched 2026-10-28 | partly read |
| 5 | https://www.w3.org/WAI/WCAG21/quickref/ | not visited | for numeric contrast, check before use |
