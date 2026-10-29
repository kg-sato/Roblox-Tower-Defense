--!strict
-- PaceClient (2026-10-29): applies the server's "Pace" events {id, dist, speed, t} to the enemies GameClient moves. GameClient moves an enemy to
-- (now - spawnTime) * speed, so a new speed v from distance d at game time t is spawnTime = t - d / v. Speed 0 (a stun) is held at 1e-4 so the maths stays finite.
-- GameClient shares its `enemies` table through ReplicatedStorage.EnemyPace (one line there). Installed as StarterPlayerScripts.PaceClient.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local bridge = require(ReplicatedStorage:WaitForChild("EnemyPace")) :: any

ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Event").OnClientEvent:Connect(function(kind: any, data: any)
	if kind ~= "Pace" or type(data) ~= "table" then
		return
	end
	local e = bridge.enemies and bridge.enemies[data.id]
	if e then
		local v = math.max(data.speed, 1e-4)
		e.speed, e.spawnTime = v, data.t - data.dist / v
	end
end)
