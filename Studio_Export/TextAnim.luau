--!strict
-- Shared.TextAnim (T188): animated text for captions, lore reveals, headings and the boss name.
-- Effects: typewrite (letters appear), drop (falls in and settles), wave (gentle bob), shake (tremble). The maths is pure
-- (testable without Instances); `run` drives one TextLabel/TextButton and yields until the effect ends.
-- Setting: SettingsDefaults key `textAnim` = "off" | "subtle" | "full" (default "full"). reducedMotion=true always means
-- static text. "off" shows the final text at once and `run` returns immediately.
-- shortcut: effects act on the whole label (typewrite uses MaxVisibleGraphemes; drop/wave/shake move the label), not per
-- letter; upgrade to per-letter labels only if a screen needs a true letter wave.

local RunService = game:GetService("RunService")

local TextAnim = {}

export type Mode = "off" | "subtle" | "full"
export type Effect = "typewrite" | "drop" | "wave" | "shake"

TextAnim.EFFECTS = { "typewrite", "drop", "wave", "shake" }

-- The client's live settings: CutsceneDirector hands over its table (kept current from the server "Settings" event), so any
-- screen can call `run` without a settings argument. Requires share one cache per client, so this is one table for all.
TextAnim.settings = {} :: { [string]: any }
function TextAnim.setSettings(s: { [string]: any })
	TextAnim.settings = s
end

-- settings = the client's settings table (reducedMotion, textAnim). Anything unknown counts as "full".
function TextAnim.mode(settings: any): Mode
	if type(settings) ~= "table" then
		return "full"
	end
	if settings.reducedMotion == true or settings.cinematics == "off" then
		return "off"
	end
	local m = settings.textAnim
	if m == "off" or m == "subtle" or m == "full" then
		return m
	end
	return "full"
end

-- strength of the motion: 0 off, 0.4 subtle, 1 full
function TextAnim.strength(mode: Mode): number
	return mode == "off" and 0 or (mode == "subtle" and 0.4 or 1)
end

local function graphemes(text: string): number
	return utf8.len(text) or #text
end
TextAnim.graphemes = graphemes

-- Seconds a typewrite takes: about 30 ms a letter, clamped to 0.4..2.5 s; subtle is twice as fast.
function TextAnim.duration(effect: Effect, text: string, mode: Mode): number
	if mode == "off" then
		return 0
	end
	local base
	if effect == "typewrite" then
		base = math.clamp(graphemes(text) * 0.03, 0.4, 2.5)
	elseif effect == "drop" then
		base = 0.45
	else
		base = 1.2 -- wave and shake: one short phrase of motion that then settles
	end
	return mode == "subtle" and base * 0.5 or base
end

-- How many letters are visible after `t` seconds of a typewrite lasting `dur`.
function TextAnim.visibleAt(count: number, t: number, dur: number): number
	if dur <= 0 then
		return count
	end
	return math.clamp(math.floor(count * t / dur + 0.5), 0, count)
end

-- Vertical pixel offset of a dropping label: starts `height` px above, overshoots a little, settles at 0.
function TextAnim.dropOffset(a: number, height: number): number
	a = math.clamp(a, 0, 1)
	if a >= 1 then
		return 0
	end
	local fall = 1 - (1 - a) ^ 3
	return -height * (1 - fall) + math.sin(a * math.pi) * height * 0.08
end

-- Wave/shake offsets in pixels at time t (seconds), fading to 0 by the end (a = t/dur) so the text settles.
function TextAnim.waveOffset(t: number, a: number, amp: number): number
	return math.sin(t * 6) * amp * (1 - math.clamp(a, 0, 1))
end

function TextAnim.shakeOffset(t: number, a: number, amp: number): (number, number)
	local f = amp * (1 - math.clamp(a, 0, 1))
	return math.sin(t * 90) * f, math.cos(t * 77) * f * 0.6
end

-- Runs `effect` on `label` showing `text`; yields until done (call from your own task). Returns a handle with cancel()
-- that snaps the label to its final state. opts: amp (px, default 6), height (drop px, default 24).
function TextAnim.run(label: GuiObject, text: string, effect: Effect, settings: any?, opts: any?)
	local mode = TextAnim.mode(settings or TextAnim.settings)
	local o = opts or {}
	local lbl = label :: any
	local home: UDim2 = lbl.Position
	lbl.Text = text
	lbl.MaxVisibleGraphemes = -1
	local dur = TextAnim.duration(effect, text, mode)
	if dur <= 0 then
		return { cancel = function() end, mode = mode }
	end
	local k = TextAnim.strength(mode)
	local amp = (o.amp or 6) * k
	local height = (o.height or 24) * k
	local count = graphemes(text)
	local cancelled = false
	local function settle()
		lbl.Position = home
		lbl.MaxVisibleGraphemes = -1
	end
	local handle = {
		mode = mode,
		cancel = function()
			cancelled = true
			settle()
		end,
	}
	local t0 = os.clock()
	if effect == "typewrite" then
		lbl.MaxVisibleGraphemes = 0
	end
	while not cancelled do
		local t = os.clock() - t0
		local a = math.clamp(t / dur, 0, 1)
		if effect == "typewrite" then
			lbl.MaxVisibleGraphemes = TextAnim.visibleAt(count, t, dur)
		elseif effect == "drop" then
			lbl.Position = home + UDim2.fromOffset(0, TextAnim.dropOffset(a, height))
		elseif effect == "wave" then
			lbl.Position = home + UDim2.fromOffset(0, TextAnim.waveOffset(t, a, amp))
		else
			local dx, dy = TextAnim.shakeOffset(t, a, amp)
			lbl.Position = home + UDim2.fromOffset(dx, dy)
		end
		if a >= 1 then
			break
		end
		RunService.Heartbeat:Wait()
	end
	if not cancelled then
		settle()
	end
	return handle
end

return TextAnim
