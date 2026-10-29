# Balatro UI: readable card rarity and the joy of scoring (T040)

Question: how does Balatro make scoring feel good and cards readable, and what should our merge and damage feedback take?

All pages fetched 2026-10-28. The most detailed timing source is a third-party guide whose numbers are illustrative, not from the game.

## Facts (sourced)
- Balatro: solo developer LocalThunk (Saskatchewan), published by Playstack; released 20 Feb 2024 on Windows, Switch, PS4/5, Xbox; mobile on 26 Sep 2024. A hand's base value becomes Chips, multiplied by Mult, which grows with cards, hands and Jokers. Praised for "retro VCR-style visuals" and lo-fi music; IGN called it "ludicrously fun". Rarity tiers and UI feedback are not in the article. [Wikipedia, Balatro](https://en.wikipedia.org/wiki/Balatro) (first 100,000 of 137,313 characters).
- Scoring is staged: the chip total rises one card at a time so each contribution is visible; each Joker announces its effect with a distinct sound; the multiplier display visually intensifies as it grows; the final score bursts onto the screen; good feedback responds within a fraction of a second; escalating and varying effects works better than repeating one (the article cites reward prediction error research); screen shake, hit-stop and rising pitch add weight. [PlayStation Universe, "Why winning feels so good"](https://www.psu.com/news/why-winning-feels-so-good-reward-design-from-arcades-to-balatro/) (9 Sep 2026; by Charles Monrose).
- A design guide by Blake Crosley (undated; copyright 2026) describes five feedback layers (card animation, counter, screen effects, particles, audio) and a three-step scored hand (base hand, each Joker left to right, final total). Its timings: score digits roll in 0.4 s staggered by 50 ms; Joker sequence about 300 ms; cards rotate about plus or minus 3 degrees; shake levels 0.2, 0.3 and 0.5 s for scores under 1,000, over 1,000 and over 10,000; each scored card plays a rising note (C to G across five cards); thresholds trigger a bass drop and flash. Colour system: blue chips, red mult, gold money, green hands remaining, purple planet cards. The guide states these in its own illustrative code, not as the game's confirmed values, and does not discuss rarity tiers. [Blake Crosley, Balatro guide](https://blakecrosley.com/guides/design/balatro)

## Not found
- Rarity presentation (Joker rarity colours or frames), any LocalThunk statement on feedback, and confirmed in-game timings.

## Recommendations for our feedback (not sourced rules)
1. Stage damage and merge results in steps: each contributor to a number appears in order (base damage, buffs, crit), with a rising note per step, in line with the Balatro pattern (T135 merge effect, T140 hit-stop and shake, T192 count-up).
2. Use the guide's numbers only as starting points to tune by feel: digit roll 0.4 s, staggered 50 ms, shake 0.2 to 0.5 s by magnitude. They match our "never longer than 0.6 s" count-up rule.
3. One colour per value type in the HUD (damage, gold, lives), as the colour system above does, and keep it colour-blind safe with icons.
4. Let shake and sound scale with magnitude, and turn them off under reduced motion (T189 task, accessibility note).
5. Rarity readability is not answered here; use the frame hierarchy work in [[Clash Royale card art and frame hierarchy]] and the alchemical ladder.

## Sources
| # | Source | Date | Note |
|---|---|---|---|
| 1 | https://en.wikipedia.org/wiki/Balatro | fetched 2026-10-28; 2024 to 2026 | read |
| 2 | https://www.psu.com/news/why-winning-feels-so-good-reward-design-from-arcades-to-balatro/ | 9 Sep 2026 | read |
| 3 | https://blakecrosley.com/guides/design/balatro | undated (2026 footer) | read; author's illustrative values |
| 4 | https://anais-siiepe.ufpel.edu.br/2025/LA_04940.pdf | 2025 (URL) | study of reviews; unread |
| 5 | https://www.itmedia.co.jp/news/article/2403/21/1240321115/ | Mar 2024 (URL) | listing only |
