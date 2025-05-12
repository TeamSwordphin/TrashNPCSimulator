--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Libraries.LemonSignal)
local NetworkClient = require(script.Parent.NetworkClient)
local NotificationClient = require(script.Parent.NotificationClient)

local CommObject = NetworkClient:BuildObject()

local PlayerQuestClient = {
	QuestReceived = Signal.new(),
}

function PlayerQuestClient:GetRequest()
	CommObject:GetCurrentQuest()
end

local function Init()
	NetworkClient:GetSignal("QuestReceived"):Connect(function(index: number)
		PlayerQuestClient.QuestReceived:Fire(tonumber(index))
		NotificationClient("New Request Received!")
	end)
end

Init()
return PlayerQuestClient
