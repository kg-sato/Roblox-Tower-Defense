# Skill tree UX in Path of Exile, Diablo and Last Epoch (T018)

Question: what reads at a glance in these skill trees, and what should our 40-node lantern tree take?

**Gap against the task:** only Path of Exile has a read source with structure facts. The Last Epoch Wikipedia page has no skill-system content, and the Icy Veins pages (Diablo 4 readability) returned 403, so Diablo and Last Epoch claims below are search-summary level.

## Facts (sourced)
- Path of Exile: one shared pool of 2,268 passive skills; each class starts at a different point; three attribute trunks (Strength, Dexterity, Intelligence) with the Scion aligned with all three; separate small trees for each Ascendancy class (up to 8 points spent). History: reworked tree in 1.2 (20 Aug 2014), jewel sockets in 2.0 (10 Jul 2015), Ascendancy in 2.2 (4 Mar 2016), major rework with Passive Skill Masteries in 3.16 (22 Oct 2021). [Wikipedia, Path of Exile](https://en.wikipedia.org/wiki/Path_of_Exile) (fetched 2026-10-28). The page does not describe node types (small, notable, keystone).
- Last Epoch released 21 Feb 2024 (Standard, Deluxe, Ultimate editions); 2,135,257 copies sold and a Steam peak of 264,708 concurrent users as of 22 Mar 2024. [Wikipedia, Last Epoch](https://en.wikipedia.org/wiki/Last_Epoch) (fetched 2026-10-28). No skill system content.
- Diablo 4: search summaries say Blizzard acknowledged players found the skill tree hard to read and promised more UI work, and that a forum post credits the move from a literal tree to icons and lines as easier to read. [Icy Veins, Official response](https://www.icy-veins.com/forums/topic/52508-official-response-to-feedback-regarding-the-diablo-4-skill-tree/) (403; snippet only, undated). Unverified.
- The same search snippets say fans want build-altering choices like Last Epoch's skill specialisation, and Paragon boards are criticised as less interesting than Path of Exile's tree. [Icy Veins, Paragon problem](https://www.icy-veins.com/d4/news/why-paragon-may-be-a-bigger-problem-than-diablo-4s-skill-tree/) (403; snippet only). Fan opinion.
- Path of Exile's tree is called overwhelming by some players, which is why planner tools exist (e.g. [PoESkillTree on GitHub](https://github.com/yazilliclick/PoESkillTree), snippet only).

## Not found
- No formal UX analysis of what reads at a glance, no node-type breakdown, and no Last Epoch tree details. The glance-readability points below are my reasoning from the facts above.

## Takeaways for us (recommendations, not sourced)
1. Start each class (or lane) at its own point on a shared board, as Path of Exile does; our lanes can map to factions (T053).
2. Three node sizes (small, notable, keystone) is the common genre pattern, but is not confirmed by the sources read; confirm before copying. Our 40 nodes (T197) do not need three sizes; two may do.
3. Reduce reading load: icon plus line layout with short text (Blizzard's stated direction), tooltips on hold (T085).
4. Avoid thousand-node scale; Path of Exile's size creates the need for planners. A 40-node tree needs none.
5. Add the "next best" hint (T199) so beginners are never stuck.
6. Check the existing menu-tree-rework task before editing: those files belong to another session (see run log 2026-10-28 T106).

## Sources and dates
| # | Source | Date | Note |
|---|---|---|---|
| 1 | https://en.wikipedia.org/wiki/Path_of_Exile | fetched 2026-10-28; patches 2014 to 2022 | read |
| 2 | https://en.wikipedia.org/wiki/Last_Epoch | fetched 2026-10-28; 2024 | read, no tree content |
| 3 | https://www.icy-veins.com/forums/topic/52508-official-response-to-feedback-regarding-the-diablo-4-skill-tree/ | undated | 403; snippet |
| 4 | https://www.icy-veins.com/d4/news/why-paragon-may-be-a-bigger-problem-than-diablo-4s-skill-tree/ | undated | 403; snippet |
| 5 | https://github.com/yazilliclick/PoESkillTree | undated | snippet |

Caveat: weak on Diablo and Last Epoch; no screenshots analysed.
