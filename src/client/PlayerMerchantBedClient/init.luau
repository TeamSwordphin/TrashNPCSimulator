--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

type Results = {
	Success: boolean,
}

local Signal = require(ReplicatedStorage.Libraries.LemonSignal)
local NetworkClient = require(script.Parent.NetworkClient)
local CommObject = NetworkClient:BuildObject()

local PlayerMerchantBedClient = {
	Purchased = Signal.new(),
	Equipped = Signal.new(),
}

function PlayerMerchantBedClient:Buy(index: number): Results
	local results = CommObject:RequestBuyBed(index)

	if results.Success then
		PlayerMerchantBedClient.Purchased:Fire(results)
	end

	return results
end

function PlayerMerchantBedClient:Equip(index: number): Results
	local results = CommObject:RequestEquipBed(index)

	if results.Success then
		PlayerMerchantBedClient.Equipped:Fire(results)
	end

	return results
end

return PlayerMerchantBedClient
