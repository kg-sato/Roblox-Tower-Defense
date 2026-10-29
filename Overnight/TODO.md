# Overnight TODO (drafted 2026-10-28, NOT armed; the user confirms each night with `arm.py --confirm-tonight`)

Task line format (the gate parses it, ids start with T): `- [ ] T001 | title | verify: <command, studio: or manual:>`. `[ ]` open, `[x]` done, `[!]` blocked. Tasks run top to bottom. Previous list: `Overnight/archive/TODO-2026-10-28-first.md`.

Goal of the night: better gameplay in every area (research, lore, characters, models, textures, effects, UI, sound, code, balance). Every research task cites its sources with links. Every character task follows the character bible (Section B). No sprout-style or fox-style designs. Look and feel stays UNVERIFIED unless a machine check exists.

Ids are in priority order: T001 is first. Research and lore come before characters, characters before models, then gameplay, UI, effects, audio, code and docs. Done tasks move to the vault (Roblox Dev/Overnight/Done.md). Id map: Roblox Dev/Overnight/Task Map 2026-10-28.md.

# 1. Research and lore

## A. Research (sources, notes in Roblox Dev/Research)

## L. More research (cited, saved to Roblox Dev/Research)

## B. Lore and world bible

## P. Story, quests and narrative

# 2. Characters and enemies

## C. Character redesign (replaces the sprout and fox families; each character gets a bio, design sheet, model and portrait)

## M. Characters, models and textures (follow the character bible, T056)
- [ ] T124 | Texture set: enemy families, 512 px, weathering per stage set | verify: manual: evidence T124
- [ ] T125 | Texture set: boss surfaces with phase wear | verify: manual: evidence T125
- [ ] T126 | Texture set: stage props (brass, wood, stone, glass) matched to the material library | verify: manual: evidence T126

## D. Enemies and bosses
- [ ] T138 | Enemy telegraphs: a one-second warning before each special move | verify: studio: evidence T138
- [ ] T139 | Enemy health bars and status icons readable at the board camera (contrast checked) | verify: studio: evidence T139
- [ ] T140 | Enemy hit reactions per family (flinch, stagger, knockback, feathers or sparks) | verify: studio: evidence T140
- [ ] T141 | Enemy death animations per family (dissolve, shatter, sink, fly off) | verify: studio: evidence T141
- [ ] T142 | Enemy walk cycles: 4 frames each, looping, no sliding feet | verify: studio: evidence T142
- [ ] T148 | Boss phase transitions: a clear visual change and a sound per phase | verify: studio: evidence T148
- [ ] T149 | Boss health bar with phases marked (not just a number) | verify: studio: evidence T149
- [ ] T152 | Enemy spawn telegraph at the portal (a gate opens, a sound, a shadow) | verify: studio: evidence T152

# 3. World and gameplay

## E. Stages and maps
- [ ] T153 | Stage set 4 Clockwork Foundry: finish the build (rails, furnaces, gears, sparks) and verify stage 16 in Play | verify: studio: evidence T153 (stage 16 shows the set, console clean)
- [ ] T157 | Path blockers: fences, carts and lamps that change routes (data-driven, tested) | verify: studio: evidence T157 (test PASS)
- [ ] T159 | Choke points: which stages need a mid-path gate and where (documented, tested in MatchSim) | verify: studio: evidence T159
- [ ] T162 | Stage backdrop variety: each set gets 3 distinct landmarks visible from the board camera | verify: studio: evidence T162
- [ ] T163 | Board edge rings for sets 4 and 5 visible at the default camera (capture) | verify: studio: evidence T163
- [ ] T164 | Weather and fog per set (drift, density, colour) tested for performance on Low | verify: studio: evidence T164
- [ ] T165 | Set-specific props that affect the path visually (not gameplay) | verify: studio: evidence T165
- [ ] T166 | Ambient sound per set (creak, wind, clock ticks, choir, drip) | verify: studio: evidence T166

