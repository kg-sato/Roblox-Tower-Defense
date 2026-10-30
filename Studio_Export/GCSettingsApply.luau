-- GCSettingsApply (T198, 2026-10-29): block moved out of GameClient to stay under the 200,000-character script limit. Called once by GameClient with the outside locals it needs.
return function(env)
local FXK, ReplicatedStorage, RunService, SETTINGS, UI, UI_SIZE_MUL, relayout, script = env.FXK, env.ReplicatedStorage, env.RunService, env.SETTINGS, env.UI, env.UI_SIZE_MUL, env.relayout, env.script
-- Player settings from the server (SettingsDefaults). SETTINGS is changed in place so every reader sees the new values.
function FXK.applySettings(s)
	if type(s) ~= "table" then
		return
	end
	SETTINGS.flashes = s.flashes ~= false
	SETTINGS.reducedMotion = s.reducedMotion == true
	SETTINGS.shake = s.shake ~= false
	SETTINGS.damageNumbers = s.damageNumbers ~= false -- T194: the Damage numbers setting reaches FloatText (it never reached SETTINGS before)
	if FXK.flashToggle then
		FXK.flashToggle.Text = SETTINGS.flashes and "Flashes: ON" or "Flashes: OFF"
	end
	SETTINGS.uiSize = UI_SIZE_MUL[s.uiSize] and s.uiSize or "normal"
	relayout() -- T117: the HUD scale follows the UI size
	SETTINGS.gameSpeed = s.gameSpeed == 2 and 2 or 1 -- CutsceneFX skips signatures by itself at 2x
	SETTINGS.cinematics = (s.cinematics == "short" or s.cinematics == "off") and s.cinematics or "full"
	local particles = s.particles == "low" and "Low" or (s.particles == "high" and "High" or "Default")
	-- Low effects detail: the Lampwick Lane lamps stop casting shadows (10 shadowed lights are the costliest part of the set)
	FXK.lowGfx = s.particles == "low"
	if s.numberFormat and s.numberFormat ~= UI.numberMode then
		UI.numberMode = s.numberFormat
		UI.refreshNumbers()
	end
	FXK.quality = FXK.CAP[s.particles] and s.particles or "default"
	if FXK.proj then
		FXK.proj.quality = FXK.quality
		FXK.proj.timeScale = s.gameSpeed == 2 and 2 or 1
	end
	for _, d in workspace:GetDescendants() do
		if d:IsA("PointLight") and d.Name == "LampLight" then
			d.Shadows = not FXK.lowGfx
		end
	end
	-- Emitter budget for everything that lives in the world (familiars, fog, portal; burst emitters have Rate 0 and are left to burst()): Rate scales with the quality, and on
	-- Low the 2nd and later emitter on one part (the secondary layers) is switched off. Bursts have their own cap in burst().
	function FXK.budgetEmitter(pe)
		if pe:GetAttribute("BaseRate") == nil then
			pe:SetAttribute("BaseRate", pe.Rate)
			pe:SetAttribute("BaseEnabled", pe.Enabled)
		end
		local base = pe:GetAttribute("BaseRate")
		if base > 0 then
			pe.Rate = base * (FXK.quality == "low" and 0.5 or (FXK.quality == "high" and 1.25 or 1))
		end
		local secondary = false
		if FXK.quality == "low" and pe.Parent then
			local first
			for _, c in pe.Parent:GetChildren() do
				if c:IsA("ParticleEmitter") then
					first = first or c
				end
			end
			secondary = first ~= pe
		end
		pe.Enabled = pe:GetAttribute("BaseEnabled") and not secondary
	end
	for _, d in workspace:GetDescendants() do
		if d:IsA("ParticleEmitter") then
			FXK.budgetEmitter(d)
		end
	end
	if not FXK.lampHook then
		FXK.lampHook = workspace.DescendantAdded:Connect(function(d)
			if d:IsA("PointLight") and d.Name == "LampLight" then
				d.Shadows = not FXK.lowGfx
			elseif d:IsA("ParticleEmitter") then
				task.defer(FXK.budgetEmitter, d)
			end
		end)
	end
	local okR, Reveal = pcall(function() return require(ReplicatedStorage:WaitForChild("RevealFX", 2)) end)
	if okR and Reveal then
		Reveal.setSettings({ flashes = SETTINGS.flashes, reducedMotion = SETTINGS.reducedMotion, particles = particles })
	end
	if FXK.sfx and type(s.sfxVolume) == "number" then
		pcall(FXK.sfx.setVolumes, { sfx = s.sfxVolume })
	end
	local okM, Music = pcall(function() return require(ReplicatedStorage:WaitForChild("MusicFX", 2)) end)
	if okM and Music and type(s.musicVolume) == "number" then
		pcall(Music.setVolumes, { music = s.musicVolume })
	end
	if game:GetService("RunService"):IsStudio() then
		script:SetAttribute("AppliedSettings", game:GetService("HttpService"):JSONEncode({ s = SETTINGS, reveal = okR and Reveal and { f = Reveal.settings.flashes, r = Reveal.settings.reducedMotion, p = Reveal.settings.particles } or false, music = okM and Music and Music.volumes and Music.volumes.music or false }))
	end
end
end
