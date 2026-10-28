--!nocheck
-- NowPlayingClient: shows the "Now Playing" popup (bottom right) whenever MusicFX starts a track.
-- Installed as StarterPlayer.StarterPlayerScripts.NowPlayingClient (LocalScript). Needs ReplicatedStorage.MusicFX
-- (with TrackStarted and getPlaying) and ReplicatedStorage.UIKit.UIScreens2. Delete the script to remove the popup.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Music = require(ReplicatedStorage:WaitForChild("MusicFX"))
local kit = ReplicatedStorage:WaitForChild("UIKit")
local K = require(kit:WaitForChild("UIKit"))
local S = require(kit:WaitForChild("UIScreens2"))

local gui = S.NowPlaying(K, Players.LocalPlayer:WaitForChild("PlayerGui"), Music)
gui.DisplayOrder = 50 -- above the game HUD

-- abstract (2026-10-28, "everything abstract"): no card box; the note sits in a thin violet ring, the progress bar is a
-- thin line, the equaliser bars stay (they are already lines); text in the game's serif
do
	local card = gui:FindFirstChild("Card", true)
	if card then
		card.BackgroundTransparency = 1
		for _, k in card:GetChildren() do if k:IsA("UIStroke") then k.Enabled = false end end
		local note = card:FindFirstChild("NoteBubble")
		if note then
			note.BackgroundTransparency = 1
			for _, k in note:GetChildren() do
				if k:IsA("UIGradient") then k.Enabled = false end
				if k:IsA("UIStroke") then k.Color = Color3.fromRGB(150, 110, 255); k.Thickness = (k.StrokeSizingMode == Enum.StrokeSizingMode.ScaledSize) and 0.05 or 2 end -- ScaledSize: 2 would mean twice the bubble (a huge disc)
			end
		end
		local prog = card:FindFirstChild("Progress")
		if prog then
			prog.BackgroundTransparency = 0.6
			prog.Size = UDim2.new(prog.Size.X.Scale, 0, 0, 1)
		end
		for _, t in card:GetDescendants() do
			if t:IsA("TextLabel") and t.Text ~= "♪" then t.FontFace = Font.fromName("Merriweather", Enum.FontWeight.Bold) end
		end
	end
end
