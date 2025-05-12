--[[

	Finds the Upgrade Shop NPC to direct players.

]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TutorialArrowClient = require(ReplicatedStorage.Client.TutorialArrowClient)
local PromptClient = require(ReplicatedStorage.Client.PromptClient)

local Janitor, StageDirectorClient

local function GetClosestUpgradeShopNPC()
	Janitor:Cleanup()

	local character = Players.LocalPlayer.Character or Players.CharacterAdded:Wait()
	local maxDistance: number = 9999
	local currentBodyPart, currentPrompt

	for _, prompt: ProximityPrompt in CollectionService:GetTagged("NPCUpgradePrompt") do
		local bodyPart: BasePart = prompt.Parent :: BasePart
		local distance: number = (bodyPart.Position - character.PrimaryPart.Position).Magnitude

		if distance < maxDistance then
			maxDistance = distance
			currentBodyPart = bodyPart
			currentPrompt = prompt
		end
	end

	if currentBodyPart then
		Janitor:Add(TutorialArrowClient:Render(character.PrimaryPart, currentBodyPart), "Cleanup")
		Janitor:Add(
			PromptClient.OnPromptTriggered:Connect(function(prompt: ProximityPrompt)
				if prompt == currentPrompt then
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
		CollectionService:GetInstanceAddedSignal("NPCUpgradePrompt"):Connect(GetClosestUpgradeShopNPC),
		"Disconnect"
	)
	GetClosestUpgradeShopNPC()
end

return function(janitor, stageDirectorClient)
	Janitor = janitor
	StageDirectorClient = stageDirectorClient
	Init()
end
