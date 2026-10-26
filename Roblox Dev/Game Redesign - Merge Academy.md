# Game Redesign: Merge Academy (proposal, 2026-10-25)

Status: **brainstorm and prototype logic only. Nothing in `GameClient` or the match scripts was changed.** Requested by the user as an early idea ("characters like 2048, gacha affects something else, very light difficulty for low attention spans, unique characters, change direction if it would be more successful"). Related: [[Game Design Doc]] (current v2.3), [[Research/Mid-Size Game Patterns|Mid-Size Game Patterns]], [[Research/Magical Roll Animation Playbook|Magical Roll Animation Playbook]], [[Research/VFX Verification Report|VFX Verification Report]], [[Systems]]. Code: `VFX/MergeCore.luau`, `VFX/Roster.luau`. Audio: `Audio/CREDITS.md`.

## 1. Short answer
Keep the tower-defense frame (the data favours it), but **change what a character is**: instead of seven pet species with tiers that need three matching, there is **one chain of eight characters, and two identical ones merge into the next character**, exactly like 2048. The gacha stops handing out characters and instead hands out **Relics (passive board perks) and Skins (looks)**, so rolling never makes the board harder to understand and merging stays the whole point. Difficulty is light on purpose: you cannot lose a run, idle play still progresses, and the time per tier is roughly flat instead of doubling.

I changed three things from the brief and want you to know which: (1) I **kept combat** rather than going to a pure puzzle, because the one dataset we have says tower defense is strong and says nothing about pure merge puzzles; (2) I made merging **drag-and-drop pairs with an assist button** instead of 2048's swipe (swipe is harder for a short attention span and fights touch camera controls); (3) I added a **"Hearth"** that auto-merges and banks surplus so the board can never dead-end.

## 2. Directions considered
| Option | What it is | For | Against |
|---|---|---|---|
| A. Keep today's design | Merge three touching pets, seven species, 5 tiers, gacha gives pets | Already built and playtested four times | The merge rule is the hardest part to teach (triples + touching + 7 species make triples rare, noted as an open risk in the GDD); 7 x 5 looks to make |
| B. Pure 2048-style puzzle | Merge board is the whole game | Fastest feedback, trivial to learn | **No data in our research for this genre on Roblox**; weak reason to come back; combat and bosses we built go unused |
| **C. Merge Defenders (recommended)** | The 2048 chain from this note, characters defend the crystal automatically | Tower defense is the best-rated genre in our snapshot (4 games, about 18K players, 96% median rating); automatic combat suits low attention; cuts the art list from about 35 looks to 8; keeps ProfileStore, UI Kit, VFX and bosses | Needs a rewrite of the merge and roll code; balance of combat on top of merging is untested |
| D. Merge + idle collection | Same chain, passive stardust, no combat | Matches the "+1 Evolution" clicker family (7 games, about 13.5K) | Less spectacle for the Sols-style effects we invested in; weaker boss and Ultimate moments |

My recommendation is C, and the fallback is D (C without the combat layer) if combat turns out too heavy for the one-month plan. The market numbers come from one snapshot taken during Halloween events (see the limits in [[Research/Mid-Size Game Patterns|Mid-Size Game Patterns]]); I have no retention data for any option.

## 3. The core loop (for a short attention span)
- **3 seconds:** tap **Summon**, a character pops onto the board.
- **10 seconds:** drag one onto an identical one (or tap **Merge!**): they become the next character, with a sound that gets bigger every tier.
- **1 minute:** a new tier; its first appearance gives a **Wish ticket** and a small reveal.
- **3 minutes:** the first **Dawn Archmage**; two top characters **Ascend** together (big effect), the rank goes up and the chain gets a little easier to climb.
- **Every day:** one free Wish, a short daily goal.
Meanwhile the characters on the board fight waves on their own. You never have to watch.

## 4. Merge rules (implemented and tested in `MergeCore`)
- Board 5 x 4. A **Summon** costs one of up to 5 stored charges (one comes back every 2.5 s).
- Any two **identical** characters merge, anywhere on the board (no adjacency rule): drop one on the other, or press **Merge!** (merges the lowest pair).
- **Echo:** merging a tier 2 or higher pair has a 35% chance to refund a tier-1 character. **Surge:** an 8% chance to jump two tiers.
- **Catch-up:** new characters start at (best tier reached - 4), so late tiers do not take twice as long as the one before.
- **Hearth:** every 8 s one free automatic merge if a pair exists (the low-attention safety net). If the board is full, the lowest character turns into stardust instead of blocking you.
- **Top tier:** two Dawn Archmages **Ascend** together (both leave, large reward, rank +1).
- Nothing can be lost by a mistake. A failed merge only plays a soft "no" sound.

