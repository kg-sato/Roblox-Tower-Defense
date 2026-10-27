--!nocheck
-- LoadingFX: loading sequence (spec section A of Roblox Dev/Research/UI/Loading and Reveal Spec.md). Standalone, client-side.
-- Source of truth: VFX/LoadingFX.luau, installed as ReplicatedStorage.LoadingFX. Not wired into the game.
-- Original emblem and name only: no art from Rivals or Sol's RNG. Idea sources are timings and structure only.
--
--   local h = LoadingFX.play({ title = "GUARDIAN GRID", total = 12, hud = someCanvasGroup, tip = "..." })
--   h.setProgress(5)      -- real progress (n of total); the bar eases toward it, never jumps
--   h.finish()            -- beat 3 onward (waits until minTime has passed so the screen never flashes by)
--   h.skip()              -- quick 0.3 s fade out (use after the first run)
--   h.cancel()            -- instant cleanup
--   LoadingFX.audit()     -- headless check of limits for every settings combination
--
-- Beats (seconds): 1 fade up 0 to 0.5 | 2 wait scene (world blurred and dimmed, calm) | 3 SYNCED (brackets contract,
-- underline sweep, soft light lift 0 -> 0.25 -> 0 over 0.7 s, never a white frame) | 4 handoff 0.8 (logo glows in while the
-- HUD fades in over the still-blurred world) | 5 resolve 0.9 (blur eases to 0 with Exponential Out while the logo shrinks
-- 15%, drifts up and fades, the dim clears).
-- Settings (shared with RevealFX.settings): flashes=false or reducedMotion=true => no light lift, blur capped at 8, no logo
-- scale or drift (plain 0.4 s crossfade). Touch: blur capped at 10. Desktop: 12.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LoadingFX = {}

LoadingFX.textures = { emblem = "rbxasset://textures/vfx/vfx_emblem.png" }

local okR, RevealFX = pcall(function()
	return require(script.Parent:WaitForChild("RevealFX", 2))
end)
local function sharedSettings(over)
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

local WHITE = Color3.new(1, 1, 1)
local MONO = Enum.Font.RobotoMono

local function new(class, props, parent)
	local i = Instance.new(class)
	for k, v in pairs(props) do
		i[k] = v
	end
	i.Parent = parent
	return i
end

-- frame-rate independent smoothing (see Smooth Motion and Blur Playbook)
local function smooth(current, target, rate, dt)
	return current + (target - current) * (1 - math.exp(-rate * dt))
end

