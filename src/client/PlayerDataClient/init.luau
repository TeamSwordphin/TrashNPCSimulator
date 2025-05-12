--!strict

--[[

	Handles PlayerDataClient

	@author Phin 2024

]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Libraries.LemonSignal)
local ClientComm = require(script.Parent.NetworkClient)
local NotificationClient = require(script.Parent.NotificationClient)

local PlayerDataClient = {
	OnKeyChanged = Signal.new(),
	OnProfileLoaded = Signal.new(),
	Loaded = false,
	Profile = {},
}

local CommSignals = {
	ProfileKeySet = ClientComm:GetSignal("ProfileKeySet"),
	ProfileLoaded = ClientComm:GetSignal("ProfileLoaded"),
	ClientProfileLoadRequest = ClientComm:GetSignal("ClientProfileLoadRequest"),
}

local function Init()
	CommSignals.ProfileLoaded:Connect(function(profile)
		PlayerDataClient.Profile = profile
		PlayerDataClient.Loaded = true
		PlayerDataClient.OnProfileLoaded:Fire()

		NotificationClient("Profile Loaded")
	end)

	CommSignals.ProfileKeySet:Connect(function(data: { number: any })
		local key: string = data[1]
		local value: any = data[2]

		PlayerDataClient.Profile[key] = value
		PlayerDataClient.OnKeyChanged:Fire(key, value)
	end)

	CommSignals.ClientProfileLoadRequest:Fire()
end

Init()
return PlayerDataClient