## 5. Difficulty: measured, not guessed
Simulated players (200 games each, 10 simulated minutes), `MergeCore.simulate`:
| Player | Acts every | Uses Merge! | Time to tier 4 / 5 / 6 / 7 / 8 | Share reaching tier 8 |
|---|---|---|---|---|
| Focused | 1.2 s | 95% | 14 / 26 / 50 / 74 / 100 s | 100% |
| Casual | 1.8 s | 60% | 21 / 40 / 72 / 114 / 161 s | 100% |
| Low attention | 3.5 s | 30% | 44 / 90 / 213 / 337 / 399 s | 21% in 10 min (89% reach tier 6) |
Before the catch-up and Hearth levers the same bots needed 14 / 29 / 56 / 110 / 206 s (focused: time doubling each tier) and the low-attention bot reached tier 5 in only 26% of games with 56 board overflows per game. After: time per tier is about +24 s per tier for the focused player (flat), and the low-attention player reaches tier 5 every time. **What this does not tell us:** how it feels, and whether it is *too* easy (a focused player finishes the chain in under two minutes). The first Ascension is meant to come fast; the long game is rank, Relics, skins and the combat difficulty, which are not built.

## 6. The eight characters (all original; humanoid or magical)
Each has one visual hook, one voice (the note its merge sound is built on), one catchphrase and one idle gesture. No stats or lore to learn: power comes from the tier. Data and test: `VFX/Roster.luau`.
| Tier | Character | Kind | Hook | Voice | Line |
|---|---|---|---|---|---|
| 1 | **Pip**, Ember Wisp | magical | living flame, tiny face, spark on its head | C5 | "Hi! Hi! Hi!" |
| 2 | **Moss**, Leaf Pixie | magical | leaf wings, red mushroom-cap hat | D5 | "Shh, the flowers are sleeping." |
| 3 | **Lumo**, Lantern Imp | magical | little horns, a lantern that brightens when he is happy | E5 | "Oops. Was that mine?" |
| 4 | **Rook**, Apprentice | humanoid | hat three sizes too big, huge spellbook | G5 | "Page forty... I think!" |
| 5 | **Vesper**, Storm Witch | humanoid | lightning streak on her hat, staff with a tiny thundercloud | A5 | "Let it rain." |
| 6 | **Sir Aurel**, Star Knight | humanoid | white and gold armour, star shield, plume | C6 | "For the little lights." |
| 7 | **Mirelle**, Moon Sage | humanoid | silver beard, crescent staff, owl called Tock | D6 | "Patience. The moon is never late." |
| 8 | **Solenne**, Dawn Archmage | humanoid | floating golden halo, rose-gold robes, sun on her back | E6 | "Every night ends." |
They read as one story (a spark that grows up into the dawn), which makes the merge feel like growing up, not like numbers going up. Portraits: `Assets/Characters/` (generated locally, see section 11).

## 7. What the gacha affects: Wishes give Relics and Skins
- **Currency:** Wish tickets, **free currency only** (milestones, daily, Ascension, stardust shop). No paid random items, so no odds duty from the Roblox rules we researched, but the odds are shown anyway ([[Research/Competitors and Policy|Competitors and Policy]]).
- **Relics** change how the board behaves, never which characters exist. First eight: Lucky Clover (Common: more chance to start a tier higher), Echo Charm (Common: +10% echo), Hearth Stone (Rare: auto-merge every 6 s), Surge Feather (Rare: +4% surge), Deep Pockets (Rare: +2 stored charges), Stardust Magnet (Epic: +25% stardust), Wishing Well (Epic: an extra free Wish a day), **Dawn Crest** (Legendary: each Ascension calls the **Dawnbreaker** sword from the Ultimate effect and banks every character below tier 4 into stardust).
- **Skins** (later): other looks for the same eight characters.
- **Pity:** a Rare or better within 5 pulls, an Epic or better within 15, a Legendary within 40 (to tune).
- **The reveal** uses the VFX we built: Common to Legendary tiers, the Ink and Vortex Legendary ideas, the Ultimate for the first Dawn Crest. Flashes, particles and reduced-motion settings apply.

## 8. Sound and music (what changed)
- **Merge ladder** (`merge_1` to `merge_8`): each tier up is louder, longer and heavier. Measured: loudness -26.0 to -18.3 dB, length 0.95 to 5.2 s, and a sub-bass layer that appears from tier 5 (share of energy under 200 Hz 0.04 to 0.12 below tier 5, 0.43 to 0.51 from tier 5). Plus new cues: summon, surge, echo, bank, charge ready, merge fail, wish pull. 38 sounds in total, all passing the analyzer.
- **Music** (all CC0, `Audio/CREDITS.md`): menu and shop play Shinsei (atmospheric lo-fi) and the Iremos Forest loop; play alternates Chill lofi inspired and Rising Moon; a quiet **tension bed** (Artifact Room, an eerie loop) eases in about 10 dB under the music when the board is busy or a boss is near, and the music ducks under big sound effects. **Not verified: nobody has listened to any of it.** The mood tags come from the track pages and our own measurements (tempo, brightness), not from ears.

## 9. Fit with what exists
Keep: ProfileStore, server authority (the server owns charges, stardust, Wishes and the board), UI Kit (Candy theme), RevealFX, LoadingFX, FeedbackFX, MotionBlurFX, boss and Ultimate moments, the skill tree if wanted. Replace: the triple-merge and touching rules, the seven species and their 35 looks (becomes 8 characters), pets as gacha prizes. The existing `MatchSim` and `GameClient` would need a migration plan; **I have not touched them** (the user asked to focus on effects first, then this brainstorm).

