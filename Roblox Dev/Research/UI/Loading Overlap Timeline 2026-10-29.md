# Loading finale overlap (2026-10-29)
User request: lid opening and suck-in must play at the same time as the tree and small eyes vanish, with a morph and no pop. Code: `Studio_Export/LoadingScreen.luau` (finale section, installed in Studio `ReplicatedFirst.LoadingScreen`, place not saved).

## Timeline now (t = 0 at the tree collapse)
| Time | Event |
|---|---|
| 0.0 to 1.2 | tree wrung into the eye's point (was 0.9) |
| 0.0 to 0.7 | great eye unfurls out of the same point, same counter-clockwise turn (was 1.6, started after a wait) |
| 0.05 to 1.55 | four watchers spiral in (was 1.1, started at 0.85) |
| 0.2 to 1.8 | lid opens in one Sine motion (was 0.7 + rest + 1.7, started at 2.2 s) |
| 0.6 to 2.6 | pull / whirlpool (was started at about 5.4 s, after the eye was open) |
| 1.8 to 2.6 | dials spin up (gradient masks come off at 1.8 so they do not turn) |

## Evidence (Studio Play recording, `Captures 2026-10-28/overlap/loading_overlap1.mp4`, 469 frames, real 19.5 fps)
- Per-frame pixel measures (video clock): tree blue pixels fall 57k to 8k between 18.1 and 18.7; eye lid height 176 px at 18.7 to 604 px at 20.3 (opens through 18.3 to 20.3); eye width grows 500 to 603 px from 19.0 (pull); the dive starts at 20.6. So tree, watchers, lid and pull overlap from 18.1 to about 19.6.
- Frame-to-frame difference: median 7.8; no spike above 2.2x median between 17.9 and 20.6. Spikes only 20.67 to 20.87 (the dive's bright bloom, a smooth ramp 18 to 30).
- Blind grade: NOT done (no `Design/Harsh Grading.md` exists; no reviewer run). Own look at sheets: brief cluttered 0.3 s at the start (eye rotated 110 degrees plus glitch bands over the tree); the eye's first frames show its whole almond silhouette earlier than the lid slit suggests, so the "lid opening" reads weaker than the tree morph. UNVERIFIED by a reviewer.
- Not measured: motion blur, sound. Probe attempt through a temp LocalScript failed (finale missed); removed.

## Blink lid (same day, user: "the eye is not opening, it just fades in through a horizontal slit")
Change: `eyeArt` (socket, lids, lashes) Size.Y = 2 x openV, centred, so the upper lid and lashes travel; the iris layers stay full size and are cut by the same opening (slitI); the old slit gradient on the socket is disabled. Lid opens 0.2 to 0.95 s after the collapse starts (Quint out, one-way); full-socket glitch bands only show once the lid is above 0.3. Evidence: `Captures 2026-10-28/overlap/loading_blink1.mp4` (16.9 fps) and `blink_zoom.jpg` (six frames 12.77 to 13.10 s: lid and lashes rise, iris revealed). Known limit: the iris is cut by flat horizontal edges, not the almond curve of the lid. Not blind-graded.

## Loading clock (same day; Low's orders, from Pinterest Batch 1 section 5)
Built in `LoadingScreen.luau` as a CanvasGroup `LoadingClock` in the tunnel (so it glides and dives with it), 30 % of the tunnel: dark ink plate, five concentric rings with tick marks (speeds +4, -9, +16, -26, +40 deg/s, no two alike), faint ghost stroke on each ring (glare), minute hand (three sweeps over the load), hour hand (one), second hand (jumps 30 degrees per second with a Back overshoot), counterweights and a hub. Pacing only from the references (never-still, independent speeds, hands as progress); no reference colours or art; gold ink only; no uploads. Fades out (0.5 s) when the finale starts; finale timing unchanged.
Evidence: `Captures 2026-10-28/overlap/loading_clock1.mp4` (first take: rings too faint) and `loading_clock2.mp4` (16.4 fps) with `clock_zoom2.jpg`: five rings and ticks read over the dark plate, hands visible and both on twelve at about 8.6 to 9.0 s, clock gone by 9.3 s.
Not measured: ring speeds and second-hand step (set in code, not measured from frames; an automatic angle probe was too noisy); not blind-graded; the glare ghost is subtle. Studio place not saved.
