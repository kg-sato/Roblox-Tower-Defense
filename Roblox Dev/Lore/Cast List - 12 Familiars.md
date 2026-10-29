# Cast list: 12 core familiars (T074)

Status: draft written overnight 2026-10-28. The twelve names come from the task list (T075 to T086): Ember, Gargoyle, Frostling, Star Drake, Sentinel, Ward, a Star Choir mirror-cat (replacing the Arcane Fox, no fox), Clockwork Owl, a mourner who gave up its face, Brass Hound, Moth-Lantern and the Grey Veil Wraith. Rarity, role, faction and hook are my proposals under [[Character Bible Rules]]. Factions and glyphs: [[Factions]]. Dialogue home sets: [[Familiar Dialogue]]. Terms: [[Glossary]].

## Cast
Rarities use the four that exist in the code (Common, Rare, Epic, Legendary). The spread is 4 Common, 4 Rare, 2 Epic, 2 Legendary. Each role is one verb and no verb repeats (rule "one job").
| # | Familiar | Rarity | Role | Faction | Home set | One-line hook | Replaces in the current code |
|---|---|---|---|---|---|---|---|
| 1 | Ember | Common | Scorch | Lantern Keepers | Lampwick Lane | Carried a Keeper's first lamp home and never forgot the way. | Ember (kept) |
| 2 | Moth-Lantern | Common | Reveal | Lantern Keepers | Lampwick Lane | A light that flies in the fog and marks what hides there. | Zap (fast chip damage) |
| 3 | Brass Hound | Common | Harry | Clockwork Guild | Clockwork Foundry | Keeps the Foundry's tally and bites anything unwound. | new |
| 4 | Sentinel | Common | Breach | Clockwork Guild | Clockwork Foundry | Obeys the last order it was given and does it beautifully. | new |
| 5 | Frostling | Rare | Chill | Hollow Court | Silent Cathedral | A cold small guest who followed a mourner home and stayed. | Frostling (kept) |
| 6 | Gargoyle | Rare | Crush | Hollow Court | Silent Cathedral | Watches the west front and has opinions about being looked at. | Boulder (heavy hit) |
| 7 | Ward | Rare | Ward | Lantern Keepers | Harbour of Brass | A lighthouse spirit waiting for ships that no longer come. | new |
| 8 | Clockwork Owl | Rare | Hasten | Clockwork Guild | Harbour of Brass | Keeps the Guild's memory, and winds its neighbours faster. | new |
| 9 | Mourner | Epic | Hush | Hollow Court | Silent Cathedral | Gave up its face to someone who needed it more. | new |
| 10 | Mirror-cat | Epic | Echo | Star Choir | Above the Grey Veil | Steps out of a star and shows you yourself, then helps. | VoltFox (Epic; the fox is retired) |
| 11 | Star Drake | Legendary | Starfall | Star Choir | Above the Grey Veil | Last of the Choir, singing alone across the open sky. | Star Drake (kept) |
| 12 | Grey Veil Wraith | Legendary | Drain | Unaligned | Above the Grey Veil | Belongs to no one, and takes the fog's shape for company. | new |

Not carried forward: Sprout (the task bans sprout-style designs) and Zap and Boulder as names (their roles move to Moth-Lantern and Gargoyle). Names in the current `Config.PETS`: Ember, Sprout, Zap, Frostling, Boulder, VoltFox, StarDrake. Replacing them in code and models is a later task (T101, T102).

## Humanoid revision (user request, 2026-10-28)
The user asked for human characters, or at least humanoid ones, in the cast. Rule from now on: **at least 8 of the 12 familiars must be humanoid** (a head, a torso, two arms and two legs, or a clearly human-shaped body), and the player's Keeper is a human (T112, T113). The creature slots that stay non-humanoid are Ember (flame), Brass Hound, Star Drake and Gargoyle (a hunched stone figure, kept as a gargoyle). Revised designs for the rest:
- **Sentinel:** humanoid already (done in T079).
- **Frostling:** a child in a hooded coat (humanoid already, T077).
- **Mourner:** a tall faceless figure in a veil and mourning coat (humanoid already).
- **Ward:** was a lighthouse spirit; now a human lighthouse keeper, a slight figure in a long coat holding a lamp on a pole.
- **Clockwork Owl:** was an owl; now **the Archivist**, an owl-masked clockwork scribe in a long coat (role Hasten unchanged).
- **Mirror-cat:** was a cat; now **the Mirror Chorister**, a robed singer whose face is a small round mirror (role Echo unchanged).
- **Moth-Lantern:** was a moth; now a young lamplighter with moth-wing fabric cloak and a lantern pole (role Reveal unchanged).
- **Grey Veil Wraith:** a tall ghostly figure under a grey veil (humanoid, role Drain unchanged).
Count: humanoid = Sentinel, Frostling, Mourner, Ward, Archivist, Mirror Chorister, Moth-Lantern lamplighter, Wraith = 8; non-humanoid = Ember, Brass Hound, Star Drake, Gargoyle = 4.
Names in the table above and in [[Familiar Dialogue]] still use the older names (Clockwork Owl, Mirror-cat, Moth-Lantern) until the pairs are revised in a later pass; the roles, rarities and factions do not change. The design sheets for these characters (T080 and later) follow this revision.

## Role verbs, in one line each (details are for T192, T193, T194)
- Scorch: steady single-target fire damage. Reveal: marks enemies for extra damage. Harry: very fast, short-range chip damage. Breach: damage that ignores brass armour (T213).
- Chill: slows. Crush: slow, heavy hits. Ward: raises the range of adjacent familiars. Hasten: raises the attack speed of adjacent familiars.
- Hush: interrupts an enemy's special move (T138). Echo: repeats the neighbouring familiar's attack at reduced power. Starfall: long-range burst with a ranged ultimate. Drain: hits through armour and heals the lantern a little.
These effects are proposals; none is balanced or implemented.

## Spread checks
- Four factions plus one unaligned: Keepers 3 (Ember, Moth-Lantern, Ward), Guild 3 (Hound, Sentinel, Owl), Hollow Court 3 (Frostling, Gargoyle, Mourner), Star Choir 2 (Mirror-cat, Star Drake), Unaligned 1 (Wraith).
- Every home set has at least two familiars; the Cathedral and the Grey Veil have three (matches [[Familiar Dialogue]]).
- Signature hues, silhouettes and glyphs are decided in T087 and T088, not here.

## Open questions for the user
1. Is 4/4/2/2 the right rarity spread, given the current odds of 60/28/10/2? Fewer Legendary rolls make two Legendaries rarer.
2. Is the Wraith (unaligned, Legendary) right as a roster unit and not only a boss-tier enemy?
3. Keep the Gargoyle with the Hollow Court, or move it to the Keepers?

## Checks
`Overnight/evidence/T074_check.py` verifies: 12 familiars; rarity counts 4/4/2/2; unique names and unique role verbs; factions only from the allowed set with all four present; hooks of 20 words or fewer; no fox or sprout name. Output in `Overnight/evidence/T074.txt`.
