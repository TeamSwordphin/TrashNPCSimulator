--!strict

local ServerStorage = game:GetService("ServerStorage")

local Types = require(ServerStorage.EntityServer.EntityTypes)
local Pathfinder = require(ServerStorage.EntityServer.EntityPathfinder)

local State = {}

function State:Cleanup(entity, janitor)
	janitor:Destroy()
end

function State:Activate(entity: Types.Entity, janitor)
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
