--!strict

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local ServerComm = require(script.Parent.NetworkService)
local PlayerDataService = require(script.Parent.PlayerDataService)
local CopService = require(script.Parent.CopService)

local Types = require(ServerStorage.EntityServer.EntityTypes)

local PlayerStatData = require(ReplicatedStorage.Modules.PlayerStatData)
local TrashItemData = require(ReplicatedStorage.Modules.TrashItemData)
local LootPlan = require(ReplicatedStorage.Libraries.LootPlan)
local GameSettings = require(ReplicatedStorage.Settings.GameSettings)
local NPCSettings = require(ReplicatedStorage.Settings.NPCSettings)

local NPCLooterService = { SendClientItemDrop = ServerComm:CreateSignal("SendItemDrop") }

local PlayerDropQueue: { [Player]: { [string]: number } } = {}

type DropData = {
	Position: Vector3,
	Id: string,
	ItemIndex: number,
}

function NPCLooterService:DropLoot(player: Player, entity: Types.Entity)
	assert(player, "Target player must be passed in!")
	assert(entity, "Target entity must be passed in!")

	local profile = PlayerDataService:GetProfile(player)

	if profile then
		local lootPool = TrashItemData:GetNPCDropPool()
		local newPlan = LootPlan.Single.new()

		for index, weight in lootPool do
			newPlan:Add(tostring(index), weight)
		end

		local itemFound = newPlan:Roll(PlayerStatData:Calculate("ChanceNPCDropItems", player))

		if itemFound then
			if itemFound == "Nothing" then
				return
			end

			itemFound = tonumber(itemFound)

			local id: string = HttpService:GenerateGUID(false)
			PlayerDropQueue[player][id] = itemFound

			local dropData: DropData = { Position = entity.Model.PrimaryPart.Position, Id = id, ItemIndex = itemFound }
			NPCLooterService.SendClientItemDrop:Fire(player, dropData)

			task.delay(GameSettings.NPC_POUCH_DELETION_TIME, function()
				PlayerDropQueue[player][id] = nil
			end)

			-- Alert any cops nearby
			if NPCSettings.COP_SETTINGS.ChaseOnNPCPranks then
				CopService:Alert(player)
			end

			return { Success = true }
		end
	end

	return { Success = false }
end

function NPCLooterService:PickupItem(player: Player, id: string): boolean
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
	return NPCLooterService:PickupItem(player, id)
end

local function OnPlayerAdded(player: Player)
	PlayerDropQueue[player] = {}
end

local function OnPlayerRemoving(player: Player)
	PlayerDropQueue[player] = nil
end

local function Init()
	ServerComm:BindFunction("RequestPickupItem", OnPickupRequest)
	Players.PlayerAdded:Connect(OnPlayerAdded)
	Players.PlayerRemoving:Connect(OnPlayerRemoving)

	for _, player in Players:GetPlayers() do
		OnPlayerAdded(player)
	end
end

Init()

return NPCLooterService
