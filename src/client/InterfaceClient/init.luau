--!strict

--[[

	To add a new interface, just add a frame to any of the screen groups in StarterGui -> PlayerInterface
	Then rename a module script to that same frame inside Interfaces.

	@author Phin 2025

]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LoadedMenus = require(ReplicatedStorage.Libraries.Loader).LoadChildren(script.Interfaces)
local PlayerDataClient = require(ReplicatedStorage.Client.PlayerDataClient)

local PlayerGui = Players.LocalPlayer.PlayerGui
local Interface = PlayerGui:WaitForChild("PlayerInterface")

local function Init()
	if not PlayerDataClient.Loaded then
		PlayerDataClient.OnProfileLoaded:Wait()
	end

	for _, section in Interface:GetChildren() do
		if not section:IsA("Frame") then
			continue
		end

		for _, ui in section:GetChildren() do
			if LoadedMenus[ui.Name] then
				LoadedMenus[ui.Name](ui)
			end
		end
	end
end

Init()
return {}
