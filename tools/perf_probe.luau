--!nocheck
-- perf_probe (T205): frame-time and memory probe for Studio Play, run in the CLIENT datamodel via execute_luau:
--   return loadstring(HttpService:GetAsync("http://127.0.0.1:8796/../tools/perf_probe.luau"))()  -- or paste the file body
-- Returns a function probe(opts) -> string. opts = { label = "set1", seconds = 3, levels = { 1, 5, 10 } }
-- levels are QualityLevel numbers: 1 = Low, 5 = Default (Automatic-ish mid), 10 = High. For each level the probe sets
-- settings().Rendering.QualityLevel, waits 0.7 s for it to settle, averages RenderStepped dt over `seconds`, restores the old level.
-- Output line: label | level | avg ms | p95 ms | fps | total memory MB (Stats:GetTotalMemoryUsageMb) | instances (Stats.InstanceCount)
-- Studio caveat: the numbers come from the Studio editor window (not a published client); compare levels only against each other.
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local function sample(seconds)
	local dts = {}
	local c = RunService.RenderStepped:Connect(function(dt)
		dts[#dts + 1] = dt
	end)
	task.wait(seconds)
	c:Disconnect()
	table.sort(dts)
	local sum = 0
	for _, d in dts do
		sum += d
	end
	local n = #dts
	if n == 0 then
		return 0, 0, 0
	end
	return sum / n * 1000, dts[math.max(1, math.floor(n * 0.95))] * 1000, n / seconds
end

return function(opts)
	opts = opts or {}
	local seconds, levels, label = opts.seconds or 3, opts.levels or { 1, 5, 10 }, opts.label or "?"
	local rendering = settings().Rendering
	local before = rendering.QualityLevel
	local lines = {}
	for _, lv in levels do
		local ok = pcall(function()
			rendering.QualityLevel = lv
		end)
		task.wait(0.7)
		local avg, p95, fps = sample(seconds)
		lines[#lines + 1] = string.format("%s | L%02d%s | %.2f ms | %.2f ms p95 | %.0f fps | %.0f MB | %d inst", label, lv, ok and "" or " (not set)", avg, p95, fps, Stats:GetTotalMemoryUsageMb(), Stats.InstanceCount)
	end
	pcall(function()
		rendering.QualityLevel = before
	end)
	return table.concat(lines, "\n")
end
