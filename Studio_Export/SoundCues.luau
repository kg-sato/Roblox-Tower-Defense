--!nocheck
-- SoundCues (T630): the overnight cue set (VFX/sfx/MANIFEST.md) wired into SoundFX without touching GameClient.
-- Installed as ReplicatedStorage.SoundCues. SoundFX merges `catalog` and `ids` into its own and runs every play() through
-- `resolve`, so old call sites get the new sounds by alias. Only 8 of the 30 new cues are uploaded (`ids`); every other new cue
-- resolves to an existing cue (`fallback`) or to nothing, so no call ever points at a missing file.
-- SoundCuesClient (StarterPlayerScripts) fires the event driven cues. Ear quality is UNVERIFIED.

local M = {}

-- dur from VFX/sfx/MANIFEST.md; vol/pri/jit chosen like SoundCatalog (pri 1 UI, 2 effect, 3 hero)
M.catalog = {
	ui_click_soft = { dur = 0.10, vol = 0.50, pri = 1, jit = 0.03 },
	ui_hover = { dur = 0.07, vol = 0.30, pri = 1, jit = 0.03 },
	ui_error = { dur = 0.30, vol = 0.50, pri = 1, jit = 0.02 },
	ui_buy = { dur = 0.80, vol = 0.55, pri = 1, jit = 0.02 },
	ui_quest = { dur = 1.35, vol = 0.60, pri = 2, jit = 0 },
	ui_achievement = { dur = 2.40, vol = 0.70, pri = 2, jit = 0 },
	ui_levelup = { dur = 2.80, vol = 0.75, pri = 3, jit = 0 },
	step_trainer = { dur = 0.16, vol = 0.30, pri = 1, jit = 0.08 },
	step_parishioner = { dur = 0.22, vol = 0.30, pri = 1, jit = 0.08 },
	step_wisp = { dur = 0.30, vol = 0.25, pri = 1, jit = 0.08 },
	step_sentinel = { dur = 0.60, vol = 0.40, pri = 1, jit = 0.05 },
	step_crow = { dur = 0.25, vol = 0.30, pri = 1, jit = 0.08 },
	step_thief = { dur = 0.12, vol = 0.25, pri = 1, jit = 0.08 },
	hit_parishioner = { dur = 0.20, vol = 0.35, pri = 1, jit = 0.08 },
	hit_wisp = { dur = 0.50, vol = 0.30, pri = 1, jit = 0.08 },
	hit_sentinel = { dur = 0.72, vol = 0.40, pri = 1, jit = 0.05 },
	hit_crow = { dur = 0.25, vol = 0.35, pri = 1, jit = 0.08 },
	hit_thief = { dur = 0.20, vol = 0.35, pri = 1, jit = 0.08 },
	boss_intro_unbound = { dur = 4.00, vol = 0.80, pri = 3, jit = 0 },
	boss_intro_automaton = { dur = 3.80, vol = 0.80, pri = 3, jit = 0 },
	boss_intro_echo = { dur = 4.60, vol = 0.80, pri = 3, jit = 0 },
	boss_intro_regent = { dur = 5.10, vol = 0.85, pri = 3, jit = 0 },
	boss_intro_clockmaker = { dur = 5.20, vol = 0.90, pri = 3, jit = 0 },
	familiar_place = { dur = 0.60, vol = 0.55, pri = 1, jit = 0.04 },
	reveal_common = { dur = 1.32, vol = 0.60, pri = 2, jit = 0 },
	reveal_rare = { dur = 2.04, vol = 0.70, pri = 2, jit = 0 },
	reveal_epic = { dur = 2.96, vol = 0.80, pri = 2, jit = 0 },
	reveal_legendary = { dur = 4.08, vol = 0.90, pri = 3, jit = 0 },
	reveal_mythic = { dur = 5.00, vol = 0.95, pri = 3, jit = 0 },
	reveal_celestial = { dur = 6.02, vol = 1.00, pri = 3, jit = 0 },
}

-- uploaded 2026-10-29 (VFX/ASSETS.md); moderation state unchecked
M.ids = {
	ui_click_soft = 111673041051226,
	ui_error = 109055487674361,
	ui_buy = 138935227500698,
	ui_levelup = 89524906675033,
	familiar_place = 135206057906557,
	reveal_legendary = 100672209997679,
	reveal_celestial = 114164363714017,
	boss_intro_clockmaker = 129659992794232,
}

