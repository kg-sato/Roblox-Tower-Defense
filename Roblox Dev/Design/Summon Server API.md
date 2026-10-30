# Summon Server API
Written 2026-10-30 by builder-p237. For the Summon menu (hud-rework). Source: [[Gacha Retention Study]] proposals P2, P3, P7; rules in `Shared.Gacha`, `Shared.Bond` (dupe part), `MatchSim` (`roll`, `claimGuarantee`, `gachaSnapshot`). Related: [[Progression Rules]], [[Systems]].

Everything is decided on the server. The client only reads the data below and sends one new action. Each feature has its own `Config` flag, all default `false`; with a flag off the matching counter is not touched and the client sees `...On = false`.

| Flag | Feature |
|---|---|
| `Config.P3_ROLL_FLOOR` | every 10 rolls hold a Rare or better (the roll made while 9 dry rolls are banked is forced up) |
| `Config.P2_CHOSEN_GUARANTEE` | each counted roll earns 1 Lantern Oil; 100 buys one chosen Rare-or-better familiar |
| `Config.P7_DUPE_BOND` | extra copies of a familiar give a permanent damage bonus (Bond steps) |

## State saved in the profile
`profile.gacha = { oil, sinceRare, claims }` (profile version 2; older profiles are migrated to a fresh state on load, damaged values are clamped). Never reset by a run, a stage or a banner change (there is one pool, no banners). Lantern Oil is earned only, never sold, never expires, no countdown. The existing Epic pity (`sincePity`, `pityEvery`) is unchanged and still per run.
P7 reads the existing `profile.collection[pet].count` (copies pulled); no new save field.

## Snapshot fields: `snapshot.gacha` (always present, arrives with every `State` event and `Begin`)
| Field | Meaning |
|---|---|
| `floorOn` | P3 active |
| `floorEvery` | 10 |
| `sinceRare` | rolls since the last Rare or better (0 to 9) |
| `rollsToFloor` | rolls until the floor fires, 1 means the next roll is guaranteed Rare or better |
| `oilOn` | P2 active |
| `oil` | Lantern Oil owned |
| `oilNeed` | 100 |
| `oilReady` | `oilOn` and `oil >= oilNeed` (show a calm static dot, no pulse) |
| `claims` | chosen guarantees used so far |
| `dupeOn` | P7 active |
| `dupes` | only when `dupeOn`: `{ [petId] = { copies, step (0-5), power (0.03 to 0.15), nextAt (extra copies for the next step, nil at the top) } }` for every owned familiar; extra copies = copies - 1 |

Suggested wording: "Rare or better in `rollsToFloor` rolls" (P3), "Lantern Oil `oil` / 100" (P2), "Bond step `step` of 5, +`power*100`%" (P7). Steps: 1, 3, 6, 10, 15 extra copies give +3, 6, 9, 12, 15 percent damage.

## Remote events (server to client, `Remotes.Event`)
- `Roll` payload gains optional fields: `floored = true` (P3 lifted this roll to Rare or better), `dupeGems = 10` (P7: a copy past the last step paid gems), `chosen = true` (P2 claim; always sent with `bonus = true`, so it does not count as a roll and does not fire the shared Legendary banner). Existing fields are unchanged.
- `Denied { reason }` for a refused `Guarantee` (reasons: "Not available", "Not in the tutorial", "Pick a Rare or better familiar", "Not enough Lantern Oil", "Too many pets (max N)", "No room left on the street"). Nothing is spent on a refusal.

## Remote action (client to server, `Remotes.Action`)
`Action:FireServer("Guarantee", petId)` where `petId` is a string key of `Config.PETS` whose rarity is Rare or better. The server checks the flag, the tutorial, the id, the rarity, the oil (100), the unit cap and free space, spends exactly 100 oil, places a tier-1 unit and sends `Roll` with `chosen = true`. The roster to show in the picker is `Config.PETS` filtered to rarity order >= 2 (`Gacha.MIN_CLAIM_ORDER`). Shares the 0.05 s action gap with other actions.

## Notes for the menu
- Pity and Rates stay inline; show `rollsToFloor` and the oil bar next to the roll buttons, and keep the "Rates" labelled button.
- The "Roll x10" button is client-side (ten `Roll` actions); the floor counts every roll, so ten single rolls and a x10 behave the same.
- A claim needs a free board slot; if the board is full the menu should say so and keep the oil (the server already does).
