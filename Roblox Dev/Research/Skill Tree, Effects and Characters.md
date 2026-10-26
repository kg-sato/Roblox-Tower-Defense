# Skill Tree, Effects and Characters

Researched 2026-10-24 from the screenshots in this folder. Related: [[Screenshot Analysis]], [[Magical Roll Animation Playbook]], [[Animation and Juice Playbook]], [[Game Design Doc]], [[Systems]], [[Blender Cinematic Pipeline]]

## What I looked at
[[fruit-hex-upgrade-tree.png]] (the honeycomb tree), [[pet-rebirth-panel-gem-upgrades.png]], [[duel-weapon-view-level-up.png]], [[fishing-upgrades-rods-stalls.png]], and the Sol's aura viewer shots ([[aura-view-hades-summoning-circle.png]], [[aura-view-origin-blue-vortex.png]] and others listed in [[Magical Roll Animation Playbook]]). The "skill tree" in your attachments is the honeycomb in [[fruit-hex-upgrade-tree.png]]; the others are plain upgrade panels. Say so if you meant a different image.

## The honeycomb tree: what it does, and what we copied
From [[fruit-hex-upgrade-tree.png]]:
- A **Start** hexagon in the middle; every purchase must touch one you already own, so the tree grows outward.
- Each open hexagon shows an **icon, a name, a level number and a cost**. Owned ones are blue; category entry points are orange and say "Open".
- **Locked hexagons are blank "?"**, which shows there is more to come without spoiling it.
- A red **notification badge** (a "1") on a node that can be bought now.
- The world behind is **blurred**, with a coin counter on the left and a big **Close** button at the bottom, plus a success line at the top ("Placed successfully").
- Weakness I could see: labels overlap the icons. We use a dark name plate under the icon instead.

What we built (all numbers are ours, to tune):
- 19 hexagons: Start, 6 inner (one per theme), 6 straight-out, 6 in-between "hybrid" nodes. A node unlocks when any touching node is owned, which gives the same outward growth.
- **Skill Points (SP)** are a separate currency from coins and gems: +1 per trainer level, +1 per boss kill, +2 at the end of the tutorial. Coins stay for per-pet upgrades; SP are for permanent run-wide effects. Cost is `base x ceil((level+1)/2)`.
- Themes: damage (Sharp Claws, Heavy Hitter, Critical Eye, Haste Aura), economy (Coin Magnet, Gem Finder, Merge Bonus, Fast Learner), safety/stakes (Crystal Armor, Boss Clock, Streak Guard), ultimate (Quick Charge, Mega Ultimate, Ult Refund), rolling (Lucky Charm, Gem Discount, Pity Shortcut, Double Hatch).
- Select a node to read its effect, then press BUY (fewer mis-taps on phones than buying on tap). Red badge on the rail button shows unspent SP.
- No paid shortcut for SP, so nothing here is a paid random item.

Ideas not built yet: connecting lines between owned nodes, per-world trees, a respec button (should cost something), a "next best node" hint for new players.

## Effects worth building next (from the aura viewer)
All of these are VFX made of parts, particles and beams, per [[Magical Roll Animation Playbook]]; none needs a skeleton.
1. **Ground rune circle** with rotating rings and glyphs ([[aura-view-hades-summoning-circle.png]], [[aura-view-ethereal-rune-rings.png]]). Used now in the ultimate.
2. **Vortex rings** tilted around the character ([[aura-view-origin-blue-vortex.png]]). Candidate for Epic hatches.
3. **Light pillars and colour beams** ([[aura-view-sirius-color-beams.png]]).
4. **Orbiting props**: cubes, swords, crystals ([[aura-view-matrix-cubes.png]], [[aura-view-starscourge-radiant-crystals.png]]). Used for tier 3+ pets.
5. **Name plate with odds and rarity word** in a themed style ([[aura-view-hades-summoning-circle.png]]: name, "1 in 6,666,666", MYTHIC). Used in our reveal.
6. **Environment takeover** for the top rarities ([[sols-roll-red-environment-takeover.png]]): tint the whole world. Needs the Flashes setting handled.
7. Lightning arcs (seen on the Origin aura): used between pets and the power orb in the ultimate.

## Characters to add
Current: 7 pets (Ember, Sprout, Zap, Frostling, Boulder, Volt Fox, Star Drake), 4 enemies. Grouping them so the collection reads as families, and so evolution has a clear identity:
- Families by element: Fire, Nature, Storm, Frost, Earth, Cosmic. Each family gets one Common, one Rare/Epic, one Legendary at launch.
- **Evolution look by tier** (already in code as "coolness"): T1 plain body; T2 accent gem; T3 glowing ring and light; T4 orbiting orbs and sparkles; T5 halo, aura, light pillar. Rarity adds the same steps earlier. Common T1 stays boring on purpose.
- Boss ideas (one per world): a crown of spikes, a shield phase, and a telegraphed ground slam, matching the existing Master Plan boss notes.
- Collection index with silhouettes for undiscovered pets and a "Replay hatch" button, as the aura viewer does ([[aura-view-hades-summoning-circle.png]] has "Replay Cutscene").

## Honest limits
- The tree screenshot is one game's UI at one moment; I copied structure, not art, and the numbers are mine.
- I cannot judge whether the tree "feels" good; that needs your play time.
- Current characters are procedural primitives and look crude up close (seen in a screenshot of the hatch reveal). The final look needs modelled assets: see [[Blender Cinematic Pipeline]].
