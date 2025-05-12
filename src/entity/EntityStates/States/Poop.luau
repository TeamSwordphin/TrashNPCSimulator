--!strict

local POOP_DURATION = 10
local SECONDS_BEFORE_RUNNING = 10

local ServerStorage = game:GetService("ServerStorage")

local Types = require(ServerStorage.EntityServer.EntityTypes)

local State = {}

function State:Cleanup(entity: Types.Entity, janitor)
	janitor:Destroy()
end

function State:Activate(entity: Types.Entity)
	entity.Model.Humanoid.WalkSpeed = 0

	for _, particle in ServerStorage.Assets.Particles.Poop:GetChildren() do
		local vomitVFX = particle:Clone()
		vomitVFX.Parent = entity.Model.PrimaryPart
		task.delay(POOP_DURATION, vomitVFX.Destroy, vomitVFX)
	end

	task.wait(SECONDS_BEFORE_RUNNING)

	entity:SetState("Run")
end

return State