## N. Level design and maps
- [ ] T167 | Stage 1 Lampwick Lane: a path rework with one clear landmark per 1/4 of the path | verify: studio: evidence T167
- [ ] T168 | Stage 2 Harbour of Brass: path with one bridge crossing that changes the enemy line | verify: studio: evidence T168
- [ ] T169 | Stage 3 Silent Cathedral: path that loops round a central nave | verify: studio: evidence T169
- [ ] T170 | Stage 4 Clockwork Foundry: path with a moving gear section (blocks a lane every 10 s) | verify: studio: evidence T170
- [ ] T171 | Stage 5 Above the Grey Veil: path that climbs a stair and comes back | verify: studio: evidence T171
- [ ] T172 | Boss arena for The Unbound: wider open section with fog edges | verify: studio: evidence T172
- [ ] T173 | Boss arena for the Clockmaker's Automaton: a gear ring round the board | verify: studio: evidence T173
- [ ] T174 | Boss arena for the Star Choir's Echo: an open sky section | verify: studio: evidence T174
- [ ] T175 | Boss arena for the Hollow Court Regent: a chapel with pews as cover-free space | verify: studio: evidence T175
- [ ] T176 | Boss arena for the Clockmaker: time-stopped version of the Foundry | verify: studio: evidence T176
- [ ] T177 | Placement rules per map: where units can stand, marked on the board | verify: studio: evidence T177
- [ ] T178 | Placement heat map: good tiles for each family, shown as a hint toggle | verify: studio: evidence T178
- [ ] T179 | Path curvature rules: no sharp corners below a set angle (documented, tested) | verify: studio: evidence T179 (test PASS)
- [ ] T180 | Spawn gate per stage set: a readable entrance with a lore prop | verify: studio: evidence T180
- [ ] T181 | Exit gate per stage set: where the lantern is when enemies get through | verify: studio: evidence T181
- [ ] T182 | Board decorations that never block placement (tested with the placement checker) | verify: studio: evidence T182 (test PASS)

## F. Gameplay systems and balance
- [ ] T183 | Merge factor vs rarity cap: decide the rule, document the reasoning, implement behind a flag | verify: manual: evidence T183
- [ ] T185 | Roster size and layouts: when a player gets a new slot and what unlocks it | verify: studio: evidence T185
- [ ] T186 | Collection schema: fields, duplicates, shards, documented and wired to the data store | verify: studio: evidence T186
- [ ] T187 | Boss attacks as data: each attack with timing, damage and telegraph | verify: studio: evidence T187 (test PASS)
- [ ] T190 | Economy simulator: coins and gems per wave, roll cost curve, checked over 25 stages | verify: studio: evidence T190
- [ ] T193 | Ability synergy list: which familiars combo and why (data, not hard-coded) | verify: studio: evidence T193
- [ ] T194 | Status effects: burn, chill, stun, mark, lantern-bright, each with duration and stack rule | verify: studio: evidence T194 (test PASS)
- [ ] T195 | Crit system: chance, damage, feedback, tested for clamping | verify: studio: evidence T195 (test PASS)
- [ ] T197 | Skill tree: 40 nodes, each with a short description and a clear effect; no dead nodes | verify: studio: evidence T197
- [ ] T198 | Skill tree respec with cost and cooldown, tested | verify: studio: evidence T198 (test PASS)
- [ ] T199 | Next-best hint in the skill tree (suggests the cheapest useful node) | verify: studio: evidence T199
- [ ] T002 | Achievement unlock logic on the server, tested | verify: studio: evidence T202 (test PASS)
- [ ] T003 | Tutorial rewrite: 6 steps, each teaching one mechanic, with a lore line | verify: studio: evidence T203
- [ ] T004 | Difficulty modes: Normal and Hard (more enemies, more gold), clearly labelled | verify: studio: evidence T204
- [ ] T005 | Speed options 1x, 2x, 3x (tested for the same results per sim second) | verify: studio: evidence T205 (test PASS)
- [ ] T006 | Pause and resume for long sessions, saved per run | verify: studio: evidence T206

