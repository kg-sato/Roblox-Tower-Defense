--!nocheck
-- StarterPlayerScripts.UILane2 (LocalScript): starts the standalone screens of the second client-ui batch. Each module
-- exposes init() and is loaded in its own pcall, so one failing screen cannot stop the others.
--   ResultsScreen (T074), FamiliarPanel (T095), PauseMenu (T097)
for _, name in { "ResultsScreen", "FamiliarPanel", "PauseMenu" } do
	local m = script.Parent:WaitForChild(name, 15)
	if m then
		local ok, mod = pcall(require, m)
		if ok and type(mod) == "table" and mod.init then
			local ok2, err = pcall(mod.init)
			if not ok2 then
				warn("UILane2: " .. name .. ".init failed: " .. tostring(err))
			end
		elseif not ok then
			warn("UILane2: " .. name .. " failed to load: " .. tostring(mod))
		end
	end
end
