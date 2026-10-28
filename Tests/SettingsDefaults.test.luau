--!nocheck
-- Headless checks for ReplicatedStorage.Shared.SettingsDefaults. Run in Studio (Edit mode) with execute_luau:
--   local body = game:GetService("HttpService"):GetAsync("http://127.0.0.1:8792/SettingsDefaults.test.luau")
--   return loadstring(body)()(game.ReplicatedStorage.Shared)
-- Returns a report string; the first line says PASS or FAIL.

return function(Shared)
	local S = require(Shared.SettingsDefaults)
	local results, failed = {}, 0
	local function check(name, cond, detail)
		if not cond then
			failed += 1
		end
		table.insert(results, (cond and "ok   " or "FAIL ") .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
	end
	local function ok(key, value)
		return (S.validate(key, value))
	end

	-- defaults pass their own rules
	local allDefaultsValid = true
	for k, v in S.defaults do
		if not ok(k, v) then
			allDefaultsValid = false
		end
	end
	check("every default passes validation", allDefaultsValid)
	check("copyDefaults is a separate table", S.copyDefaults() ~= S.defaults)

	-- accepted values
	check("volume in range accepted", ok("musicVolume", 0.5))
	check("boolean accepted", ok("flashes", false))
	check("enum accepted", ok("particles", "low"))
	local _, clamped = S.validate("sfxVolume", 7)
	check("volume above range is clamped to 1", clamped == 1, clamped)
	local _, low = S.validate("sfxVolume", -3)
	check("volume below range is clamped to 0", low == 0, low)

	-- rejected values
	check("unknown key rejected", not ok("godMode", true))
	check("non-string key rejected", not ok(5, true))
	check("table key rejected", not ok({}, true))
	check("string for a boolean rejected", not ok("flashes", "yes"))
	check("number for a boolean rejected", not ok("reducedMotion", 1))
	check("string for a number rejected", not ok("musicVolume", "loud"))
	check("NaN rejected", not ok("musicVolume", 0 / 0))
	check("inf rejected", not ok("sfxVolume", math.huge))
	check("table value rejected", not ok("musicVolume", {}))
	check("nil value rejected", not ok("shake", nil))
	check("enum outside the list rejected", not ok("particles", "ultra"))
	check("enum wrong type rejected", not ok("backdrop", 3))
	check("numberFormat bogus rejected", not ok("numberFormat", "roman"))
	check("cinematics short accepted", ok("cinematics", "short"))
	check("cinematics bogus rejected", not ok("cinematics", "epic"))
	check("cinematics default is full", S.defaults.cinematics == "full")

	-- sanitize
	local s = S.sanitize({ musicVolume = 99, flashes = "x", bogus = 1, particles = "high", backdrop = false })
	check("sanitize clamps numbers", s.musicVolume == 1, s.musicVolume)
	check("sanitize replaces a bad boolean by the default", s.flashes == S.defaults.flashes)
	check("sanitize keeps a good enum", s.particles == "high")
	check("sanitize replaces a bad enum by the default", s.backdrop == S.defaults.backdrop)
	check("sanitize drops unknown keys", s.bogus == nil)
	local fromNil = S.sanitize(nil)
	local same = true
	for k, v in S.defaults do
		if fromNil[k] ~= v then
			same = false
		end
	end
	check("sanitize(nil) gives the defaults", same)
	check("sanitize of a non-table gives the defaults", S.sanitize("hack").flashes == S.defaults.flashes)

	-- rate limit
	local last = {}
	local p, q = {}, {}
	check("first save allowed", S.allowSave(last, p, 100))
	check("second save within a second refused", not S.allowSave(last, p, 100.5))
	check("a refused save does not move the clock", not S.allowSave(last, p, 100.9))
	check("save after the gap allowed", S.allowSave(last, p, 101.1))
	check("another player is limited separately", S.allowSave(last, q, 100.2))

	return (failed == 0 and "PASS" or ("FAIL (" .. failed .. ")")) .. "\n" .. table.concat(results, "\n")
end
