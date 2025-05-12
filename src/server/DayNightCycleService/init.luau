--!strict

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local GameSettings = require(ReplicatedStorage.Settings.GameSettings)
local Janitor = require(ReplicatedStorage.Libraries.Janitor).new()

local DAY_DURATION = GameSettings.CYCLE_DAY_TIME
local NIGHT_DURATION = GameSettings.CYCLE_NIGHT_TIME

local Tweening: boolean = false

local function OnLightingUpdate()
	if Tweening then
		return
	end

	Tweening = true

	local duration = 0
	local clockGoal = 0
	local isNight = false

	if Lighting.ClockTime >= 6 and Lighting.ClockTime < 18 then
		duration = DAY_DURATION
		clockGoal = 18
	else
		duration = (NIGHT_DURATION * 0.5) -- to account for the clock time resets
		clockGoal = 24
		isNight = true
	end

	local tween = Janitor:Add(
		TweenService:Create(Lighting, TweenInfo.new(duration, Enum.EasingStyle.Linear), { ClockTime = clockGoal }),
		"Cancel"
	)
	tween:Play()
	tween.Completed:Wait()

	-- Additional tweening for night
	if isNight then
		local nightTween = Janitor:Add(
			TweenService:Create(Lighting, TweenInfo.new(duration, Enum.EasingStyle.Linear), { ClockTime = 6 }),
			"Cancel"
		)
		nightTween:Play()
		nightTween.Completed:Wait()
	end

	Tweening = false
end

local DayNightCycle = {}

function DayNightCycle:Pause()
	Janitor:Cleanup()
end

function DayNightCycle:Resume()
	DayNightCycle:Pause()
	Lighting.ClockTime = 6
	Janitor:Add(RunService.PostSimulation:Connect(OnLightingUpdate))
end

local function Init()
	DayNightCycle:Resume()
end

Init()
return DayNightCycle
