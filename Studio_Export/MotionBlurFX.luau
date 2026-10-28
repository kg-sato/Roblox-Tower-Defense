--!nocheck
-- MotionBlurFX: motion blur for Roblox, which has no native or directional motion blur. Standalone, client-side.
-- Source: VFX/MotionBlurFX.luau, installed as ReplicatedStorage.MotionBlurFX. Not wired into the game.
--
--   local mb = MotionBlurFX.cameraBlur()                  -- blurs the world in proportion to how fast the view turns or moves
--   mb.stop()
--   MotionBlurFX.slide(frame, UDim2.fromScale(0.5, 0.5), 0.5)   -- tweens a UI object and leaves fading echo copies while it is fast
--   MotionBlurFX.audit()                                  -- headless maths checks (frame-rate independence, caps, settings)
--
-- Camera blur: each frame, speed = view turn rate (rad/s) + a small share of camera travel (studs/s). Anything under a dead
-- zone (0.35 rad/s) gives no blur, so ordinary play stays sharp. Target = (speed - deadzone) * 2.2, capped at 8 (desktop) or
-- 4 (touch), 60% of that when Particles is Low. The size follows the target with frame-rate independent smoothing: rate 14
-- when it rises, 7 when it falls, so a whip is softened at once and clears gently. Runs at the last render priority so it
-- reads the final camera. A BlurEffect never blurs UI, only the world (measured), so UI motion gets echoes instead.
-- Reduced motion turns both off. Only one BlurEffect applies at a time (the largest wins), so this coexists with reveal blur.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local MotionBlurFX = {}

MotionBlurFX.tuning = { deadzone = 0.35, gain = 2.2, capDesktop = 8, capTouch = 4, lowFactor = 0.6, attack = 14, release = 7, travelShare = 0.02 }

local okR, RevealFX = pcall(function()
	return require(script.Parent:WaitForChild("RevealFX", 2))
end)
local function settings(over)
	local s = { flashes = true, particles = "Default", reducedMotion = false }
	if okR and RevealFX and RevealFX.settings then
		for k, v in pairs(RevealFX.settings) do
			s[k] = v
		end
	end
	if over then
		for k, v in pairs(over) do
			s[k] = v
		end
	end
	return s
end

-- frame-rate independent smoothing (the same value is reached in the same time at 30 or 120 fps)
function MotionBlurFX._smooth(current, target, rate, dt)
	return current + (target - current) * (1 - math.exp(-rate * dt))
end

function MotionBlurFX._target(speed, cap)
	local T = MotionBlurFX.tuning
	return math.clamp((speed - T.deadzone) * T.gain, 0, cap)
end

function MotionBlurFX.capFor(S, touch)
	local T = MotionBlurFX.tuning
	local cap = touch and T.capTouch or T.capDesktop
	if S.particles == "Low" then
		cap *= T.lowFactor
	end
	return cap
end

function MotionBlurFX.cameraBlur(opts)
	opts = opts or {}
	local S = settings(opts.settings)
	local touch = opts.forceTouch
	if touch == nil then
		touch = UserInputService.TouchEnabled
	end
	local handle = { stats = { peak = 0, frames = 0, off = false, cap = 0 } }
	if S.reducedMotion then
		handle.stats.off = true
		function handle.stop() end
		function handle.size()
			return 0
		end
		return handle
	end
	local T = MotionBlurFX.tuning
	local cap = MotionBlurFX.capFor(S, touch)
	handle.stats.cap = cap
	local cam = workspace.CurrentCamera
	local blur = Instance.new("BlurEffect")
	blur.Name = "MotionBlurFX"
	blur.Size = 0
	blur.Parent = cam
	local lastLook, lastPos = cam.CFrame.LookVector, cam.CFrame.Position
	local size = 0
	local name = "MotionBlurFX_" .. tostring(math.random(1, 1000000000))
	RunService:BindToRenderStep(name, Enum.RenderPriority.Last.Value, function(dt)
		dt = math.clamp(dt, 1 / 240, 1 / 15)
		local c = workspace.CurrentCamera
		local look, p = c.CFrame.LookVector, c.CFrame.Position
		local ang = math.acos(math.clamp(look:Dot(lastLook), -1, 1)) / dt
		local travel = (p - lastPos).Magnitude / dt
		lastLook, lastPos = look, p
		local target = MotionBlurFX._target(ang + travel * T.travelShare, cap)
		size = MotionBlurFX._smooth(size, target, target > size and T.attack or T.release, dt)
		blur.Size = size < 0.05 and 0 or size
		handle.stats.frames += 1
		if size > handle.stats.peak then
			handle.stats.peak = size
		end
	end)
	function handle.size()
		return blur.Size
	end
	function handle.stop()
		pcall(function()
			RunService:UnbindFromRenderStep(name)
		end)
		blur:Destroy()
	end
	return handle
end

