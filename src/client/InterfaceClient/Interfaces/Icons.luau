local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Settings = require(ReplicatedStorage.Client.SettingsClient)
local DailyReward = require(ReplicatedStorage.Client.DailyRewardClient)
local SleepClient = require(ReplicatedStorage.Client.SleepClient)

return function(frame)
	frame.SettingsInterface.MouseButton1Click:Connect(function()
		Settings:Open()
	end)

	frame.DailyInterface.MouseButton1Click:Connect(function()
		DailyReward:Open("Playtime")
	end)

	frame.Sleep.MouseButton1Click:Connect(function()
		SleepClient:Toggle()
	end)
end
