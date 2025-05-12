local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local SettingsTemplate = require(ReplicatedStorage.Settings.PlayerSettings)
local Janitor = require(ReplicatedStorage.Libraries.Janitor).new()

local Player = Players.LocalPlayer

local SettingsInterface = Player.PlayerGui:WaitForChild("SettingInterface")
SettingsInterface.Enabled = false

local Settings = {}
local Initialized = false

local TINY: number = 0.0001
type ValidInputs = string | number | boolean

local function OnSettingsInterfaceOpen()
	SettingsInterface.Enabled = true
	SettingsInterface.MainFrame.Size = UDim2.fromScale(0, 0)

	TweenService:Create(
		SettingsInterface.MainFrame,
		TweenInfo.new(1, Enum.EasingStyle.Elastic),
		{ Size = UDim2.fromScale(0.6, 0.6) }
	):Play()

	if not Initialized then
		Initialized = true

		local scrollFrame = SettingsInterface.MainFrame.ScrollingFrame

		for name, value in SettingsTemplate do
			local frame = Janitor:Add(scrollFrame.Template.Slot:Clone(), "Destroy")
			frame.Visible = true
			frame.Title.Text = name
			frame.Parent = scrollFrame

			if typeof(value) == "number" then
				frame.Slider.Visible = true
				frame.Percentage.Visible = true

				local percentageLabel = frame.Percentage
				local barBackground = frame.Slider
				local dot = barBackground.Button

				local min_x = barBackground.AbsolutePosition.X
				local max_x = min_x + barBackground.AbsoluteSize.X

				local function IsMouseButtonDown(inputType)
					for _, button in (UserInputService:GetMouseButtonsPressed()) do
						if button.UserInputType == inputType then
							return true
						end
					end
					return false
				end

				local function updateMusic(percent)
					local mouse_x = UserInputService:GetMouseLocation().X
					percent = if percent
						then math.clamp(percent, 0, 1)
						else math.clamp((mouse_x - min_x) / (max_x - min_x), 0, 1)

					-- for _, music in pairs(Player.PlayerGui.Sounds.MusicScript:GetChildren()) do
					-- 	if music:IsA("Sound") then
					-- 		music.Volume = percent * 0.5
					-- 	end
					-- end

					percentageLabel.Number.Text = `{math.floor(percent * 100)}%`
					dot.Position = UDim2.new(percent, 0, 0.5, 0)

					if percent >= 1 then
						barBackground.Bar.UIGradient.Transparency = NumberSequence.new(0)
					else
						barBackground.Bar.UIGradient.Transparency = NumberSequence.new({
							NumberSequenceKeypoint.new(0, 0),
							NumberSequenceKeypoint.new(math.max(0, percent), 0),
							NumberSequenceKeypoint.new(math.min(1, percent + TINY), 1),
							NumberSequenceKeypoint.new(1, 1),
						})
					end

					barBackground.Bar.Visible = percent > 0
				end

				-- for _, music in pairs(Player.PlayerGui.Sounds.MusicScript:GetChildren()) do
				-- 	if music:IsA("Sound") then
				-- 		updateMusic(music.Volume / 0.5)
				-- 	end
				-- end

				updateMusic(1) -- temporary for now

				dot.MouseButton1Down:Connect(function()
					while IsMouseButtonDown(Enum.UserInputType.MouseButton1) do
						updateMusic()
						task.wait()
					end
				end)

				dot.Parent:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
					min_x = dot.Parent.AbsolutePosition.X
					max_x = min_x + dot.Parent.AbsoluteSize.X
				end)
			end
		end
	end
end

local function OnSettingsInterfaceClose()
	SettingsInterface.Enabled = false
end

local function Init()
	SettingsInterface.MainFrame.CloseButton.MouseButton1Click:Connect(OnSettingsInterfaceClose)
	OnSettingsInterfaceClose()
end

Init()

function Settings:Set(name: string, value: ValidInputs)
	assert(name, "Name of the setting must be passed!")
	assert(value, "Value must be passed!")
end

function Settings:Open()
	OnSettingsInterfaceOpen()
end

return Settings
