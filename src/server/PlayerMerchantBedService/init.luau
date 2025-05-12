--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ServerComm = require(script.Parent.NetworkService)
local PlayerDataService = require(script.Parent.PlayerDataService)
local SleepItemData = require(ReplicatedStorage.Modules.SleepItemData)

type Results = {
	Success: boolean,
}

local function OnBuyRequest(player: Player, index: number): Results
	local profileExport = PlayerDataService:GetProfile(player)

	if profileExport then
		local inventory = profileExport:Get("SleepItemsPurchased")
		local sleepItem = SleepItemData:Get(index)

		if not sleepItem or table.find(inventory, index) then
			return { Success = false }
		end

		local money: number = profileExport:Get("Money")

		if money >= sleepItem.Price then
			profileExport:Set("Money", money - sleepItem.Price)

			table.insert(inventory, index)
			profileExport:Set("SleepItemsPurchased", inventory)

			return { Success = true }
		end
	end

	return { Success = false }
end

local function OnEquipRequest(player: Player, index: number): Results
	local profileExport = PlayerDataService:GetProfile(player)

	if profileExport then
		local inventory = profileExport:Get("SleepItemsPurchased")
		local sleepItem = SleepItemData:Get(index)

		if not sleepItem or not table.find(inventory, index) then
			return { Success = false }
		end

		profileExport:Set("SleepItemEquippedID", index)

		return { Success = true }
	end

	return { Success = false }
end

local PlayerSellService = {}

function PlayerSellService:Buy(player: Player, index: number): Results
	assert(player, "Player must be passed!")
	assert(index, "SleepIndex must be passed!")

	return OnBuyRequest(player, index)
end

function PlayerSellService:Equip(player: Player, index: number): Results
	assert(player, "Player must be passed!")
	assert(index, "SleepIndex must be passed!")

	return OnEquipRequest(player, index)
end

local function Init()
	ServerComm:BindFunction("RequestBuyBed", OnBuyRequest)
	ServerComm:BindFunction("RequestEquipBed", OnEquipRequest)
end

Init()
return PlayerSellService
