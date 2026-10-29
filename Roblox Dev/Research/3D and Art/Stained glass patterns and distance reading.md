# Stained glass patterns and how they read at a distance (T048)

Question: what makes a stained glass window pattern, and how does it read from far away, for the Silent Cathedral set and glass UI?

**Gap against the task:** the sources read describe construction, palette and rose window structure but say nothing about how designs read at a distance. The distance rules below are my recommendations.

## Facts (sourced)
**Construction and palette** ([Wikipedia, Stained glass](https://en.wikipedia.org/wiki/Stained_glass), fetched 2026-10-28; first 100,000 of 277,592 characters)
- A full-size cartoon is divided into templates; glass pieces are set into H-shaped lead cames, soldered and sealed; larger windows need iron or steel supports. Black linear detail is grisaille paint fired onto the glass.
- Medieval palette: cobalt gave the deep blues of Chartres; gold gave ruby and violet but gold-red was too dark at full thickness, so it was usually flashed onto clear glass; other colours were green, amber and purple-brown.
- Windows were meant less to admit light than to control it, and are often described as illuminated wall decorations. Narrative windows use panels with borders, canopies and floral motifs. Dates: Monkwearmouth glazing recorded from 675; York Minster Tree of Jesse about 1170; silver stain after about 1300.

**Rose windows** ([Wikipedia, Rose window](https://en.wikipedia.org/wiki/Rose_window), fetched 2026-10-28)
- Radial structure: stone mullions and tracery divide the circle into segments around a central roundel; wheel windows have spokes from a central boss; rose windows suggest a multi-petalled flower. Most are symmetrical about a centre; late Flamboyant ones may not be (Lincoln's Bishop's Eye).
- Medieval glass was dark and richly coloured, with blue and red the most common pair; later work used lighter yellows and greens. Notre-Dame's façade rose (completed about 1255) is nearly 33 feet across with two bands of mullions from a central roundel; Chartres' west rose (late 12th century) has a central roundel, spokes and a ring of small lights. Roses sit high on the façade as the focal point.

## Not found
- How patterns read at a distance, contrast values, or minimum pane size. No source on game-scale use.

## Recommendations for the Cathedral set and glass UI (not sourced)
1. Read-at-distance rule of thumb: keep three to five large colour fields separated by dark leading lines (the lead cames act as outlines), and avoid fine detail inside any one pane; test the window by shrinking the render to 64 px (as with the familiar silhouette test).
2. Use blue and red as the dominant pair with yellow or green accents (the medieval pairing above), and make the lead lines the darkest value so shape survives when colour is lost.
3. Radial design for hero windows (rose) with one central roundel carrying the focal symbol (a lantern, an eye, a star), and tall lancets for side walls (T105).
4. Give the board-camera view a light shaft or coloured glow rather than a detailed window, since the board camera sits far away (T162 landmarks, T105 earlier visibility fix).
5. For UI frames, use the same leading-and-panels logic: dark outlines around coloured panels reads as stained glass without extra ornament; combine with Art Nouveau curves from [[Art Nouveau ornament references]] only for late sets.
6. Check contrast and colour-blind safety on the final palette (accessibility note).

## Sources
| # | Source | Date | Note |
|---|---|---|---|
| 1 | https://en.wikipedia.org/wiki/Stained_glass | fetched 2026-10-28 | partly read |
| 2 | https://en.wikipedia.org/wiki/Rose_window | fetched 2026-10-28 | mostly read |
| 3 | https://en.wikipedia.org/wiki/Chartres_Cathedral | not visited | for window layout |
| 4 | https://en.wikipedia.org/wiki/Tiffany_glass | see [[Art Nouveau ornament references]] | later glass techniques |
| 5 | https://www.metmuseum.org/ | not visited | possible primary museum source |
