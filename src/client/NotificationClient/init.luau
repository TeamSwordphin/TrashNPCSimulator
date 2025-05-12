--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GameSettings = require(ReplicatedStorage.Settings.GameSettings)

local Interface = Players.LocalPlayer.PlayerGui:WaitForChild("NotificationInterface")

return function(message: string)
	local notification = Interface.Templates.Notification:Clone()
	notification.Visible = true
	notification.Text = message
	notification.Parent = Interface.Frame

	task.delay(5 / GameSettings.NOTIFICATION_POPUP_TIME_SCALE, notification.Destroy, notification) -- Failsafe to remove the message if tweening goes wrong somewhere
	task.delay(3 / GameSettings.NOTIFICATION_POPUP_TIME_SCALE, function()
		local tween = TweenService:Create(notification, TweenInfo.new(1), { TextTransparency = 1 })
		tween:Play()
		tween.Completed:Wait()

		notification:Destroy()
	end)
end
