--!strict

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ServerComm = require(script.Parent.NetworkService)
local PlayerDataService = require(script.Parent.PlayerDataService)
local CopService = require(script.Parent.CopService)

local TrashItemData = require(ReplicatedStorage.Modules.TrashItemData)
local PlayerStatData = require(ReplicatedStorage.Modules.PlayerStatData)
local GameSettings = require(ReplicatedStorage.Settings.GameSettings)
local NPCSettings = require(ReplicatedStorage.Settings.NPCSettings)

local PlayerLooterService = { SendClientPlayerItemDrop = ServerComm:CreateSignal("SendPlayerItemDrop") }

local PlayerDropQueue: { [Player]: { [string]: number } } = {}

type DropData = {
	Position: Vector3,
	Id: string,
	ItemIndex: number,
	IsPlayer: boolean,
}

local SEED = Random.new()

function PlayerLooterService:DropLoot(player: Player, targetPlayer: Player)
	if SEED:NextNumber(1, 100) > GameSettings.PLAYER_DROP_ITEM_CHANCE then
		return
	end

	assert(player, "Player must be passed in!")
	assert(targetPlayer, "Target player must be passed in!")

	local profile = PlayerDataService:GetProfile(player)
	local targetProfile = PlayerDataService:GetProfile(player)

	if profile and targetProfile then
		local inventory = targetProfile:Get("Inventory")
		local targetIndex = SEED:NextInteger(1, #inventory)
		local itemFound = inventory[targetIndex]

		if itemFound then
			itemFound = tonumber(itemFound)

			local itemInformation: TrashItemData.ItemData = TrashItemData:Get(itemFound) :: TrashItemData.ItemData

			-- Remove this item from the target player
			for inventoryIndex, itemIndex in inventory do
				local currentItemData = TrashItemData:Get(itemIndex)

				if currentItemData and currentItemData.Name == itemInformation.Name then
					table.remove(inventory, inventoryIndex)
					break
				end
			end

			targetProfile:Set("Inventory", inventory)

			-- Drop this item for the player
			local id: string = HttpService:GenerateGUID(false)
			PlayerDropQueue[player][id] = itemFound

			local targetCharacter = targetPlayer.Character :: Model
			local targetRoot = targetCharacter.PrimaryPart :: BasePart

			local dropData: DropData =
				{ Position = targetRoot.Position, Id = id, ItemIndex = itemFound, IsPlayer = true }
			PlayerLooterService.SendClientPlayerItemDrop:Fire(player, dropData)

			task.delay(GameSettings.NPC_POUCH_DELETION_TIME, function()
				PlayerDropQueue[player][id] = nil
			end)

			-- Alert police!
			if NPCSettings.COP_SETTINGS.ChaseOnPlayerPranks then
				CopService:Alert(player)
			end

			return { Success = true }
		end
	end

	return { Success = false }
end

function PlayerLooterService:PickupItem(player: Player, id: string): boolean
	local itemIndex = tonumber(PlayerDropQueue[player][id])
	local profile = PlayerDataService:GetProfile(player)

	if itemIndex and profile then
		local inventory: { [number]: number } = profile:Get("Inventory")
		local carryCapacity: number = PlayerStatData:Calculate("CarryCapacity", player)

		if #inventory < carryCapacity then
			table.insert(inventory, itemIndex :: number)
		end

		require(script.Parent.TrashLooterService):GrantToolInstance(player, itemIndex :: number)
		profile:Set("Inventory", inventory)
		PlayerDropQueue[player][id] = nil

		return true
	end

	return false
end

local function OnPickupRequest(player: Player, id: string): boolean
	return PlayerLooterService:PickupItem(player, id)
end

local function OnPlayerAdded(player: Player)
	PlayerDropQueue[player] = {}
end

local function OnPlayerRemoving(player: Player)
	PlayerDropQueue[player] = nil
end

local function Init()
	ServerComm:BindFunction("RequestPickupItemPlayer", OnPickupRequest)
	Players.PlayerAdded:Connect(OnPlayerAdded)
	Players.PlayerRemoving:Connect(OnPlayerRemoving)

	for _, player in Players:GetPlayers() do
		OnPlayerAdded(player)
	end
end

Init()

return PlayerLooterService
