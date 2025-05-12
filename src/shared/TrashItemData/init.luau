--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Loader = require(ReplicatedStorage.Libraries.Loader)

local ItemDatas = Loader.LoadChildren(script.Items)
local ChanceDatas = Loader.LoadChildren(script.LootPool)
local NPCChanceDatas = Loader.LoadChildren(script.NPCDropLootPool)

export type ItemData = {
	Name: string,
	Description: string,
	Image: string,
	SellPrice: number,
	Tool: boolean?,
}

export type ItemDataCollection = {
	[string]: ItemData,
}

-- [ItemIndex]: Weight
export type LootPool = {
	[number]: number,
}

local TrashData = {}

function TrashData:Get(itemIndex: number): ItemData?
	assert(typeof(itemIndex) == "number", "Index must be passed as a number!")

	return ItemDatas[tostring(itemIndex)]
end

function TrashData:GetAll(): ItemDataCollection
	return ItemDatas
end

function TrashData:GetTrashDropPool(trashLevel: number): LootPool
	assert(typeof(trashLevel) == "number", "Level of trash must be passed as a number!")

	return ChanceDatas[tostring(trashLevel)]
end

function TrashData:GetNPCDropPool(): LootPool
	return NPCChanceDatas["1"] --- TBD
end

return TrashData
