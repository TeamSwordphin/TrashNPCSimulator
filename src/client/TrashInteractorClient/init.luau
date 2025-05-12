--!strict

local CollectionService = game:GetService("CollectionService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Janitor = require(ReplicatedStorage.Libraries.Janitor).new()
local Signal = require(ReplicatedStorage.Libraries.LemonSignal)

local TrashMinigameSettings = require(ReplicatedStorage.Settings.TrashMinigameSettings)
local GameSettings = require(ReplicatedStorage.Settings.GameSettings)
local TrashItemData = require(ReplicatedStorage.Modules.TrashItemData)
local PlayerStatData = require(ReplicatedStorage.Modules.PlayerStatData)

local TrashMinigameClient = require(script.Parent.TrashMinigameClient)
local ConfirmationClient = require(script.Parent.ConfirmationClient)
local NotificationClient = require(script.Parent.NotificationClient)
local PlayerDataClient = require(script.Parent.PlayerDataClient)
local NetworkClient = require(script.Parent.NetworkClient)

local CommObject = NetworkClient:BuildObject()
local TrashInteractor = {
	OnTrashTriggered = Signal.new(),
}

local CurrentEnergy = 0

local COLORS = {
	Selectable = Color3.fromRGB(0, 255, 0),
	Unselectable = Color3.fromRGB(255, 0, 0),
}

local function UpdateProximitySpeed(prompt: ProximityPrompt)
	-- local item = prompt.Parent :: Instance
	-- local trashLevel = item:GetAttribute("Level") or 1

	-- local rummageSpeed = PlayerStatData:Calculate("RummageSpeedScale")
	-- local speed = GameSettings.BASE_RUMMAGE_SPEED_SECONDS[trashLevel] / rummageSpeed
	-- prompt.HoldDuration = speed
end

local function OnRummageOrAccessChanged(key, value)
	if key == "Energy" then
		CurrentEnergy = value
	else
		if key == "RummageSpeedScale" or key ~= "TrashLevelAccess" then
			for _, prompt: ProximityPrompt in CollectionService:GetTagged("_TrashProximityPrompt") do
				UpdateProximitySpeed(prompt)
			end
		end
	end
end

local function FailureState(item: PVInstance)
	local character = Players.LocalPlayer.Character
	local rootPart = character.PrimaryPart
	local pivot = item:GetPivot() * CFrame.new(0, 2, 0)

	rootPart.Anchored = true
	character:PivotTo(pivot * CFrame.Angles(math.rad(180), 0, 0))

	task.wait(3)

	rootPart.Anchored = false
end

local function OnTrashObjectInstantiated(item: PVInstance)
	local trashLevel = item:GetAttribute("Level") or 1

	local proximityPrompt: ProximityPrompt = Instance.new("ProximityPrompt")
	proximityPrompt.ActionText = "Rummage"
	proximityPrompt.ObjectText = `Lv.{trashLevel} Trash`
	proximityPrompt:AddTag("_TrashProximityPrompt")
	proximityPrompt.Parent = item

	UpdateProximitySpeed(proximityPrompt)

	proximityPrompt.PromptShown:Connect(function()
		Janitor:Cleanup()

		local currentAccess: number = PlayerStatData:Calculate("TrashLevelAccess")
		local unlocked: boolean = currentAccess >= trashLevel :: number
		local color: Color3 = COLORS[unlocked and "Selectable" or "Unselectable"]

		local highlight: Highlight = Janitor:Add(Instance.new("Highlight"), "Destroy")
		highlight.Adornee = item
		highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		highlight.FillTransparency = 0.95
		highlight.FillColor = color
		highlight.OutlineColor = color
		highlight.Parent = item

		if unlocked then
			UpdateProximitySpeed(proximityPrompt)
		else
			proximityPrompt.HoldDuration = 0
		end
	end)

	proximityPrompt.PromptHidden:Connect(function()
		Janitor:Cleanup()
	end)

	proximityPrompt.Triggered:Connect(function()
		if PlayerStatData:Calculate("TrashLevelAccess") < trashLevel :: number then
			NotificationClient("Current Trash Level Access too low!")
			return
		end

		local inventorySize = #PlayerDataClient.Profile.Inventory
		local carryCapacity = PlayerStatData:Calculate("CarryCapacity")

		if inventorySize >= carryCapacity then
			NotificationClient("Cannot carry anymore trash!")
			return
		end

		local minigameSettings: TrashMinigameSettings.MinigameSettings =
			table.clone(TrashMinigameSettings.BASE_DIFFICULTIES[trashLevel])
		minigameSettings.Leniency *= PlayerStatData:Calculate("RummageSpeedScale")
		minigameSettings.BonusZone *= PlayerStatData:Calculate("ChanceRareItems")

		local minigameResults = TrashMinigameClient:Start(minigameSettings)

		--- Failed miserably! Put them in the trash! Serverside will also inflict them with a debuff
		if minigameResults.Successes == 0 and minigameResults.Failures > 0 then
			task.defer(FailureState, item)
		end

		local results = CommObject:RequestTrashPickup(item, minigameResults)
		local success: boolean = results.Success

		if success then
			local itemIndex: number = results.ItemIndex
			local itemData: TrashItemData.ItemData? = TrashItemData:Get(itemIndex)

			if itemData then
				NotificationClient(`Picked up {itemData.Name}!`)
				TrashInteractor.OnTrashTriggered:Fire(item)
			else
				NotificationClient(`Error! No Trash Item Data found with index {itemIndex}!`)
			end

			return
		end

		if CurrentEnergy == 0 then
			local response = ConfirmationClient:Ask("Would you like to purchase more Energy?")

			if response then
				MarketplaceService:PromptProductPurchase(Players.LocalPlayer, 3242587266) -- Energy gain product
			end

			return
		end

		NotificationClient("No trash was found!")
	end)
end

local function Init()
	if not PlayerDataClient.Loaded then
		PlayerDataClient.OnProfileLoaded:Wait()
	end

	PlayerDataClient.OnKeyChanged:Connect(OnRummageOrAccessChanged)
	CollectionService:GetInstanceAddedSignal("_TrashProximityPrompt", UpdateProximitySpeed)
	CollectionService:GetInstanceAddedSignal(GameSettings.TRASH_INTERACTABLE_TAG):Connect(OnTrashObjectInstantiated)

	for _, item in CollectionService:GetTagged(GameSettings.TRASH_INTERACTABLE_TAG) do
		OnTrashObjectInstantiated(item)
	end
end

Init()
return TrashInteractor
