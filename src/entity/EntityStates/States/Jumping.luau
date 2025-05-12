local JUMPING_DURATION = 30

local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Types = require(ServerStorage.EntityServer.EntityTypes)

local State = {}

function State:Cleanup(entity, janitor)
	janitor:Destroy()
end

function State:Activate(entity: Types.Entity, janitor)
	janitor:Add(
		RunService.PostSimulation:Connect(function()
			entity.Model.Humanoid.Jump = not entity.Model.Humanoid.Jump
		end),
		"Disconnect"
	)

	janitor:Add(task.delay(JUMPING_DURATION, State.Cleanup, State, entity, janitor))
end

return State
