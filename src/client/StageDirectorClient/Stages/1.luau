--[[

	The first tutorial. Finds the nearest trash to direct player's onboarding to.

]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameSettings = require(ReplicatedStorage.Settings.GameSettings)
local TutorialArrowClient = require(ReplicatedStorage.Client.TutorialArrowClient)
local TrashInteractorClient = require(ReplicatedStorage.Client.TrashInteractorClient)

local Janitor, StageDirectorClient

local function GetClosestTrashPile()
	Janitor:Cleanup()

	local character = Players.LocalPlayer.Character or Players.CharacterAdded:Wait()
	local maxDistance: number = 9999
	local currentTrash

	for _, item in CollectionService:GetTagged(GameSettings.TRASH_INTERACTABLE_TAG) do
		local distance: number = (item.Position - character.PrimaryPart.Position).Magnitude
		local itemLevel: number = item:GetAttribute("Level") or 1

		-- Search only for Trash Access Level 1 bins
		if itemLevel <= 1 and distance < maxDistance then
			maxDistance = distance
			currentTrash = item
		end
	end

	if currentTrash then
		Janitor:Add(TutorialArrowClient:Render(character.PrimaryPart, currentTrash), "Cleanup")
		Janitor:Add(
			TrashInteractorClient.OnTrashTriggered:Connect(function(trashTriggered: Instance)
				if trashTriggered == currentTrash then
					Janitor:Cleanup()
					StageDirectorClient:NextStage()
				end
			end),
			"Disconnect"
		)
	end
end

local function Init()
	Janitor:Add(
		CollectionService:GetInstanceAddedSignal(GameSettings.TRASH_INTERACTABLE_TAG):Connect(GetClosestTrashPile),
		"Disconnect"
	)
	GetClosestTrashPile()
end

return function(janitor, stageDirectorClient)
	Janitor = janitor
	StageDirectorClient = stageDirectorClient
	Init()
end
