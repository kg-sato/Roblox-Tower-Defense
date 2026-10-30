--!nocheck
-- Headless checks for ReplicatedStorage.SoundFX concurrency cap (T606). Run via RunAll in Studio Edit mode.
-- SoundFX lives outside Shared, so a private copy (SoundFX + SoundCatalog + AudioIds) is cloned and required.

return function(Shared)
	local RS = game:GetService("ReplicatedStorage")
	local results, failed = {}, 0
	local function check(name, cond, detail)
		if not cond then
			failed += 1
		end
		table.insert(results, (cond and "ok   " or "FAIL ") .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
	end

	local box = Instance.new("Folder")
	for _, n in { "SoundFX", "SoundCatalog", "AudioIds" } do
		local src = RS:FindFirstChild(n)
		if src then
			src:Clone().Parent = box
		end
	end
	local SoundFX = require(box.SoundFX)
	local cat = SoundFX.catalog
	check("catalog has anticipation at priority 3", cat.anticipation and cat.anticipation.pri == 3)
	check("catalog has bell_toll at priority 2", cat.bell_toll and cat.bell_toll.pri == 2)
	check("catalog has brass_click at priority 1", cat.brass_click and cat.brass_click.pri == 1)

	local made = {}
	local function play(name)
		local s = SoundFX.play(name, { forceTouch = false })
		if s then
			table.insert(made, s)
		end
		return s
	end

	local voices = {}
	for i = 1, 8 do
		voices[i] = play("anticipation")
	end
	check("8 priority-3 voices all start", #made == 8)
	local low = play("bell_toll")
	check("priority 2 at a full cap is dropped (nil)", low == nil)
	local stopped = 0
	for _, v in voices do
		if v.Parent == nil then
			stopped += 1
		end
	end
	check("priority 2 stops none of the priority-3 voices", stopped == 0, stopped)
	check("priority 1 at a full cap is dropped", play("brass_click") == nil)

	local high = play("legendary_burst")
	check("equal priority 3 replaces exactly one older voice", high ~= nil)
	stopped = 0
	for _, v in voices do
		if v.Parent == nil then
			stopped += 1
		end
	end
	check("exactly one voice was replaced", stopped == 1, stopped)

	-- higher replaces lower: fill a fresh copy with priority 2, then play priority 3
	for _, s in made do
		if s.Parent then
			s:Destroy()
		end
	end
	box:Destroy()
	local box2 = Instance.new("Folder")
	for _, n in { "SoundFX", "SoundCatalog", "AudioIds" } do
		local src = RS:FindFirstChild(n)
		if src then
			src:Clone().Parent = box2
		end
	end
	SoundFX = require(box2.SoundFX)
	made = {}
	local lows = {}
	for i = 1, 8 do
		lows[i] = play("bell_toll")
	end
	local top = play("anticipation")
	check("priority 3 at a cap of priority 2 starts", top ~= nil)
	local gone = 0
	for _, v in lows do
		if v.Parent == nil then
			gone += 1
		end
	end
	check("priority 3 replaces one priority-2 voice", gone == 1, gone)

	for _, s in made do
		if s.Parent then
			s:Destroy()
		end
	end
	box2:Destroy()

	return (failed == 0 and "PASS" or ("FAIL (" .. failed .. ")")) .. "\n" .. table.concat(results, "\n")
end