-- old call sites that now play a new cue (only used when the new cue is uploaded)
M.alias = { brass_click = "ui_click_soft", place_thud = "familiar_place", merge_fail = "ui_error" }

-- new cue without an upload -> existing cue; false = stay silent
M.fallback = {
	ui_hover = false, ui_quest = "milestone", ui_achievement = "discovery",
	step_trainer = false, step_parishioner = false, step_wisp = false, step_sentinel = false, step_crow = false, step_thief = false,
	hit_parishioner = "enemy_hit", hit_wisp = "enemy_hit", hit_sentinel = "enemy_hit", hit_crow = "enemy_hit", hit_thief = "enemy_hit",
	boss_intro_unbound = "bell_toll", boss_intro_automaton = "iron_clank", boss_intro_echo = "bell_toll", boss_intro_regent = "bell_toll",
	reveal_common = "common", reveal_rare = "rare", reveal_epic = "epic", reveal_mythic = "legendary_burst",
}

-- the cue group that the UI volume slider (T605) scales
local UI = { brass_click = true, card_flip = true, menu_open = true, menu_close = true, ui_click = true, coin_clink = true, spotlight = true }
function M.isUI(name)
	return UI[name] == true or string.sub(name, 1, 3) == "ui_"
end

-- the name SoundFX should really play, or nil for silence. `oldCatalog` is SoundCatalog (old names always exist as files).
function M.resolve(name, oldCatalog)
	local a = M.alias[name]
	if a and M.ids[a] then
		return a
	end
	if oldCatalog[name] or M.ids[name] then
		return name
	end
	if M.catalog[name] then
		return M.fallback[name] or nil
	end
	return name -- unknown: let SoundFX warn as before
end

function M.native(name)
	return M.ids[name] ~= nil
end

local HIT = { Parishioner = "hit_parishioner", FogWisp = "hit_wisp", Tank = "hit_sentinel", Crow = "hit_crow", Thief = "hit_thief" }
local STEP = { Parishioner = "step_parishioner", FogWisp = "step_wisp", Tank = "step_sentinel", Crow = "step_crow", Thief = "step_thief" }
function M.hitCue(kind)
	return HIT[kind] or "enemy_hit"
end
function M.stepCue(kind)
	return STEP[kind]
end
function M.bossCue(bossId)
	return "boss_intro_" .. string.lower(tostring(bossId))
end
-- merge cue ladder like MergeCore.cuesFor: the pair WAS tier-1 (a tier 1+1 pair plays merge_1)
function M.mergeCue(tier)
	return "merge_" .. math.clamp((tonumber(tier) or 2) - 1, 1, 8)
end
function M.revealCue(rarity)
	return "reveal_" .. string.lower(tostring(rarity))
end

-- music duck under a reveal: { amount, seconds } by rarity (T605)
M.revealDuck = { Common = { 0.15, 1.2 }, Rare = { 0.25, 1.8 }, Epic = { 0.4, 2.5 }, Legendary = { 0.55, 3.2 }, Mythic = { 0.6, 3.8 }, Celestial = { 0.7, 4.5 } }

-- Sound mix (T605): master scales everything, then music / effects / UI sliders. Called from SettingsPanel and on server sync.
function M.applyMix(s, SoundFX, Music)
	local n = function(v, d)
		return type(v) == "number" and v or d
	end
	local master = n(s.masterVolume, 1)
	if SoundFX then
		SoundFX.setVolumes({ master = master, sfx = n(s.sfxVolume, 0.8), ui = n(s.uiVolume, 1) })
	end
	if Music then
		Music.setVolumes({ master = master, music = n(s.musicVolume, 0.7) })
	end
end

M.log = {} -- { cue, played, native, t } for the Play evidence
function M.fire(SoundFX, cue, opts)
	local played = M.resolve(cue, SoundFX.catalogOld or SoundFX.catalog)
	table.insert(M.log, { cue = cue, played = played, native = M.native(cue), t = os.clock() })
	if played then
		SoundFX.play(played, opts)
	end
	return played
end

return M
