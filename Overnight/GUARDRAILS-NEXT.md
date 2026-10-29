# Overnight: next-night plan and guardrail changes (drafted 2026-10-29 by the main chat "Low"; NOT applied, NOT armed)
Trigger: the user says go. Until then nothing in `tools/overnight/`, `Overnight/POLICY.md` or `.claude/settings.json` changes (they are protected while `Overnight/ACTIVE` exists, and the user owns them).

## What "go" does, in order
1. Check `QUEUE.md`: every other chat released or told to stop; Studio free; no Play running. If a chat still holds something, wait or ask it (SendMessage).
2. Read `Overnight/BOARD.draft.md` (built by a triage worker from TODO, PROGRESS, Backlog, Bug Log, Known Issues, git log): done and obsolete items are dropped, duplicates merged, lanes defined. Promote it: archive the old `TODO.md` to `Overnight/archive/`, write the open board as the new `TODO.md` (gate format `- [ ] T### | title | verify: ...`, lane details on an indented next line the gate ignores).
3. Apply the guardrail changes below (policy, guard, checkpoint), then `python tools/overnight/arm.py --confirm-tonight`.
4. The main chat runs as controller: hands each lane to a worker (Agent tool; Sonnet for build and creative tasks, Haiku for mechanical ones), serialises Studio and GPU through `QUEUE.md`, re-verifies worker reports itself, keeps the ledger, and never lets two workers touch the same lane files.

## Guardrail changes (everything local and reversible becomes possible)
| Was blocked | Becomes |
|---|---|
| Commits capped at 3 per run (`checkpoint.py`) | One commit per finished task on `overnight/*`, via `checkpoint.py --task T### --desc "three words" -m "two plain sentences"`; cap removed; still never pushes, never stages `*.rbxl` or `*.mp4`, nothing over 20 MB, no history rewrites, no trailers |
| Tools outside the project folder (Blender in Downloads, ComfyUI, Hunyuan3D venv) | Their folders join `ALLOWED_ROOTS` for running; Kimi, ComfyUI, Animation Kit and Hunyuan3D-2 source stay read-only (third-party code) |
| Studio `subagent` and `skill` calls | Allowed (Studio's own helper; still no purchases or publishing) |
| `curl` and web fetches to non-approved hosts | HTTPS GET of data files (png, jpg, glb, fbx, wav, ogg, mp3, json, md, txt, lua, luau, zip) from public hosts into `Vendor/` or `Roblox Dev/Assets/`, URL pinned to a commit or version, source and licence logged; never executables, installers or scripts to run |
| The words `publish` and `deploy` anywhere in a shell command | Only blocked when they are the command itself (false positives on notes and file names removed) |
| Tasks marked blocked because of the above | Re-opened on the board as `unblocked-by-relaxation` |
| Parallel work | Workers allowed (Agent tool), one lane each, one Studio holder at a time |

Also: milestone pushes (`python tools/notify.py --done "..."`) are allowed all night, with no quiet hours or cap (changed 2026-10-29); emergencies (`--reason`) keep their limits. The controller sends one per finished lane or major task and one with the final report.

**Morning digest (added 2026-10-29):** the controller appends one ledger line per finished task, and as the last step runs `python tools/morning_digest.py --push`. It writes `Overnight/MORNING.md` (and a vault copy `Roblox Dev/Overnight/Morning <date>.md`) with: tasks finished by lane (id, commit hash, three words, status, evidence), all commits, the phone milestones, what is still open or blocked, anything unverified, denied actions, and a reminder that the place is unsaved; it then pushes a one-line notice. All notifications (milestone and emergency) are allowed while armed and at night; only one emergency per 30 minutes.

Comms: controller and workers talk through `tools/comms.py` files (status, inbox, decisions), not prompts; the 15-minute digest loop keeps pushing to the phone; the ledger and morning digest read the same files.

## Stays blocked (irreversible or external; needs the user in words)
Publishing or deploying the game, purchases and dev products, Open Cloud keys and any secret, pushing, merging to `main`, pull requests, `git reset` / rebase / history edits, installing software or packages (`pip`, `npm`, installers), recursive deletes, stopping Studio or Claude, saving the place file (not possible from the tools anyway: tell the user at the end that the place is unsaved).
Asset uploads to the user's Roblox account stay allowed (pre-approved 2026-10-28; every id logged in `VFX/ASSETS.md`).

## Ledger (no overlap, no revisiting old issues)
- `Overnight/LEDGER.md`, one line per finished task, appended by the controller: `T### | commit <hash> | "three word desc" | status (gate-verified / attested / UNVERIFIED) | lane | evidence`.
- A task id appears once on the board; done ids are listed in the board's "Already done" section and never re-assigned. A worker starting a task first greps the ledger and `git log` for it.
- Old issues: Bug Log and Known Issues items are on the board only if still open and reproducible; fixed or superseded items are closed in the vault (Bug Log), not re-worked.
- Lanes (from the board) own files; the controller checks `git diff --name-only` per worker against the lane's owner-files before each checkpoint and moves out-of-lane edits to the right lane's task.
- After each task: vault update (Backlog tick, Bug Log, Systems, one Session Log line) as in `CLAUDE.md`; the final `Overnight/REPORT.md` lists commit hashes with their three-word descriptions.

## Open decisions for the user (only these)
1. Confirm the "Stays blocked" list is right (in particular push and pull request stay with you).
2. Which night: tonight, or after the UI rework and loading clock finish (the board excludes those areas while their chats work).
