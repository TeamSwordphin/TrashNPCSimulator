--!strict

local VOMIT_DURATION = 30

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local Entity = require(ServerStorage.EntityServer.Entity)
local PlayerDataService = require(ServerScriptService.Server.PlayerDataService)
local TrashItemData = require(ReplicatedStorage.Modules.TrashItemData)
local NPCLooterService = require(ServerScriptService.Server.NPCLooterService)
local PlayerLooterService = require(ServerScriptService.Server.PlayerLooterService)

local Item = {}

function Item:Activate(character)
	local head: BasePart = character:FindFirstChild("Head") :: BasePart

	for _, particle in ServerStorage.Assets.Particles.Vomit:GetChildren() do
		local vomitVFX = particle:Clone()
		vomitVFX.Parent = head
		task.delay(VOMIT_DURATION, vomitVFX.Destroy, vomitVFX)
	end
end

function Item:Create(player: Player, tool: Tool)
	local profileExport: PlayerDataService.ProfileExport? = PlayerDataService:GetProfile(player)
	local primaryPart: BasePart = tool.PrimaryPart :: BasePart
	local debounce: boolean = true

	primaryPart.Touched:Connect(function(hit)
		if not debounce then
			return
		else
			debounce = false
			task.delay(1, function()
				debounce = true
			end)
		end

		local entity = Entity:GetEntityFromModel(hit.Parent :: Instance)

		if entity and profileExport then
			local inventory = profileExport:Get("Inventory")

			for inventoryIndex, itemIndex in inventory do
				local itemInformation: TrashItemData.ItemData? = TrashItemData:Get(itemIndex)

				if itemInformation and itemInformation.Name == tool.Name then
					table.remove(inventory, inventoryIndex)
					break
				end
			end

			tool:Destroy()
			profileExport:Set("Inventory", inventory)
			entity:SetState("Vomit")
			NPCLooterService:DropLoot(player, entity)
		else
			local targetPlayer: Player? = Players:GetPlayerFromCharacter(hit.Parent)

			if not targetPlayer or targetPlayer == player then
				return
			end

			Item:Activate(targetPlayer.Character :: Model)
			PlayerLooterService:DropLoot(player, targetPlayer)
		end
	end)
end

return Item
