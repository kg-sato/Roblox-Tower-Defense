--!nocheck
-- Motion (ReplicatedStorage.Shared.Motion, 2026-10-28): the motion craft from
-- Roblox Dev/Research/VFX and Animation/Animation Craft and Capabilities.md.
--   M.follower(f, z, r, x0)  second-order follower (t3ssel8r): f = speed in Hz, z = damping (<1 wobbles, 1 settles),
--                            r = response (0 eases in, 1 instant, >1 overshoots, <0 anticipates). Numbers or vectors.
--                            :update(dt, target) -> value; :set(v) jumps.
--   M.echoGui(gui, opts)     multiples: faded copies replay where a GuiObject was gap, 2*gap ... frames ago.
--   M.echoModel(model, opts) the same for a moving Model or BasePart (merge leaps, thrown things).
--   M.pop(gui, amount, t)    squash-and-stretch pop that keeps area (x*y constant), springing back with overshoot.
--   M.reduced                set true for Reduced Motion: echoes and pops do nothing.
-- Every echo stops and cleans up by itself when its source leaves the game, or when the returned stop() is called.
local RunService = game:GetService("RunService")

local M = { reduced = false }

function M.follower(f, z, r, x0)
	local w = 2 * math.pi * f
	local k1, k2, k3 = z / (math.pi * f), 1 / (w * w), r * z / w
	local xp, y, yd = x0, x0, x0 * 0
	local o = {}
	function o:update(dt, x, xd)
		if dt <= 0 then return y end
		if xd == nil then
			xd = (x - xp) / dt
			xp = x
		end
		local k2s = math.max(k2, dt * dt / 2 + dt * k1 / 2, dt * k1) -- keeps it stable when the frame rate drops
		y = y + yd * dt
		yd = yd + (x + xd * k3 - y - yd * k1) * (dt / k2s)
		return y
	end
	function o:set(v)
		xp, y, yd = v, v, v * 0
	end
	function o:value()
		return y
	end
	return o
end

-- raise every visible transparency of a copy so it reads as a ghost (t = 0.6 -> 40% as strong as the original)
local function ghostly(root, t)
	local function f(v) return 1 - (1 - v) * (1 - t) end
	for _, o in { root, table.unpack(root:GetDescendants()) } do
		if o:IsA("LuaSourceContainer") or o:IsA("Sound") or o:IsA("Light") or o:IsA("ParticleEmitter") or o:IsA("Highlight") or o:IsA("Trail") or o:IsA("Beam") then
			o:Destroy()
		elseif o:IsA("BasePart") then
			o.Transparency = f(o.Transparency)
			o.Anchored, o.CanCollide, o.CanQuery, o.CanTouch, o.CastShadow = true, false, false, false, false
		elseif o:IsA("Decal") then
			o.Transparency = f(o.Transparency)
		elseif o:IsA("GuiObject") then
			if o.BackgroundTransparency < 1 then o.BackgroundTransparency = f(o.BackgroundTransparency) end
			if o:IsA("ImageLabel") or o:IsA("ImageButton") then o.ImageTransparency = f(o.ImageTransparency) end
			if o:IsA("TextLabel") or o:IsA("TextButton") then
				o.TextTransparency = f(o.TextTransparency)
				o.TextStrokeTransparency = f(o.TextStrokeTransparency)
			end
		elseif o:IsA("UIStroke") then
			o.Transparency = f(o.Transparency)
		end
	end
end

