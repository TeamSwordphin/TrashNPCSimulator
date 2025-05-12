--!strict

type Results = {
	Success: boolean,
	Stage: number?,
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataClient = require(script.Parent.PlayerDataClient)
local NotificationClient = require(script.Parent.NotificationClient)
local NetworkClient = require(script.Parent.NetworkClient)

local Stages = require(ReplicatedStorage.Libraries.Loader).LoadChildren(script.Stages)
local Janitor = require(ReplicatedStorage.Libraries.Janitor).new()

local CommObject = NetworkClient:BuildObject()
local StageDirectorClient = {}

local function ActivateCurrentStage(stage: number)
	assert(stage, "The current stage number must be passed!")

	Janitor:Cleanup()

	local currentStageCallback = Stages[tostring(stage)]

	if not currentStageCallback then
		warn(`No stage index of {stage} was found inside Stages!`)
		return
	end

	currentStageCallback(Janitor, StageDirectorClient)
end

function StageDirectorClient:GetStage(): number
	return PlayerDataClient.Profile.TutorialStage
end

function StageDirectorClient:NextStage(): number
	local results: Results = CommObject:RequestStageDirectorNextStage()

	if results.Success then
		ActivateCurrentStage(results.Stage :: number)
		NotificationClient("Tutorial Updated")
	else
		NotificationClient("Could not advance stage director!")
	end

	return results.Stage or StageDirectorClient:GetStage()
end

local function Init()
	if not PlayerDataClient.Loaded then
		PlayerDataClient.OnProfileLoaded:Wait()
	end

	ActivateCurrentStage(StageDirectorClient:GetStage())
end

Init()
return StageDirectorClient
