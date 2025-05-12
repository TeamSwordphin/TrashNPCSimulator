local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ServerComm = require(script.Parent.NetworkService)
local PlayerDataService = require(script.Parent.PlayerDataService)
local PlayerStatData = require(ReplicatedStorage.Modules.PlayerStatData)

local PlayerUpgradeService = {}

local function OnUpgradeKeyRequest(player: Player, key: string)
	local statData: PlayerStatData.Stat = PlayerStatData.Stats[key]

	assert(statData, "Invalid key passed into stats!")

	local profileExport = PlayerDataService:GetProfile(player)

	if profileExport then
		local currentLevel = profileExport:Get(key)
		local currentMoney = profileExport:Get("Money")
		local currentPrice = statData.CostPerLevel * currentLevel

		if currentMoney >= currentPrice and currentLevel < statData.MaxLevel then
			profileExport:Set("Money", currentMoney - currentPrice)
			profileExport:Set(key, currentLevel + 1)

			return { Success = true }
		end
	end

	return { Success = false }
end

function PlayerUpgradeService:Upgrade(player: Player, key: string)
	assert(player, "Player must be passed!")
	assert(key, "Stat Key must be passed!")

	return OnUpgradeKeyRequest(player, key)
end

local function Init()
	ServerComm:BindFunction("RequestUpgradeStat", OnUpgradeKeyRequest)
end

Init()
return PlayerUpgradeService
