--[[

	Opens the sell UI from the Pawn Shop NPC. Only proceed when the player has sold an item.

]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TutorialArrowClient = require(ReplicatedStorage.Client.TutorialArrowClient)
local PlayerSellClient = require(ReplicatedStorage.Client.PlayerSellClient)
local NotificationClient = require(ReplicatedStorage.Client.NotificationClient)
local HighlighterClient = require(ReplicatedStorage.Client.HighlighterClient)

local Janitor, StageDirectorClient

local function GetClosestPawnShopNPC()
	Janitor:Cleanup()
	NotificationClient("Sell the trash to earn money!")

	local character = Players.LocalPlayer.Character or Players.CharacterAdded:Wait()
	local maxDistance: number = 9999
	local currentBodyPart

	for _, prompt: ProximityPrompt in CollectionService:GetTagged("NPCSellPrompt") do
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
			PlayerSellClient.ItemSold:Connect(function()
				Janitor:Cleanup()
				HighlighterClient:Disable()
				StageDirectorClient:NextStage()
			end),
			"Disconnect"
		)
		Janitor:Add(CollectionService:GetInstanceAddedSignal("UISellFrame"):Connect(function(frame)
			HighlighterClient:Enable(frame.SellButton)
		end))

		for _, sellFrame in CollectionService:GetTagged("UISellFrame") do
			HighlighterClient:Enable(sellFrame.SellButton)
		end
	end
end

local function Init()
	Janitor:Add(CollectionService:GetInstanceAddedSignal("NPCSellPrompt"):Connect(GetClosestPawnShopNPC), "Disconnect")
	GetClosestPawnShopNPC()
end

return function(janitor, stageDirectorClient)
	Janitor = janitor
	StageDirectorClient = stageDirectorClient
	Init()
end
