# Skill tree r3 review (harsh)

Scores /10: shape 5, icons 6, colour/lighting 7, tarot/arcane 7, readability 5, polish 4. Verdict: FAIL.

Bugs
- Storm node reads "5/4" (rank above max).
- Bottom-left button label is scrambled/illegible blocks; RESPEC text is smeared and changes weight between frames (faint in A, bold in B and hover).
- Tarot card labels clip/crowd ("THE FORTUNE", "THE STORM").
- Popup says "Rank 0/5" with "2 skill points" and "Click to kindle": ambiguous. It also covers the Eye branch.
- Card positions differ between captures (IV card y~446 hover/burst vs ~388 idle; cards 105 vs 112): layout shifts.
- Frame A vs B: only ambient motion (rays right, motes, node glow pulse). Unlock burst is small dots ring, weak.

Biggest issues
1. Layout is a radial wheel with six symmetric cards around a tree: reads as rings, not irregular S-curve web. Branches are thin, mostly straight, with stray jagged spurs.
2. State clarity: locked nodes near-black and barely visible; owned/available differ only by cream fill and glow; small outer nodes all look alike. Hub nodes cream blobs vs gold rings is inconsistent.
3. Text polish: garbled button, smudged RESPEC, tiny card captions, rank bugs.

Fixes
1. Redraw branches as long S-curves with varied lengths and offset node positions; drop the guide rings and tick marks.
2. Give locked nodes a visible dim-gold outline plus padlock-free desaturated icon; available gets a pulsing gold ring; owned gets a solid fill. Clamp ranks to max.
3. Fix button fonts and sizes, enlarge card captions, pin popup beside the node without covering neighbours, and freeze card layout between states.
