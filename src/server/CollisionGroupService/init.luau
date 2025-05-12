--!strict

local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CollisionGroups = require(ReplicatedStorage.Settings.CollisionGroups)
local Signal = require(ReplicatedStorage.Libraries.LemonSignal)

local CollisionGroupService = {
	Registered = false,
	Loaded = Signal.new(),
	Added = Signal.new(),
}

local function Init()
	for _, name in CollisionGroups do
		PhysicsService:RegisterCollisionGroup(name)
	end

	CollisionGroupService.Registered = true
	CollisionGroupService.Loaded:Fire()
end

Init()

function CollisionGroupService:RegisterCollisionGroup(name: string)
	PhysicsService:RegisterCollisionGroup(name)
	CollisionGroupService.Added:Fire(name)
end

return CollisionGroupService
