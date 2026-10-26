-- Installs (or updates) ServerStorage.AnimKit from the pack folder.
-- 1. Run `python kit/serve.py` in the pack folder.  2. Paste this into Studio's command bar (Edit mode).
-- No server? Make a ModuleScript in ServerStorage called AnimKit and paste roblox/AnimKit.luau into it.
local HttpService = game:GetService("HttpService")
local was = HttpService.HttpEnabled
HttpService.HttpEnabled = true
local ok, source = pcall(HttpService.GetAsync, HttpService, "http://127.0.0.1:8765/roblox/AnimKit.luau", true)
HttpService.HttpEnabled = was
assert(ok, "start the server first: python kit/serve.py  (" .. tostring(source) .. ")")
local old = game.ServerStorage:FindFirstChild("AnimKit")
if old then
	old:Destroy() -- a fresh instance, so require() doesn't hand back the old cached copy
end
local mod = Instance.new("ModuleScript")
mod.Name = "AnimKit"
mod.Source = source
mod.Parent = game.ServerStorage
require(mod)
print("AnimKit installed in ServerStorage")
