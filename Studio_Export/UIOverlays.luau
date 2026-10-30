--!nocheck
-- StarterPlayerScripts.UIOverlays (LocalScript, T098/T085): loads the shared overlay modules once so they are ready for every
-- screen: Dialogs (confirm/error/empty), Toasts (queue) and Tooltips (hover/long press on any object tagged with the
-- attribute Tooltip, TooltipKind+TooltipId or Label). Other scripts require the modules directly:
--   local Dialogs = require(script.Parent.Dialogs)
local Players = game:GetService("Players")

require(script.Parent:WaitForChild("Dialogs"))
require(script.Parent:WaitForChild("Toasts"))
local Tooltips = require(script.Parent:WaitForChild("Tooltips"))
Tooltips.autoAttach(Players.LocalPlayer:WaitForChild("PlayerGui"))
