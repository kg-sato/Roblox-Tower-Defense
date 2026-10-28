--!nocheck
-- Headless checks for ReplicatedStorage.Shared.NumberFormat. Run in Studio (Edit mode) with execute_luau:
--   local body = game:GetService("HttpService"):GetAsync("http://127.0.0.1:8792/NumberFormat.test.luau")
--   return loadstring(body)()(game.ReplicatedStorage.Shared)
-- Returns a report string; the first line says PASS or FAIL.

return function(Shared)
	local NumberFormat = require(Shared.NumberFormat)
	local results, failed = {}, 0
	local function check(name, got, want)
		local ok = got == want
		if not ok then
			failed += 1
		end
		table.insert(results, (ok and "ok   " or "FAIL ") .. name .. " -> " .. tostring(got) .. (ok and "" or " (want " .. tostring(want) .. ")"))
	end
	local f = NumberFormat.format

	check("zero", f(0), "0")
	check("999", f(999), "999")
	check("1000", f(1000), "1K")
	check("1500", f(1500), "1.5K")
	check("999999 rolls up", f(999999), "1M")
	check("1.5M", f(1500000), "1.5M")
	check("13.66T", f(13660000000000), "13.66T")
	check("negative", f(-1500), "-1.5K")
	check("negative small", f(-7), "-7")
	check("rounds fractions", f(12.6), "13")
	check("tiny rounds to zero", f(0.2), "0")
	check("nan is zero", f(0 / 0), "0")
	check("inf is zero", f(math.huge), "0")
	check("beyond the suffix list stays in range", f(1e40):match("Dc$") ~= nil, true)
	check("grouped", f(1234567, "grouped"), "1,234,567")
	check("grouped small", f(999, "grouped"), "999")
	check("grouped round thousand", f(1000, "grouped"), "1,000")
	check("grouped negative", f(-1234567, "grouped"), "-1,234,567")
	check("scientific", f(1500, "scientific"), "1.5e3")
	check("scientific small stays plain", f(999, "scientific"), "999")
	check("scientific big", f(13660000000000, "scientific"), "1.37e13")
	check("scientific negative", f(-2500000, "scientific"), "-2.5e6")
	check("scientific zero", f(0, "scientific"), "0")
	check("unknown mode falls back to short", f(1500, "bogus"), "1.5K")

	return (failed == 0 and "PASS" or ("FAIL (" .. failed .. ")")) .. "\n" .. table.concat(results, "\n")
end
