--!strict
-- Balance data: Economy (T199). Config re-exports these fields; edit the numbers here.
local D = {}

D.START_COINS = 30
D.START_GEMS = 60 -- was 30; the tutorial forces 3 rolls, so this stays 3 x ROLL_COST
D.CRYSTAL_HP = 20
D.TIER_MAX = 8 -- tiers 6 to 8 are the long game: tier t needs 3^(t-1) tier-1 units (2,187 for tier 8)
D.TIER_MULT = 3.5
D.ULT_NEED = 10
D.ULT_DAMAGE = 60
D.SPAWN_GAP = 0.45
D.STAGE_BREAK = 1.2
D.BOSS_EVERY = 5
D.BOSS_TIME = 35
D.OVERRUN_STAGE_LOSS = 2
D.OVERRUN_COIN_LOSS = 0.3
D.ROLL_COST = 20 -- was 10; 2026-10-29 tuning: with 16 familiars the full bot cleared 25 stages in 6 min, now a mean of 10.6 min over 10 seeds
D.PITY_EVERY = 20 -- guaranteed Epic or better within this many rolls
D.UPGRADE_MAX = 5
D.CRIT_CAP = 0.75 -- crit chance never exceeds this, whatever upgrades and skills add
D.RESPEC_COST = 50 -- gems for resetting the skill tree
D.RESPEC_COOLDOWN = 120 -- sim seconds between respecs in one run

return D
