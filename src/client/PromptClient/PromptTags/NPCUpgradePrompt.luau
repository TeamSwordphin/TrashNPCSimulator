--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local PlayerDataClient = require(ReplicatedStorage.Client.PlayerDataClient)
local PlayerUpgradeClient = require(ReplicatedStorage.Client.PlayerUpgradeClient)
local NotificationClient = require(ReplicatedStorage.Client.NotificationClient)

local PlayerStatData = require(ReplicatedStorage.Modules.PlayerStatData)
local Janitor = require(ReplicatedStorage.Libraries.Janitor).new()

local PlayerStatInterface = Players.LocalPlayer.PlayerGui:WaitForChild("UpgradesItemUI")
PlayerStatInterface.Enabled = false

type Stat = PlayerStatData.Stat

local function OnPromptTriggered()
	Janitor:Cleanup()

	for k, value in PlayerStatData.Stats :: { Stat } do
		local key = tostring(k)

		if not key then
			continue
		end

		local upgradeFrame = Janitor:Add(PlayerStatInterface.MainFrame.ScrollingFrame.Template.Slot:Clone(), "Destroy")
		upgradeFrame.Visible = true
		upgradeFrame.LayoutOrder = value.ID or 999
		upgradeFrame:AddTag("UIUpgradeFrame")
		upgradeFrame:SetAttribute("Stat", key)
		upgradeFrame.Parent = PlayerStatInterface.MainFrame.ScrollingFrame

		local function updateDisplayValues()
			local currentLevel: number = PlayerDataClient.Profile[key]
			local maxed: boolean = currentLevel >= value.MaxLevel
			local showPerc = value.DisplayCoefficient > 1 and "%" or ""
			local displayCoff = `{math.ceil(PlayerStatData:Calculate(key) * value.DisplayCoefficient)}{showPerc}`

			upgradeFrame.ItemName.Text = `{value.Name} {displayCoff}`
			upgradeFrame.ItemCost.Text = `Cost: {maxed and "N/A" or value.CostPerLevel * currentLevel}`
			upgradeFrame.UpgradeButton.CurrentLevel.Text = `Current Lv.{currentLevel}`
			upgradeFrame.UpgradeButton.UpgradeLabel.Text = maxed and "MAXED" or `+Upgrade`
		end

		updateDisplayValues()

		upgradeFrame.UpgradeButton.MouseButton1Click:Connect(function()
			if PlayerDataClient.Profile[key] >= value.MaxLevel then
				return
			end

			local results = PlayerUpgradeClient:Upgrade(key)

			if results.Success then
				NotificationClient(`{value.Name} Upgraded!`)

				Janitor:Add(
					PlayerDataClient.OnKeyChanged:Connect(function(currentKey, value)
						if currentKey == key then
							updateDisplayValues()
						end
					end),
					"Disconnect"
				)
			else
				NotificationClient("You do not have enough Money!")
			end
		end)
	end

	PlayerStatInterface.MainFrame.Size = UDim2.fromScale(0, 0)
	PlayerStatInterface.Enabled = true

	TweenService:Create(
		PlayerStatInterface.MainFrame,
		TweenInfo.new(1, Enum.EasingStyle.Elastic),
		{ Size = UDim2.fromScale(0.32, 0.55) }
	):Play()
end

local function OnPlayerStatInterfaceClose()
	PlayerStatInterface.Enabled = false
end

return function(prompt: ProximityPrompt)
	prompt.Triggered:Connect(OnPromptTriggered)
	PlayerStatInterface.MainFrame.CloseButton.MouseButton1Click:Connect(OnPlayerStatInterfaceClose)
end
