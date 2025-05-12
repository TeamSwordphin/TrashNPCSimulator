--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local PlayerDataService = require(script.Parent.PlayerDataService)
local NetworkService = require(script.Parent.NetworkService)

local GameSettings = require(ReplicatedStorage.Settings.GameSettings)
local Janitor = require(ReplicatedStorage.Libraries.Janitor)
local SleepItemData = require(ReplicatedStorage.Modules.SleepItemData)

local MAX_ENERGY = GameSettings.PLAYER_ENERGY_MAX
local RECHARGE_RATE = GameSettings.PLAYER_ENERGY_RECHARGE_RATE

type PlayerJanitorObject = {
	LastDelta: number,
	Janitor: Janitor.Janitor,
}

local Janitors: { [Player]: PlayerJanitorObject } = {}
local EnergyService = {}

--[[
	Returns the current Energy of the player. Also updates the Energy if time has passed,
	ensuring it is always up to date.
]]
function EnergyService:Check(player: Player): number
	assert(player, "Player must be passed!")

	local profileExport = PlayerDataService:GetProfile(player)

	if profileExport then
		local currentEnergy: number = profileExport:Get("Energy")
		local lastEnergyUsed: number = profileExport:Get("EnergyLastUseTime")

		local difference: number = os.time() - lastEnergyUsed
		local energyGained: number = math.floor(difference / RECHARGE_RATE)

		profileExport:Set("Energy", math.min(MAX_ENERGY, currentEnergy + energyGained))

		if energyGained > 0 then -- Update the timer if they gained energy.
			profileExport:Set("EnergyLastUseTime", os.time())
		end

		return profileExport:Get("Energy")
	end

	return 0
end

function EnergyService:Use(player: Player, energyUsed: number?): boolean
	assert(player, "Player must be passed!")

	local profileExport = PlayerDataService:GetProfile(player)

	if profileExport then
		local energyCost: number = energyUsed or 1
		local currentEnergy: number = profileExport:Get("Energy")

		if currentEnergy >= energyCost then
			if currentEnergy == MAX_ENERGY then -- Only start the timer if they are at full energy
				profileExport:Set("EnergyLastUseTime", os.time())
			end

			profileExport:Set("Energy", math.max(0, currentEnergy - energyCost))

			return true
		end
	end

	return false
end

function EnergyService:ToggleSleep(player: Player)
	Janitors[player].Janitor:Cleanup()

	local character = player.Character

	if not character then
		return
	end

	local humanoid: Humanoid? = character:FindFirstChildOfClass("Humanoid")
	local rootPart: BasePart? = character.PrimaryPart

	if not humanoid or not rootPart then
		return
	end

	player:SetAttribute("Sleeping", not player:GetAttribute("Sleeping"))

	if player:GetAttribute("Sleeping") then
		local profileExport = PlayerDataService:GetProfile(player)

		if profileExport then
			local sleepEquipped: number = profileExport:Get("SleepItemEquippedID")
			local sleepData = SleepItemData:Get(sleepEquipped)

			if not sleepData then
				return
			end

			local amount = math.floor(sleepData and sleepData.SleepQuality or 2)

			Janitors[player].Janitor:Add(
				RunService.PostSimulation:Connect(function(delta: number)
					Janitors[player].LastDelta += delta

					if Janitors[player].LastDelta < 1 then
						return
					end

					Janitors[player].LastDelta = 0
					profileExport:Set("EnergyLastUseTime", profileExport:Get("EnergyLastUseTime") - amount)
				end),
				"Disconnect"
			)

			local model: Model? = ServerStorage.Assets.Beds:FindFirstChild(sleepData.Model or "")

			if model then
				local offset = model:GetAttribute("RotationOffset") :: Vector3

				local clone = Janitors[player].Janitor:Add(model:Clone(), "Destroy")
				clone:PivotTo(
					character:GetPivot() * CFrame.Angles(math.rad(offset.X), math.rad(offset.Y), math.rad(offset.Z))
				)

				for _, part in clone:GetDescendants() do
					if part:IsA("BasePart") then
						part.Anchored = false
						part.CanTouch = false
						part.CanCollide = true
						part.Massless = true

						local weldConstraint: WeldConstraint = Instance.new("WeldConstraint")
						weldConstraint.Name = `{part.Name}->{rootPart.Name}`
						weldConstraint.Part0 = part
						weldConstraint.Part1 = rootPart
						weldConstraint.Parent = part
					end
				end

				clone.Parent = character
			end
		end
	end
end

local function OnPlayerAdded(player: Player)
	Janitors[player] = {
		LastDelta = 0,
		Janitor = Janitor.new(),
	}
end

local function OnPlayerRemoving(player: Player)
	Janitors[player].Janitor:Destroy()
	Janitors[player] = nil
end

local function OnToggleSleep(player: Player)
	EnergyService:ToggleSleep(player)
end

local function Init()
	local update = 9999

	RunService.PostSimulation:Connect(function(delta: number)
		update += delta

		if update < 1 then
			return
		end

		update = 0

		for _, player in Players:GetPlayers() do
			EnergyService:Check(player)
		end
	end)

	Players.PlayerAdded:Connect(OnPlayerAdded)
	Players.PlayerRemoving:Connect(OnPlayerRemoving)
	NetworkService:CreateSignal("ToggleSleep"):Connect(OnToggleSleep)
end

Init()
return EnergyService
