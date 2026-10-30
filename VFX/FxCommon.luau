--!nocheck
-- FxCommon (overnight fx-audio, 2026-10-29): shared bits for the new effect modules (FamiliarShots, MergeTierFX, LanternFX,
-- EnemyFamilyFX, UltFlourish): the gold-ink palette, the player's effect settings, one emitter budget and small part helpers.
-- Installed as ReplicatedStorage.FxCommon. Client side only. Settings come from the server "Settings" event (FxLayer feeds them in).
--   FxCommon.take(n, life)   -- reserve n emitters for `life` seconds; false when over the cap (Low 10, Default 20, High 32, same as FXK.CAP)
--   FxCommon.still()         -- reduced motion on
--   FxCommon.slow            -- duration multiplier for freeze-frame captures (1 in the game)
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local C = { live = 0, peak = 0, skipped = 0, quality = "default", reducedMotion = false, flashes = true, shake = true }
-- C.slow reads the script attribute "Slow" (set it in Studio to stretch every effect for freeze-frame captures; 1 in the game)
setmetatable(C, { __index = function(_, k) if k == "slow" then return script:GetAttribute("Slow") or 1 end end })
C.CAP = { low = 10, default = 20, high = 32 }
-- near-black ink, antique gold, cream (the game's palette); each familiar's own colour is the accent on top
C.INK, C.GOLD, C.GOLD_HI, C.CREAM = Color3.fromRGB(20, 16, 26), Color3.fromRGB(201, 162, 75), Color3.fromRGB(255, 208, 96), Color3.fromRGB(245, 232, 200)

-- test counters: every effect call bumps an attribute on this script (readable from any script context, unlike a module's own table)
function C.note(name)
	script:SetAttribute(name, (script:GetAttribute(name) or 0) + 1)
end

function C.apply(s)
	if type(s) ~= "table" then return end
	C.reducedMotion = s.reducedMotion == true
	C.flashes = s.flashes ~= false
	C.shake = s.shake ~= false
	C.quality = (s.particles == "low" or s.particles == "high") and s.particles or "default"
end

function C.still() return C.reducedMotion end

function C.take(n, life)
	n = n or 1
	if C.live + n > C.CAP[C.quality] then
		C.skipped += n
		return false
	end
	C.live += n
	C.peak = math.max(C.peak, C.live)
	script:SetAttribute("Peak", math.max(script:GetAttribute("Peak") or 0, C.live))
	task.delay((life or 1) * C.slow, function() C.live -= n end)
	return true
end

function C.folder()
	local f = workspace:FindFirstChild("FxLayer")
	if not f then
		f = Instance.new("Folder")
		f.Name = "FxLayer"
		f.Parent = workspace
	end
	return f
end

function C.part(props, parent)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Material = Enum.Material.Neon
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	for k, v in props do p[k] = v end
	p.Parent = parent or C.folder()
	return p
end

-- tween and clean up; durations stretch with C.slow so captures can catch a frame
function C.tw(inst, t, props, style, dir)
	local tw = TweenService:Create(inst, TweenInfo.new(t * C.slow, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end
function C.gone(inst, t) Debris:AddItem(inst, t * C.slow + 0.05) end

-- one ParticleEmitter on a part; `n` particles at once (Rate 0). Counts against the budget, Low halves n.
function C.emit(parent, o)
	if not C.take(1, o.life or 1) then return nil end
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = o.texture or "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = ColorSequence.new(o.c0 or C.GOLD_HI, o.c1 or o.c0 or C.GOLD_HI)
	pe.LightEmission = o.light or 0.8
	pe.LightInfluence = 0
	pe.Rate = 0
	pe.Lifetime = NumberRange.new((o.life or 0.6) * 0.7 * C.slow, (o.life or 0.6) * C.slow)
	pe.Speed = NumberRange.new((o.speed or 4) * 0.5, o.speed or 4)
	pe.SpreadAngle = Vector2.new(o.spread or 180, o.spread or 180)
	pe.Acceleration = o.accel or Vector3.zero
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, o.size or 0.5), NumberSequenceKeypoint.new(1, 0) })
	pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
	pe.ZOffset = 1
	pe.TimeScale = 1 / C.slow
	pe.Parent = parent
	pe:Emit(math.max(1, math.floor((o.n or 8) * (C.quality == "low" and 0.5 or 1) + 0.5)))
	return pe
end

-- flat FrameArt image on the ground (art = "sigil" | "ring" | "glow"); fades out over `life`
function C.decal(pos, color, size, life, art)
	local okFA, FA = pcall(function() return require(game:GetService("ReplicatedStorage"):WaitForChild("FrameArt", 3)) end)
	local p = C.part({ Transparency = 1, Size = Vector3.new(size, .05, size), CFrame = CFrame.new(pos.X, pos.Y + .25, pos.Z) })
	local sg = Instance.new("SurfaceGui")
	sg.Face, sg.LightInfluence, sg.Brightness, sg.SizingMode, sg.PixelsPerStud = Enum.NormalId.Top, 0, 2, Enum.SurfaceGuiSizingMode.PixelsPerStud, 20
	sg.Parent = p
	local img = Instance.new("ImageLabel")
	img.BackgroundTransparency, img.AnchorPoint, img.Position, img.Size, img.ImageColor3, img.ImageTransparency = 1, Vector2.new(.5, .5), UDim2.fromScale(.5, .5), UDim2.fromScale(1, 1), color, .15
	if okFA and FA then
		img.ImageContent = art == "ring" and (FA.thinRing and FA.thinRing() or FA.ring()) or (art == "glow" and FA.glow() or FA.sigil())
	else
		img.Image = "rbxasset://textures/particles/sparkles_main.dds"
	end
	img.Parent = sg
	if art == "sigil" and not C.reducedMotion then C.tw(img, life, { Rotation = 90 }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut) end
	C.tw(img, life, { ImageTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	C.gone(p, life + .1)
	return p, img
end

function C.softAlpha(a) -- flashes off: every bright flash starts fainter
	return C.flashes and a or math.max(a, 0.6)
end

return C
