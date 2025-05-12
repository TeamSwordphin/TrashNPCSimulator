--!strict

local Types = require(script.Parent.EntityTypes)
local EntityChaser = {}

function EntityChaser:MoveToTarget(entity: Types.Entity, target: Model): Enum.PathStatus
	assert(entity, "Expecting Entity object")
	assert(target, "Expecting target!")

	local path: Path = entity.Path
	local primaryPart: BasePart? = target.PrimaryPart

	if not primaryPart then
		return Enum.PathStatus.NoPath
	end

	local originalPosition = primaryPart.Position

	path:ComputeAsync(entity.Model.PrimaryPart.Position, originalPosition)

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

		for i, waypoint: PathWaypoint in waypoints do
			-- Cancel the pathfinding if the target has strayed too far away
			if (primaryPart.Position - originalPosition).Magnitude > 10 then
				break
			end

			local clock = os.clock()

			while (waypoint.Position - entity.Model.PrimaryPart.Position).Magnitude >= 5 do
				if os.clock() - clock >= 5 then
					entity.Model:PivotTo(CFrame.new(waypoint.Position))
					task.wait(0.1)

					continue
				end

				MoveToWaypoint(waypoint)
			end
		end

		return path.Status
	end

	return Enum.PathStatus.NoPath
end

return EntityChaser