## O. More gameplay and systems
- [ ] T007 | Familiar bond system: each familiar gains a bond level from use, with a small reward | verify: studio: evidence T207 (test PASS)
- [ ] T008 | Familiar mood: a short-term state (eager, tired, lantern-lit) shown in the portrait | verify: studio: evidence T208
- [ ] T009 | Night and day cycle per stage set: a bonus window for some families | verify: studio: evidence T209
- [ ] T010 | Weather events per stage set (fog wave, rain, ash fall) changing range or speed | verify: studio: evidence T210 (test PASS)
- [ ] T011 | Lantern power: a player-controlled light that buffs nearby familiars (cooldown, tested) | verify: studio: evidence T211 (test PASS)
- [ ] T012 | Combo system: two familiars of the same faction adjacent give a bonus | verify: studio: evidence T212 (test PASS)
- [ ] T013 | Enemy armour types (brass, fog, flesh, stone) and matching damage types | verify: studio: evidence T213 (test PASS)
- [ ] T014 | Elite enemies: 1 in 10 waves, with a visible marker and a loot bonus | verify: studio: evidence T214
- [ ] T015 | Wave modifiers: 10 modifiers (no shields, double speed, mirror path) as data | verify: studio: evidence T215 (test PASS)
- [ ] T016 | Endless mode after stage 25 with scaling (tested to wave 100) | verify: studio: evidence T216 (test PASS)
- [ ] T019 | Sell and recycle rules: refund percent per tier, tested | verify: studio: evidence T219 (test PASS)
- [ ] T023 | Quest tracker in the HUD (one line, collapsible) | verify: studio: evidence T223
- [ ] T025 | Leaderboards: weekly best wave, anti-cheat checks on the server | verify: studio: evidence T225 (test PASS)

# 4. Interface and feel

## G. UI (every screen: research board, wireframe, build, Harsh Grading pass)
- [ ] T027 | Research board for the in-match HUD (5 cited references, what each does right) | verify: manual: evidence T227
- [ ] T028 | Research board for the summon reveal (5 references) | verify: manual: evidence T228
- [ ] T029 | Research board for the collection screen (5 references) | verify: manual: evidence T229
- [ ] T030 | Research board for the skill tree (5 references) | verify: manual: evidence T230
- [ ] T052 | Research board for the loading and title screen (5 references) | verify: manual: evidence T231
- [ ] T053 | Research board for the shop and passes (5 references) | verify: manual: evidence T232
- [ ] T054 | Research board for the settings screen (5 references, accessibility included) | verify: manual: evidence T233
- [ ] T055 | Research board for the results screen (5 references) | verify: manual: evidence T234
- [ ] T056 | HUD wireframe at 844x390 and 1333x777, each element with a reason | verify: manual: evidence T235
- [ ] T057 | Reveal screen: the familiar's silhouette first, rarity sigil, lore line | verify: studio: evidence T236
- [ ] T058 | Collection screen: grid of silhouettes, lore card on tap, filter by faction | verify: studio: evidence T237
- [ ] T059 | Skill tree: lantern-node redesign from the T230 research, readable at phone size | verify: studio: evidence T238
- [ ] T060 | Title screen: painted key art, logo, a menu with 4 buttons | verify: studio: evidence T239
- [ ] T061 | Shop screen: 3 tiers, clear prices, no dark patterns (no fake countdowns) | verify: studio: evidence T240
- [ ] T074 | Results screen: wave, gold, a lore line, a next-step button | verify: studio: evidence T241
- [ ] T075 | Settings screen grouped by Sound, Display, Accessibility, Controls | verify: studio: evidence T242
- [ ] T076 | Harsh Grading pass on the HUD (reviewer subagent, 7 of 10 or fix) | verify: manual: evidence T243
- [ ] T077 | Harsh Grading pass on the reveal screen | verify: manual: evidence T244
- [ ] T078 | Harsh Grading pass on the collection screen | verify: manual: evidence T245
- [ ] T079 | Harsh Grading pass on the skill tree | verify: manual: evidence T246
- [ ] T080 | Harsh Grading pass on the title screen | verify: manual: evidence T247
- [ ] T081 | Icon set: 40 icons in one style for status, currency, rarity, faction | verify: manual: evidence T248
- [ ] T082 | Font pass: 2 faces maximum, sizes from one scale, 14 px minimum | verify: studio: evidence T249
- [ ] T083 | Colour tokens for UI (one palette, dark and light tested) | verify: studio: evidence T250
- [ ] T084 | Button states: idle, hover, pressed, disabled, each with sound and motion | verify: studio: evidence T251
- [ ] T085 | Tooltip system: every icon and stat explains itself on hover and long press | verify: studio: evidence T252
- [ ] T086 | Gamepad navigation for the main screens (NextSelection links) | verify: studio: evidence T253
- [ ] T087 | Localisation-ready text: all strings in one table | verify: studio: evidence T254 (test PASS)
- [ ] T088 | Empty states for collection, shop and achievements (with a line of lore) | verify: studio: evidence T255
- [ ] T089 | Error states: network failed, data loading, server full (plain language) | verify: studio: evidence T256

