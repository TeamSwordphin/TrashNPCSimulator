local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local TrashItemData = require(ReplicatedStorage.Modules.TrashItemData)
local PlayerDataClient = require(ReplicatedStorage.Client.PlayerDataClient)
local Janitor = require(ReplicatedStorage.Libraries.Janitor).new()

local Frame

local KEYS = {
	[0] = "Zero",
	[1] = "One",
	[2] = "Two",
	[3] = "Three",
	[4] = "Four",
	[5] = "Five",
	[6] = "Six",
	[7] = "Seven",
	[8] = "Eight",
	[9] = "Nine",
}

local function OnProfileKeyChanged(inventory: any)
	Janitor:Cleanup()

	for index, itemIndex in inventory do
		Janitor:Add(task.defer(function()
			local itemData: TrashItemData.ItemData? = TrashItemData:Get(itemIndex)

			if not itemData then
				return
			end

			-- local isActive: Color3 = itemData.Tool and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 255, 255)

			local tool = Janitor:Add(Frame.Template.ToolSelection:Clone(), "Destroy")
			tool.Visible = true
			tool.LayoutOrder = index
			tool.KeyLabel.Text = tostring(index)
			tool.ImageButton.Image = itemData.Image
			-- tool.ImageButton.BackgroundColor3 = isActive
			-- tool.UIStroke.Enabled = isActive
			tool.UIStroke.Enabled = false
			tool:AddTag("_UIHotbarItem")
			tool.Parent = Frame

			local toolInstance

			local function OnItemSelected()
				if not toolInstance then
					return
				end

				if not itemData.Tool then
					return
				end

				for _, ui in CollectionService:GetTagged("_UIHotbarItem") do
					-- tool.UIStroke.Color = isActive
					tool.UIStroke.Enabled = false
				end

				if toolInstance.Parent == Players.LocalPlayer.Character then
					Players.LocalPlayer.Character.Humanoid:UnequipTools()
				else
					Players.LocalPlayer.Character.Humanoid:EquipTool(toolInstance)
					tool.UIStroke.Enabled = true
				end
			end

			tool.ImageButton.MouseButton1Click:Connect(OnItemSelected)

			Janitor:Add(UserInputService.InputEnded:Connect(function(inputObject: InputObject)
				if inputObject.KeyCode == Enum.KeyCode[KEYS[index]] then
					OnItemSelected()
				end
			end))

			toolInstance = itemData.Tool and Players.LocalPlayer.Backpack:WaitForChild(itemData.Name, 5)
		end))
	end
end

return function(frame)
	Frame = frame

	PlayerDataClient.OnKeyChanged:Connect(function(key: string, value: any)
		if key == "Inventory" then
			OnProfileKeyChanged(value)
		end
	end)

	OnProfileKeyChanged(PlayerDataClient.Profile.Inventory)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
end