## 10. One-month scope if you approve option C
Week 1: board UI (5 x 4, drag, Merge! button, charges), `MergeCore` on the server, saving. Week 2: eight characters as 2D tiles first (portraits), combat on top (damage from tier), waves with gentle scaling. Week 3: Wishes and Relics, daily goal, Ascension. Week 4: polish (sound, music, effects already built), phone testing, tutorial (one highlighted step: drag Pip onto Pip). Cut first if time runs out: skins, the skill tree, extra worlds.

## 11. What is built and what is verified
- `MergeCore` (rules, tests pass, simulation above), `Roster` (test passes: eight distinct characters), 15 new sound cues plus music playback `MusicFX`, 5 downloaded CC0 tracks leveled and analyzed, eight character portraits (see `Assets/Characters/`).
- **Not built:** the board UI, combat on top of merging, Wishes and Relics logic, saving, the tutorial. **Unverified:** that it is fun; how the music and the merge sounds feel; the combat balance; the claim that C outperforms A or B (my judgment from one snapshot, not a measurement).

## 12. Questions for you (answer when you can; each changes the plan)
1. Keep combat (C) or go merge-and-idle (D)?
2. Is "you cannot lose" right, or do you want some stakes in boss fights?
3. Is a whole chain in under about three minutes too fast? (The long game then has to come from rank, Relics and the world difficulty.)
4. Names and looks for the eight characters: keep, change, or pick your own references?
5. May I upload the music and sounds to Roblox when the time comes (needs your account and your OK)?

## 13. Decision (2026-10-25): both, as two ways to play ONE board
The user asked whether idle merging and stage progression can coexist. Yes: they are two modes on the same board, same eight characters, same stardust, not two games.
- **Hearth (idle):** the board keeps summoning (charges regenerate) and the free auto-merge keeps running; characters on the board produce stardust per second by tier; offline earnings (capped, say 8 hours at half rate) greet you with the Welcome Back screen the UI Kit already has. No fighting, no way to lose. This is the default for a short attention span.
- **Journey (active):** the same characters defend the crystal against waves and bosses, stage by stage. Merging makes them stronger, so playing actively is faster. Stakes stay soft (a boss you miss pushes you back a stage, nothing is lost).
- **How they feed each other:** stardust (earned in both) buys upgrades that make Journey easier; every Journey stage cleared raises the idle rate a little; first clears and Ascensions give Wish tickets; Relics from Wishes help both. A toggle switches mode at any time.
- **Balance rule:** idle income stays at roughly a third of active income and offline is capped, so Journey is never pointless and idle is never a trap. (My judgment: untested, to be tuned with play data.)
- **Build order for a one-month solo plan:** Hearth first (MergeCore already has the idle logic; it is cheap and playable alone), then Journey. If time runs short, ship Hearth and add Journey as an update; the reverse order would leave nothing playable.
- **New risks:** two modes means two things to explain and balance; keep one tutorial step per mode and one shared currency. Not built: the mode switch, offline earnings, stage progression.

## 14. Answers received (2026-10-25, relayed from the user through another session; not yet confirmed in this chat)
1. **Combat stays, and the player CAN lose a boss fight** (so the recommended direction is option C, merge defenders with combat, plus the idle Hearth from section 13).
2. **A boss fight lasts 30 seconds.** Losing a boss costs only progress (back a stage), never characters or currency.
3. **Names and looks are kept:** Pip, Moss, Lumo, Rook, Vesper, Sir Aurel, Mirelle, Solenne and the current portraits.
4. **Uploading the music and sound effects to Roblox "later" was approved in principle.** Not done: uploading publishes assets on the user's account, so it waits for a direct confirmation in the working session (what, how many, which tool). See `Audio/CREDITS.md` for the licences; no API key is to be created or stored.
5. **Still open:** whether a whole chain in about three minutes is too fast (left as designed). Priority order is unchanged: animations and effects before gameplay, so no board UI is built and `GameClient` and the match scripts stay untouched.

## 15. Audio upload status (2026-10-25): approved, prepared, NOT done
The user confirmed the upload in the working session. It could not be completed with the tools available: Studio's MCP upload tool is image-only, `AssetService:CreateAssetAsync` documents no audio route, the Studio importer needs a person at the file dialog, and Open Cloud would need an API key (not to be created or stored). Prepared instead: `Audio/Upload/` (5 music Ogg + 38 original sound-effect WAV, 14 MB, within Roblox's 20 MB / 7 minute limits), `Audio/Upload/README.md` (the five-minute steps), `Audio/apply_ids.py` (turns `Audio/asset_ids.json` into `VFX/AudioIds.luau`), and `SoundFX`/`MusicFX` now use an uploaded id automatically when one exists and fall back to the local files otherwise (checked: sounds and music tests still pass). Needs from the user: import the files at the PC and send the ids. Nobody has listened to the audio; Roblox moderation may still reject a file.
