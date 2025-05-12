--!strict

local JUMP_DURATION = 20

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local Janitor = require(ReplicatedStorage.Libraries.Janitor)
local Entity = require(ServerStorage.EntityServer.Entity)
local PlayerDataService = require(ServerScriptService.Server.PlayerDataService)
local NPCLooterService = require(ServerScriptService.Server.NPCLooterService)
local TrashItemData = require(ReplicatedStorage.Modules.TrashItemData)
local PlayerLooterService = require(ServerScriptService.Server.PlayerLooterService)

local Item = {}

function Item:Create(player: Player, tool: Tool)
	local newJanitor = Janitor.new()
	local handle: BasePart = tool.PrimaryPart :: BasePart

	tool.Equipped:Connect(function()
		local character: Model = tool.Parent :: Model
		local humanoid: Humanoid = character:FindFirstChild("Humanoid") :: Humanoid

		local topHat: Accessory = newJanitor:Add(ReplicatedStorage.Assets.Accessories.TopHat:Clone(), "Destroy")
		humanoid:AddAccessory(topHat)

		newJanitor:Add(RunService.PostSimulation:Connect(function()
			humanoid.Jump = not humanoid.Jump
		end))

		newJanitor:Add(task.delay(JUMP_DURATION, newJanitor.Destroy, newJanitor))
	end)

	tool.Unequipped:Connect(function()
		if newJanitor.Cleanup then
			newJanitor:Cleanup()
		end
	end)

	tool.Destroying:Connect(function()
		if newJanitor.Destroy then
			newJanitor:Destroy()
		end
	end)

	local db = false

	handle.Touched:Connect(function(hit)
		if db or hit.Parent == nil then
			return
		end

		db = true

		local humanoid: Humanoid? = hit.Parent:FindFirstChildOfClass("Humanoid")

		if humanoid then
			handle.CanTouch = false
			humanoid:EquipTool(tool)

			task.delay(JUMP_DURATION, tool.Destroy, tool)

			-- Remove the tool if found in inventory, and also remove from inventory
			local entity = Entity:GetEntityFromModel(hit.Parent :: Instance)
			local profileExport: PlayerDataService.ProfileExport? = PlayerDataService:GetProfile(player)

			if profileExport then
				local inventory = profileExport:Get("Inventory")

				for inventoryIndex, itemIndex in inventory do
					local itemInformation: TrashItemData.ItemData? = TrashItemData:Get(itemIndex)

					if itemInformation and itemInformation.Name == tool.Name then
						table.remove(inventory, inventoryIndex)
						break
					end
				end

				profileExport:Set("Inventory", inventory)

				if entity then
					NPCLooterService:DropLoot(player, entity)
				else
					local targetPlayer = Players:GetPlayerFromCharacter(hit.Parent :: Instance)

					if targetPlayer then
						PlayerLooterService:DropLoot(player, targetPlayer)
					end
				end
			end
		end

		task.wait(1)

		db = false
	end)
end

return Item
