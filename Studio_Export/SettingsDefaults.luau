--!strict
-- Player settings: the allowed keys, their defaults and the server-side validation. Pure, no Instances.
-- The client changes a setting at once and tells the server; the server only keeps values that pass `validate`.

local SettingsDefaults = {}

type Rule = { kind: "number", min: number, max: number } | { kind: "choice", values: { number } } | { kind: "boolean" } | { kind: "enum", values: { string } }

local RULES: { [string]: Rule } = {
	musicVolume = { kind = "number", min = 0, max = 1 },
	sfxVolume = { kind = "number", min = 0, max = 1 },
	flashes = { kind = "boolean" },
	reducedMotion = { kind = "boolean" },
	shake = { kind = "boolean" },
	damageNumbers = { kind = "boolean" },
	uiSize = { kind = "enum", values = { "small", "normal", "large" } },
	hideUi = { kind = "boolean" },
	particles = { kind = "enum", values = { "low", "default", "high" } },
	backdrop = { kind = "enum", values = { "moving", "still" } },
	numberFormat = { kind = "enum", values = { "short", "grouped", "scientific" } },
	gameSpeed = { kind = "choice", values = { 1, 2 } },
	cinematics = { kind = "enum", values = { "full", "short", "off" } },
}

SettingsDefaults.defaults = {
	musicVolume = 0.7,
	sfxVolume = 0.8,
	flashes = true,
	reducedMotion = false,
	shake = true,
	damageNumbers = true,
	uiSize = "normal",
	hideUi = false,
	particles = "default",
	backdrop = "moving",
	numberFormat = "short",
	gameSpeed = 1,
	cinematics = "full",
}

SettingsDefaults.MIN_SAVE_GAP = 1 -- seconds between accepted settings saves per player

function SettingsDefaults.copyDefaults(): { [string]: any }
	return table.clone(SettingsDefaults.defaults)
end

-- Returns (true, cleanValue) or (false, reason). Numbers are clamped to the range, never trusted as sent.
function SettingsDefaults.validate(key: any, value: any): (boolean, any)
	if type(key) ~= "string" then
		return false, "bad key"
	end
	local rule = RULES[key]
	if not rule then
		return false, "unknown setting"
	end
	if rule.kind == "boolean" then
		if type(value) ~= "boolean" then
			return false, "expected true or false"
		end
		return true, value
	elseif rule.kind == "choice" then
		if type(value) ~= "number" or not table.find(rule.values, value) then
			return false, "not an allowed choice"
		end
		return true, value
	elseif rule.kind == "number" then
		if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then
			return false, "expected a number"
		end
		return true, math.round(math.clamp(value, rule.min, rule.max) * 100) / 100
	else
		if type(value) ~= "string" or not table.find(rule.values, value) then
			return false, "not an allowed choice"
		end
		return true, value
	end
end

-- A whole saved table made safe: unknown keys dropped, bad or missing values replaced by the default.
function SettingsDefaults.sanitize(raw: any): { [string]: any }
	local out = SettingsDefaults.copyDefaults()
	if type(raw) == "table" then
		for key in RULES do
			local ok, clean = SettingsDefaults.validate(key, raw[key])
			if ok then
				out[key] = clean
			end
		end
	end
	return out
end

-- Fixed-step scheduling shared by the server loop and the tests: `accum` collects real time times the game speed and
-- is paid out in `tick`-sized sim steps, so 2x runs two 0.1 s steps where 1x runs one and the results stay identical.
function SettingsDefaults.stepsFor(accum: number, dt: number, speed: number, tick: number): (number, number)
	accum += dt * speed
	local steps = 0
	while accum >= tick do
		accum -= tick
		steps += 1
	end
	return steps, accum
end

-- Rate limit: one accepted save per MIN_SAVE_GAP per player. `last` maps player to the time of the last accepted save.
function SettingsDefaults.allowSave(last: { [any]: number }, player: any, now: number): boolean
	local prev = last[player]
	if prev and now - prev < SettingsDefaults.MIN_SAVE_GAP then
		return false
	end
	last[player] = now
	return true
end

return SettingsDefaults
