--!strict

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local PlayerDataClient = require(ReplicatedStorage.Client.PlayerDataClient)
-- local ConfirmationClient = require(ReplicatedStorage.Client.ConfirmationClient)

local Janitor = require(ReplicatedStorage.Libraries.Janitor).new()

local GameSettings = require(ReplicatedStorage.Settings.GameSettings)
local ConvertToMS = require(ReplicatedStorage.Modules.ConvertToMS)
local SleepData = require(ReplicatedStorage.Modules.SleepItemData)

local Frame
local LastUpdate = 0

local function OnButtonAddPrompt()
	-- local response = ConfirmationClient:Ask("Would you like to purchase more Energy?")

	-- if not response then
	-- 	return
	-- end

	MarketplaceService:PromptProductPurchase(Players.LocalPlayer, 3242587266) -- Energy gain product
end

local function OnProfileKeyChanged(newValue: number)
	local energyToGain: number = GameSettings.PLAYER_ENERGY_MAX - newValue

	Frame.Timer.Visible = false
	Janitor:Cleanup()

	if energyToGain > 0 then
		-- local gainEstimate: number = (GameSettings.PLAYER_ENERGY_RECHARGE_RATE * energyToGain)
		-- local endTime: number = LastUpdate + gainEstimate
		-- local difference: number = endTime - os.time()

		-- if difference > 0 then
		-- 	Frame.Timer.Visible = true

		-- 	local update: number = 999

		-- 	Janitor:Add(RunService.PostSimulation:Connect(function(delta: number)
		-- 		update += delta
		-- 		difference = endTime - os.time()

		-- 		if update < 1 then
		-- 			return
		-- 		end

		-- 		Frame.Timer.Text = `{ConvertToMS(difference)} til +1`
		-- 		update = 0
		-- 	end))
		-- end

		local energyRechargeTime: number = GameSettings.PLAYER_ENERGY_RECHARGE_RATE
		local nextEnergyTime: number = LastUpdate + energyRechargeTime
		local difference: number = nextEnergyTime - os.time()

		if difference > 0 then
			Frame.Timer.Visible = true

			local update: number = 999

			Janitor:Add(RunService.PostSimulation:Connect(function(delta: number)
				update += delta
				difference = nextEnergyTime - os.time()

				if update < 1 then
					return
				end

				Frame.Timer.Text = `{ConvertToMS(difference)} til +1`
				update = 0
			end))
		end
	end

	Frame.TextLabel.Text = `{newValue}/{GameSettings.PLAYER_ENERGY_MAX}`
	Frame.Add.Visible = newValue < GameSettings.PLAYER_ENERGY_MAX
end

local function OnSleepToggled()
	local sleeping = Players.LocalPlayer:GetAttribute("Sleeping")

	if sleeping then
		local sleepItem = SleepData:Get(PlayerDataClient.Profile.SleepItemEquippedID)

		if sleepItem then
			Frame.Timer.Multiplier.Text = `x{sleepItem.SleepQuality} Speed`
			Frame.Timer.Multiplier.Visible = true
		end
	else
		Frame.Timer.Multiplier.Visible = false
	end
end

return function(frame)
	Frame = frame

	PlayerDataClient.OnKeyChanged:Connect(function(key: string, value: any)
		if key == "Energy" then
			OnProfileKeyChanged(value)
		elseif key == "EnergyLastUseTime" then
			LastUpdate = value
		end
	end)

	Frame.Add.MouseButton1Click:Connect(OnButtonAddPrompt)
	Players.LocalPlayer:GetAttributeChangedSignal("Sleeping"):Connect(OnSleepToggled)

	OnSleepToggled()
	OnProfileKeyChanged(PlayerDataClient.Profile.EnergyLastUseTime)
	OnProfileKeyChanged(PlayerDataClient.Profile.Energy)
end
