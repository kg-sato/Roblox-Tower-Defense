# Manager handoff (written by the old main manager "Low", 2026-10-30)

You are the new main manager/controller for the Roblox merge tower defense project (`C:\Users\kgsat\Documents\Roblox`, place `Claude.rbxl`, branch `overnight/2026-10-27`, nothing pushed). Read `CLAUDE.md`, `QUEUE.md`, `Overnight/REPORT.md`, `Overnight/MORNING.md`, `Roblox Dev/Home.md`, `Roblox Dev/Backlog.md` first.

## User rules
- The user is often away and on Remote Control: new sessions (`start_session`) cannot be started then; ask them to type "start it" in the desktop app. SendMessage to existing sessions works.
- SILENT MODE: only the main manager writes to the user, short. Other chats and workers write nothing; phone pushes via `python tools/notify.py --done "..."`. Chat-to-chat communication is files (`tools/comms.py`, QUEUE.md rule 8b); SendMessage only when the other agent must decide.
- Send screenshots/files to the user with SendUserFile (they review from their phone).
- Max 5 commits per armed overnight run (`tools/overnight/checkpoint.py`, `MAX_COMMITS`). Commit/push/merge only when asked; commits under kg-sato, no Claude trailers, two plain sentences. Never save the place, publish, or push.
- Uploads to the user's Roblox account and Studio AI generation are pre-approved; log ids in `VFX/ASSETS.md`.

## Open sessions (SendMessage `to` = id)
- hud-rework `local_3dd2c7ab-7178-41c2-9693-d0c9d5cd70a8`: rebuilds the HUD (vine + steampunk gears, brass). Blind review stuck near 5-5.5/10 (target 7); `Config.HUD_REWORK` is OFF. Current step: swap leaf/vine motifs for Art Nouveau whiplash ironwork (art ready in `UI Kit/art/hud_art/final/i_wide|i_tall|i_panel|i_ring.png`; note `Roblox Dev/Research/3D and Art/Art Nouveau ornament references.md`), then screenshots `hud_m.png`/`hud_n.png`, then the queued SUMMON MENU task (move Roll out of the board HUD into a gacha-style Summon menu behind flag `SUMMON_MENU`, per `Roblox Dev/Research/Game Design/Gacha Retention Study.md`). BLOCKED NOW: Studio MCP calls all time out (dialog or hung plugin; the user must clear it). It holds the QUEUE.md Studio row.
- loading-anim `local_edb20698-6c34-4271-a6de-188a1a59fd1b` and refs-intake `local_2db4739a-e5ac-47c7-a1e1-5d30b829f435`: idle.
- Background subagent building P3 (`P3_ROLL_FLOOR`), P2 (`P2_CHOSEN_GUARANTEE`, "Lantern Oil" at 100 pulls) and P7 (`P7_DUPE_BOND`), all flags default OFF, server-authoritative; writes `Roblox Dev/Design/Summon Server API.md`, evidence `Overnight/evidence/P237.txt`, reports via comms inbox from `builder-p237`. It will stall on Studio steps until Studio answers. Do not duplicate it.

## Decisions made by the user
- T200 install approved: `Vendor/luau/luau-analyze.exe` (v0.744); five type errors fixed in `Studio_Export/` (NumberFormat, Bond, Quests, LeaderboardRules) and synced to Studio; unknown Roblox globals in its output are noise.
- Tier cap stays 5 (fusions later). Rarity tier cap (Epic 4, Legendary 3, `Config.RARITY_TIER_CAP`, default OFF) approved to build; achievements and quests screens approved but only AFTER everything else (HUD, summon) is done. P2, P3, P7 approved (yes, yes, yes).
- HUD taste: whimsical like the skill tree, vines subtle, add steampunk gears/gauges, Art Nouveau ornament; no constant lamp glow; no odds popup; unique ultimate button per equipped character; keep the actual skill tree UI and make its cutscene match.

## Not done / waiting on the user
- Clear the Studio hang, then tell hud-rework to resume.
- Character animations (wire Hit/Death clips on the board, verify Walk/Attack/Idle for all 20 familiars and enemies, motion smoothness) was offered; needs the user to type "start animations" in the desktop app to start a session.
- Rarity tier cap + achievements/quests screens session not started (Remote Control block).
- Save `Claude.rbxl`, review/merge branch `overnight/2026-10-27`, look/listen review of effects and sounds, enable feature flags one at a time (PATH_PER_SET, MAP_RULES, PATH_BLOCKERS, HOLLOW_ENEMIES, ENDLESS, BOSS_V2, BOSS_UNMERGE, WAVES_V2, ACHIEVEMENTS_ON, QUESTS_ON, BOND_ON, LEADERBOARD_ON, SKY_ON; run `Tests/lean_bot.luau` after each).
- Blocked tasks: T076/T640 (HUD blind review), T200 (needs Studio RunAll evidence).
- Background loop `comms.py digest --push --loop 900` may still run in the old chat; restart it if needed.

## Update 2026-10-30 (late): P2/P3/P7 builder finished its turn BLOCKED
- Code and docs written in `Studio_Export/` (new `Gacha.luau`; edits to `Bond.luau`, `MatchSim.luau`, `MatchService.luau` with profile version 2 and a `Guarantee` action, `Config.luau` flags `P3_ROLL_FLOOR`, `P2_CHOSEN_GUARANTEE`, `P7_DUPE_BOND` all default false), tests `Tests/P3Floor|P2Guarantee|P7DupeBond.test.luau`, doc `Roblox Dev/Design/Summon Server API.md`. NOTHING RUN: no Studio install, no RunAll (expect 36 suites), no lean bot, no balance numbers. Evidence `Overnight/evidence/P237.txt` line 1 BLOCKED.
- Cause: hud-rework holds the Studio row in QUEUE.md (stale; its comms status idle since 12:15) and Studio MCP does not answer. Next: when Studio answers, install `Shared.Gacha` ModuleScript plus the 4 edited scripts, run all suites and the lean bot with each flag, record numbers, then commit via the controller.
- Seen bug (pre-existing, only with hook flags on): `MatchService.startRun` calls `syncProfile` before the local is defined. Fix it.
- Agent report was a subagent claim, not proof: re-verify.

## Update 2026-10-30 (Studio relaunched by the user)
- Studio MCP answers again. It reopened the 15:06 save of `Claude.rbxl` (overnight work + T200 fixes included) in PLAY mode. Missing in Studio, present only in `Studio_Export/`: `HudRework`, `GCHudDressing`, `HudPolish`, `Gacha` and the edits to `Config` (HUD_REWORK, P2/P3/P7 flags), `Bond`, `MatchSim`, `MatchService`. The Studio row in QUEUE.md is still marked held by hud-rework (stale): clear it, stop Play, reinstall those scripts from `Studio_Export/`, run all suites + lean bot, then resume hud-rework.
