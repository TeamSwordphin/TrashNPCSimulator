--!strict

local FALL_TIMER = 3

local ServerStorage = game:GetService("ServerStorage")

local Types = require(ServerStorage.EntityServer.EntityTypes)

local State = {}

function State:Cleanup(entity: Types.Entity, janitor)
	entity.Model.Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	janitor:Destroy()
end

function State:Activate(entity: Types.Entity)
	entity.Model.Humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	entity.Model.PrimaryPart.AssemblyLinearVelocity = Vector3.yAxis * 40
	entity.Model.PrimaryPart.AssemblyAngularVelocity = Vector3.yAxis * 15

	task.wait(FALL_TIMER)

	entity:SetState("Walking")
end

return State
