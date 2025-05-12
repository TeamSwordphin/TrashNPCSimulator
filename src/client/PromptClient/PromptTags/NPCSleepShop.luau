--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local PlayerDataClient = require(ReplicatedStorage.Client.PlayerDataClient)
local NotificationClient = require(ReplicatedStorage.Client.NotificationClient)
local BedClient = require(ReplicatedStorage.Client.PlayerMerchantBedClient)

local Janitor = require(ReplicatedStorage.Libraries.Janitor).new()
local SleepData = require(ReplicatedStorage.Modules.SleepItemData)

local Interface = Players.LocalPlayer.PlayerGui:WaitForChild("BetterSleepItemUI")
Interface.Enabled = false

local CurrentlyEquippedBedId: number = 0
local CurrentlyOwnedSleepItems: { number } = {}

local function OnPromptTriggered()
	Janitor:Cleanup()

	for index, sleepData: SleepData.SleepItemData in SleepData:GetAll() do
		local numberIndex: number? = tonumber(index)

		if not numberIndex then
			continue
		end

		local equipped = CurrentlyEquippedBedId == numberIndex
		local owned = table.find(CurrentlyOwnedSleepItems, numberIndex)

		local frame = Janitor:Add(Interface.MainFrame.ScrollingFrame.Template.Slot:Clone(), "Destroy")
		frame.Visible = true
		frame.LayoutOrder = numberIndex
		frame.ItemName.Text = sleepData.Name
		frame.ItemQuality.Text = `Quality: {sleepData.SleepQuality}`
		frame.EquippedButton.Status.Text = owned and "EQUIP" or `BUY (${sleepData.Price})`
		frame:AddTag("UISleepButton")

		if equipped then
			frame.EquippedButton.Status.Text = "EQUIPPED"
		end

		frame.EquippedButton.MouseButton1Click:Connect(function()
			if owned then
				BedClient:Equip(numberIndex)
				CurrentlyEquippedBedId = numberIndex
				NotificationClient("Equipped!")
			else
				local response = BedClient:Buy(numberIndex)

				if response then
					table.insert(CurrentlyOwnedSleepItems, numberIndex)
					NotificationClient("Purchased!")
				else
					NotificationClient("Not enough money!")
				end
			end

			OnPromptTriggered()
		end)

		frame.Parent = Interface.MainFrame.ScrollingFrame
	end

	Interface.Enabled = true
end

local function OnInterfaceClose()
	Interface.Enabled = false
end

local function OnInterfaceEnabled()
	if not Interface.Enabled then
		return
	end

	Interface.MainFrame.Size = UDim2.fromScale(0, 0)

	TweenService
		:Create(Interface.MainFrame, TweenInfo.new(1, Enum.EasingStyle.Elastic), { Size = UDim2.fromScale(0.32, 0.5) })
		:Play()
end

local function OnSleepItemsChanged(key, value: number | { number })
	if key == "SleepItemEquippedID" then
		CurrentlyEquippedBedId = value :: number
	elseif key == "SleepItemsPurchased" then
		CurrentlyOwnedSleepItems = value :: { number }
	end
end

return function(prompt: ProximityPrompt)
	if not PlayerDataClient.Loaded then
		PlayerDataClient.OnProfileLoaded:Wait()
	end

	prompt.Triggered:Connect(OnPromptTriggered)
	Interface.MainFrame.CloseButton.MouseButton1Click:Connect(OnInterfaceClose)
	Interface:GetPropertyChangedSignal("Enabled"):Connect(OnInterfaceEnabled)
	PlayerDataClient.OnKeyChanged:Connect(OnSleepItemsChanged)

	OnSleepItemsChanged("SleepItemsPurchased", PlayerDataClient.Profile.SleepItemsPurchased)
end
