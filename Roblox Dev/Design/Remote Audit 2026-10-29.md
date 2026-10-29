# Remote audit (T227)
Static read of `MatchService.luau`, `ActionArgs.luau`, `MatchSim.luau` and `SettingsDefaults.luau` on 2026-10-29, plus the existing tests (all passing: see below). There is one client-to-server remote, `Remotes.Action` (a RemoteEvent with `kind, a, b`), and one server-to-client remote, `Remotes.Event`. No remote was added today (the "new remotes" in the task text: none found); the audit covers all of them.

| Kind | Argument checks | Rate limit | Notes |
|---|---|---|---|
| any | `kind` must be a string; unknown kinds are dropped before they use the rate gap | `MIN_ACTION_GAP` 0.05 s per player for in-run actions (at most 20 a second) | actions need a live session |
| Start | no arguments used | one per second per player | spawns a waiting thread (up to 15 s) while the profile loads; up to about 15 such threads per player, minor |
| SkipTutorial | none | one per second | only replaces a tutorial run; mid-run it is ignored |
| Setting | `ActionArgs.settingChanges` (string key or a table of at most 16 keys); each value through `SettingsDefaults.validate` | `SettingsDefaults.allowSave` gap per player | works without a run; invalid keys and values are dropped |
| Roll | none | action gap | gems, cap and room checked in the sim |
| Drop | both args `isSlot` (positive integer under 1e7) | action gap | refuses mismatches in the sim |
| Move | `a` is a slot, `b` a table with finite `x` and `z` under 1000 | action gap | legality by `Config.canPlace` |
| Recycle | `isSlot` | action gap | |
| Upgrade | pet and kind must be strings that exist | action gap | checked in `MatchSim.upgrade` (owned, level, coins) |
| Skill | id must be a string that exists, not `Start` | action gap | neighbour, points and level in `MatchSim.skill` |
| AutoWave | must be a boolean | action gap | |
| Ult, StartWave, EndTutorial | none | action gap | state checked in the sim |

Findings
- No client value is trusted for currency, rewards, purchases, inventory or cooldowns: all of them change only inside `MatchSim` on the server. This matches the project rule.
- NaN and infinite coordinates are refused (`isCoord` requires `n == n` and a bound).
- A client can send up to 20 valid actions per second per player; that is generous but bounded; no per-kind limit for expensive actions (none is expensive).
- `Start` can queue up to about 15 waiting threads per player (one per second while loading); minor, could be limited to one pending thread.
- A fired `Setting` is rate-limited and validated, but a client can still make the server do one `FireClient` per accepted save; bounded by the gap.
- Not audited: the premium product handlers (`Config.PRODUCTS` ids are 0, no purchase flow exists yet) and the `SeenPets` attribute (server to client only, set by the server).

Tests that cover this: `Tests/ActionArgs.test.luau` (argument shapes), `Tests/SettingsDefaults.test.luau` (validation and the save gap), `Tests/MatchSim.test.luau` and `Tests/ServerRules.test.luau` (the sim rules behind each kind). All 12 suites passed in Studio Edit mode on 2026-10-29 (11 through a temporary runner, plus the Balance run).
