local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Janitor = require(ReplicatedStorage.Libraries.Janitor).new()
local HighlighterInterface = Players.LocalPlayer.PlayerGui:WaitForChild("HighlighterInterface")

local HighlighterClient = {}

local TWEEN_OPTIONS = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, true)

function HighlighterClient:Enable(gui: GuiObject)
	Janitor:Cleanup()

	local cursor = Janitor:Add(HighlighterInterface.Template.Cursor:Clone(), "Destroy")
	cursor.Visible = true
	cursor.Size = UDim2.fromScale(1.25, 1.25)
	cursor.Position = UDim2.fromScale(0.5, 0.5)
	cursor.Parent = gui

	local tween = Janitor:Add(TweenService:Create(cursor, TWEEN_OPTIONS, { Size = UDim2.fromScale(2, 2) }), "Cancel")
	tween:Play()
end

function HighlighterClient:Disable()
	Janitor:Cleanup()
	HighlighterInterface.Enabled = false
end

local function Init()
	HighlighterClient:Disable()
end

Init()
return HighlighterClient
