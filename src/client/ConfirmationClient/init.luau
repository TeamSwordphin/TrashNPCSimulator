--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LemonSignal = require(ReplicatedStorage.Libraries.LemonSignal)
local Janitor = require(ReplicatedStorage.Libraries.Janitor).new()

local Interface = Players.LocalPlayer.PlayerGui:WaitForChild("ConfirmationInterface")

local ConfirmationClient = { PromptConfirmed = LemonSignal.new() }

function ConfirmationClient:Hide()
	Janitor:Cleanup()
	Interface.Enabled = false
end

function ConfirmationClient:Ask(message: string): boolean
	assert(message, "Must pass a message!")

	ConfirmationClient:Hide()
	Interface.Frame.MainMessage.Text = message
	Interface.Enabled = true

	Janitor:Add(Interface.Frame.Buttons.No.MouseButton1Click:Connect(function()
		ConfirmationClient.PromptConfirmed:Fire(false)
	end))

	Janitor:Add(Interface.Frame.Buttons.Yes.MouseButton1Click:Connect(function()
		ConfirmationClient.PromptConfirmed:Fire(true)
	end))

	local response: boolean = ConfirmationClient.PromptConfirmed:Wait()
	ConfirmationClient:Hide()

	return response
end

return ConfirmationClient
