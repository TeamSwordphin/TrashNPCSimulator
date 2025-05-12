--!strict

local ServerStorage = game:GetService("ServerStorage")

local Types = require(ServerStorage.EntityServer.EntityTypes)

local State = {}

function State:Cleanup(entity: Types.Entity, janitor)
	janitor:Destroy()
	--	entity.Model.Humanoid.WalkSpeed = entity.WalkSpeed
end

function State:Activate(entity: Types.Entity, janitor)
	janitor:Cleanup()

	entity.Model.Humanoid.WalkSpeed = entity.WalkSpeed * 6
	entity:SetState("Walking")

	janitor:Add(task.delay(30, function()
		entity.Model.Humanoid.WalkSpeed = entity.WalkSpeed
	end))
end

return State
