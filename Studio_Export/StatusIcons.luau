--!nocheck
-- StarterPlayerScripts.StatusIcons (ModuleScript, T641, 2026-10-30): image ids of the 40-icon set (UI Kit/art/icons_set, data in ids.json; decal -> image ids in VFX/ASSETS.md).
--   StatusIcons.status[kind]   -- burn / chill / stun / mark / hush (128 px)
--   StatusIcons.rarity(name)   -- image id for a rarity name (Celestial reuses the mythic icon; no uncommon familiars exist yet)
--   StatusIcons.faction(name)  -- image id for a faction name (nil for Unaligned)
--   StatusIcons.badge(parent, assetId, props) -- ImageLabel, transparent background, Fit
local I = {}
I.status = {
	burn = "rbxassetid://130600374270007", chill = "rbxassetid://112399922875818", stun = "rbxassetid://116068335264381",
	mark = "rbxassetid://127577573617964", hush = "rbxassetid://101071874097965",
}
local R = {
	Common = "rbxassetid://80975321404816", Uncommon = "rbxassetid://81971249784010", Rare = "rbxassetid://114138177982231",
	Epic = "rbxassetid://106229139435139", Legendary = "rbxassetid://86276646138853", Mythic = "rbxassetid://127254787757093",
}
R.Celestial = R.Mythic
local F = {
	["Clockwork Guild"] = "rbxassetid://116898824662849", ["Hollow Court"] = "rbxassetid://82153877503662",
	["Lantern Keepers"] = "rbxassetid://137588560007605", ["Star Choir"] = "rbxassetid://131419654901778",
}
I.currency = { coin = "rbxassetid://89013935218228", gem = "rbxassetid://88932316257839" }
I.frames = {
	"rbxassetid://138170664090489", "rbxassetid://105706560066249", "rbxassetid://75864067836379",
	"rbxassetid://127388004118831", "rbxassetid://126460826056125", "rbxassetid://96685116360654",
}
function I.rarity(name) return R[name] end
function I.faction(name) return F[name] end
function I.badge(parent, id, props)
	if not id then return nil end
	local img = Instance.new("ImageLabel")
	img.BackgroundTransparency, img.Image, img.ScaleType = 1, id, Enum.ScaleType.Fit
	for k, v in props or {} do img[k] = v end
	img.Parent = parent
	return img
end
return I
