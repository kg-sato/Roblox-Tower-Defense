--!strict
-- Shared.Strings (T087): one table of player-facing names and one-line blurbs for familiars, enemies, items (upgrades),
-- status effects and skill nodes. Pure data; Tests/Strings.test.luau checks that every id in Config has a key and that
-- familiar names match Config.PETS[id].name. Blurbs are short, plain, for tooltips and lists. Add a new id here when you
-- add it to Config (the test fails otherwise).

export type Entry = { name: string, blurb: string }

local Strings = {}

Strings.familiars = {
	Ember = { name = "Ember", blurb = "A small flame that scorches what it touches." },
	Zap = { name = "Moth-Lantern", blurb = "Shows what hides in the fog." },
	BrassHound = { name = "Brass Hound", blurb = "Harries enemies with quick clockwork bites." },
	Sentinel = { name = "Sentinel", blurb = "Breaks armour with heavy blows." },
	Frostling = { name = "Frostling", blurb = "Chills enemies and slows them down." },
	Boulder = { name = "Gargoyle", blurb = "Crushes whatever stands in its range." },
	Ward = { name = "Ward", blurb = "Guards the lane and shields nearby friends." },
	Archivist = { name = "Archivist", blurb = "Hastens the attacks of friends close by." },
	Mourner = { name = "Mourner", blurb = "Hushes enemies so they cannot act." },
	VoltFox = { name = "Mirror Chorister", blurb = "Echoes each attack a second time." },
	StarDrake = { name = "Star Drake", blurb = "Calls falling stars on a crowd." },
	GreyVeilWraith = { name = "Grey Veil Wraith", blurb = "Drains the life of what it hits." },
	CantorVesper = { name = "Cantor Vesper", blurb = "Sings a hymn that strengthens the choir." },
	DameOrrery = { name = "Dame Orrery", blurb = "Rewinds the hour for those she guards." },
	TheLamplighter = { name = "The Lamplighter", blurb = "Kindles every lantern on the board." },
	VeilWalker = { name = "Veil Walker", blurb = "Steps through the veil to strike unseen." },
	ConstableWren = { name = "Constable Wren", blurb = "Whistles to call enemies out of line." },
	MadamQuill = { name = "Madam Quill", blurb = "Annotates a foe so it takes more damage." },
	CogWarden = { name = "The Cog-Warden", blurb = "Locks the step of enemies in the lane." },
	FerrymanOfFog = { name = "The Ferryman of Fog", blurb = "Carries enemies back across the water." },
} :: { [string]: Entry }

Strings.enemies = {
	Grunt = { name = "Grunt", blurb = "Plain and steady. Walks the lane." },
	Swift = { name = "Swift", blurb = "Fast and fragile. Fog-born." },
	FogWisp = { name = "Fog Wisp", blurb = "Very quick. Slips through the fog." },
	Parishioner = { name = "Parishioner", blurb = "Slow and tough. Hollow-armoured." },
	Crow = { name = "Crow", blurb = "Fast flier. Perches before it strikes." },
	Thief = { name = "Thief", blurb = "Quick. Steals a lamp if it gets close." },
	Boss = { name = "Boss", blurb = "A great shape in the lane. Defeat it before it escapes." },
	Tank = { name = "Tank", blurb = "Slow, brass-plated, very hard to stop." },
} :: { [string]: Entry }

-- items = the three upgrades a familiar can carry
Strings.items = {
	Power = { name = "Power", blurb = "More damage on every level." },
	Haste = { name = "Haste", blurb = "Attacks come faster on every level." },
	Crit = { name = "Crit", blurb = "A chance to hit for heavy damage." },
} :: { [string]: Entry }

Strings.statuses = {
	burn = { name = "Burn", blurb = "Takes damage over time." },
	chill = { name = "Chill", blurb = "Moves slower." },
	hush = { name = "Hush", blurb = "Cannot use its special." },
	mark = { name = "Mark", blurb = "Takes extra damage." },
	stun = { name = "Stun", blurb = "Stops for a moment." },
} :: { [string]: Entry }

Strings.skills = {
	Start = { name = "Start", blurb = "Your journey begins here." },
	Claws = { name = "Sharp Claws", blurb = "More damage for every familiar." },
	Magnet = { name = "Coin Magnet", blurb = "More coins from monsters." },
	Armor = { name = "Crystal Armor", blurb = "More crystal health." },
	Charge = { name = "Quick Charge", blurb = "Ultimate needs one fewer kill." },
	Charm = { name = "Lucky Charm", blurb = "Better luck on rolls." },
	Finder = { name = "Gem Finder", blurb = "More gems from monsters." },
	Heavy = { name = "Heavy Hitter", blurb = "More damage to bosses." },
	Merger = { name = "Merge Bonus", blurb = "Merging pays coins." },
	Clock = { name = "Boss Clock", blurb = "More seconds before a boss escapes." },
	Mega = { name = "Mega Ultimate", blurb = "Stronger ultimate." },
	Discount = { name = "Gem Discount", blurb = "Rolls cost less." },
	Guard = { name = "Streak Guard", blurb = "Ignore a leak for your streak." },
	Eye = { name = "Critical Eye", blurb = "More crit chance." },
	Learner = { name = "Fast Learner", blurb = "More trainer experience." },
	Refund = { name = "Ult Refund", blurb = "Start with ultimate charge after casting." },
	Pity = { name = "Pity Shortcut", blurb = "Guaranteed Epic comes sooner." },
	Double = { name = "Double Hatch", blurb = "A chance for a free bonus familiar." },
	Haste = { name = "Haste Aura", blurb = "Faster attacks for every familiar." },
} :: { [string]: Entry }

-- Strings.get("familiars", "Ember") -> Entry; unknown ids give a readable fallback so the UI never shows nil
function Strings.get(kind: string, id: string): Entry
	local group = (Strings :: any)[kind]
	local e = type(group) == "table" and group[id] or nil
	if e then
		return e
	end
	return { name = tostring(id), blurb = "" }
end

function Strings.name(kind: string, id: string): string
	return Strings.get(kind, id).name
end

return Strings
