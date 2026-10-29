--!nocheck
-- Headless checks for ReplicatedStorage.Shared.LoreFragments (T071). Run in Studio (Edit mode) with execute_luau:
--   local body = game:GetService("HttpService"):GetAsync("http://127.0.0.1:8792/LoreFragments.test.luau")
--   return loadstring(body)()(game.ReplicatedStorage.Shared)
-- Returns a report string; the first line says PASS or FAIL.

return function(Shared)
	local L = require(Shared.LoreFragments)
	local results, failed = {}, 0
	local function check(name, got, want)
		local ok = got == want
		if not ok then
			failed += 1
		end
		table.insert(results, (ok and "ok   " or "FAIL ") .. name .. " -> " .. tostring(got) .. (ok and "" or " (want " .. tostring(want) .. ")"))
	end

	check("60 fragments in total", L.count(), 60)

	local perChapter, seen, dup, badRange, tooLong, empty = {}, {}, 0, 0, 0, 0
	for _, f in L.list do
		perChapter[f.chapter] = (perChapter[f.chapter] or 0) + 1
		if seen[f.id] then
			dup += 1
		end
		seen[f.id] = true
		if f.stage < (f.chapter - 1) * 5 + 1 or f.stage > f.chapter * 5 then
			badRange += 1
		end
		local words = 0
		for _ in string.gmatch(f.text, "%S+") do
			words += 1
		end
		if words > 25 then
			tooLong += 1
		end
		if words == 0 or f.kind == "" then
			empty += 1
		end
	end
	for c = 1, 5 do
		check("chapter " .. c .. " has 12", perChapter[c], 12)
	end
	check("ids are unique", dup, 0)
	check("every fragment's stage lies inside its chapter", badRange, 0)
	check("no fragment longer than 25 words", tooLong, 0)
	check("no empty text or kind", empty, 0)

	local missing = 0
	for st = 1, 25 do
		if #L.forStage(st) == 0 then
			missing += 1
		end
	end
	check("every stage 1 to 25 has at least one fragment", missing, 0)

	check("chapterForStage(1) = 1", L.chapterForStage(1), 1)
	check("chapterForStage(5) = 1", L.chapterForStage(5), 1)
	check("chapterForStage(6) = 2", L.chapterForStage(6), 2)
	check("chapterForStage(5.9) floors to chapter 1", L.chapterForStage(5.9), 1)
	check("chapterForStage(25) = 5", L.chapterForStage(25), 5)
	check("chapterForStage(0) is nil", L.chapterForStage(0), nil)
	check("chapterForStage(26) is nil", L.chapterForStage(26), nil)
	check("chapterForStage(-3) is nil", L.chapterForStage(-3), nil)
	check("byId finds LF-C3-01", L.byId("LF-C3-01") ~= nil, true)
	check("byId misses an unknown id", L.byId("LF-C9-99"), nil)
	check("forStage(26) is empty", #L.forStage(26), 0)

	return (failed == 0 and "PASS" or ("FAIL (" .. failed .. ")")) .. "\n" .. table.concat(results, "\n")
end
