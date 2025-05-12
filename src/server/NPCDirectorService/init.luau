--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Types = require(ServerStorage.EntityServer.EntityTypes)
local Entity = require(ServerStorage.EntityServer.Entity)
local Settings = require(ReplicatedStorage.Settings.GameSettings)

local Seed = Random.new()
local NPCDirectorService = {}

function NPCDirectorService:GetRandomLane(): Instance
	local lanes = CollectionService:GetTagged("Lane")
	return lanes[Seed:NextInteger(1, #lanes)]
end

function NPCDirectorService:GetRandomHomelessLane(): Instance
	local lanes = CollectionService:GetTagged("LaneHomeless")
	return lanes[Seed:NextInteger(1, #lanes)]
end

function NPCDirectorService:GetRandomStrayLane(): Instance
	local lanes = CollectionService:GetTagged("LaneStrays")
	return lanes[Seed:NextInteger(1, #lanes)]
end

function NPCDirectorService:GenerateRandomNPC(entityString: string?): Types.Entity
	return Entity:Spawn(entityString)
end

local function GenerateNPC(entityString: string?)
	task.defer(function()
		local entity = NPCDirectorService:GenerateRandomNPC(entityString)
		entity.Destroyed:Connect(GenerateNPC)

		local newLook: string = entity.LooksChanged:Wait()

		if newLook == "Homeless" then
			entity:SetLaneProperties(NPCDirectorService:GetRandomHomelessLane())
			entity:SetState("Walking")
		elseif newLook == "Dog" or newLook == "Rat" then
			entity:SetLaneProperties(NPCDirectorService:GetRandomStrayLane())
			entity:SetState("Hostile")
		else
			entity:SetLaneProperties(NPCDirectorService:GetRandomLane())
			entity:SetState("Walking")
		end
	end)
end

local function Init()
	for i = 1, Settings.NPC_AMOUNT do
		GenerateNPC()
	end

	for i = 1, Settings.NPC_STRAYS_AMOUNT do
		GenerateNPC("Dog")
	end
end

Init()
return NPCDirectorService
