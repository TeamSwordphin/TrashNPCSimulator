--!strict

local ServerComm = require(script.Parent.NetworkService)
local PlayerDataService = require(script.Parent.PlayerDataService)
local ToolService = require(script.Parent.ToolService)
local TrashItemData = require(game:GetService("ReplicatedStorage").Modules.TrashItemData)

type Results = {
	Success: boolean,
}

local function OnSellRequest(player: Player, inventoryIndex: number, doNotAddMoney: boolean?): Results
	local profileExport = PlayerDataService:GetProfile(player)

	if profileExport then
		local inventory = profileExport:Get("Inventory")
		local itemIndex: number = inventory[inventoryIndex]

		if itemIndex then
			local itemInformation: TrashItemData.ItemData? = TrashItemData:Get(itemIndex)

			if itemInformation then
				table.remove(inventory, inventoryIndex)

				profileExport:Set("Inventory", inventory)
				ToolService:DestroyTool(player, itemInformation.Name)

				if doNotAddMoney ~= true then
					local lifeEarned: number = profileExport:Get("TotalLifetimeMoneyEarned")
					local money: number = profileExport:Get("Money")

					profileExport:Set("Money", money + itemInformation.SellPrice)
					profileExport:Set("TotalLifetimeMoneyEarned", lifeEarned + itemInformation.SellPrice)
				end

				return { Success = true }
			end
		end
	end

	return { Success = false }
end

local PlayerSellService = {}

function PlayerSellService:Sell(player: Player, inventoryIndex: number, doNotAddMoney: boolean?): Results
	assert(player, "Player must be passed!")
	assert(inventoryIndex, "InventoryIndex must be passed!")

	return OnSellRequest(player, inventoryIndex, doNotAddMoney)
end

local function Init()
	ServerComm:BindFunction("RequestSellItem", OnSellRequest)
end

Init()
return PlayerSellService
