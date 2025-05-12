--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Entity = require(ServerStorage.EntityServer.Entity)
local NPCSettings = require(ReplicatedStorage.Settings.NPCSettings)

local HomelessService = {}

local function OnHomelessSpawned(npc: Model)
	local entity = Entity:GetEntityFromModel(npc)

	local proximityPrompt: ProximityPrompt = Instance.new("ProximityPrompt")
	proximityPrompt.ObjectText = "Homeless Person"
	proximityPrompt.ActionText = "Help"
	proximityPrompt.RequiresLineOfSight = false
	proximityPrompt.Parent = npc.PrimaryPart

	proximityPrompt.Triggered:Connect(function(player: Player)
		--
	end)
end

local function Init()
	CollectionService:GetInstanceAddedSignal("Homeless"):Connect(OnHomelessSpawned)

	for _, npc in CollectionService:GetTagged("Homeless") do
		OnHomelessSpawned(npc)
	end
end

Init()
return HomelessService
