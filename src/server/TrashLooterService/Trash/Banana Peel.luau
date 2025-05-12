--!strict

local PEEL_SELF_DELETE_TIMER = 120

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local Entity = require(ServerStorage.EntityServer.Entity)
local PlayerDataService = require(ServerScriptService.Server.PlayerDataService)
local TrashItemData = require(ReplicatedStorage.Modules.TrashItemData)
local CollisionGroups = require(ReplicatedStorage.Settings.CollisionGroups)
local NPCLooterService = require(ServerScriptService.Server.NPCLooterService)
local PlayerLooterService = require(ServerScriptService.Server.PlayerLooterService)

local Item = {}

function Item:Create(player: Player, tool: Tool)
	local profileExport: PlayerDataService.ProfileExport? = PlayerDataService:GetProfile(player)

	tool.Activated:Connect(function()
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

			-- Spawn the peel in the overworld!
			local handle: Part = tool.PrimaryPart :: Part

			local peel: Part = handle:Clone()
			peel.CollisionGroup = CollisionGroups.PLAYER_COLLISION_GROUP_ID
			peel.CFrame = handle.CFrame
			peel.CanCollide = true
			peel.Parent = workspace
			task.delay(PEEL_SELF_DELETE_TIMER, peel.Destroy, peel)

			task.delay(1.5, function()
				peel.Touched:Connect(function(hit)
					local entity = Entity:GetEntityFromModel(hit.Parent :: Instance)

					if entity then
						peel:Destroy()
						entity:SetState("Fall")
						NPCLooterService:DropLoot(player, entity)
					else
						local targetPlayer: Player? = Players:GetPlayerFromCharacter(hit.Parent)

						if not targetPlayer then
							return
						end

						local character: Model = targetPlayer.Character :: Model
						local rootPart: BasePart? = character.PrimaryPart

						if rootPart then
							rootPart:SetNetworkOwner(nil)
							rootPart.AssemblyLinearVelocity = Vector3.yAxis * 40
							rootPart.AssemblyAngularVelocity = Vector3.yAxis * 15
						end

						local humanoid: Humanoid = character:FindFirstChild("Humanoid") :: Humanoid
						humanoid:ChangeState(Enum.HumanoidStateType.Physics)

						peel:Destroy()
						PlayerLooterService:DropLoot(player, targetPlayer)

						task.wait(3)

						if rootPart then
							rootPart:SetNetworkOwnershipAuto()
						end

						humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
					end
				end)
			end)

			tool:Destroy()
		end
	end)
end

return Item
