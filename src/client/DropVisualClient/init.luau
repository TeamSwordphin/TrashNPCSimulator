--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Libraries.LemonSignal)
local TrashItemData = require(ReplicatedStorage.Modules.TrashItemData)
local CollisionGroups = require(ReplicatedStorage.Settings.CollisionGroups)
local GameSettings = require(ReplicatedStorage.Settings.GameSettings)
local NotificationClient = require(ReplicatedStorage.Client.NotificationClient)

local NetworkClient = require(script.Parent.NetworkClient)
local CommObject = NetworkClient:BuildObject()

local DropVisualClient = {
	ItemDropped = Signal.new(),
}

type DropData = {
	Position: Vector3,
	Id: string,
	ItemIndex: number,
	IsPlayer: boolean?,
}

local function OnItemDropped(dropData: DropData)
	local itemIndex = dropData.ItemIndex
	local item = TrashItemData:Get(itemIndex)

	if not item then
		return
	end

	local pouch = ReplicatedStorage.Assets.Misc.Pouch:Clone()
	pouch.PrimaryPart.CollisionGroup = CollisionGroups.NPC_COLLISION_GROUP_ID
	pouch:PivotTo(CFrame.new(dropData.Position))
	pouch.Parent = workspace
	task.delay(GameSettings.NPC_POUCH_DELETION_TIME, pouch.Destroy, pouch)

	if item.Tool then
		local tool: Tool? = ReplicatedStorage.Assets.Tools:FindFirstChild(item.Name)

		if tool then
			for _, part in pouch:GetDescendants() do
				if part:IsA("BasePart") then
					part.Transparency = 1
				end
			end

			local toolClone = tool:Clone()
			toolClone:PivotTo(pouch:GetPivot())

			local model = Instance.new("Model")
			model.PrimaryPart = toolClone.PrimaryPart

			for _, part in toolClone:GetChildren() do
				part.Parent = model
			end

			toolClone:Destroy()

			local weldConstraint = Instance.new("WeldConstraint")
			weldConstraint.Part0 = model.PrimaryPart :: BasePart
			weldConstraint.Part1 = pouch.PrimaryPart
			weldConstraint.Parent = pouch.PrimaryPart
		end
	end

	local touched = false

	pouch.PrimaryPart.Touched:Connect(function(hit)
		if touched then
			return
		end

		touched = true
		pouch:Destroy()

		local success: boolean = dropData.IsPlayer and CommObject:RequestPickupItemPlayer(dropData.Id)
			or CommObject:RequestPickupItem(dropData.Id)

		if not success then
			NotificationClient("This item no longer exists.")
		end

		touched = false
	end)

	DropVisualClient.ItemDropped:Fire(dropData)

	task.delay(2, function()
		pouch.PrimaryPart.CanTouch = true
	end)
end

local function Init()
	NetworkClient:GetSignal("SendItemDrop"):Connect(OnItemDropped)
	NetworkClient:GetSignal("SendPlayerItemDrop"):Connect(OnItemDropped)
end

Init()
return DropVisualClient
