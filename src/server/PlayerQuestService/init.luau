--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ServerComm = require(script.Parent.NetworkService)
local QuestData = require(ReplicatedStorage.Modules.QuestData)
local PlayerDataService = require(script.Parent.PlayerDataService)

local Freeze = require(ReplicatedStorage.Libraries.Freeze)
local List = Freeze.List
local Dictionary = Freeze.Dictionary

local Seed = Random.new()
local QuestKeySet = ServerComm:CreateSignal("QuestReceived")

local QuestSystem = {}

function QuestSystem:GetCurrentQuest(player: Player)
	assert(player, "Player must be passed")

	local quests = QuestData:GetAll()
	local index = Seed:NextInteger(1, #quests)
	local profileExport = PlayerDataService:GetProfile(player)

	if profileExport then
		if profileExport:Get("CurrentQuestId") == 0 then
			profileExport:Set("CurrentQuestId", index)
			QuestKeySet:Fire(player, index)
		else
			local quest = QuestData:Get(profileExport:Get("CurrentQuestId"))
			local got = 0
			local maxCount = Dictionary.count(quest.ItemsRequired)

			for itemIndex: number, amount: number in quest.ItemsRequired do
				local count = List.count(profileExport:Get("Inventory"), function(value)
					return value == itemIndex
				end)

				if count >= amount then
					got += 1
				end
			end

			if got >= maxCount then
				-- Remove the items
				local currentInventory = profileExport:Get("Inventory")

				for itemIndex: number, amount: number in quest.ItemsRequired do
					for i = #currentInventory, 1, -1 do
						local value = currentInventory[i]

						if value == itemIndex and amount > 0 then
							amount -= 1
							table.remove(currentInventory, i)
						end
					end
				end

				profileExport:Set("Inventory", currentInventory)

				-- Reward the money!
				local lifeEarned: number = profileExport:Get("TotalLifetimeMoneyEarned")
				local money: number = profileExport:Get("Money")

				profileExport:Set("Money", money + quest.Rewards.Money)
				profileExport:Set("TotalLifetimeMoneyEarned", lifeEarned + quest.Rewards.Money)
			end

			profileExport:Set("CurrentQuestId", 0)
			QuestKeySet:Fire(player, index)
		end
	end
end

local function OnQuestRequest(player: Player)
	return QuestSystem:GetCurrentQuest(player)
end

local function Init()
	ServerComm:BindFunction("GetCurrentQuest", OnQuestRequest)
end

Init()

return QuestSystem
