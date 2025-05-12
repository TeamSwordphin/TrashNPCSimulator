export type Stat = {
	ID: number?,
	Name: string,
	Description: string,
	DisplayCoefficient: number,
	BaseValue: number,
	MaxLevel: number,
	CostPerLevel: number,
	ValuePerLevel: number,
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerStatData = { Stats = require(script.StatValues) }
local IS_CLIENT = RunService:IsClient()

function PlayerStatData:Calculate(key: string, player: Player?): number
	local currentStat: Stat? = PlayerStatData.Stats[key]

	assert(key, "A key value pertaining to a stat must be passed!")
	assert(currentStat, "Invalid stat type!")

	local profile

	if IS_CLIENT then
		local PlayerDataClient = require(ReplicatedStorage.Client.PlayerDataClient)
		profile = PlayerDataClient.Profile
	else
		assert(player, "Player must be passed in!")

		local PlayerDataService = require(ServerScriptService.Server.PlayerDataService)
		local profileExport = PlayerDataService:GetProfile(player)

		if profileExport then
			profile = profileExport.Profile.Data
		end
	end

	assert(profile, "No profile found!")

	return currentStat.BaseValue + (currentStat.ValuePerLevel * (profile[key] - 1))
end

return PlayerStatData
