--!strict

--[[

	Manages Trash loots when players interact with them. Has basic sanity checking to ensure players don't collect
	all the trashes in a short amount of time.

	@author Phin 2025

]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LootPlan = require(ReplicatedStorage.Libraries.LootPlan)
-- local GameSettings = require(ReplicatedStorage.Settings.GameSettings)
local TrashMinigameSettings = require(ReplicatedStorage.Settings.TrashMinigameSettings)

local CooldownManager = require(ReplicatedStorage.Modules.CooldownManager)
local TrashItemData = require(ReplicatedStorage.Modules.TrashItemData)
local PlayerStatData = require(ReplicatedStorage.Modules.PlayerStatData)

local EnergyService = require(script.Parent.EnergyService)
local PlayerDataService = require(script.Parent.PlayerDataService)
local ServerComm = require(script.Parent.NetworkService)

local Freeze = require(ReplicatedStorage.Libraries.Freeze)
local Trashes = require(ReplicatedStorage.Libraries.Loader).LoadChildren(script.Trash)

local Seed = Random.new()
local TrashLooterService = {}

export type TrashLootResults = {
	Success: boolean,
	ItemIndex: number?,
}

function TrashLooterService:GrantToolInstance(player: Player, itemIndex: number)
	local itemData: TrashItemData.ItemData? = TrashItemData:Get(itemIndex :: number)

	if itemData and itemData.Tool then
		local tool: Tool? = ReplicatedStorage.Assets.Tools:FindFirstChild(itemData.Name)

		if tool then
			if not tool.PrimaryPart then
				error(`Tool {itemData.Name} must have a primaryPart!`)
			end

			local newTool: Tool = tool:Clone()
			newTool.Parent = player.Backpack
			Trashes[itemData.Name]:Create(player, newTool)
		else
			warn(`No tool with the name of {itemData.Name} was found! Could not clone!`)
		end
	end
end

function TrashLooterService:RewardTrash(
	player: Player,
	trashLevel: number,
	minigameResults: TrashMinigameSettings.MinigameResult
): TrashLootResults
	assert(player, "Target player must be passed in!")
	assert(typeof(trashLevel) == "number", "Trash Level needs to be a number!")

	-- Give them a debuff!
	if minigameResults.Successes == 0 and minigameResults.Failures > 0 then
		local possibleOutcomes = Freeze.Dictionary.filter(Trashes, function(v)
			return v.Activate ~= nil
		end)

		local list = Freeze.Dictionary.keys(possibleOutcomes)
		local outcome = list[Seed:NextInteger(1, #list)]

		if player.Character then
			Trashes[outcome]:Activate(player.Character)
		end

		return { Success = false }
	end

	local profile = PlayerDataService:GetProfile(player)

	if profile then
		local lootPool = TrashItemData:GetTrashDropPool(trashLevel)
		local newPlan = LootPlan.Single.new()

		for index, weight in lootPool do
			newPlan:Add(tostring(index), weight)
		end

		local bonus = tonumber(minigameResults.Bonuses) or 0
		local chance = PlayerStatData:Calculate("ChanceRareItems", player) * bonus
		local itemFound = newPlan:Roll(chance)

		if itemFound then
			local itemIndex = tonumber(itemFound)
			local inventory: { [number]: number } = profile:Get("Inventory")
			local carryCapacity: number = PlayerStatData:Calculate("CarryCapacity", player)

			if #inventory < carryCapacity then
				table.insert(inventory, itemIndex :: number)
			end

			TrashLooterService:GrantToolInstance(player, itemIndex :: number)
			profile:Set("Inventory", inventory)

			return { Success = true, ItemIndex = itemIndex }
		end
	end

	return { Success = false }
end

local function OnTrashRequestPickup(
	player: Player,
	item: BasePart,
	minigameResults: TrashMinigameSettings.MinigameResult
): TrashLootResults
	if item and EnergyService:Check(player) > 0 then
		local itemLevel = item:GetAttribute("Level") or 1
		local cooldownKey: string = `{player.UserId}_{itemLevel}`

		if CooldownManager:get(cooldownKey) == 0 then
			local character: Model? = player.Character

			-- Ensure the character isn't too far away to get this trash
			if character then
				if character.PrimaryPart then
					local dist = (item.Position - character.PrimaryPart.Position).Magnitude

					if dist >= 30 then
						return { Success = false }
					end
				end
			end

			local profile: PlayerDataService.ProfileExport? = PlayerDataService:GetProfile(player)

			if profile then
				-- local rummageSpeed = PlayerStatData:Calculate("RummageSpeedScale", player)

				-- CooldownManager:set(cooldownKey, GameSettings.BASE_RUMMAGE_SPEED_SECONDS[itemLevel] / rummageSpeed)
				EnergyService:Use(player)

				return TrashLooterService:RewardTrash(player, itemLevel :: number, minigameResults)
			end
		end
	end

	return { Success = false }
end

local function OnPlayerRemoving(player: Player)
	for level in TrashMinigameSettings.BASE_DIFFICULTIES do
		CooldownManager:destroy(`{player.UserId}_{level}`)
	end
end

local function OnPlayerAdded(player: Player)
	local profile: PlayerDataService.ProfileExport? = PlayerDataService:GetProfile(player)

	while profile == nil do
		PlayerDataService:GetProfile(player)
		task.wait(0.1)
	end

	local function OnCharacterAdded(character)
		if profile then
			for _, itemIndex in profile:Get("Inventory") do
				TrashLooterService:GrantToolInstance(player, itemIndex)
			end
		end
	end

	OnCharacterAdded(player.Character or player.CharacterAdded:Wait())
	player.CharacterAdded:Connect(OnCharacterAdded)
end

local function Init()
	Players.PlayerRemoving:Connect(OnPlayerRemoving)
	Players.PlayerAdded:Connect(OnPlayerAdded)
	ServerComm:BindFunction("RequestTrashPickup", OnTrashRequestPickup)

	for _, player in Players:GetPlayers() do
		OnPlayerAdded(player)
	end
end

Init()
return TrashLooterService
