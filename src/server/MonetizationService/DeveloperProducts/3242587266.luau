--!strict

--[[
	We shouldn't yield during the product granting process!

	Energy Refill developer product
]]

local ENERGY_TO_RESTORE_PER_USE = 5

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameSettings = require(ReplicatedStorage.Settings.GameSettings)
local EnergyService = require(ServerScriptService.Server.EnergyService)
local PlayerDataService = require(ServerScriptService.Server.PlayerDataService)

return function(player: Player)
	local profileData = PlayerDataService:GetProfile(player)

	if profileData then
		local amount: number = GameSettings.PLAYER_ENERGY_RECHARGE_RATE * ENERGY_TO_RESTORE_PER_USE

		profileData:Set("EnergyLastUseTime", profileData:Get("EnergyLastUseTime") - amount)
		EnergyService:Check(player) -- force update
	end
end
