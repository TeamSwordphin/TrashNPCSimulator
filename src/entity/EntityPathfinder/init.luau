--!strict

local CollectionService = game:GetService("CollectionService")

local Types = require(script.Parent.EntityTypes)

local EntityPathfinder = {}

local SEED = Random.new()
local RandomSpawned = true

function EntityPathfinder:CalculateNextNode(entity: Types.Entity): number
	assert(entity, "Expecting Entity object")
	assert(entity.Model.PrimaryPart, "NPC missing PrimaryPart!")

	local direction: number = entity.Direction
	local nextNode: number = entity.CurrentNode + direction
	local maxNodes: number = entity.MaxNodes
	local lane: any = entity.Lane

	local canTraverse: boolean = false

	if direction == -1 then
		canTraverse = (nextNode >= 1)
	else
		canTraverse = (nextNode <= maxNodes)
	end

	if canTraverse then
		local currentNode: BasePart = lane[nextNode]
		local distance: number = (currentNode.Position - entity.Model.PrimaryPart.Position).Magnitude

		entity.CurrentNode += (distance <= 4 and direction or 0)
		entity.LaneTraversed = false

		return math.clamp(entity.CurrentNode + direction, 1, maxNodes)
	else
		-- Respawn Entity

		if entity.Look == "Homeless" then
			local lanes = CollectionService:GetTagged("LaneHomeless")
			entity:SetLaneProperties(lanes[Random.new():NextInteger(1, #lanes)])
		else
			entity:Destroy()
		end
	end

	return entity.CurrentNode
end

function EntityPathfinder:MoveToNextNode(entity: Types.Entity, nodeGoal: number): Enum.PathStatus
	assert(entity, "Expecting Entity object")

	if not entity.LaneTraversed then
		local lane: any = entity.Lane
		local currentNode: BasePart = lane[nodeGoal]

		local path: Path = entity.Path
		path:ComputeAsync(entity.Model.PrimaryPart.Position, currentNode.Position)

		if path.Status == Enum.PathStatus.Success then
			local humanoid: Humanoid = entity.Model.Humanoid

			local function MoveToWaypoint(waypoint: PathWaypoint)
				if waypoint.Action == Enum.PathWaypointAction.Jump then
					humanoid.Jump = true
				end

				humanoid:MoveTo(waypoint.Position)
				task.wait(0.1)
			end

			local waypoints = path:GetWaypoints()

			-- Teleport the entity to a random point
			if not entity.FirstSpawned and RandomSpawned then
				entity.FirstSpawned = true
				entity.Model:PivotTo(CFrame.new(waypoints[SEED:NextInteger(1, #waypoints)].Position))
			else
				for i, waypoint: PathWaypoint in waypoints do
					if entity.State == "Walking" or entity.State == "Hostile" then
						local clock = os.clock()

						while (waypoint.Position - entity.Model.PrimaryPart.Position).Magnitude >= 5 do
							if os.clock() - clock >= 5 then
								entity.Model:PivotTo(CFrame.new(waypoint.Position))
								task.wait(0.1)

								continue
							end

							MoveToWaypoint(waypoint)
						end
					else
						break
					end
				end
			end

			return path.Status
		end
	end

	return Enum.PathStatus.NoPath
end

task.delay(5, function()
	RandomSpawned = not RandomSpawned
end)

return EntityPathfinder
