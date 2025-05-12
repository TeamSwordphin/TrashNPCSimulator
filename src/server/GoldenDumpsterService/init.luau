--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local GameSettings = require(ReplicatedStorage.Settings.GameSettings)
local NotificationReplicatorService = require(script.Parent.NotificationReplicatorService)
local TrashLooterService = require(script.Parent.TrashLooterService)

local SpawnLocations: { BasePart } = {}
local Timer: number = GameSettings.GOLDEN_CHEST_SPAWN_TIMER * 0.8
local RandomSeed = Random.new()

local GoldenDumpsterService = {}

local function Update(delta: number)
	Timer += delta

	if Timer <= GameSettings.GOLDEN_CHEST_SPAWN_TIMER then
		return
	else
		Timer = 0
	end

	if RandomSeed:NextInteger(1, 100) <= GameSettings.GOLDEN_CHEST_SPAWN_CHANCE then
		-- Delete any spawned dumpsters
		for _, dumpster in CollectionService:GetTagged("_GoldenDumpster") do
			dumpster:Destroy()
		end

		-- Spawn a dumpster
		local chosen: BasePart = SpawnLocations[RandomSeed:NextInteger(1, #SpawnLocations)]

		local dumpster: Model = ServerStorage.Assets.Misc.GoldenDumpster:Clone()
		dumpster:PivotTo(chosen.CFrame)
		dumpster:AddTag("_GoldenDumpster")

		local highlight: Highlight = Instance.new("Highlight")
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		highlight.FillTransparency = 1
		highlight.OutlineColor = Color3.fromRGB(255, 193, 22)
		highlight.Parent = dumpster

		local proximityPrompt: ProximityPrompt = Instance.new("ProximityPrompt")
		proximityPrompt.ObjectText = "Golden Dumpster"
		proximityPrompt.ActionText = "Receive 3 - 5 random items"
		proximityPrompt.HoldDuration = 3
		proximityPrompt.RequiresLineOfSight = false
		proximityPrompt.Parent = dumpster.PrimaryPart

		proximityPrompt.Triggered:Connect(function(player: Player)
			dumpster:Destroy()
			GoldenDumpsterService:Activate(player)
		end)

		dumpster.Parent = chosen
		NotificationReplicatorService:SendAll("A golden dumpster has spawned!")
	end
end

function GoldenDumpsterService:Activate(player: Player)
	for i = 1, Random.new():NextInteger(3, 5) do
		TrashLooterService:RewardTrash(player, 10)
	end
end

function GoldenDumpsterService:Init(part: BasePart)
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Transparency = 1

	table.insert(SpawnLocations, part)
end

local function Init()
	for _, part in CollectionService:GetTagged("GoldenDumpsterSpawner") do
		GoldenDumpsterService:Init(part)
	end

	RunService.PostSimulation:Connect(Update)
end

Init()
return GoldenDumpsterService
