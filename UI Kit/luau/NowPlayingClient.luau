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
