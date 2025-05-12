--!strict

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Janitor = require(ReplicatedStorage.Libraries.Janitor).new()
local LemonSignal = require(ReplicatedStorage.Libraries.LemonSignal)
local TrashMinigameSettings = require(ReplicatedStorage.Settings.TrashMinigameSettings)

local Interface = Players.LocalPlayer.PlayerGui:WaitForChild("PlayerInterface").CenterMiddle.Minigame
local RandomSeed = Random.new()

type GuessResult = {
	Result: "Bonus" | "Normal" | "Wrong",
}

local COLORS = {
	["Perfect!"] = Color3.fromRGB(0, 255, 0),
	["Great!"] = Color3.fromRGB(255, 255, 0),
	["Bad!"] = Color3.fromRGB(255, 0, 0),
}

local function GetRandomGoal(): number
	return RandomSeed:NextInteger(0, 360)
end

local function Normalize(num: number): number
	return (num % 361)
end

local function getAngleDistance(a: number, b: number): number
	local diff = math.abs(a - b) % 361
	return math.min(diff, 361 - diff)
end

local function GetGuessResult(goal: number, guess: number, leniency: number, bonusRange: number): GuessResult
	goal = Normalize(goal)
	guess = Normalize(guess)

	local distance = getAngleDistance(goal, guess)

	if distance <= leniency then
		if distance > (leniency - bonusRange) then
			return { Result = "Bonus" }
		else
			return { Result = "Normal" }
		end
	end

	return { Result = "Wrong" }
end

local function ShowMessage(text: string): TextLabel
	local message = Interface.Message:Clone()
	message.Text = text
	message.Visible = true
	message.TextColor3 = COLORS[text] or message.TextColor3
	message.Parent = Interface

	task.delay(0.25, function()
		local tween = TweenService:Create(message, TweenInfo.new(0.25), { TextTransparency = 1 })
		tween:Play()

		local strokeTween = TweenService:Create(message.UIStroke :: UIStroke, TweenInfo.new(0.25), { Transparency = 1 })
		strokeTween:Play()

		strokeTween.Completed:Wait()
		message:Destroy()
	end)

	return message
end

local Minigame = {}

function Minigame:Stop()
	Janitor:Cleanup()
	Interface.ProgressBar.Bar.Size = UDim2.fromScale(0, 1)
	Interface.Visible = false
	ProximityPromptService.Enabled = true
	Players.LocalPlayer.Character.Humanoid.WalkSpeed = 16
end

function Minigame:Start(settings: TrashMinigameSettings.MinigameSettings): TrashMinigameSettings.MinigameResult
	assert(settings)

	Minigame:Stop()
	ProximityPromptService.Enabled = false
	Players.LocalPlayer.Character.Humanoid.WalkSpeed = 0

	local stages = settings.MaxStages
	local leniency = settings.Leniency
	local bonusZone = settings.BonusZone
	local pivotSpeed = settings.PivotSpeed

	Interface.Pivotor.Rotation = 0
	Interface.Visible = true

	local bonuses = 0
	local successes = 0
	local failures = 0

	local direction = 1
	local currentNumber = 0

	for i = 1, stages do
		Janitor:Cleanup()

		local goal = GetRandomGoal()
		local signal = Janitor:Add(LemonSignal.new(), "Destroy")

		local greenLength = leniency * 2
		local goldLength = greenLength - bonusZone * 2

		local greenScale = greenLength / 360
		local goldScale = goldLength / 360
		local position = goal / 360

		-- Create main bars
		local goldBar = Janitor:Add(Interface.Background.Templates.GoldBar:Clone(), "Destroy")
		goldBar.Visible = true
		goldBar.AnchorPoint = Vector2.new(0.5, 0.5)
		goldBar.Size = UDim2.fromScale(goldScale, 1)
		goldBar.Position = UDim2.fromScale(position, 0.5)
		goldBar.Parent = Interface.Background

		local greenBar = Janitor:Add(Interface.Background.Templates.GreenBar:Clone(), "Destroy")
		greenBar.Visible = true
		greenBar.AnchorPoint = Vector2.new(0.5, 0.5)
		greenBar.Size = UDim2.fromScale(greenScale, 1)
		greenBar.Position = UDim2.fromScale(position, 0.5)
		greenBar.Parent = Interface.Background

		-- Wrapping edge checks (in scale)
		local leftEdge = position - (greenScale / 2)
		local rightEdge = position + (greenScale / 2)

		local wrapsLeft = leftEdge < 0
		local wrapsRight = rightEdge > 1

		if wrapsLeft then
			local wrapPos = 1 + leftEdge + (greenScale / 2) -- shift to right side
			local goldBarWrap = Janitor:Add(goldBar:Clone(), "Destroy")
			goldBarWrap.Position = UDim2.fromScale(wrapPos, 0.5)
			goldBarWrap.Parent = Interface.Background

			local greenBarWrap = Janitor:Add(greenBar:Clone(), "Destroy")
			greenBarWrap.Position = UDim2.fromScale(wrapPos, 0.5)
			greenBarWrap.Parent = Interface.Background
		end

		if wrapsRight then
			local wrapPos = (rightEdge - 1) - (greenScale / 2) -- shift to left side
			local goldBarWrap = Janitor:Add(goldBar:Clone(), "Destroy")
			goldBarWrap.Position = UDim2.fromScale(wrapPos, 0.5)
			goldBarWrap.Parent = Interface.Background

			local greenBarWrap = Janitor:Add(greenBar:Clone(), "Destroy")
			greenBarWrap.Position = UDim2.fromScale(wrapPos, 0.5)
			greenBarWrap.Parent = Interface.Background
		end

		Janitor:Add(RunService.PostSimulation:Connect(function(delta: number)
			currentNumber = Normalize(currentNumber + ((pivotSpeed * delta) * direction))
			Interface.Pivotor.Position = UDim2.fromScale(currentNumber / 360, 0.5)
		end))

		Janitor:Add(UserInputService.InputBegan:Connect(function(inputObject: InputObject)
			local inputType = inputObject.UserInputType

			if inputType == Enum.UserInputType.MouseButton1 or inputType == Enum.UserInputType.Touch then
				local result = GetGuessResult(goal, currentNumber, leniency, bonusZone).Result
				local bonus = result == "Bonus"

				if bonus or result == "Normal" then
					successes += 1

					if bonus then
						bonuses += 1
						ShowMessage("Perfect!")
					else
						ShowMessage("Great!")
					end
				else
					failures += 1
					ShowMessage("Bad!")
				end

				signal:Fire()
			end
		end))

		signal:Wait()
		direction *= -1

		local tween = TweenService:Create(
			Interface.ProgressBar.Bar,
			TweenInfo.new(0.5, Enum.EasingStyle.Elastic),
			{ Size = UDim2.fromScale(i / stages, 1) }
		)
		tween:Play()
	end

	Minigame:Stop()

	return { Bonuses = bonuses, Successes = successes, Failures = failures }
end

local function Init()
	Interface.Visible = false
end

Init()
-- Minigame:Start({ MaxStages = 5, Leniency = 30, BonusZone = 10, PivotSpeed = 200 })

return Minigame