-- UI motion blur: tween an object and leave short-lived, fading echo copies behind it while it moves fast.
function MotionBlurFX.slide(obj, goal, dur, opts)
	opts = opts or {}
	local S = settings(opts.settings)
	local tween = TweenService:Create(obj, TweenInfo.new(dur, opts.style or Enum.EasingStyle.Quint, opts.direction or Enum.EasingDirection.Out), { Position = goal })
	local handle = { tween = tween, stats = { ghosts = 0, maxAlive = 0 } }
	tween:Play()
	if S.reducedMotion then
		return handle
	end
	local maxGhosts = ({ Low = 2, Default = 4, High = 6 })[S.particles] or 4
	local alive = 0
	local lastPos, acc = obj.AbsolutePosition, 0
	local conn
	conn = RunService.Heartbeat:Connect(function(dt)
		if not obj.Parent or tween.PlaybackState ~= Enum.PlaybackState.Playing then
			conn:Disconnect()
			return
		end
		local p = obj.AbsolutePosition
		local speed = (p - lastPos).Magnitude / math.max(dt, 1 / 240)
		lastPos = p
		acc += dt
		local screenW = (obj:FindFirstAncestorOfClass("ScreenGui") and obj:FindFirstAncestorOfClass("ScreenGui").AbsoluteSize.X) or 1920
		-- spawn an echo every 20 ms while moving faster than 0.8 screen widths per second
		if speed > screenW * 0.8 and acc >= 0.02 and alive < maxGhosts then
			acc = 0
			local g = obj:Clone()
			for _, d in ipairs(g:GetDescendants()) do
				if d:IsA("LuaSourceContainer") then
					d:Destroy()
				end
			end
			g.Name = "MBGhost"
			g.Active = false
			g.ZIndex = math.max(0, obj.ZIndex - 1)
			g.Parent = obj.Parent
			alive += 1
			handle.stats.ghosts += 1
			handle.stats.maxAlive = math.max(handle.stats.maxAlive, alive)
			local props = {}
			if g:IsA("GuiObject") then
				g.BackgroundTransparency = math.clamp(obj.BackgroundTransparency + 0.55, 0, 1)
				props.BackgroundTransparency = 1
			end
			if g:IsA("TextButton") or g:IsA("TextLabel") then
				g.TextTransparency = 0.6
				props.TextTransparency = 1
			end
			if g:IsA("ImageLabel") or g:IsA("ImageButton") then
				g.ImageTransparency = 0.6
				props.ImageTransparency = 1
			end
			local t = TweenService:Create(g, TweenInfo.new(0.16, Enum.EasingStyle.Sine), props)
			t:Play()
			t.Completed:Once(function()
				alive -= 1
				g:Destroy()
			end)
		end
	end)
	return handle
end

-- Headless maths checks. Returns (report, failures).
function MotionBlurFX.audit()
	local lines, fails = {}, 0
	local function check(ok, msg)
		if not ok then
			fails += 1
			table.insert(lines, "FAIL " .. msg)
		end
	end
	-- 1. frame-rate independence: 1 s of attack toward 8 reaches the same value at 30, 60 and 144 fps
	local vals = {}
	for _, fps in ipairs({ 30, 60, 144 }) do
		local s, dt = 0, 1 / fps
		for _ = 1, fps do
			s = MotionBlurFX._smooth(s, 8, MotionBlurFX.tuning.attack, dt)
		end
		table.insert(vals, s)
	end
	check(math.abs(vals[1] - vals[3]) < 0.02 and math.abs(vals[2] - vals[3]) < 0.02, string.format("smoothing differs with frame rate (%.3f %.3f %.3f)", vals[1], vals[2], vals[3]))
	-- 2. dead zone and monotonic response
	check(MotionBlurFX._target(0.3, 8) == 0, "blur inside the dead zone")
	local prev = -1
	for sp = 0, 12, 0.5 do
		local t = MotionBlurFX._target(sp, 8)
		check(t >= prev, "response not monotonic at speed " .. sp)
		prev = t
	end
	-- 3. caps
	check(MotionBlurFX._target(99, MotionBlurFX.capFor({ particles = "Default" }, false)) == 8, "desktop cap is not 8")
	check(MotionBlurFX._target(99, MotionBlurFX.capFor({ particles = "Default" }, true)) == 4, "touch cap is not 4")
	check(math.abs(MotionBlurFX._target(99, MotionBlurFX.capFor({ particles = "Low" }, false)) - 4.8) < 1e-6, "Low particles cap is not 4.8")
	-- 4. reduced motion is inert (needs a camera, so only when one exists)
	if workspace.CurrentCamera then
		local h = MotionBlurFX.cameraBlur({ settings = { reducedMotion = true } })
		check(h.stats.off and h.size() == 0, "reduced motion did not turn camera blur off")
		check(workspace.CurrentCamera:FindFirstChild("MotionBlurFX") == nil, "reduced motion left a BlurEffect")
	end
	table.insert(lines, fails == 0 and "MOTION BLUR AUDIT PASS (frame-rate independent, dead zone, monotonic, caps 8/4/4.8, reduced motion off)" or ("MOTION BLUR AUDIT FAILURES: " .. fails))
	return table.concat(lines, "\n"), fails
end

return MotionBlurFX
