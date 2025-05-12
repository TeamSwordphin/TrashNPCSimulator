--!strict

local PathfindingService = game:GetService("PathfindingService")
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local LemonSignal = require(ReplicatedStorage.Libraries.LemonSignal)
local NPCSettings = require(ReplicatedStorage.Settings.NPCSettings)
local CollisionGroups = require(ReplicatedStorage.Settings.CollisionGroups)

local Types = require(script.Parent.EntityTypes)
local EntityStates = require(script.Parent.EntityStates)
local EntityLooks = require(script.Parent.EntityLooks)

local CollisionGroupService = require(ServerScriptService.Server.CollisionGroupService)

local NPCContainer = workspace.NPCContainer
local Seed = Random.new()

local EntitySpawnerServer = {}
local Entities = {}

local DEFAULT_PARAMETERS = {
	AgentRadius = 5,
	AgentHeight = 4,
	AgentCanJump = true,
	AgentCanClimb = true,
	WaypointSpacing = 2,
	Costs = {},
}

local DISPLAY_TYPE = NPCSettings.SHOW_STATE_ABOVE_HEAD and Enum.HumanoidDisplayDistanceType.Viewer
	or Enum.HumanoidDisplayDistanceType.None

local function ConvertToColliderGroupEntity(entity: Types.Entity)
	for _, part in entity.Model:GetDescendants() do
		if not part:IsA("BasePart") then
			continue
		end

		part.CollisionGroup = CollisionGroups.NPC_COLLISION_GROUP_ID
	end
end

local function CreateColliderGroup()
	PhysicsService:CollisionGroupSetCollidable(
		CollisionGroups.NPC_COLLISION_GROUP_ID,
		CollisionGroups.NPC_COLLISION_GROUP_ID,
		false
	)
	PhysicsService:CollisionGroupSetCollidable(
		CollisionGroups.PLAYER_COLLISION_GROUP_ID,
		CollisionGroups.NPC_COLLISION_GROUP_ID,
		false
	)
end

local function Init()
	if not CollisionGroupService.Registered then
		CollisionGroupService.Loaded:Wait()
	end

	CreateColliderGroup()
end

Init()

function EntitySpawnerServer:Spawn(entityName: string?, agentParameters: Types.AgentParameter?): Types.Entity
	local entity = {
		Model = ServerStorage.Assets.Entity[entityName or "NPC"]:Clone(),
		Path = PathfindingService:CreatePath(agentParameters or table.clone(DEFAULT_PARAMETERS)),
		State = "Idle",
		WalkSpeed = 16,
		CurrentNode = 1,
		LaneTraversed = false,
		Direction = 1,
		FirstSpawned = false,
		StateChanged = LemonSignal.new(),
		Destroyed = LemonSignal.new(),
		LooksChanged = LemonSignal.new(),
	}

	function entity:SetLaneProperties(lane: any)
		assert(lane, "Must designate a lane for the NPC!")

		local maxNodes = #lane:GetChildren()
		entity.MaxNodes = maxNodes
		entity.Lane = lane

		if Seed:NextInteger(1, 2) == 1 then
			entity.CurrentNode = maxNodes
			entity.Direction = -1
		end

		entity.Model:PivotTo(lane[tostring(entity.CurrentNode)].CFrame)
	end

	function entity:Destroy()
		task.defer(function()
			Entities[entity.Model] = nil
			entity.LaneTraversed = true
			entity.StateChanged:Destroy()
			entity.Model:Destroy()
			entity.Destroyed:Fire()
			entity.Destroyed:Destroy()
		end)
	end

	function entity:SetState(newState: string)
		task.defer(function() -- Defer is required to keep the ordering consistent
			if newState then
				entity.StateChanged:Fire(entity.State, newState)
				entity.State = newState
				entity.Model.Humanoid.DisplayName = `State: {newState}`
			end
		end)
	end

	ConvertToColliderGroupEntity(entity)

	entity.WalkSpeed = entity.Model.Humanoid.WalkSpeed
		* Seed:NextNumber(NPCSettings.WALK_SPEED_RANGE_SCALES.Minimum, NPCSettings.WALK_SPEED_RANGE_SCALES.Maximum)

	task.defer(EntityLooks.Generatelook, EntityLooks, entity)
	EntityStates:ActivateStateListeners(entity)

	entity:SetState(entity.State)
	entity.Model.Humanoid.DisplayDistanceType = DISPLAY_TYPE
	entity.Model.Humanoid.WalkSpeed = entity.WalkSpeed
	entity.Model:AddTag("NPC")
	entity.Model:PivotTo(CFrame.new(0, 99999999, 0))
	entity.Model.Parent = NPCContainer

	Entities[entity.Model] = entity

	return entity
end

function EntitySpawnerServer:GetEntityFromModel(model: Instance): Types.Entity?
	return Entities[model]
end

return EntitySpawnerServer
