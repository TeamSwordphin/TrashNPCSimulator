--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Types = require(ServerStorage.EntityServer.EntityTypes)
local Pathfinder = require(ServerStorage.EntityServer.EntityPathfinder)
local Settings = require(ReplicatedStorage.Settings.NPCSettings)

local State = {}

function State:Cleanup(entity, janitor)
	janitor:Destroy()
end

function State:Activate(entity: Types.Entity, janitor)
	janitor:Add(task.defer(function()
		local check: number = 0
		local maxDistance: number = Settings.STRAYS_SETTINGS.Range
		local target = nil

		RunService.PostSimulation:Connect(function(delta: number)
			check += delta

			if check < 2 then
				return
			else
				check = 0
			end

			for _, player in Players:GetPlayers() do
				local character = player.Character

				if not character then
					continue
				end

				local rootPart = character.PrimaryPart
				local entityRoot = entity.Model.PrimaryPart

				if rootPart and entityRoot then
					local distance = (rootPart.Position - entityRoot.Position).Magnitude

					if distance <= maxDistance then
						maxDistance = distance
						target = character
					end
				end
			end

			if target then
				entity.Target = target
				entity:SetState("ChaseStray")
			end
		end)
	end))

	janitor:Add(task.defer(function()
		while entity.State == script.Name and not entity.LaneTraversed do
			local pathStatus: Enum.PathStatus = Pathfinder:MoveToNextNode(entity, Pathfinder:CalculateNextNode(entity))

			if pathStatus == Enum.PathStatus.NoPath then
				-- Probably stuck? We should teleport them
				entity.Model:PivotTo(entity.Lane[tostring(entity.CurrentNode)].CFrame)
			end
		end

		-- Finished traversal.
		entity:SetState("Idle")
	end))
end

return State
