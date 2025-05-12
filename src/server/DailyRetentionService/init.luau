--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlaytimeRewards = require(ReplicatedStorage.Modules.PlaytimeRewards)
local PlayerStatData = require(ReplicatedStorage.Modules.PlayerStatData)

local ServerComm = require(script.Parent.NetworkService)
local PlayerDataService = require(script.Parent.PlayerDataService)

local DailyRetentionService = {}
local PlayerProgress = {}

function DailyRetentionService:GetProgress(player: Player)
	assert(player, "Player must be passed")
end

function DailyRetentionService:Redeem(player: Player, id: number): boolean
	local difference = os.time() - (player:GetAttribute("Joined") :: number)

	if PlayerProgress[player] + 1 == id then
		if difference >= PlaytimeRewards[id].TimeRequired then
			local profileExport = PlayerDataService:GetProfile(player)

			if profileExport then
				if PlaytimeRewards[id].Reward.Money then
					local lifeEarned: number = profileExport:Get("TotalLifetimeMoneyEarned")
					local money: number = profileExport:Get("Money")

					profileExport:Set("Money", money + PlaytimeRewards[id].Reward.Money)
					profileExport:Set("TotalLifetimeMoneyEarned", lifeEarned + PlaytimeRewards[id].Reward.Money)
				elseif PlaytimeRewards[id].Reward.Item then
					local inventory: { [number]: number } = profileExport:Get("Inventory")
					local carryCapacity: number = PlayerStatData:Calculate("CarryCapacity", player)

					if #inventory >= carryCapacity then
						return false
					end

					local itemIndex = PlaytimeRewards[id].Reward.Item

					table.insert(inventory, itemIndex :: number)
					require(script.Parent.TrashLooterService):GrantToolInstance(player, itemIndex :: number)
					profileExport:Set("Inventory", inventory)
				end
			end

			PlayerProgress[player] += 1
			player:SetAttribute("RetentionLevel", PlayerProgress[player])

			return true
		end
	end

	return false
end

function DailyRetentionService:RedeemDaily(player: Player, id: number): boolean
	local profileExport = PlayerDataService:GetProfile(player)

	if profileExport then
		local lastTimer = profileExport:Get("LastDailyGiftRedeemed")
		local currentDay = profileExport:Get("CurrentDailyGiftIndex")
		local canRedeem = false

		if id == currentDay then
			local timerGoal = (lastTimer + 86400)

			if os.time() >= timerGoal then
				canRedeem = true
			end
		end

		if canRedeem then
			if PlaytimeRewards[id].Reward.Money then
				local lifeEarned: number = profileExport:Get("TotalLifetimeMoneyEarned")
				local money: number = profileExport:Get("Money")

				profileExport:Set("Money", money + PlaytimeRewards[id].Reward.Money)
				profileExport:Set("TotalLifetimeMoneyEarned", lifeEarned + PlaytimeRewards[id].Reward.Money)
			elseif PlaytimeRewards[id].Reward.Item then
				local inventory: { [number]: number } = profileExport:Get("Inventory")
				local carryCapacity: number = PlayerStatData:Calculate("CarryCapacity", player)

				if #inventory >= carryCapacity then
					return false
				end

				local itemIndex = PlaytimeRewards[id].Reward.Item

				table.insert(inventory, itemIndex :: number)
				require(script.Parent.TrashLooterService):GrantToolInstance(player, itemIndex :: number)
				profileExport:Set("Inventory", inventory)
			end

			profileExport:Set("LastDailyGiftRedeemed", os.time())
			profileExport:Set("CurrentDailyGiftIndex", profileExport:Get("CurrentDailyGiftIndex") + 1)

			if profileExport:Get("CurrentDailyGiftIndex") > 7 then
				profileExport:Set("CurrentDailyGiftIndex", 1)
			end

			return true
		end
	end

	return false
end

local function OnPlaytimeRedeem(player: Player, id: number): boolean
	return DailyRetentionService:Redeem(player, id)
end

local function OnDailyRedeem(player: Player, id: number): boolean
	return DailyRetentionService:RedeemDaily(player, id)
end

local function OnPlayerAdded(player: Player)
	PlayerProgress[player] = 0
	player:SetAttribute("RetentionLevel", PlayerProgress[player])
end

local function OnPlayerRemoving(player: Player)
	PlayerProgress[player] = nil
end

local function Init()
	ServerComm:BindFunction("RequestPlaytimePickup", OnPlaytimeRedeem)
	ServerComm:BindFunction("RequestDailyPickup", OnDailyRedeem)

	Players.PlayerAdded:Connect(OnPlayerAdded)
	Players.PlayerRemoving:Connect(OnPlayerRemoving)

	for _, player in Players:GetPlayers() do
		OnPlayerAdded(player)
	end
end

Init()
return DailyRetentionService
