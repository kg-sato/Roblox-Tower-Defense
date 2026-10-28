--!nocheck
-- Freeze-frame harness for FXRecipes (Play, client). Each recipe is played at the board centre and frozen three times:
-- 0.05 s into the anticipation, 0.04 s into the hit (after the hit-stop) and 0.2 s into the aftermath, so a screenshot
-- can be taken at each beat. Load with:
--   loadstring(game:GetService("HttpService"):GetAsync("http://127.0.0.1:8792/harness/FXRecipes.capture.luau"))()
-- then call _G.FXT.step() once per screenshot; it returns "<recipe> frozen:<beat>", and "all done" at the end.
-- _G.FXT.report() gives the logged hit-stops, shakes, the peak and final live emitter counts against the baseline.

for _, g in game.Players.LocalPlayer.PlayerGui:GetChildren() do
	if g:IsA("ScreenGui") then
		g.Enabled = false
	end
end
local FXR = require(game.ReplicatedStorage:WaitForChild("FXRecipes"))
local shakes, stops = {}, {}
local R = FXR.new({ shake = function(a) table.insert(shakes, a) end, hitStop = function(f) table.insert(stops, f) end, settings = {} })
local function count()
	local n = 0
	for _, d in workspace:GetDescendants() do
		if d:IsA("ParticleEmitter") then
			n += 1
		end
	end
	return n
end
local T = { R = R, baseline = count(), state = "idle", i = 0, peak = 0 }
_G.FXT = T
local list = {
	{ "placement", { color = Color3.fromRGB(110, 210, 255), scale = 1.5 } },
	{ "merge", { color = Color3.fromRGB(255, 196, 90), scale = 1.5 } },
	{ "enemyDefeat", { color = Color3.fromRGB(255, 90, 90), scale = 1.5 } },
	{ "familiarHit", { color = Color3.fromRGB(186, 128, 255), scale = 1.5 } },
	{ "summonBurst", { rarity = "Legendary", scale = 1.5 } },
	{ "ultimateImpact", { color = Color3.fromRGB(255, 200, 90), scale = 1 } },
}
local DELAY = { anticipation = 0.05, hit = 0.04, aftermath = 0.2 }
local function hold(label)
	T.peak = math.max(T.peak, count())
	R.freeze(true)
	T.state, T.go = "frozen:" .. label, false
	while not T.go do
		task.wait(0.05)
	end
	R.freeze(false)
	T.state = label == "aftermath" and "done" or "running"
end
function T.step()
	if T.state == "idle" or T.state == "done" then
		T.i += 1
		local e = list[T.i]
		if not e then
			return "all done"
		end
		T.state, T.pending = "running", false
		local opts = e[2]
		opts.onBeat = function(b)
			while T.pending do
				task.wait(0.01)
			end
			T.pending = true
			task.delay(DELAY[b], function()
				hold(b)
				T.pending = false
			end)
		end
		R.play(e[1], CFrame.new(0, 1, 2), opts)
	else
		T.go = true
		task.wait(0.12)
	end
	local t0 = os.clock()
	while not tostring(T.state):find("frozen") and os.clock() - t0 < 5 do
		task.wait(0.03)
	end
	return (list[T.i] and list[T.i][1] or "?") .. " " .. T.state
end
function T.report()
	return string.format("hit-stop frames %s | shakes %s | emitters baseline %d, peak %d, now %d",
		table.concat(stops, ","), table.concat(shakes, ","), T.baseline, T.peak, count())
end
return T
