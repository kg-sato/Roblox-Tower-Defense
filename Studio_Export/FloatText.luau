--!nocheck
-- FloatText (T194, 2026-10-29): the damage numbers that rise from a hit. Colour follows the shooter's family (faction, Shared.Familiars);
-- a crit is gold, larger and ends in "!". Obeys the Damage numbers setting (SETTINGS.damageNumbers == false shows nothing).
-- GameClient's shotFx makes one call: FXK.floatFx.hit(pos, data, pet). Small hits (under 25) stay silent so a swarm does not turn to confetti.
-- M.log keeps the last 60 calls { text, colour, shown } and mirrors them to the script attribute "Log" for Studio tests. Look UNVERIFIED.
return function(env)
	local Config, SETTINGS, STYLE, floatText, fmt = env.Config, env.SETTINGS, env.STYLE, env.floatText, env.fmt
	local M = { log = {}, MIN = 25 }
	M.COLORS = {
		["Lantern Keepers"] = Color3.fromRGB(255, 120, 70),
		["Clockwork Guild"] = Color3.fromRGB(220, 190, 100),
		["Hollow Court"] = Color3.fromRGB(130, 205, 255),
		["Star Choir"] = Color3.fromRGB(205, 150, 255),
		["Unaligned"] = Color3.fromRGB(180, 235, 200),
	}
	function M.colorFor(pet)
		local def = Config.PETS[pet]
		return M.COLORS[def and def.faction or ""] or (def and def.color) or Color3.new(1, 1, 1)
	end

	function M.hit(pos, data, pet)
		local crit = data.crit and true or false
		if not crit and data.dmg < M.MIN then return end
		local shown = SETTINGS.damageNumbers ~= false
		local text = fmt(data.dmg) .. (crit and "!" or "")
		local color = crit and STYLE.gold or M.colorFor(pet)
		if #M.log >= 60 then table.remove(M.log, 1) end
		table.insert(M.log, { text, color, shown })
		if shown then
			floatText(pos, text, color, crit and 26 or 18)
		end
		script:SetAttribute("Log", game:GetService("HttpService"):JSONEncode({ n = #M.log, last = { text, color:ToHex(), shown } }))
	end

	return M
end
