local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local PlayerDataClient = require(ReplicatedStorage.Client.PlayerDataClient)
local PlayerSellClient = require(ReplicatedStorage.Client.PlayerSellClient)
local NotificationClient = require(ReplicatedStorage.Client.NotificationClient)

local Janitor = require(ReplicatedStorage.Libraries.Janitor).new()
local TrashItemData = require(ReplicatedStorage.Modules.TrashItemData)

local PlayerSellInterface = Players.LocalPlayer.PlayerGui:WaitForChild("SellItemUI")
PlayerSellInterface.Enabled = false

local function OnPromptTriggered()
	Janitor:Cleanup()

	for slot: number, itemIndex: number in PlayerDataClient.Profile.Inventory do
		local itemInformation: TrashItemData.ItemData? = TrashItemData:Get(itemIndex)

		if itemInformation then
			local sellFrame = Janitor:Add(PlayerSellInterface.MainFrame.ScrollingFrame.Template.Slot:Clone(), "Destroy")
			sellFrame.Visible = true
			sellFrame.LayoutOrder = slot
			sellFrame.Icon.Image = itemInformation.Image or ""
			sellFrame.Price.Text = `{itemInformation.Name} | Sell Price: {itemInformation.SellPrice}`
			sellFrame.Parent = PlayerSellInterface.MainFrame.ScrollingFrame
			sellFrame:AddTag("UISellFrame")

			sellFrame.SellButton.MouseButton1Click:Connect(function()
				local results = PlayerSellClient:Sell(slot)

				if results.Success then
					NotificationClient("Item sold success!")

					-- Refresh the window upon the inventory replicating
					Janitor:Add(
						PlayerDataClient.OnKeyChanged:Connect(function(key)
							if key == "Inventory" then
								OnPromptTriggered()
							end
						end),
						"Disconnect"
					)
				else
					NotificationClient("Could not sell this item!")
				end
			end)
		end
	end

	PlayerSellInterface.Enabled = true
end

local function OnPlayerSellInterfaceClose()
	PlayerSellInterface.Enabled = false
end

local function OnPlayerSellInterfaceOpen()
	if not PlayerSellInterface.Enabled then
		return
	end

	PlayerSellInterface.MainFrame.Size = UDim2.fromScale(0, 0)

	TweenService:Create(
		PlayerSellInterface.MainFrame,
		TweenInfo.new(1, Enum.EasingStyle.Elastic),
		{ Size = UDim2.fromScale(0.32, 0.55) }
	):Play()
end

return function(prompt: ProximityPrompt)
	prompt.Triggered:Connect(OnPromptTriggered)
	PlayerSellInterface:GetPropertyChangedSignal("Enabled"):Connect(OnPlayerSellInterfaceOpen)
	PlayerSellInterface.MainFrame.CloseButton.MouseButton1Click:Connect(OnPlayerSellInterfaceClose)
end
