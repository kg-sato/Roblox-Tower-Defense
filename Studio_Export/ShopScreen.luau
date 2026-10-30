--!nocheck
-- StarterPlayerScripts.ShopScreen (ModuleScript, T092): the cosmetic shop. DISPLAY ONLY, nothing can be bought here.
--   ShopScreen.render(root, {}, close)
-- Items are the cosmetic categories of Roblox Dev/Design/Content Plans.md and Progression Rules.md (trainer outfits, familiar palette skins,
-- lantern colours, frames, title cards, emotes, the golden trail). The design leaves every price to the user ("Robux price: the user decides"),
-- so no price is shown and every Buy button is disabled ("Not on sale yet"). There is no PromptPurchase, ProcessReceipt or Marketplace call in
-- this module; gems, luck and the tier cap are never sold, and nothing here is a random item.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local K = require(ReplicatedStorage:WaitForChild("UIKit"):WaitForChild("UIKit"))
local Shell = require(script.Parent:WaitForChild("ScreenShell"))
local Dialogs = require(script.Parent:WaitForChild("Dialogs"))
local P = Shell.P

local ShopScreen = {}

ShopScreen.ITEMS = {
	{ id = "outfit_keeper", name = "Keeper's Coat", kind = "Trainer outfit", blurb = "A lamp-oil dyed coat for the trainer." },
	{ id = "outfit_clock", name = "Clockwork Vest", kind = "Trainer outfit", blurb = "Brass buttons that tick softly." },
	{ id = "skin_ember", name = "Ashen Ember", kind = "Familiar palette", blurb = "Ember in cold grey. Same stats." },
	{ id = "skin_moth", name = "Moonlit Moth", kind = "Familiar palette", blurb = "Moth-Lantern in silver. Same stats." },
	{ id = "lantern_blue", name = "Harbour Blue", kind = "Lantern colour", blurb = "A blue flame for the lantern." },
	{ id = "frame_brass", name = "Brass Frame", kind = "Profile frame", blurb = "A riveted gold-ink frame." },
	{ id = "title_warden", name = "Lamp Warden", kind = "Title card", blurb = "A title under your name." },
	{ id = "trail_gold", name = "Golden Trail", kind = "Lantern trail", blurb = "Sparks follow the lantern." },
}

function ShopScreen.render(root, d, close)
	local h = Shell.frame(root, { name = "Shop", title = "COSMETIC SHOP", sub = "Looks only. Nothing here changes power." }, close)
	local cols, rows = 4, 2
	local grid = K.box(h.body, { name = "Grid", y = 0.45, w = 1, h = 0.88 })
	for i, item in ShopScreen.ITEMS do
		local col, row = (i - 1) % cols, (i - 1) // cols
		local card = K.box(grid, { name = "Item_" .. item.id, x = (col + 0.5) / cols, y = (row + 0.5) / rows, w = 0.235, h = 0.47, fill = P.ink, corner = 0.06, stroke = 0.03, strokeColor = P.goldDark, z = 13 })
		Dialogs.text(card, { name = "Kind", text = item.kind, y = 0.1, w = 0.9, h = 0.12, size = 16, color3 = P.muted, z = 14 })
		Dialogs.text(card, { name = "Name", text = item.name, y = 0.28, w = 0.9, h = 0.16, size = 22, color3 = P.gold, z = 14 })
		Dialogs.text(card, { name = "Blurb", text = item.blurb, y = 0.54, w = 0.9, h = 0.24, size = 16, color3 = P.cream, z = 14 })
		local buy = Dialogs.button(card, { name = "Buy", text = "Not on sale yet", fill = P.goldDark, y = 0.86, w = 0.86, h = 0.22, size = 16, z = 14 })
		K.setDisabled(buy, true)
		if i == 1 then
			h.first = buy
		end
	end
	return h
end

Shell.register("Shop", ShopScreen)
return ShopScreen
