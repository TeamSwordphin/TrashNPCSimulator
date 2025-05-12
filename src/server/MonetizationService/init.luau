--!strict

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = require(script.Parent.PlayerDataService)

local Loader = require(ReplicatedStorage.Libraries.Loader)

local PaidItems = {
	Products = Loader.LoadChildren(script.DeveloperProducts),
}

local Processing: { [Player]: boolean } = {}
local MAX_PURCHASE_LOG_COUNT: number = 30

type ReceiptInfo = {
	PurchaseId: string,
	PlayerId: number,
	ProductId: number,
	PlaceIdWherePurchased: number,
	CurrencySpent: number,
	CurrencyType: Enum.CurrencyType,
	ProductPurchaseChannel: Enum.ProductPurchaseChannel,
}

local function PurchaseIdCheckAsync(player, profile, purchase_id, grant_product_callback): Enum.ProductPurchaseDecision
	if profile:IsActive() ~= true then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	else
		Processing[player] = true

		local meta_data = profile.Metadata
		local local_purchase_ids = meta_data.Metatags.ProfilePurchaseIds
		local result

		if not local_purchase_ids then
			local_purchase_ids = {}
			meta_data.Metatags.ProfilePurchaseIds = local_purchase_ids
		end

		-- Granting product if not received:
		if not table.find(local_purchase_ids, purchase_id) then
			while #local_purchase_ids >= MAX_PURCHASE_LOG_COUNT do
				table.remove(local_purchase_ids, 1)
			end

			table.insert(local_purchase_ids, purchase_id)
			task.spawn(grant_product_callback)
		end

		local function check_latest_meta_tags()
			local saved_purchase_ids = meta_data.MetatagsLatest.ProfilePurchaseIds

			if saved_purchase_ids and table.find(saved_purchase_ids, purchase_id) then
				result = Enum.ProductPurchaseDecision.PurchaseGranted
			end
		end

		check_latest_meta_tags()

		local meta_tags_connection = profile.MetatagsUpdated:Connect(function()
			check_latest_meta_tags()

			if profile:IsActive() == false and result == nil then
				result = Enum.ProductPurchaseDecision.NotProcessedYet
			end
		end)

		while result == nil do
			task.wait()
		end

		meta_tags_connection:Disconnect()

		return result
	end
end

local function GrantProduct(player: Player, product_id: number)
	local product_function = PaidItems.Products[tostring(product_id)]

	if product_function ~= nil then
		local handledRewards, result = pcall(product_function, player)

		if not handledRewards then
			error(result)
		else
			Processing[player] = nil
		end
	else
		warn(`ProductId {tostring(product_id)} has not been defined in Products table`)
	end
end

local function ProcessReceipt(receipt_info: ReceiptInfo)
	local player = Players:GetPlayerByUserId(receipt_info.PlayerId)

	if player == nil then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local profileData = PlayerDataService:GetProfile(player)

	if profileData then
		return PurchaseIdCheckAsync(player, profileData.Profile, receipt_info.PurchaseId, function()
			GrantProduct(player, receipt_info.ProductId)
		end)
	else
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
end

local function OnPlayerRemoving(player: Player)
	Processing[player] = nil
end

local MonetizationService = {}

function MonetizationService:Purchase(player: Player, productType: "Products" | "GamePass", id: number)
	assert(PaidItems[productType] ~= nil, "Invalid product type!")

	if productType == "Products" then
		MarketplaceService:PromptProductPurchase(player, id)
	elseif productType == "GamePass" then
		--- something else
	end
end

local function Init()
	Players.PlayerRemoving:Connect(OnPlayerRemoving)
	MarketplaceService.ProcessReceipt = ProcessReceipt
end

Init()
return MonetizationService
