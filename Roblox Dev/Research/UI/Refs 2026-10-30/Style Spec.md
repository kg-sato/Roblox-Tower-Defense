# HUD style spec from the 7 pins (2026-10-30)

Images saved here (`ref1`..`ref7`). Pulled from the pin pages' og:image (same image the browser shows), not by driving the pane. Colours measured with PIL palette quantise (6 colours, 200 px thumbnail).

| # | Pin | Take-away | Measured |
|---|---|---|---|
| 1 | Steampunk options | Rope-twist rails, rivets, flat brass plaques for buttons, slim slider with orange fill, one lit lamp as accent. Small gauges, not big icons | dark `#242321`, brass `#726957` |
| 2 | Prince of Persia display | Calm parchment panel, small-caps serif headings, thin sliders with a pearl knob and small ornate end caps; radio = tiny ringed pearl | dark `#2a2621`, parchment `#aaa699`/`#eae9e3`, bronze `#8a7f6d` |
| 3 | Metal game border | Ring HUD: one circular rim with 4 to 6 small round buttons hugging it; thin gold line, no text labels, glyph icons | dark `#272422`, brass edge |
| 4 | Undead Gothic | Flat dark inset panels (`#110c09`) with thin bone-coloured frame and corner caps only; no glows | dark `#241911`, bone `#938168` |
| 5 | Hello Dave circles | Gold line art on near-black: ticks, tiny icons, one gold only; hairlines | bg `#141318`, gold `#c9a96a` (visual), `#6e624f` mid |
| 6 | Dark Romance Victorian | Dark wood bg, rose-pink ribbon header, gold hairline frames, roman numerals, seal for state, bottom tab bar of line icons with label under | bg `#251e19`, rose `#855e52`/`#a17c6a`, gold hairline |
| 7 | Visual novel menu | Thin violet lines, diamond buttons, short text labels, huge empty space | lines `#949199`/purple, bg `#010101` |

## Rules we take (apply to the whole HUD)
1. **Calm.** Dark flat panel (`#17120e` to `#241911`), 1 gold hairline frame, no constant glow, no pulsing except one claimable thing.
2. **One accent gold `#c9a96a`** for lines and numbers; **one alarm colour** (rose `#a8584a`) for badges. Currency numbers in warm white `#f0e6d0`.
3. **Small, labelled, line icons** (ref 5, 6 tab bar): icon above a short label at the bottom of a plaque. No emoji-looking blobs.
4. **Fonts:** serif small-caps for headings (Fondamento/Cinzel-like), a clean body face (Titillium Web) for numbers and labels. No Grenze Gotisch on HUD text.
5. **Layout:** top-left = currencies in one slim bar (no overlap); top-centre = slim stage/HP strip; left = one vertical plaque with icon+label buttons; bottom-centre = roll plaque; menu = a single button at top-right area, never mid-screen.
6. **State by shape not glow:** claimable = small rose dot; locked = 40 percent alpha.
7. **Sliders** (settings): thin dark track, gold fill, round pearl knob (ref 2).