## Q. More UI (research first, then build, then Harsh Grading)
- [ ] T090 | Inventory screen design: silhouettes in a grid, tier stars, empty slot lore | verify: manual: evidence T257
- [ ] T091 | Quest screen design: a parchment list, one tracked quest pinned | verify: manual: evidence T258
- [ ] T092 | Battle pass screen design: a path of lanterns, cosmetic previews | verify: manual: evidence T259
- [ ] T093 | Leaderboard screen design: weekly and all-time tabs, friend rows | verify: manual: evidence T260
- [ ] T094 | Stage select screen design: a map of the city with unlocked stages lit | verify: manual: evidence T261
- [ ] T095 | Familiar detail panel: lore, stats, bond, moods, evolve button | verify: studio: evidence T262
- [ ] T096 | Evolution screen (merge tier up) with a silhouette morph preview | verify: studio: evidence T263
- [ ] T097 | Pause menu design and build (resume, speed, settings, quit with confirm) | verify: studio: evidence T264
- [ ] T098 | Confirm dialog pattern for spending and quitting (plain text, default safe button) | verify: studio: evidence T265
- [ ] T099 | Toast notifications pattern (unlocks, rewards) with queue and dismiss | verify: studio: evidence T266
- [ ] T100 | Boss health bar polish (phase ticks, shake only when reduced motion is off) | verify: studio: evidence T267
- [ ] T101 | Dark and light UI theme test (colour tokens, contrast 4.5:1 for body text) | verify: studio: evidence T268
- [ ] T102 | Screen reader friendly labels for buttons (Roblox AutoLocalize and labels) | verify: studio: evidence T269
- [ ] T103 | UI sound for each new screen (open, close, select) | verify: studio: evidence T270

## H. Effects and feel
- [ ] T133 | Attack effect per familiar (12, each tied to its lore) | verify: studio: evidence T271
- [ ] T134 | Impact effect per enemy family | verify: studio: evidence T272
- [ ] T135 | Merge effect per tier (1 to 8), scaled and readable | verify: studio: evidence T273
- [ ] T136 | Death effect per enemy family | verify: studio: evidence T274
- [ ] T137 | Boss phase effect per boss (5) | verify: studio: evidence T275
- [ ] T138 | Ultimate effect per familiar (12) with its camera move | verify: studio: evidence T276
- [ ] T139 | Status effect visuals (burn, chill, stun, mark, lantern-bright) readable on every enemy | verify: studio: evidence T277
- [ ] T140 | Hit-stop and shake per impact, scaled, off with reduced motion | verify: studio: evidence T278 (test PASS)
- [ ] T141 | Projectile trails per familiar | verify: studio: evidence T279
- [ ] T142 | Ground decals per stage set (scorch, frost, ash, oil) | verify: studio: evidence T280
- [ ] T143 | Camera nudges on boss arrival and big merges (short, skippable) | verify: studio: evidence T281
- [ ] T144 | Lantern light language: one glow style across the game | verify: studio: evidence T282

## R. More effects and feel
- [ ] T145 | Familiar spawn sparkle per family (uses the lantern colour language) | verify: studio: evidence T283
- [ ] T146 | Enemy spawn shadow per family (size and shape match the enemy) | verify: studio: evidence T284
- [ ] T147 | Ground impact dust per stage set | verify: studio: evidence T285
- [ ] T148 | Screen edge vignette on low lantern (pulses, reduced motion off) | verify: studio: evidence T286
- [ ] T149 | Level-up light column (a warm gold column, one per level) | verify: studio: evidence T287
- [ ] T150 | Stage clear confetti of lantern-ash (one style, tested for performance) | verify: studio: evidence T288
- [ ] T151 | Death fog puff for Fog Wisps and wraiths | verify: studio: evidence T289
- [ ] T152 | Crystal shatter effect for Ward crystals | verify: studio: evidence T290
- [ ] T153 | Gear tick effect on Sentinel steps | verify: studio: evidence T291
- [ ] T154 | Star trail for the Star Drake and mirror-cat | verify: studio: evidence T292