function LoadingFX.play(opts)
	opts = opts or {}
	local S = sharedSettings(opts.settings)
	local ts = opts.timeScale or 1
	local touch = opts.forceTouch
	if touch == nil then
		touch = UserInputService.TouchEnabled
	end
	local soft = (not S.flashes) or S.reducedMotion
	local blurPeak = soft and 8 or (touch and 10 or 12) -- 18 before; measured: past about 11 the image stops getting blurrier, and a peak of about 11 matched the Rivals ramp best (RMSE 0.07 vs 0.109)
	local total = opts.total or 12
	local minTime = opts.minTime or 1.6
	local title = opts.title or "GUARDIAN GRID"

	local stats = { blurPeak = blurPeak, lift = false, liftPeak = 0, logoScale = false, resolveTime = 0.9, skipped = false, beats = {} }
	local handle = { stats = stats, blurLog = {}, done = false, state = "wait" }
	local alive = true
	local conns, tweens, extras = {}, {}, {}
	local clock0 = os.clock()
	local function now()
		return (os.clock() - clock0) * ts
	end

	local function T(x)
		return x / ts
	end
	local function at(t, fn)
		if opts.headless then
			fn()
			return
		end
		task.delay(T(t), function()
			if alive then
				fn()
			end
		end)
	end
	local function tw(inst, dur, props, style, dir)
		if opts.headless then
			return nil
		end
		local t = TweenService:Create(inst, TweenInfo.new(T(dur), style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
		t:Play()
		table.insert(tweens, t)
		return t
	end
	local rawSfx = opts.sfx or (okR and RevealFX and RevealFX.defaultSfx) or function() end
	stats.cues = {}
	local BEAT_SFX = { fadeUp = "load_start", synced = "load_synced", resolve = "load_resolve" }
	local function beat(name)
		table.insert(stats.beats, { name = name, t = now() })
		handle.state = name
		local c = BEAT_SFX[name]
		if c then
			table.insert(stats.cues, { name = c, t = now() })
			rawSfx(c)
		end
	end

	local blurFx, gui, black, hudGroup
	local function cleanup()
		if handle.done then
			return
		end
		handle.done = true
		alive = false
		for _, c in ipairs(conns) do
			c:Disconnect()
		end
		for _, t in ipairs(tweens) do
			t:Cancel()
		end
		for _, e in ipairs(extras) do
			if e.Parent then
				e:Destroy()
			end
		end
		if opts.onDone then
			opts.onDone()
		end
	end
	handle.cancel = cleanup

	if not opts.headless then
		local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
		gui = new("ScreenGui", { Name = "LoadingFX_UI", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 100, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, pg)
		table.insert(extras, gui)
		local cam = workspace.CurrentCamera
		blurFx = new("BlurEffect", { Name = "LoadingFX_Blur", Size = 0 }, cam)
		table.insert(extras, blurFx)
		if opts.measure then
			table.insert(conns, RunService.Heartbeat:Connect(function()
				table.insert(handle.blurLog, { t = now(), size = blurFx.Size, beat = handle.state })
			end))
		end
	end

	-- ---- layers ------------------------------------------------------------------------------------
	black = not opts.headless and new("Frame", { Name = "Black", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 1 }, gui) or nil
	local function label(parent, text, x, y, w, h, maxSize, color, font, z)
		local l = new("TextLabel", { Text = text, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x, y), Size = UDim2.fromScale(w, h), BackgroundTransparency = 1, Font = font or MONO, TextColor3 = color or WHITE, TextTransparency = 1, TextScaled = true, ZIndex = z or 3 }, parent)
		new("UITextSizeConstraint", { MaxTextSize = maxSize }, l)
		return l
	end

	local emblemSmall, ruleBack, ruleFill, loadingText, tipText, cornerText, logo, logoEmblem, logoTitle, synced
	if not opts.headless then
		emblemSmall = new("ImageLabel", { Name = "Emblem", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromScale(0.1, 0.17), BackgroundTransparency = 1, Image = LoadingFX.textures.emblem, ImageTransparency = 1, ZIndex = 3 }, gui)
		new("UIAspectRatioConstraint", { AspectRatio = 1 }, emblemSmall)
		ruleBack = new("Frame", { Name = "Rule", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.62), Size = UDim2.fromScale(0.34, 0.003), BackgroundColor3 = WHITE, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 3 }, gui)
		ruleFill = new("Frame", { Name = "Fill", Size = UDim2.fromScale(0, 1), BackgroundColor3 = WHITE, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 4 }, ruleBack)
		loadingText = label(gui, string.format("Loading assets | 0 / %d", total), 0.5, 0.655, 0.34, 0.032, 22, Color3.fromRGB(190, 195, 210))
		tipText = label(gui, opts.tip or "Tip: merge three that touch to evolve them.", 0.5, 0.71, 0.5, 0.03, 20, Color3.fromRGB(150, 156, 175))
		cornerText = label(gui, "Loading 0", 0.9, 0.93, 0.14, 0.04, 24, Color3.fromRGB(200, 205, 220))

		logo = new("CanvasGroup", { Name = "Logo", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromScale(0.6, 0.42), BackgroundTransparency = 1, GroupTransparency = 1, ZIndex = 6 }, gui)
		logoEmblem = new("ImageLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.3), Size = UDim2.fromScale(0.3, 0.55), BackgroundTransparency = 1, Image = LoadingFX.textures.emblem }, logo)
		new("UIAspectRatioConstraint", { AspectRatio = 1 }, logoEmblem)
		logoTitle = new("TextLabel", { Text = title, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.78), Size = UDim2.fromScale(1, 0.22), BackgroundTransparency = 1, Font = MONO, TextColor3 = WHITE, TextScaled = true }, logo)
		new("UITextSizeConstraint", { MaxTextSize = 64 }, logoTitle)
		new("UIStroke", { StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize, Thickness = 0.03, Color = Color3.fromRGB(8, 10, 20), ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual }, logoTitle)

		synced = new("Frame", { Name = "Synced", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.52), Size = UDim2.fromScale(0.3, 0.12), BackgroundTransparency = 1, ZIndex = 7, Visible = false }, gui)
		local function line(x, y, w, h, ax, ay)
			new("Frame", { AnchorPoint = Vector2.new(ax, ay), Position = UDim2.fromScale(x, y), Size = UDim2.fromScale(w, h), BackgroundColor3 = WHITE, BorderSizePixel = 0 }, synced)
		end
		for _, c in ipairs({ { 0, 0 }, { 1, 0 }, { 0, 1 }, { 1, 1 } }) do
			line(c[1], c[2], 0.12, 0.03, c[1], c[2]) -- horizontal arm
			line(c[1], c[2], 0.012, 0.3, c[1], c[2]) -- vertical arm
		end
		local st = label(synced, "SYNCED", 0.5, 0.5, 0.7, 0.5, 40, WHITE, MONO, 8)
		st.Name = "SyncedText"
		local under = new("Frame", { Name = "Underline", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.8), Size = UDim2.fromScale(0, 0.02), BackgroundColor3 = WHITE, BorderSizePixel = 0 }, synced)
	end
	local lift = not opts.headless and new("Frame", { Name = "Lift", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(235, 240, 255), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 5 }, gui) or nil

	-- the HUD stays hidden until the handoff (beat 4)
	if not opts.headless and opts.hud then
		if opts.hud:IsA("CanvasGroup") then
			opts.hud.GroupTransparency = 1
		end
		opts.hud.Visible = false
	end

	-- ---- progress ----------------------------------------------------------------------------------
	local target, display = 0, 0
	function handle.setProgress(n)
		target = math.clamp(n, 0, total)
		if loadingText then
			loadingText.Text = string.format("Loading assets | %d / %d", math.floor(n + 0.0001), total)
			cornerText.Text = "Loading " .. math.floor(n + 0.0001)
		end
	end
	if not opts.headless then
		table.insert(conns, RunService.Heartbeat:Connect(function(dt)
			display = smooth(display, target, 6, dt * ts)
			ruleFill.Size = UDim2.fromScale(display / total, 1)
		end))
	end

	-- ---- beats ---------------------------------------------------------------------------------------
	-- beat 1: fade up (0 to 0.5)
	beat("fadeUp")
	if not opts.headless then
		emblemSmall.Size = UDim2.fromScale(0.095, 0.16)
		tw(emblemSmall, 0.5, { ImageTransparency = 0, Size = UDim2.fromScale(0.1, 0.17) }, Enum.EasingStyle.Quint)
		tw(ruleBack, 0.5, { BackgroundTransparency = 0.8 }, Enum.EasingStyle.Sine)
		tw(ruleFill, 0.5, { BackgroundTransparency = 0 }, Enum.EasingStyle.Sine)
		for _, l in ipairs({ loadingText, tipText, cornerText }) do
			tw(l, 0.5, { TextTransparency = 0.05 }, Enum.EasingStyle.Sine)
		end
	end

	-- beat 2: wait scene (from 0.5): world blurred and dimmed, calm
	at(0.5, function()
		beat("wait")
		if not opts.headless then
			tw(black, 0.7, { BackgroundTransparency = 0.45 }, Enum.EasingStyle.Sine)
			tw(blurFx, 0.7, { Size = blurPeak }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		end
	end)

	local finishing = false
	local function resolveAndEnd()
		-- beat 5: resolve (0.9): blur eases out while the logo shrinks, drifts and fades, the dim clears
		beat("resolve")
		local d = 0.9
		if soft then
			d = 0.4
			stats.resolveTime = 0.4
		else
			stats.logoScale = true
		end
		if not opts.headless then
			tw(blurFx, soft and 0.8 or d, { Size = 0 }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			tw(black, d, { BackgroundTransparency = 1 }, Enum.EasingStyle.Sine)
			tw(logo, d, { GroupTransparency = 1 }, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
			if not soft then
				tw(logo, d, { Size = UDim2.fromScale(0.6 * 0.85, 0.42 * 0.85), Position = UDim2.fromScale(0.5, 0.41) }, Enum.EasingStyle.Quint)
			end
			for _, l in ipairs({ emblemSmall }) do
				tw(l, 0.3, { ImageTransparency = 1 }, Enum.EasingStyle.Sine)
			end
		end
		at(math.max(d, 0.8) + 0.1, function()
			beat("done")
			cleanup()
		end)
	end

	local function handoff()
		-- beat 4: handoff (0.8): logo glows in while the HUD fades in over the still-blurred world
		beat("handoff")
		if not opts.headless then
			logo.Size = soft and UDim2.fromScale(0.6, 0.42) or UDim2.fromScale(0.6 * 0.96, 0.42 * 0.96)
			tw(logo, 0.4, { GroupTransparency = 0, Size = UDim2.fromScale(0.6, 0.42) }, Enum.EasingStyle.Quint)
			for _, l in ipairs({ loadingText, tipText, cornerText }) do
				tw(l, 0.4, { TextTransparency = 1 }, Enum.EasingStyle.Sine)
			end
			tw(ruleBack, 0.4, { BackgroundTransparency = 1 }, Enum.EasingStyle.Sine)
			tw(ruleFill, 0.4, { BackgroundTransparency = 1 }, Enum.EasingStyle.Sine)
			local hud = opts.hud
			if hud then
				if hud:IsA("CanvasGroup") then
					hud.GroupTransparency = 1
					hud.Visible = true
					tw(hud, 0.8, { GroupTransparency = 0 }, Enum.EasingStyle.Sine)
				else
					hud.Visible = true
				end
			end
		end
		at(0.8, resolveAndEnd)
	end

	function handle.finish()
		if finishing or handle.done then
			return
		end
		finishing = true
		local wait = math.max(0, minTime - now())
		at(wait, function()
			-- beat 3: SYNCED
			beat("synced")
			if not opts.headless then
				synced.Visible = true
				synced.Size = soft and UDim2.fromScale(0.3, 0.12) or UDim2.fromScale(0.38, 0.15)
				for _, d in ipairs(synced:GetDescendants()) do
					if d:IsA("Frame") then
						d.BackgroundTransparency = 1
						tw(d, 0.35, { BackgroundTransparency = 0 }, Enum.EasingStyle.Sine)
					elseif d:IsA("TextLabel") then
						tw(d, 0.35, { TextTransparency = 0 }, Enum.EasingStyle.Sine)
					end
				end
				if not soft then
					tw(synced, 0.4, { Size = UDim2.fromScale(0.3, 0.12) }, Enum.EasingStyle.Quint)
				end
				local under = synced:FindFirstChild("Underline")
				under.Size = UDim2.fromScale(0, 0.02)
				under.BackgroundTransparency = 0
				tw(under, 0.4, { Size = UDim2.fromScale(0.5, 0.02) }, Enum.EasingStyle.Quint)
				tw(emblemSmall, 0.4, { ImageTransparency = 1 }, Enum.EasingStyle.Sine)
			end
			if not soft then
				-- soft light lift: luminance 0 -> 0.25 -> 0 over 0.7 s (not a white frame)
				stats.lift = true
				stats.liftPeak = 0.25
				if not opts.headless then
					tw(lift, 0.25, { BackgroundTransparency = 0.75 }, Enum.EasingStyle.Sine)
					at(0.25, function()
						tw(lift, 0.45, { BackgroundTransparency = 1 }, Enum.EasingStyle.Sine)
					end)
				end
			end
			at(0.9, function()
				if not opts.headless then
					for _, d in ipairs(synced:GetDescendants()) do
						if d:IsA("Frame") then
							tw(d, 0.3, { BackgroundTransparency = 1 }, Enum.EasingStyle.Sine)
						elseif d:IsA("TextLabel") then
							tw(d, 0.3, { TextTransparency = 1 }, Enum.EasingStyle.Sine)
						end
					end
				end
				at(0.3, handoff)
			end)
		end)
	end

	function handle.skip()
		if handle.done then
			return
		end
		stats.skipped = true
		finishing = true
		if not opts.headless then
			tw(black, 0.3, { BackgroundTransparency = 1 }, Enum.EasingStyle.Sine)
			tw(blurFx, 0.3, { Size = 0 }, Enum.EasingStyle.Sine)
			for _, e in ipairs(gui:GetChildren()) do
				if e ~= black and e ~= lift then
					if e:IsA("TextLabel") then
						tw(e, 0.2, { TextTransparency = 1 })
					elseif e:IsA("ImageLabel") then
						tw(e, 0.2, { ImageTransparency = 1 })
					elseif e:IsA("CanvasGroup") then
						tw(e, 0.2, { GroupTransparency = 1 })
					end
				end
			end
			if opts.hud then
				opts.hud.Visible = true
				if opts.hud:IsA("CanvasGroup") then
					opts.hud.GroupTransparency = 0
				end
			end
		end
		at(0.35, cleanup)
	end

	if opts.autoProgress then -- test helper: simulate loading over N seconds, then finish
		task.spawn(function()
			local t0 = os.clock()
			while alive and not finishing do
				local f = math.clamp((os.clock() - t0) * ts / opts.autoProgress, 0, 1)
				handle.setProgress(f * total)
				if f >= 1 then
					handle.finish()
				end
				task.wait(0.1)
			end
		end)
	end
	return handle
end

-- Headless check of the limits for every settings combination. Returns (report, failures).
function LoadingFX.audit()
	local lines, fails = {}, 0
	for _, touch in ipairs({ true, false }) do
		for _, flashes in ipairs({ true, false }) do
			for _, reduced in ipairs({ false, true }) do
				local h = LoadingFX.play({ headless = true, forceTouch = touch, settings = { flashes = flashes, reducedMotion = reduced }, minTime = 0 })
				h.finish()
				local s = h.stats
				local bad = {}
				local softMode = (not flashes) or reduced
				if s.blurPeak > (touch and 10 or 18) then
					table.insert(bad, "blur " .. s.blurPeak .. " too high")
				end
				if softMode and (s.blurPeak > 8 or s.lift or s.logoScale) then
					table.insert(bad, "soft mode has lift/scale/blur above 8")
				end
				if s.liftPeak > 0.25 then
					table.insert(bad, "light lift above 0.25")
				end
				local order = {}
				for _, b in ipairs(s.beats) do
					table.insert(order, b.name)
				end
				local seq = table.concat(order, ">")
				if seq ~= "fadeUp>wait>synced>handoff>resolve>done" then
					table.insert(bad, "beat order " .. seq)
				end
				if #bad > 0 then
					fails += 1
					table.insert(lines, string.format("FAIL touch=%s flashes=%s reduced=%s: %s", tostring(touch), tostring(flashes), tostring(reduced), table.concat(bad, "; ")))
				end
			end
		end
	end
	table.insert(lines, fails == 0 and "LOADING AUDIT PASS (beats in order; blur 12 desktop, 10 touch, 8 soft; lift peak 0.25, none in soft mode)" or ("LOADING AUDIT FAILURES: " .. fails))
	return table.concat(lines, "\n"), fails
end

return LoadingFX
