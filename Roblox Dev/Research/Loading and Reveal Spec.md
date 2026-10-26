# Loading and Reveal Spec

Design spec (2026-10-25) that combines **Rivals' blur handoff** with **Sol's RNG's loading and rolling style**, using the vibe-coded game as the motion baseline. Evidence: [[Video Reference Analysis]]. Rules: [[Smooth Motion and Blur Playbook]] (everything eases, blur capped, dt-based), [[Game Design Doc]] (Flashes, Particles, Reduced motion), [[Low-End Device Playbook]]. Build target: `VFX/RevealFX.luau` and a new loading module; do not touch the game HUD yet.

Our own marks only: no Rivals logo, mascot or lettering, no Sol's emblem. Use a simple original emblem and the project's name.

## A. Loading sequence (about 6 to 10 s, skippable after the first view)
| Beat | Time | What | Source of idea |
|---|---|---|---|
| 1 Fade up | 0 to 0.5 s | Black. Thin emblem fades in with a slight scale 0.95 → 1 (Quint Out). Hairline progress rule underneath, tiny monospace "Loading assets \| n / m", one tip line | Sol's loading |
| 2 Wait scene | 0.5 s onward | Behind the emblem, the **world is heavily blurred and dim** (BlurEffect on the camera, Size 18 desktop / 10 touch), slowly drifting (camera orbit or clouds of light). A corner counter "Loading n" bottom-right, optional small mascot/tip bottom-left. **Nothing else moves fast.** Progress rule eases toward the real value (exponential smoothing), never jumps | Rivals loading (calm blurred wait) + Sol's monospace |
| 3 SYNCED | when loaded | The brackets contract around **"SYNCED"**, underline sweeps in (0.4 s). A **soft light lift** (luminance 0 → 0.25 → 0 over 0.7 s, not a white flash) | Sol's "SYNCED" |
| 4 Handoff | 0.8 s | **Logo glows in** (opacity + small scale, 0.4 s) while the **HUD fades in at the same time**, still over the blurred world | Rivals 19.5 to 20.0 s |
| 5 Resolve | next 0.8 to 1.0 s | **Blur eases 18 → 0 (Exponential or Quint Out)**; the logo **shrinks about 15%, drifts up, and fades out** during the same window; the HUD finishes fading in. Camera settles | Rivals 20.0 to 21.0 s |
| 6 Play (optional) | after 5 | If we want a menu gate: bracketed "Play" button bottom-left (Sol's style) instead of auto-entering | Sol's loading |

Rules: total blur time per beat under 1 s; **one** BlurEffect (the largest wins); parented to the camera and destroyed after. With **Reduced motion or Flashes off**: skip beat 3's light lift (use a slow fade), cap blur at 8, no scale or drift on the logo, 0.4 s plain crossfade. Always allow **skip** after the first run.

## B. Reveal sequence (crate or roll), tied to rarity
Follow the tiers in [[Magical Roll Animation Playbook]], rebuilt on what the Sols videos show:
1. **Anticipation (the key):** a **single point of light** on a dark, softly streaked backdrop. Length scales with rarity: Common none, Rare about 0.8 s, Epic about 2 s, Legendary about 4 s. The point slowly grows and shifts colour toward the result's identity colour.
2. **Identity:** every Legendary gets its **own idea**, not a recolour. Starter set to build: (a) ink splash with a rune ring (green), (b) swirling gold vortex, (c) typographic words orbiting a star (blue/purple), (d) glitch/scan-line corruption (red). Rare and Epic share simpler ring-and-rays recipes.
3. **Release:** the star flares (bloom ramp, **no hard white frame**), world blur clears with the Rivals-style ease-out while the **result card (odds line, big name, tier word)** eases in.
4. **After:** cut/crossfade to the result card or collection view with a "Replay" button (Sol's aura viewer idea).
5. Blur and bloom values follow the playbook; Flashes off means no brightness spike, only a slow rise.

## C. Menu and feedback animation baseline (from the vibe-coded game)
Every screen gets at least:
- **Living background:** slow parallax or drifting light, never a static flat colour.
- **Menu transitions:** world blur + dim (+ optional green or theme tint) behind panels; panels **fade/pop in together** with the dim, and **close in the same way** (Rivals battle pass).
- **Click feedback:** floating combo/value text rising from the click point, a small **ring pulse**, and a gentle **edge tint** on milestones (alpha under 0.2, no strobing).
- **Milestone banners** ("STELLAR!", "GREAT JOB!") that ease in and out.
- **Tutorial highlight:** dim everything except the target, **gold outline**, pointing hand.
- **Discovery:** a new pet/item flies or fades in with a soft **orbit/glow line** and a large title that fades in behind it.
- **Particle convergence** onto the focus object for charge-ups.

## D. UI look
- Menus and shop: use the **Candy** theme (chunky, readable) or **Pixel** if retro; battle-pass style cards come from the Rivals videos (two reward rows, bundle cards with strike-through prices).
- System and loading moments: **Aura** theme (hairlines, corner brackets, monospace).
- No stud or low-poly UI. Keep contrast high; the vibe game's dim tiny text is the anti-pattern.

## E. Acceptance checks
- [ ] Loading shows beats 1 to 5 in order on desktop and a phone-sized viewport; blur peak and duration match the numbers above (measure `BlurEffect.Size` over time).
- [ ] Blur resolves while HUD and logo overlap (screenshots at 0.0, 0.4, 0.8, 1.2 s after handoff).
- [ ] Flashes off and Reduced motion variants exist and are verified.
- [ ] Reveal tiers differ in length and idea; Legendary has at least two different cutscene ideas.
- [ ] No ambiguous fast brightness change (frame-to-frame luminance delta under a chosen limit; state the limit).
- [ ] No IP copied: original emblem, name and art.
- [ ] Frame rate holds on a low-end phone with post-effects on.

## F. Out of scope for now
Sound, wiring into the real HUD, the gameplay loop, and exact copies of any game's art.

## Build status and acceptance results (2026-10-25)
Built in `VFX/` (see `VFX/README.md`): `LoadingFX` (section A), anticipation plus two Legendary ideas in `RevealFX` (section B), `FeedbackFX` (section C). Stills: `Research/VFX Renders/loading-*`, `legendary-ink-*`, `legendary-vortex-*`, `feedback-*`.
- [x] **Beats 1 to 5 in order** (measured at real speed): fadeUp 0.00 s, wait 0.51, synced 3.03, handoff 4.24, resolve 5.06, done 6.07. Desktop only: a phone-sized viewport was **not** tested (Studio client cannot be resized from here); layout is Scale-only, the touch caps are tested by forcing touch in the audit.
- [x] **Blur numbers measured** (`BlurEffect.Size` every frame, real time): peak 18 reached in about 0.37 s of the wait. Resolve with **Quad Out over 0.9 s**: 18.0, 14.7, 11.1, 8.6, 5.8, 3.7, 2.3, 1.0, 0.2, 0.0 at +0.0 to +0.9 s in 0.1 s steps (steady, flattening at the end, like the sharpness curve measured on Rivals). Exponential Out from the playbook was too front-loaded (18 to 4.1 in 0.2 s, clear in 0.5 s), so it was not used. Flashes-off variant: peak 8, resolve 8.0 to 0.0 in 0.8 s, no light lift.
- [x] **Blur resolves while HUD and logo overlap**: stills at handoff and at +0.22 s and +0.55 s into the resolve (a mock HUD stand-in, not the game's HUD).
- [x] **Flashes off and Reduced motion variants** exist and are covered by the audits; Flashes-off loading was run for real (peak 8, no lift). Reduced-motion was exercised by the audits, not looked at as a still.
- [x] **Legendary has two different ideas** (Ink, Vortex) plus the earlier default and the Ultimate; lengths: Ink 4 s anticipation + 4.8 s, Vortex 4 s + 5.2 s. Rare and Epic anticipation exist (0.8 s, 2 s) but were only audited, not looked at.
- [x] **Luminance limit stated:** the idea cutscenes use no flash at all (bloom ramp, soft modes cap at 0.6x and a 0.6 s rise); the loading light lift peaks at 0.25 over 0.7 s; the edge tint peaks at 0.18 (0.09 soft); the older Legendary and Ultimate keep a flash of 0.85 and 0.95 only when Flashes is on (rise 0.08 and 0.05 s, once per reveal). Frame-to-frame luminance was **not** measured on pixels.
- [x] **No IP copied:** original emblem and name, no Rivals or Sol's art.
- [ ] **Frame rate on a low-end phone: not tested.** Vortex uses up to 45 billboard motes at High; BlurEffect mobile cost is unmeasured.
Findings that changed the code: a CanvasGroup with `GroupTransparency = 1` still drew in Studio (hide with `Visible = false`); an image with X scale 0 plus an aspect constraint collapses to zero size (give both axes a size); BlurEffect never blurs ScreenGui UI.

### Update after verification (2026-10-25)
Desktop loading blur peak changed from 18 to **12** (touch 10, soft 8 unchanged): the stills stop getting blurrier past about 11, and a peak near 11 matched the Rivals ramp best (RMSE 0.07 vs 0.109 at 18). Re-measured resolve: 12.0, 9.8, 7.4, 5.7, 3.9, 2.4, 1.5, 0.7, 0.2, 0.0 at +0.0 to +0.9 s. See [[VFX Verification Report]].
