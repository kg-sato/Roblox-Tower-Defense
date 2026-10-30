--!nocheck
-- UIMotion: the animation layer for UIKit. Loaded by UIKit before the art layer; replaces K.pressFx and K.popIn and
-- adds K.stagger, K.pulse, K.shake, K.countUp, K.setReducedMotion and a K.sfx hook.
-- Rules (from our Animation and Juice Playbook and the Roblox UI animation docs):
--   * Tween Size / Position with SCALE values only, on centred anchors, so layouts stay resolution-independent.
--     Size is tweened, never UIScale (UIScale mis-scales ScaledSize strokes).
--   * Ease out for things responding to input, Back-out for a small overshoot on arrival, Sine for loops.
--   * Reduced motion: every effect applies its end state instantly and loops are not started.
--   * Hover only exists where a mouse exists (not on phones or tablets).
--   * Never tween a text UIStroke's thickness.
-- Sound: set K.sfx = function(name) ... end later; it is called with "click" on press.

return function(K)
	local TweenService = game:GetService("TweenService")
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")

	local M = { reduced = false, hover = true, press = 0.94, hoverScale = 1.06 }
	K.Motion = M

	function K.setReducedMotion(on)
		M.reduced = on and true or false
	end

	local function mul(size, f)
		return UDim2.fromScale(size.X.Scale * f, size.Y.Scale * f)
	end

	-- play a tween, or apply the end state at once when reduced motion is on
	local function go(inst, info, props)
		if M.reduced then
			for k, v in pairs(props) do
				inst[k] = v
			end
			return nil
		end
		local t = TweenService:Create(inst, info, props)
		t:Play()
		return t
	end
	K.tween = go

	local QUAD_OUT = Enum.EasingStyle.Quad
	local BACK = Enum.EasingStyle.Back
	local SINE = Enum.EasingStyle.Sine
	local OUT = Enum.EasingDirection.Out
	local INOUT = Enum.EasingDirection.InOut

	---------------------------------------------------------------------------------------------
	-- buttons: four states. idle, hover (mouse) or focus (keyboard / gamepad selection) grows, pressed squashes,
	-- disabled dims and ignores input. K.setDisabled(btn, on) flips it; K.setState(btn, name) forces a state (tests).
	---------------------------------------------------------------------------------------------
	local DISABLED_ALPHA = 0.55
	function K.pressFx(btn)
		local base = btn.Size
		local hovered, pressed, focused, disabled = false, false, false, false
		local current
		local baseAlpha = btn.BackgroundTransparency
		local function apply()
			local f = disabled and 1 or (pressed and M.press or ((hovered or focused) and M.hoverScale or 1))
			local info
			if pressed then
				info = TweenInfo.new(0.06, QUAD_OUT, OUT)
			elseif hovered or focused then
				info = TweenInfo.new(0.12, QUAD_OUT, OUT)
			else
				info = TweenInfo.new(0.2, BACK, OUT)
			end
			if current then
				current:Cancel()
			end
			btn:SetAttribute("State", disabled and "disabled" or (pressed and "pressed" or ((hovered or focused) and "hover" or "idle")))
			current = go(btn, info, { Size = mul(base, f), BackgroundTransparency = disabled and DISABLED_ALPHA or baseAlpha })
		end
		local function dimLabel()
			local lbl = btn:FindFirstChild("Label")
			if lbl then
				go(lbl, TweenInfo.new(0.15, SINE, OUT), { TextTransparency = disabled and 0.45 or 0 })
			end
		end
		local function setDisabled()
			disabled = btn:GetAttribute("Disabled") == true
			btn.Interactable = not disabled
			if disabled then
				hovered, pressed = false, false
			end
			apply()
			dimLabel()
		end
		btn:GetAttributeChangedSignal("Disabled"):Connect(setDisabled)
		if btn:GetAttribute("Disabled") then
			setDisabled()
		end
		btn.MouseEnter:Connect(function()
			if M.hover and UserInputService.MouseEnabled and not disabled then
				hovered = true
				apply()
			end
		end)
		btn.MouseLeave:Connect(function()
			hovered, pressed = false, false
			apply()
		end)
		btn.MouseButton1Down:Connect(function()
			if disabled then
				return
			end
			pressed = true
			apply()
			if K.sfx then
				K.sfx("click")
			end
		end)
		btn.MouseButton1Up:Connect(function()
			pressed = false
			apply()
		end)
		btn.SelectionGained:Connect(function()
			focused = true
			apply()
		end)
		btn.SelectionLost:Connect(function()
			focused, pressed = false, false
			apply()
		end)
		M.force = M.force or setmetatable({}, { __mode = "k" })
		M.force[btn] = function(name) -- tests: put the button in a state without a mouse
			hovered, pressed = name == "hover", name == "pressed"
			if name == "disabled" then
				btn:SetAttribute("Disabled", true)
			else
				btn:SetAttribute("Disabled", nil)
				disabled = false
				btn.Interactable = true
				apply()
				dimLabel()
			end
		end
		return btn
	end

	function K.setDisabled(btn, on)
		btn:SetAttribute("Disabled", on and true or nil)
	end

	function K.setState(btn, name)
		local f = M.force and M.force[btn]
		if f then
			f(name)
		end
	end

	---------------------------------------------------------------------------------------------
	-- panels
	---------------------------------------------------------------------------------------------
	-- modal arrives: dim fades in, panel grows from 80% with a small overshoot
	function K.popIn(frame, o)
		o = o or {}
		local base = frame.Size
		local dim = frame.Parent
		if dim and dim.Name == "Dim" and not M.reduced then
			local target = dim.BackgroundTransparency
			dim.BackgroundTransparency = 1
			go(dim, TweenInfo.new(0.18, SINE, OUT), { BackgroundTransparency = target })
		end
		if M.reduced then
			return
		end
		frame.Size = mul(base, 0.8)
		go(frame, TweenInfo.new(o.time or 0.28, BACK, OUT), { Size = base })
	end

	-- children of a container pop in one after another (cards, slots, rows)
	function K.stagger(container, o)
		o = o or {}
		if M.reduced then
			return
		end
		local step, from = o.step or 0.045, o.from or 0.55
		local i = 0
		for _, c in ipairs(container:GetChildren()) do
			if c:IsA("GuiObject") then
				local base = c.Size
				c.Size = mul(base, from)
				task.delay(i * step, function()
					if c.Parent then
						go(c, TweenInfo.new(0.26, BACK, OUT), { Size = base })
					end
				end)
				i += 1
			end
		end
	end

	---------------------------------------------------------------------------------------------
	-- attention
	---------------------------------------------------------------------------------------------
	-- gentle looping grow and shrink (Claim buttons, new-item badges). Hover or press takes over and stops it.
	function K.pulse(inst, o)
		o = o or {}
		if M.reduced then
			return nil
		end
		local t = TweenService:Create(inst, TweenInfo.new(o.period or 0.9, SINE, INOUT, -1, true), { Size = mul(inst.Size, o.scale or 1.06) })
		t:Play()
		return t
	end

	-- A row of tutorial chevrons that point at something and ripple in sequence (like the "this way" arrows on a
	-- game's first screen). o: x, y, w, h (container, Scale of parent), count (default 5), dir ("right" | "left" |
	-- "up" | "down"), speed (waves per second, default 0.9). Sprite is icon_chevron. Reduced motion shows it still.
	function K.chevrons(parent, o)
		local count = o.count or 5
		local dir = o.dir or "right"
		local rot = ({ right = 0, down = 90, left = 180, up = 270 })[dir] or 0
		local horizontal = dir == "left" or dir == "right"
		local row = K.box(parent, { name = o.name or "Chevrons", x = o.x, y = o.y, w = o.w or 0.4, h = o.h or 0.12, anchor = o.anchor, reason = o.reason, z = o.z })
		local imgs = {}
		for i = 1, count do
			local f = (i - 0.5) / count
			local pos = (dir == "left" or dir == "up") and (1 - f) or f -- index 1 is the tail, count is the head
			local img = K.sprite(row, {
				sprite = "icon_chevron", name = "Chevron" .. i, rotation = rot,
				x = horizontal and pos or 0.5, y = horizontal and 0.5 or pos,
				w = horizontal and (0.92 / count) or 1, h = horizontal and 1 or (0.92 / count), aspect = 1,
			})
			img.ImageTransparency = M.reduced and 0 or 0.85
			imgs[i] = img
		end
		if M.reduced then
			return row
		end
		local speed = o.speed or 0.9
		local conn
		conn = RunService.Heartbeat:Connect(function()
			if not row.Parent then
				conn:Disconnect()
				return
			end
			local t = os.clock() * speed
			for i, img in ipairs(imgs) do
				local a = 0.5 + 0.5 * math.sin((t - (i - 1) / count) * math.pi * 2) -- the wave runs tail to head
				img.ImageTransparency = 0.9 - 0.9 * a
			end
		end)
		return row
	end
	-- quick left-right wiggle for "locked" or "not enough" feedback (position stays in Scale)
	function K.shake(inst)
		if M.reduced then
			return
		end
		local base = inst.Position
		task.spawn(function()
			for _, dx in ipairs({ 0.012, -0.012, 0.008, -0.008, 0.004, 0 }) do
				if not inst.Parent then
					return
				end
				local t = TweenService:Create(inst, TweenInfo.new(0.04, QUAD_OUT, OUT), { Position = base + UDim2.fromScale(dx, 0) })
				t:Play()
				t.Completed:Wait()
			end
			inst.Position = base
		end)
	end

	-- number counts up with an ease-out (rewards, totals). o: from, time, prefix, format
	function K.countUp(label, to, o)
		o = o or {}
		local fmt = o.format or K.fmt
		local prefix = o.prefix or ""
		local from, dur = o.from or 0, o.time or 1.1
		if M.reduced then
			label.Text = prefix .. fmt(to)
			return
		end
		local start = os.clock()
		label.Text = prefix .. fmt(from)
		local conn
		conn = RunService.Heartbeat:Connect(function()
			local t = math.clamp((os.clock() - start) / dur, 0, 1)
			local e = 1 - (1 - t) ^ 3
			label.Text = prefix .. fmt(math.floor(from + (to - from) * e))
			if t >= 1 or not label.Parent then
				conn:Disconnect()
			end
		end)
	end
end
