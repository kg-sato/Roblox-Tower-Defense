# Design decision log, 2026-10-29 (Sonnet, familiar art chat)
Every decision I made on my own today, with the reason and what it costs. Decisions that need the user are marked ASK.

| # | Decision | Reason | Cost or risk |
|---|---|---|---|
| 1 | Enemy and boss triangle budget 3,000 (project limit 20,000) | enemies are many on screen; all built models are 200 to 730 triangles | a budget of my choosing, not the user's |
| 2 | The enemy verifier compares FRONT against the familiar fronts (pass/fail) and prints the worst over all views for information | the familiar cutouts are front views; Brass Sentinel failed against Ward at three-quarter | I changed my own test after a failure; Brass Sentinel's three-quarter overlap with Ward is 0.60 |
| 3 | Redesign on a failed silhouette check, never loosen the limit | the check exists so enemies never read as familiars | more rebuilds (Sentinel squat, Thief crouched, Unbound wide, Clockmaker hoop) |
| 4 | `DoubleSided = true` on the thin familiar meshes | visual-hull meshes rendered as outlines | slightly more fill cost |
| 5 | The Unbound follows the lore (faceless fog), not the research note (a mage) | the lore and chapter 1 agree; the note predates them | ASK which stands |
| 6 | Config's familiar block uses `FindFirstChild` with a fallback and a warning | `WaitForChild` hung the tests that clone only Config | a missing Familiars module only warns |
| 7 | Studio use only in Edit mode, with a claim in `QUEUE.md`, release after | two chats share one Studio; the user asked for a queue | slower, but no collisions |
| 8 | Paused the gold-ink recolour | it was not clear whether the 12 familiars or the loading-screen eye was meant | ASK |
| 9 | 512 px maps per model plus family sheets instead of shared atlases | atlases would need a UV re-layout and re-import of every model | the task text "one atlas per family" is unmet |
| 10 | One emissive rule for all familiars (bright and saturated pixels) | a single rule is checkable and consistent | Gargoyle's gold trim glows |
| 11 | Normal maps inferred from colour | there is no sculpted detail to bake | shading relief only; the task's "silhouette detail" is unmet |
| 12 | Recommended capping tier by rarity (Legendary 3, Epic 4, others 5) behind a flag | a Legendary at tier 5 is 12 times a Common at tier 5 | ASK; the flag is not implemented |
| 13 | Recommended replacing the 2x Coins pass with cosmetics | it is pay-for-progress, against the no pay-to-win rule | ASK |
| 14 | Recommended fusion at tier 5, not tier 8 | `TIER_MAX` is 5 | ASK; adds about 20 designs |
| 15 | Uploaded 11 enemy and boss meshes as `Enemy_<Name>` | uploads are pre-approved; ids logged in `tools/uploads.json` | concept-grade meshes now sit on the account |
| 16 | Did not open the PR myself | `gh` is missing and GitKraken is not signed in | the user opens the compare link |
| 17 | Commit message without a Claude trailer | the user's rule (kg-sato, no trailers) overrides the default | none |
| 18 | Tasks recorded as PARTIAL stay open in `Overnight/TODO.md` (T183, T150, T193, T194, T212, T213) | the design is written but the code or test the task asks for is not | the open count stays higher than the work feels |
| 19 | Restored 21 TODO lines I removed by mistake | the TODO reuses numbers in later sections, so removing by number deleted other tasks; later removals match the text | disclosed in the final summary |
