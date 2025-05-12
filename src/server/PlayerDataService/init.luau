--!strict

--[[

	Handles PlayerData, using ProfileService as the base.

	See below for more information
	https://madstudioroblox.github.io/ProfileService/

	@author Phin 2024

]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ProfileService = require(ReplicatedStorage.Libraries.ProfileService)
local ProfileStoreTemplate = require(ReplicatedStorage.Settings.ProfileDataTemplate)
local DataStoreConfig = require(ReplicatedStorage.Settings.DataStore)
local Signal = require(ReplicatedStorage.Libraries.LemonSignal)
local ServerComm = require(script.Parent.NetworkService)

local PlayerDataStore = ProfileService.GetProfileStore(DataStoreConfig.Profile_Store_Scope, ProfileStoreTemplate)

export type ProfileExport = {
	Profile: any,
	Player: Player,
	Get: (self: ProfileExport, key: string) -> any,
	Set: (self: ProfileExport, key: string, value: any) -> (),
	Release: (self: ProfileExport) -> (),
	Destroy: (self: ProfileExport) -> (),
}

export type ProfileContainer<DataType, any> = {
	[DataType]: any,
}

local PlayerDataService = {}

local Container: ProfileContainer<string, any> = {
	_Profiles = {},
	_Signals = {
		ProfileKeySet = ServerComm:CreateSignal("ProfileKeySet"),
		ProfileLoaded = ServerComm:CreateSignal("ProfileLoaded"),
		ClientProfileLoadRequest = ServerComm:CreateSignal("ClientProfileLoadRequest"),
	},
	_Events = {
		OnProfileLoaded = Signal.new(),
	},
	_Loaded = {},
}

function PlayerDataService:GetProfile(player: Player): ProfileExport?
	assert(player:IsA("Player"), "Must pass a player instance!")

	return Container._Profiles[player]
end

local function NewProfileExport(player: Player, profile: any): ProfileExport
	local newProfileExport = { Profile = profile, Player = player }

	function newProfileExport:Get(key: string): any
		return profile.Data[key]
	end

	function newProfileExport:Set(key: string, value: any): any
		profile.Data[key] = value
		Container._Signals.ProfileKeySet:Fire(newProfileExport.Player, { key, value })

		return newProfileExport:Get(key)
	end

	function newProfileExport:Release()
		newProfileExport.Profile:Release()
	end

	newProfileExport.Destroy = newProfileExport.Release

	return newProfileExport
end

local function PlayerAdded(player: Player)
	local profile = PlayerDataStore:LoadProfileAsync(`{DataStoreConfig.Profile_Store_Key}_{player.UserId}`, "ForceLoad")

	if profile then
		profile:AddUserId(player.UserId)
		profile:Reconcile()
		profile:ListenToRelease(function()
			Container._Profiles[player] = nil

			task.delay(120, function()
				if player then
					player:Kick("Still in the game!")
				end
			end)

			print(`{player.UserId} left and their data automatically saved`)
		end)

		if player and player:IsDescendantOf(Players) then
			player:SetAttribute("Joined", os.time())

			local newProfileExport = NewProfileExport(player, profile)
			Container._Profiles[player] = newProfileExport
			Container._Events.OnProfileLoaded:Fire(newProfileExport)

			print(`{player.UserId} Data Size: {string.len(HttpService:JSONEncode(profile.Data))} / 4,000,000 Bytes`)

			if RunService:IsStudio() then
				print(profile.Data)
			end
		else
			profile:Release()
		end
	else
		if player then
			player:Kick("Your data could not be loaded. Try again later.")
		end
	end
end

local function PlayerRemoving(player: Player)
	local profile = PlayerDataService:GetProfile(player)

	if profile then
		profile:Release()
	end

	Container._Loaded[player] = nil
end

local function OnPlayerProfileRequest(player: Player)
	if Container._Loaded[player] then
		return
	end

	local profileExport: ProfileExport? = PlayerDataService:GetProfile(player)

	if not profileExport then
		local tempSignal = Signal.new()
		local listenSignal = Container._Events.OnProfileLoaded:Connect(function(profile: ProfileExport)
			if profile.Player == player then
				profileExport = profile
				tempSignal:Fire()
			end
		end)

		tempSignal:Wait()
		tempSignal:Destroy()
		listenSignal:Disconnect()
	end

	if profileExport then
		Container._Loaded[player] = true
		Container._Signals.ProfileLoaded:Fire(player, profileExport.Profile.Data)
	end
end

local function Init()
	if DataStoreConfig.Use_Mock_Profile_Stores_In_Studio then
		if RunService:IsStudio() then
			PlayerDataStore = PlayerDataStore.Mock
			print("Using Mock ProfileStores...")
		end
	end

	Players.PlayerAdded:Connect(PlayerAdded)
	Players.PlayerRemoving:Connect(PlayerRemoving)
	Container._Signals.ClientProfileLoadRequest:Connect(OnPlayerProfileRequest)

	for _, player: Player in Players:GetPlayers() do
		PlayerAdded(player)
	end
end

Init()
return PlayerDataService
