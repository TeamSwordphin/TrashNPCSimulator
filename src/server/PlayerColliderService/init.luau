--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CollisionGroups = require(ReplicatedStorage.Settings.CollisionGroups)
local CollisionGroupService = require(script.Parent.CollisionGroupService)

local PlayerCollisionGroupService = {}

local function OnCharacterAdded(character)
	local function OnPartAdded(part: any)
		if not part:IsA("BasePart") then
			return
		end

		part.CollisionGroup = CollisionGroups.PLAYER_COLLISION_GROUP_ID
	end

	character.DescendantAdded:Connect(OnPartAdded)

	for _, part in character:GetDescendants() do
		OnPartAdded(part)
	end
end

local function OnCollisionGroupRequestCreate(player: Player)
	local character = player.Character or player.CharacterAdded:Wait()

	player.CharacterAdded:Connect(OnCharacterAdded)
	OnCharacterAdded(character)
end

local function Init()
	if not CollisionGroupService.Registered then
		CollisionGroupService.Loaded:Wait()
	end

	Players.PlayerAdded:Connect(OnCollisionGroupRequestCreate)

	for _, player in Players:GetPlayers() do
		task.defer(OnCollisionGroupRequestCreate, player)
	end
end

Init()

function PlayerCollisionGroupService:CreateCollisionGroup(player: Player)
	OnCollisionGroupRequestCreate(player)
end

return PlayerCollisionGroupService