local function echo(src, opts, isGui)
	opts = opts or {}
	if M.reduced then return function() end end
	local n, gap = opts.count or 3, opts.gap or 2
	local fades = opts.fades or { 0.6, 0.75, 0.9 }
	local copies, hist = {}, {}
	local scale0 = (not isGui and src:IsA("Model")) and src:GetScale() or 1
	for k = 1, n do
		local was = src.Archivable
		src.Archivable = true
		local c = src:Clone()
		src.Archivable = was
		ghostly(c, fades[k] or 0.9)
		c.Name = src.Name .. "_echo"
		if isGui then
			c.ZIndex = math.max(1, src.ZIndex - 1)
			c.Visible = false
		end
		c.Parent = src.Parent
		copies[k] = { inst = c, scale = scale0 }
		if not isGui then
			if c:IsA("Model") then c:PivotTo(CFrame.new(0, -1e4, 0)) else c.CFrame = CFrame.new(0, -1e4, 0) end
		end
	end
	local conn
	local function stop()
		if conn then conn:Disconnect() conn = nil end
		for _, c in copies do c.inst:Destroy() end
		table.clear(copies)
	end
	conn = RunService.RenderStepped:Connect(function()
		if not src.Parent then stop() return end
		local h
		if isGui then
			h = { src.Position, src.Rotation, src.Size, src.Visible }
		else
			local isModel = src:IsA("Model")
			h = { isModel and src:GetPivot() or src.CFrame, isModel and src:GetScale() or 1 }
		end
		table.insert(hist, h)
		if #hist > n * gap + 1 then table.remove(hist, 1) end
		for k, c in copies do
			local p = hist[#hist - k * gap]
			if isGui then
				c.inst.Visible = p ~= nil and p[4] and src.Visible
				if p then c.inst.Position, c.inst.Rotation, c.inst.Size = p[1], p[2], p[3] end
			elseif p then
				if c.inst:IsA("Model") then
					if math.abs(p[2] - c.scale) > 0.02 then -- ScaleTo touches every part, so only when it changed
						c.inst:ScaleTo(p[2])
						c.scale = p[2]
					end
					c.inst:PivotTo(p[1])
				else
					c.inst.CFrame = p[1]
				end
			end
		end
	end)
	return stop
end

function M.echoGui(gui, opts)
	return echo(gui, opts, true)
end

function M.echoModel(model, opts)
	return echo(model, opts, false)
end

-- squash and stretch that keeps area: x grows by (1 + a) while y shrinks by 1 / (1 + a), then a spring brings both back
-- with a small overshoot. Works on Scale or Offset sizes.
function M.pop(gui, amount, t)
	if M.reduced then return end
	local base = gui:GetAttribute("PopBase") or gui.Size
	gui:SetAttribute("PopBase", base)
	local sp = M.follower(3.2, 0.45, 0, amount or 0.25) -- starts squashed, springs to 0 with ~20% overshoot
	local t0, dur = os.clock(), t or 0.6
	local conn
	conn = RunService.RenderStepped:Connect(function(dt)
		local a = sp:update(dt, 0)
		local sx, sy = 1 + a, 1 / (1 + a)
		gui.Size = UDim2.new(base.X.Scale * sx, base.X.Offset * sx, base.Y.Scale * sy, base.Y.Offset * sy)
		if os.clock() - t0 > dur then
			conn:Disconnect()
			gui.Size = base
		end
	end)
end

-- rolling counter smear (neildegracce's "900 frames" digits): while a TextLabel's number is counting, two fading
-- copies show the previous values just above it, so the digits read as rolling upward with a vertical blur. The
-- copies hide 0.12 s after the last change. reduced: a function returning true turns it off.
function M.rollSmear(lbl, reduced)
	local ghosts, hist, last = {}, {}, 0
	for k = 1, 2 do
		local g = lbl:Clone()
		for _, d in g:GetChildren() do
			if not (d:IsA("UIStroke") or d:IsA("UIGradient") or d:IsA("UITextSizeConstraint")) then d:Destroy() end
		end
		g.Name, g.Visible, g.ZIndex = lbl.Name .. "_roll", false, math.max(1, lbl.ZIndex - 1)
		g.TextTransparency = 0.45 + k * 0.2
		for _, s in g:GetChildren() do if s:IsA("UIStroke") then s.Transparency = 0.6 + k * 0.15 end end
		g.Parent = lbl.Parent
		ghosts[k] = g
	end
	lbl:GetPropertyChangedSignal("Text"):Connect(function()
		table.insert(hist, 1, lbl.Text)
		if #hist > 3 then table.remove(hist) end
		if (reduced and reduced()) or M.reduced then return end
		last = os.clock()
		local h = lbl.AbsoluteSize.Y
		for k, g in ghosts do
			local t = hist[k + 1]
			g.Visible = t ~= nil and lbl.Visible
			if t then
				g.Text = t
				g.Position = lbl.Position + UDim2.fromOffset(0, -h * 0.28 * k)
				g.Size, g.AnchorPoint, g.TextXAlignment = lbl.Size, lbl.AnchorPoint, lbl.TextXAlignment
			end
		end
		local mine = last
		task.delay(0.12, function()
			if last == mine then for _, g in ghosts do g.Visible = false end end
		end)
	end)
end

-- self-check (run with require(Motion).selfTest()): step responses behave as their dials say
function M.selfTest()
	local function run(f, z, r, dt, secs)
		local s, lo, hi = M.follower(f, z, r, 0), 0, 0
		for _ = 1, math.floor(secs / dt) do
			local y = s:update(dt, 1)
			lo, hi = math.min(lo, y), math.max(hi, y)
		end
		return s:value(), lo, hi
	end
	local v, lo, hi = run(2, 1, 0, 1 / 60, 2)
	assert(math.abs(v - 1) < 0.01 and hi < 1.01 and lo > -0.01, "critically damped: settles without overshoot")
	v, lo, hi = run(2, 0.3, 0, 1 / 60, 3)
	assert(hi > 1.2 and math.abs(v - 1) < 0.05, "underdamped: overshoots then settles")
	v, lo = run(2, 0.5, -1, 1 / 60, 2)
	assert(lo < -0.05, "negative r: anticipates (dips the wrong way first)")
	v = run(12, 0.5, 2, 1 / 10, 3)
	assert(math.abs(v - 1) < 0.05, "stable at 10 fps with a fast spring")
	return "Motion selfTest ok"
end

return M