## U. Text animation (captions, lore, numbers, titles)
- [ ] T188 | Text animation library: one module with typewriter, letter-by-letter drop, wave and shake, each with a duration and a skip | verify: studio: evidence T310 (test PASS)
- [ ] T189 | Reduced-motion rule for text animation: static text when reduced motion is on, tested | verify: studio: evidence T311 (test PASS)
- [ ] T190 | Stage captions use the typewriter reveal (bracketed captions, 0.4 s per line) | verify: studio: evidence T312
- [ ] T191 | Lore and story text reveals with a soft fade-in per line, tap to finish | verify: studio: evidence T313
- [ ] T192 | Count-up animation for gold, gems and wave numbers in the HUD (ease-out, never longer than 0.6 s) | verify: studio: evidence T314
- [ ] T193 | Title and results headings: a slight letter-spacing settle on appear | verify: studio: evidence T315
- [ ] T194 | Damage and float text: a short rise and fade with a per-family colour, obeys the damage numbers setting | verify: studio: evidence T316
- [ ] T195 | Boss name entrance: letters ignite one by one with a gold flash | verify: studio: evidence T317
- [ ] T196 | Tooltip text reveal: fast fade, no typewriter (readability first) | verify: studio: evidence T318
- [ ] T197 | Text animation settings: off, subtle, full (saved and validated), tested | verify: studio: evidence T319 (test PASS)

# 5. Sound

## I. Audio
- [ ] T155 | Placement sound per familiar (12) | verify: studio: evidence T293
- [ ] T156 | Merge sound per tier (1 to 8) | verify: studio: evidence T294
- [ ] T157 | Enemy footstep and hit sounds per family | verify: studio: evidence T295
- [ ] T158 | Boss intro sound per boss (5) | verify: studio: evidence T296
- [ ] T159 | Reveal sounds per rarity (common to mythic) | verify: studio: evidence T297
- [ ] T160 | Music per stage set (5 tracks, crossfade) | verify: studio: evidence T298
- [ ] T161 | Tension music layer that rises with the wave count | verify: studio: evidence T299 (test PASS)
- [ ] T162 | UI sounds: click, hover, error, buy, level-up | verify: studio: evidence T300
- [ ] T163 | Sound mix: master, music, effects, UI sliders tested | verify: studio: evidence T301
- [ ] T164 | Ducking when a boss speaks or the reveal plays | verify: studio: evidence T302

## S. More sound
- [ ] T165 | Ambient loop for the lobby (lamp hum, distant clock) | verify: studio: evidence T303
- [ ] T166 | Quest complete sound and a gentle reward chime | verify: studio: evidence T304
- [ ] T183 | Achievement sound (distinct from reward chime) | verify: studio: evidence T305
- [ ] T184 | Footstep sounds for the trainer avatar on each stage material | verify: studio: evidence T306
- [ ] T187 | Sound priority list: which sounds may be cut when too many play at once | verify: studio: evidence T309 (test PASS)

# 6. Engineering and docs

## J. Code health, tests and data
- [ ] T198 | Split GameClient below 150,000 characters (new modules, same behaviour) | verify: studio: evidence T320 (test PASS)
- [ ] T199 | Move balance numbers into data modules, one table per system | verify: studio: evidence T321 (test PASS)
- [ ] T200 | Strict typing on the pure modules (NumberFormat, SettingsDefaults, StageSets, MatchSim helpers) | verify: studio: evidence T322 (test PASS)
- [ ] T201 | Luau type check on every module, zero errors | verify: studio: evidence T323
- [ ] T204 | Save migration test: old profile to new template, no data loss | verify: studio: evidence T326 (test PASS)
- [ ] T205 | Memory check after 10 waves on each stage set | verify: studio: evidence T327
- [ ] T206 | Frame-time probe on Low, Default and High | verify: studio: evidence T328

## T. Quality, measurement and tests
- [ ] T232 | Automated test: every stage has lore, caption and music assigned | verify: studio: evidence T334 (test PASS)
- [ ] T233 | Automated test: every item and enemy has a localisation key | verify: studio: evidence T335 (test PASS)
- [ ] T234 | Automated test: every button has a tooltip or a clear label | verify: studio: evidence T336 (test PASS)
- [ ] T235 | Automated test: no text below 14 px on the HUD at 844x390 | verify: studio: evidence T337 (test PASS)
- [ ] T238 | Playtest script: 3 bot runs per stage set, logged to a table | verify: studio: evidence T340

## K. Documentation
- [ ] T246 | Morning report draft: what was built, what to judge, what to delete | verify: manual: evidence T348
