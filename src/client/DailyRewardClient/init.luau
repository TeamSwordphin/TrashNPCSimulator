--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local PlayerDataClient = require(ReplicatedStorage.Client.PlayerDataClient)
local DailyRewards = require(ReplicatedStorage.Modules.DailyRewards)
local PlaytimeRewards = require(ReplicatedStorage.Modules.PlaytimeRewards)
local TrashItemData = require(ReplicatedStorage.Modules.TrashItemData)
local NotificationClient = require(ReplicatedStorage.Client.NotificationClient)
local Janitor = require(ReplicatedStorage.Libraries.Janitor).new()
local NetworkClient = require(ReplicatedStorage.Client.NetworkClient)

local ConvertToHMS = require(ReplicatedStorage.Modules.ConvertToHMS)

local CommObject = NetworkClient:BuildObject()

local Player = Players.LocalPlayer

local DailyInterface = Player.PlayerGui:WaitForChild("PlaytimeRewardsUI")
DailyInterface.Enabled = false

type PlaytimeRewards = {
	TimeRequired: number,
	Reward: { [string]: number },
}

local function OpenPlaytime()
	for i, reward: PlaytimeRewards in PlaytimeRewards do
		local playtimeFrame = Janitor:Add(DailyInterface.MainFrame.ScrollingFrame.Template.Slot:Clone(), "Destroy")
		playtimeFrame.Visible = true

		if reward.Reward.Money then
			playtimeFrame.Amount.Text = reward.Reward.Money
		elseif reward.Reward.Item then
			local item = TrashItemData:Get(reward.Reward.Item)

			if item then
				playtimeFrame.Amount.Text = "x1"
				playtimeFrame.Icon.Image = item.Image
			end
		end

		local cd = 999
		local difference = os.time() - Player:GetAttribute("Joined")

		Janitor:Add(
			RunService.PostSimulation:Connect(function(delta: number)
				cd += delta

				if cd < 1 then
					return
				else
					cd = 0
				end

				-- Update text
				local timer = ConvertToHMS(reward.TimeRequired - difference)
				local canClaim = difference >= reward.TimeRequired

				playtimeFrame.Timer.Text = timer
				playtimeFrame.Claim.Visible = canClaim
				difference = os.time() - Player:GetAttribute("Joined")

				if Player:GetAttribute("RetentionLevel") > i then
					playtimeFrame.Timer.Text = ""
					playtimeFrame.Claim.Visible = false
				end
			end),
			"Disconnect"
		)

		playtimeFrame.Parent = DailyInterface.MainFrame.ScrollingFrame
		playtimeFrame.Claim.MouseButton1Click:Connect(function()
			if difference < reward.TimeRequired then
				NotificationClient("Must wait a bit longer before redeeming!")
				return
			end

			-- Claim!
			local success = CommObject:RequestPlaytimePickup(i)

			if success then
				NotificationClient("Redeemed!")
				Player:SetAttribute("RetentionLevel", i + 1)
				cd = 9999
			else
				NotificationClient("Inventory full!")
			end
		end)
	end
end

local function OpenDaily()
	for i, reward: PlaytimeRewards in DailyRewards do
		local playtimeFrame = Janitor:Add(DailyInterface.MainFrame.ScrollingFrame.Template.Slot:Clone(), "Destroy")
		playtimeFrame.Visible = true

		if reward.Reward.Money then
			playtimeFrame.Amount.Text = reward.Reward.Money
		elseif reward.Reward.Item then
			local item = TrashItemData:Get(reward.Reward.Item)

			if item then
				playtimeFrame.Amount.Text = "x1"
				playtimeFrame.Icon.Image = item.Image
			end
		end

		local cd = 999

		Janitor:Add(
			RunService.PostSimulation:Connect(function(delta: number)
				cd += delta

				if cd < 1 then
					return
				else
					cd = 0
				end

				-- Update text
				local lastTimer = PlayerDataClient.Profile.LastDailyGiftRedeemed
				local currentDay = PlayerDataClient.Profile.CurrentDailyGiftIndex
				local passed = currentDay > i

				if i == currentDay then
					local timerGoal = (lastTimer + 86400)

					if os.time() >= timerGoal then
						playtimeFrame.Claim.Visible = true
					else
						local timer = ConvertToHMS(timerGoal - os.time())
						playtimeFrame.Timer.Text = timer
					end
				elseif not passed then
					playtimeFrame.Timer.Text = "Must unlock previous first!"
				end

				if passed then
					playtimeFrame.Claim.Visible = false
					playtimeFrame.Timer.Text = ""
				end
			end),
			"Disconnect"
		)

		playtimeFrame.Parent = DailyInterface.MainFrame.ScrollingFrame
		playtimeFrame.Claim.MouseButton1Click:Connect(function()
			-- Claim!
			local success = CommObject:RequestDailyPickup(i)

			if success then
				NotificationClient("Redeemed!")
				PlayerDataClient.Profile.CurrentDailyGiftIndex += 1
				PlayerDataClient.Profile.LastDailyGiftRedeemed = os.time()
				cd = 9999
			else
				NotificationClient("Cannot redeem!")
			end
		end)
	end
end

local DailyRewardClient = {}

function DailyRewardClient:Open(rewardType: string)
	Janitor:Cleanup()

	if rewardType == "Playtime" then
		OpenPlaytime()
	elseif rewardType == "Daily" then
		OpenDaily()
	end

	DailyInterface.Enabled = true
end

local function OnInterfaceEnabled()
	if not DailyInterface.Enabled then
		return
	end

	DailyInterface.MainFrame.Size = UDim2.fromScale(0, 0)

	TweenService
		:Create(
			DailyInterface.MainFrame,
			TweenInfo.new(1, Enum.EasingStyle.Elastic),
			{ Size = UDim2.fromScale(0.4, 0.64) }
		)
		:Play()
end

local function OnInterfaceClose()
	DailyInterface.Enabled = false
end

local function Init()
	DailyInterface.MainFrame.CloseButton.MouseButton1Click:Connect(OnInterfaceClose)
	DailyInterface:GetPropertyChangedSignal("Enabled"):Connect(OnInterfaceEnabled)

	DailyInterface.MainFrame.PlaytimeButton.MouseButton1Click:Connect(function()
		DailyRewardClient:Open("Playtime")
	end)

	DailyInterface.MainFrame.DailyButton.MouseButton1Click:Connect(function()
		DailyRewardClient:Open("Daily")
	end)
end

Init()

return DailyRewardClient
