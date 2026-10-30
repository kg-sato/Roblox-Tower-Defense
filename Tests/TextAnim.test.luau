--!nocheck
-- Checks for Shared.TextAnim (T188) and its textAnim setting. Run via Tests/RunAll or:
--   return loadstring(game:GetService("HttpService"):GetAsync("http://127.0.0.1:8796/TextAnim.test.luau"))()(game.ReplicatedStorage.Shared)

return function(Shared)
	local T = require(Shared.TextAnim)
	local S = require(Shared.SettingsDefaults)
	local results, failed = {}, 0
	local function check(name, cond, detail)
		if not cond then
			failed += 1
		end
		table.insert(results, (cond and "ok   " or "FAIL ") .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
	end

	-- setting
	check("textAnim default is full", S.defaults.textAnim == "full")
	check("textAnim off, subtle, full accepted", (S.validate("textAnim", "off")) and (S.validate("textAnim", "subtle")) and (S.validate("textAnim", "full")))
	check("textAnim bogus and non-string rejected", not (S.validate("textAnim", "wild")) and not (S.validate("textAnim", true)))
	check("sanitize replaces a bad textAnim by the default", S.sanitize({ textAnim = "x" }).textAnim == "full")

	-- mode
	check("mode full by default", T.mode({}) == "full" and T.mode(nil) == "full")
	check("mode follows the setting", T.mode({ textAnim = "subtle" }) == "subtle" and T.mode({ textAnim = "off" }) == "off")
	check("reducedMotion forces off", T.mode({ reducedMotion = true, textAnim = "full" }) == "off")
	check("cinematics off forces off", T.mode({ cinematics = "off", textAnim = "full" }) == "off")
	check("strength 0, 0.4, 1", T.strength("off") == 0 and T.strength("subtle") == 0.4 and T.strength("full") == 1)

	-- pure maths
	check("duration off is 0", T.duration("typewrite", "hello", "off") == 0)
	check("typewrite duration clamped", T.duration("typewrite", "a", "full") == 0.4 and T.duration("typewrite", string.rep("a", 500), "full") == 2.5)
	check("subtle is faster than full", T.duration("typewrite", string.rep("a", 40), "subtle") < T.duration("typewrite", string.rep("a", 40), "full"))
	check("visibleAt start, middle, end", T.visibleAt(10, 0, 1) == 0 and T.visibleAt(10, 0.5, 1) == 5 and T.visibleAt(10, 2, 1) == 10)
	check("visibleAt with zero duration shows all", T.visibleAt(7, 0, 0) == 7)
	check("grapheme count handles unicode", T.graphemes("a\u{00e9}") == 2)
	check("drop starts above and ends at 0", T.dropOffset(0, 24) < -20 and T.dropOffset(1, 24) == 0)
	check("wave and shake fade to 0 at the end", T.waveOffset(1, 1, 6) == 0 and select(1, T.shakeOffset(1, 1, 6)) == 0)
	check("wave stays within amplitude", math.abs(T.waveOffset(0.26, 0, 6)) <= 6)

	-- driver on a real label (Heartbeat runs in Edit mode)
	local label = Instance.new("TextLabel")
	label.Position = UDim2.fromScale(0.5, 0.5)
	label.MaxVisibleGraphemes = -1
	local t0 = os.clock()
	T.run(label, "static caption", "typewrite", { reducedMotion = true })
	check("reduced motion: text static, shown whole, instant", label.Text == "static caption" and label.MaxVisibleGraphemes == -1 and os.clock() - t0 < 0.1)
	T.run(label, "off caption", "drop", { textAnim = "off" })
	check("textAnim off: position untouched", label.Position == UDim2.fromScale(0.5, 0.5) and label.Text == "off caption")
	t0 = os.clock()
	local h = T.run(label, "hi", "typewrite", { textAnim = "full" })
	check("typewrite takes about its duration and ends fully visible", os.clock() - t0 >= 0.3 and label.MaxVisibleGraphemes == -1 and h.mode == "full", os.clock() - t0)
	local seen = {}
	task.spawn(function()
		T.run(label, "abcdefghijklmnopqrst", "typewrite", { textAnim = "full" })
	end)
	task.wait(0.25)
	table.insert(seen, label.MaxVisibleGraphemes)
	check("typewrite is partial mid-way", seen[1] >= 0 and seen[1] < 20, seen[1])
	task.wait(0.6)
	for _, eff in { "drop", "wave", "shake" } do
		T.run(label, "motion", eff, { textAnim = "subtle" })
		check(eff .. " settles back to the home position", label.Position == UDim2.fromScale(0.5, 0.5) and label.MaxVisibleGraphemes == -1)
	end
	T.setSettings({ reducedMotion = true })
	T.run(label, "shared settings", "typewrite")
	check("run without a settings argument uses the shared table (reduced motion: static)", label.Text == "shared settings" and label.MaxVisibleGraphemes == -1 and T.mode(T.settings) == "off")
	T.setSettings({})
	label:Destroy()

	return (failed == 0 and "PASS" or ("FAIL (" .. failed .. ")")) .. "\n" .. table.concat(results, "\n")
end
