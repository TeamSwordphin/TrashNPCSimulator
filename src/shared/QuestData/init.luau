--!strict

local QuestData = {}
local Quests = {}

type ItemList = {
	[number]: number,
}

type RewardList = {
	[string]: any,
}

export type Quest = {
	ItemsRequired: ItemList,
	Name: string,
	Description: string,
	Rewards: RewardList,
}

function QuestData:Get(questId: number): Quest
	return Quests[questId]
end

function QuestData:GetAll()
	return Quests
end

local function Init()
	for _, quest: ModuleScript in script.Quests:GetChildren() do
		local load = require(quest) :: ModuleScript
		Quests[tonumber(quest.Name)] = load
	end
end

Init()
return QuestData
