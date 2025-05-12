--!strict

local ServerStorage = game:GetService("ServerStorage")

local Types = require(ServerStorage.EntityServer.EntityTypes)

local State = {}

function State:Cleanup(entity, janitor)
	janitor:Destroy()
end

function State:Activate(entity: Types.Entity)
	entity.Model.Humanoid.WalkSpeed = entity.WalkSpeed
end

return State
