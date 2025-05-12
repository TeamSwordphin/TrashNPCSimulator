--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local Janitor = require(ReplicatedStorage.Libraries.Janitor)
local Entity = require(ServerStorage.EntityServer.Entity)
local EntityStates = require(ServerStorage.EntityServer.EntityStates)
local PlayerDataService = require(ServerScriptService.Server.PlayerDataService)
local NPCLooterService = require(ServerScriptService.Server.NPCLooterService)
local TrashItemData = require(ReplicatedStorage.Modules.TrashItemData)
local PlayerLooterService = require(ServerScriptService.Server.PlayerLooterService)

local SEED = Random.new()
local Item = {}

function Item:Create(player: Player, tool: Tool)
	local newJanitor = Janitor.new()
	local handle: BasePart = tool.PrimaryPart :: BasePart

	tool.Equipped:Connect(function()
		local character: Model = tool.Parent :: Model
		local humanoid: Humanoid = character:FindFirstChild("Humanoid") :: Humanoid

		for _, shoeAsset in ReplicatedStorage.Assets.Accessories.DancingShoes:GetChildren() do
			local shoe: Accessory = newJanitor:Add(shoeAsset:Clone(), "Destroy")
			humanoid:AddAccessory(shoe)
		end

		local entity = Entity:GetEntityFromModel(character :: Instance)

		if entity then
			entity:SetState("Dance")
		else
			if Players:GetPlayerFromCharacter(character) then
				local state = EntityStates:GetState("Dance")
				local animator: Animator = humanoid:FindFirstChild("Animator") :: Animator

				local animationList: { string } = state:GetDanceAnimations()
				local animation: Animation = newJanitor:Add(Instance.new("Animation"), "Destroy")
				animation.AnimationId = animationList[SEED:NextInteger(1, #animationList)]

				local load: AnimationTrack = newJanitor:Add(animator:LoadAnimation(animation), "Destroy")
				load.Looped = true
				load:Play()

				load.Destroying:Connect(function()
					load:Stop()
				end)

				newJanitor:Add(task.delay(state:GetDuration(), load.Destroy, load))
			end
		end
	end)

	tool.Unequipped:Connect(function()
		newJanitor:Cleanup()
	end)

	tool.Destroying:Connect(function()
		newJanitor:Destroy()
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

		db = false
	end)
end

return Item
