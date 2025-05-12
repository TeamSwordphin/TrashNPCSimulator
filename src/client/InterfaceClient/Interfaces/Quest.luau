local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataClient = require(ReplicatedStorage.Client.PlayerDataClient)
local PlayerQuestClient = require(ReplicatedStorage.Client.PlayerQuestClient)

local QuestData = require(ReplicatedStorage.Modules.QuestData)
local TrashItemData = require(ReplicatedStorage.Modules.TrashItemData)

local Janitor = require(ReplicatedStorage.Libraries.Janitor).new()
local Freeze = require(ReplicatedStorage.Libraries.Freeze)

local List = Freeze.List
local Frame

local function OnQuestUpdated(index: number)
	Janitor:Cleanup()

	local quest = QuestData:Get(PlayerDataClient.Profile.CurrentQuestId)

	if not quest then
		Frame.Visible = false
		return
	end

	for itemIndex: number, amount: number in quest.ItemsRequired do
		local item = TrashItemData:Get(itemIndex)

		if not item then
			warn(`No item with the id {itemIndex} was found`)
			continue
		end

		local count = List.count(PlayerDataClient.Profile.Inventory, function(value)
			return value == itemIndex
		end)

		local objective = Janitor:Add(Frame.Template.Objective:Clone(), "Destroy")
		objective.Text = `Find {item.Name} {count}/{amount}`
		objective.Visible = true
		objective.Parent = Frame

		if count >= amount then
			objective.TextColor3 = Color3.fromRGB(0, 255, 0)
		end
	end

	local reward = Janitor:Add(Frame.Template.Objective:Clone(), "Destroy")
	reward.Text = `Reward: {quest.Rewards.Money} Money`
	reward.TextColor3 = Color3.fromRGB(251, 255, 25)
	reward.Visible = true
	reward.Parent = Frame

	Frame.Visible = true
end

return function(frame)
	Frame = frame
	PlayerQuestClient.QuestReceived:Connect(OnQuestUpdated)

	PlayerDataClient.OnKeyChanged:Connect(function(key: string, value: any)
		if key == "Inventory" or key == "CurrentQuestId" then
			OnQuestUpdated(PlayerDataClient.Profile.CurrentQuestId)
		end
	end)

	OnQuestUpdated(PlayerDataClient.Profile.CurrentQuestId)
end
