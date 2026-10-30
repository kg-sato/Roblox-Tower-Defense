-- GCMergeCut (T198, 2026-10-29): block moved out of GameClient to stay under the 200,000-character script limit. Called once by GameClient with the outside locals it needs.
return function(env)
local FXK, ReplicatedStorage, SETTINGS, STYLE, burst, camera, floatText, flying, groundOf, pending, petParts, rarityColor, ring, screenFlash, setPet, shake, tween = env.FXK, env.ReplicatedStorage, env.SETTINGS, env.STYLE, env.burst, env.camera, env.floatText, env.flying, env.groundOf, env.pending, env.petParts, env.rarityColor, env.ring, env.screenFlash, env.setPet, env.shake, env.tween
return function(data)
		-- Merge cutscene (2026-10-28, user: "every action a cutscene"): the camera drops to a low orbit, the three
		-- familiars crouch and leap together, collide in a burst of light above the target, the new one drops and lands
		-- with a stomp. Full (2.1 s) for the first two merges and tier 3+; short (0.9 s, no camera) after that or at 2x.
		pending[data.to] = true
		FXK.merges = (FXK.merges or 0) + 1
		local full = FXK.cut and not FXK.cineOff() and not FXK.cineShort() and (FXK.merges <= 2 or data.tier >= 3)
		local base = groundOf(data.to)
		local color = rarityColor(data.pet)
		local fxColor = (color.R + color.G + color.B > 2.6) and STYLE.gold or color -- white rarity washed the frame out
		local apex = base + Vector3.new(0, full and 7 or 1, 0)
		local leapT = full and 0.7 or 0.24
		local i = 0
		for _, sl in data.from do
			local entry = petParts[sl]
			if entry then
				petParts[sl] = nil
				i += 1
				if full then -- the brass footprint plates stay on the ground (v1 flipped up with the familiars)
					for _, n in { "Footprint", "FootprintRim" } do
						local fp = entry.model:FindFirstChild(n)
						if fp then fp:Destroy() end
					end
				end
				table.insert(flying, { model = entry.model, from = entry.model:GetPivot().Position, to = apex, t = 0,
					dur = full and leapT or nil, delay = full and 0.25 + i * 0.05 or nil, arc = full and 6 or nil,
					spin = full and 10 or nil, flip = full, shrink = full and 0.4 or nil })
				if not SETTINGS.reducedMotion then -- multiples: three fading copies trail the leap (Animation Craft note)
					require(ReplicatedStorage.Shared.Motion).echoModel(entry.model, { count = 3, gap = 2 })
				end
			end
		end
		local land = function()
			pending[data.to] = nil
			setPet(data.to, data.pet, data.tier, true)
			burst(base + Vector3.new(0, 3, 0), Color3.new(1, 1, 1), 24, nil, true)
			ring(base, color, 10 + data.tier * 2, 0.6)
			local sheet = FXK.sheetReady("upgrade")
			if sheet then
				FXK.pfx.play(sheet, CFrame.new(base + Vector3.new(0, 3, 0)), { color = color })
			elseif FXK.td then
				FXK.td.upgrade(base, color, data.tier) -- light column + one chevron per tier
			end
			floatText(base + Vector3.new(0, 7, 0), data.tier >= 4 and "EVOLVED!" or "MERGE!", STYLE.gold, 26)
		end
		if not full then
			task.delay(0.24, land)
		else
			local K = FXK.cut.kit
			local cctx = { gameCamera = function() return FXK.gameCF or camera.CFrame end, setCamera = function(cf) FXK.camOverride = cf end, settings = SETTINGS }
			local stage = K.stage()
			local ov = K.overlay()
			ov.open(0.08)
			local cam = K.camera(cctx)
			local side = Vector3.new(1, 0, 0.35).Unit
			-- 1. drop to a low three-quarter shot beside the target
			cam.to(CFrame.lookAt(base + side * 13 + Vector3.new(0, 3.5, 6), base + Vector3.new(0, 3, 0)), 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
			FXK.play("anticipation", { pitch = 0.9 })
			task.spawn(function()
				task.wait(0.3)
				-- 2. leap: slow orbit up toward the apex while they fly
				cam.to(CFrame.lookAt(base - side * 6 + Vector3.new(0, 5, 13), apex), leapT, Enum.EasingStyle.Sine)
				K.gather(stage, apex, fxColor, 14, 6, leapT)
				task.wait(leapT)
				-- 3. collide: flash, orb, shockwave, shake
				FXK.play("ring", { pitch = 1.1 })
				K.flash(ov, cctx, Color3.new(1, 1, 1), 0.55, 0.2)
				local orb = Instance.new("Part")
				orb.Shape, orb.Anchored, orb.CanCollide, orb.CanQuery, orb.Material = Enum.PartType.Ball, true, false, false, Enum.Material.Neon
				orb.Color, orb.Size, orb.Position, orb.Parent = fxColor:Lerp(Color3.new(1, 1, 1), 0.3), Vector3.one * 1.5, apex, stage
				tween(orb, 0.2, { Size = Vector3.one * 3.2 }, Enum.EasingStyle.Back)
				K.shockwave(stage, apex - Vector3.new(0, 0.2, 0), fxColor, 9, 0.45)
				shake.t, shake.amp = 0.3, 1.2
				task.wait(0.28)
				-- 4. drop and land with a stomp
				tween(orb, 0.22, { Position = base + Vector3.new(0, 1.2, 0), Size = Vector3.one * 1.2 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				cam.to(CFrame.lookAt(base + side * 9 + Vector3.new(0, 2.2, 5), base + Vector3.new(0, 2.5, 0)), 0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				task.wait(0.22)
				orb:Destroy()
				land()
				K.impact(stage, base, fxColor, 0.8 + data.tier * 0.1)
				cam.shake(0.6, 0.35)
				FXK.play("summon")
				-- 5. hold on the new familiar, then back to the board
				cam.to(CFrame.lookAt(base + side * 8 + Vector3.new(0, 3, 6), base + Vector3.new(0, 3, 0)), 0.55, Enum.EasingStyle.Sine)
				task.wait(0.55)
				ov.close()
				cam.done(0.4)
				task.wait(0.45)
				stage:Destroy()
			end)
		end
		if (data.coins or 0) > 0 then
			floatText(base + Vector3.new(2.5, 5, 0), "+" .. data.coins, STYLE.gold, 20)
		end
		if data.tier >= 4 then
			screenFlash(color, 0.25)
		end
end
end
