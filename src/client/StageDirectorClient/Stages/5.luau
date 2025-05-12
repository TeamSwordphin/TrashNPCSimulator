--[[

	Opens the upgrade UI from the Upgrade Shop NPC. Only proceed when the player has upgraded the stat.

]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TutorialArrowClient = require(ReplicatedStorage.Client.TutorialArrowClient)
local PlayerDataClient = require(ReplicatedStorage.Client.PlayerDataClient)
local NotificationClient = require(ReplicatedStorage.Client.NotificationClient)
local HighlighterClient = require(ReplicatedStorage.Client.HighlighterClient)

local Janitor, StageDirectorClient

local function GetClosestUpgradeShopNPC()
	Janitor:Cleanup()
	NotificationClient("Sell the trash to earn money!")

	local character = Players.LocalPlayer.Character or Players.CharacterAdded:Wait()
	local maxDistance: number = 9999
	local currentBodyPart

	for _, prompt: ProximityPrompt in CollectionService:GetTagged("NPCUpgradePrompt") do
		local bodyPart: BasePart = prompt.Parent :: BasePart
		local distance: number = (bodyPart.Position - character.PrimaryPart.Position).Magnitude

		if distance < maxDistance then
			maxDistance = distance
			currentBodyPart = bodyPart
		end
	end

	if currentBodyPart then
		Janitor:Add(TutorialArrowClient:Render(character.PrimaryPart, currentBodyPart), "Cleanup")
		Janitor:Add(
			PlayerDataClient.OnKeyChanged:Connect(function(key)
				if key == "RummageSpeedScale" then
					Janitor:Cleanup()
					HighlighterClient:Disable()
					StageDirectorClient:NextStage()
				end
			end),
			"Disconnect"
		)

		local function OnUpgradeFrameInstantiated(upgradeFrame)
			if upgradeFrame:GetAttribute("Stat") == "RummageSpeedScale" then
				HighlighterClient:Enable(upgradeFrame.UpgradeButton)
			end
		end

		Janitor:Add(
			CollectionService:GetInstanceAddedSignal("UIUpgradeFrame"):Connect(OnUpgradeFrameInstantiated),
			"Disconnect"
		)

		for _, sellFrame in CollectionService:GetTagged("UIUpgradeFrame") do
			OnUpgradeFrameInstantiated(sellFrame)
		end
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
