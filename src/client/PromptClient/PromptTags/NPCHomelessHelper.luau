local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerQuestClient = require(ReplicatedStorage.Client.PlayerQuestClient)
local PlayerDataClient = require(ReplicatedStorage.Client.PlayerDataClient)
local ConfirmationClient = require(ReplicatedStorage.Client.ConfirmationClient)

local QuestData = require(ReplicatedStorage.Modules.QuestData)
local PlayerStatData = require(ReplicatedStorage.Modules.PlayerStatData)
local Janitor = require(ReplicatedStorage.Libraries.Janitor).new()

local Freeze = require(ReplicatedStorage.Libraries.Freeze)
local List = Freeze.List
local Dictionary = Freeze.Dictionary

type Stat = PlayerStatData.Stat

local MESSAGE = {
	Request = "Accept this homeless' request? You cannot take more than one request at a time.",
	Completed = "Turn in this request?",
	Cancel = "Cancel your current request?",
}

local function OnPromptTriggered()
	Janitor:Cleanup()

	local message = MESSAGE.Request

	if PlayerDataClient.Profile.CurrentQuestId ~= 0 then
		local quest = QuestData:Get(PlayerDataClient.Profile.CurrentQuestId)

		if quest then
			local got = 0
			local maxCount = Dictionary.count(quest.ItemsRequired)

			for itemIndex: number, amount: number in quest.ItemsRequired do
				local count = List.count(PlayerDataClient.Profile.Inventory, function(value)
					return value == itemIndex
				end)

				if count >= amount then
					got += 1
				end
			end

			message = got >= maxCount and MESSAGE.Completed or MESSAGE.Cancel
		end
	end

	local response = ConfirmationClient:Ask(message)

	if response == true then
		PlayerQuestClient:GetRequest()
	end
end

return function(prompt: ProximityPrompt)
	prompt.Triggered:Connect(OnPromptTriggered)
end
