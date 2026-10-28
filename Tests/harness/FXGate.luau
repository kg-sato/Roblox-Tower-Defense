--!nocheck
-- Effect quality gate, Studio Play (client). Plays each FXRecipes recipe once, 3.5 s apart at the board centre, and
-- samples every frame: live ParticleEmitters (whole workspace, minus the idle baseline), parts left in the effect
-- folders, and how long until both are back to the baseline (clean-up time). Fails a recipe that goes over the emitter
-- cap or leaves parts behind after 6 s. Pixel measures (peak luminance, hot area) come from a screen recording of the
-- same run, analysed by tools/fx_gate_frames.py. Used as a ModuleScript; call .run() and read the returned table.

local CAP = 24 -- live emitters one recipe may add on top of the idle scene (FXK.CAP default 20 bursts + a little headroom)
local GAP = 3.5
local RunService = game:GetService("RunService")

local M = {}

function M.run()
	for _, g in game.Players.LocalPlayer.PlayerGui:GetChildren() do
		if g:IsA("ScreenGui") then
			g.Enabled = false
		end
	end
	local FXR = require(game.ReplicatedStorage:WaitForChild("FXRecipes"))
	local R = FXR.new({ settings = {} })
	local function emitters()
		local n = 0
		for _, d in workspace:GetDescendants() do
			if d:IsA("ParticleEmitter") then
				n += 1
			end
		end
		return n
	end
	local function fxParts()
		local n = 0
		for _, name in { "FXRecipes", "FlipbookFX" } do
			local f = workspace:FindFirstChild(name)
			if f then
				for _, d in f:GetDescendants() do
					if d:IsA("BasePart") then
						n += 1
					end
				end
			end
		end
		return n
	end
	local e0, p0 = emitters(), fxParts()
	local rows = {}
	local recipes = {
		{ "placement", { color = Color3.fromRGB(110, 210, 255), scale = 1.5 } },
		{ "merge", { color = Color3.fromRGB(255, 196, 90), scale = 1.5 } },
		{ "enemyDefeat", { color = Color3.fromRGB(255, 90, 90), scale = 1.5 } },
		{ "familiarHit", { color = Color3.fromRGB(186, 128, 255), scale = 1.5 } },
		{ "summonBurst", { rarity = "Legendary", scale = 1.5 } },
		{ "ultimateImpact", { color = Color3.fromRGB(255, 200, 90), scale = 1 } },
	}
	local start = os.clock()
	for i, r in recipes do
		local t0 = os.clock()
		R.play(r[1], CFrame.new(0, 1, 2), r[2])
		local peakE, peakP, clean = 0, 0, nil
		while os.clock() - t0 < GAP do
			RunService.RenderStepped:Wait()
			local e, p = emitters() - e0, fxParts() - p0
			peakE, peakP = math.max(peakE, e), math.max(peakP, p)
			if not clean and os.clock() - t0 > 0.1 and e <= 0 and p <= 0 then
				clean = os.clock() - t0
			end
		end
		table.insert(rows, { name = r[1], at = t0 - start, peakEmitters = peakE, peakParts = peakP, cleanup = clean })
	end
	task.wait(6 - GAP)
	local leftover = fxParts() - p0
	local ok = true
	for _, row in rows do
		row.overCap = row.peakEmitters > CAP
		row.leaves = row.cleanup == nil
		ok = ok and not row.overCap and not row.leaves
	end
	return { ok = ok and leftover <= 0, rows = rows, cap = CAP, baseline = { emitters = e0, parts = p0 }, leftover = leftover }
end

return M
