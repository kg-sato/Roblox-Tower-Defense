--!strict
-- Balance data: Difficulty (T199). Config re-exports these fields; edit the numbers here.
local D = {}

-- ===== Difficulty (T004): the server picks it; labels and numbers live here =====
-- hp scales enemy health, coins and gems scale kill rewards. Hard opens once the player has reached `unlockStage`. Changeable only at stage 1, before a wave.
D.DIFFICULTY = {
	Normal = { label = "Normal", desc = "The intended challenge.", unlockStage = 1, hp = 1, coins = 1, gems = 1 },
	Hard = { label = "Hard", desc = "Tougher enemies, richer rewards.", unlockStage = 10, hp = 1.6, coins = 1.4, gems = 1.25 },
}
D.DIFFICULTY_ORDER = { "Normal", "Hard" }

return D
