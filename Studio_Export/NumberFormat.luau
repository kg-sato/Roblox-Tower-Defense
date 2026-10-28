--!strict
-- Big-number text for the HUD. Modes: "short" (1.5K, 13.66T), "grouped" (1,234,567), "scientific" (1.5e3).
-- Pure function, no Instances; the player's numberFormat setting picks the mode.

local NumberFormat = {}

local SUFFIX = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

local function trim(n: number, decimals: number): string
	local s = string.format("%." .. decimals .. "f", n)
	if string.find(s, ".", 1, true) then
		s = string.gsub(s, "0+$", "")
		s = string.gsub(s, "%.$", "")
	end
	return s
end

local function grouped(n: number): string
	local s = string.format("%.0f", n)
	local out = string.reverse(string.gsub(string.reverse(s), "(%d%d%d)", "%1,"))
	return (string.gsub(out, "^,", ""))
end

function NumberFormat.format(value: number, mode: string?): string
	if value ~= value or value == math.huge or value == -math.huge then
		return "0"
	end
	local sign = value < 0 and "-" or ""
	local n = math.abs(value)
	if n < 0.5 then
		return "0"
	end
	if mode == "grouped" then
		return sign .. grouped(n)
	end
	if mode == "scientific" then
		if n < 1000 then
			return sign .. trim(n, 0)
		end
		local exp = math.floor(math.log10(n))
		local mant = tonumber(trim(n / 10 ^ exp, 2)) :: number
		if mant >= 10 then
			mant /= 10
			exp += 1
		end
		return sign .. trim(mant, 2) .. "e" .. exp
	end
	if n < 1000 then
		return sign .. trim(n, 0)
	end
	local tier = math.min(math.floor(math.log10(n) / 3), #SUFFIX - 1)
	local scaled = tonumber(trim(n / 1000 ^ tier, 2)) :: number
	if scaled >= 1000 and tier < #SUFFIX - 1 then
		tier += 1
		scaled = tonumber(trim(n / 1000 ^ tier, 2)) :: number
	end
	return sign .. trim(scaled, 2) .. SUFFIX[tier + 1]
end

return NumberFormat
