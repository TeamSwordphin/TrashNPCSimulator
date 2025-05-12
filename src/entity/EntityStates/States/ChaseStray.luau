--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local Types = require(ServerStorage.EntityServer.EntityTypes)
local NPCSettings = require(ReplicatedStorage.Settings.NPCSettings)
local Chaser = require(ServerStorage.EntityServer.EntityChaser)
local PlayerSellService = require(ServerScriptService.Server.PlayerSellService)
local PlayerDataService = require(ServerScriptService.Server.PlayerDataService)
local PlayerStatData = require(ReplicatedStorage.Modules.PlayerStatData)

local State = {}

function State:Reset(entity: Types.Entity)
	entity.Target = nil
	entity:SetState("Idle")
	entity:SetState("Walking")
end

function State:Cleanup(entity: Types.Entity, janitor)
	janitor:Destroy()
end

function State:Activate(entity: Types.Entity, janitor)
	janitor:Cleanup()

	if not entity.Target then
		State:Reset(entity)
		return
	end

	local humanoid: Humanoid? = entity.Target:FindFirstChild("Humanoid") :: Humanoid

	if not humanoid then
		State:Reset(entity)
		return
	end

	entity.Model.Humanoid.WalkSpeed = entity.WalkSpeed * NPCSettings.STRAYS_SETTINGS.RunMultiplier

	janitor:Add(task.defer(function()
		local lastAttackTime: number = os.clock()

		while entity.State == script.Name and entity.Target and entity.Target.PrimaryPart and humanoid.Health > 0 do
			local pathStatus: Enum.PathStatus = Chaser:MoveToTarget(entity, entity.Target)

			if pathStatus == Enum.PathStatus.NoPath then
				-- Probably stuck? We should teleport them
				entity.Model:PivotTo(entity.Lane[tostring(entity.CurrentNode)].CFrame)
			end

			if not entity.Target or not entity.Target.PrimaryPart then
				return
			end

			-- See if target is nearby. If they are, damage!
			local targetDistance: number = (entity.Target.PrimaryPart.Position - entity.Model.PrimaryPart.Position).Magnitude

			if targetDistance <= NPCSettings.STRAYS_SETTINGS.RangeToDamage then
				if os.clock() - lastAttackTime >= NPCSettings.STRAYS_SETTINGS.DamageCooldown then
					lastAttackTime = os.clock()

					if humanoid.Health > NPCSettings.STRAYS_SETTINGS.Damage then
						humanoid:TakeDamage(NPCSettings.STRAYS_SETTINGS.Damage)
					else
						humanoid:TakeDamage(999)

						-- Lose all items in inventory!
						local player: Player? = Players:GetPlayerFromCharacter(entity.Target)

						if player then
							local profileExport = PlayerDataService:GetProfile(player)

							if profileExport then
								for i = PlayerStatData:Calculate("CarryCapacity", player), 1, -1 do
									PlayerSellService:Sell(player, i, true)
								end
							end
						end
					end
				end
			end
		end

		-- Finished traversal. Go back to walking.
		State:Reset(entity)
	end))
end

return State
