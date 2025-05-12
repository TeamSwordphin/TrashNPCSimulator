--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

type Results = {
	Success: boolean,
}

local Signal = require(ReplicatedStorage.Libraries.LemonSignal)
local NetworkClient = require(script.Parent.NetworkClient)

local CommObject = NetworkClient:BuildObject()

local PlayerSellClient = {
	ItemSold = Signal.new(),
}

function PlayerSellClient:Sell(inventoryIndex: number): Results
	local results = CommObject:RequestSellItem(inventoryIndex)

	if results.Success then
		PlayerSellClient.ItemSold:Fire(results)
	end

	return results
end

return PlayerSellClient
