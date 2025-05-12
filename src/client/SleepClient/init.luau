--!strict

local Players = game:GetService("Players")

local NetworkClient = require(script.Parent.NetworkClient)
local ToggleSleepReplicator = NetworkClient:GetSignal("ToggleSleep")

local SleepClient = {}

function SleepClient:Toggle()
	ToggleSleepReplicator:Fire()
end

local function OnSleepToggled()
	local character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
	local sleeping = Players.LocalPlayer:GetAttribute("Sleeping")
	local humanoid: Humanoid = character.Humanoid

	if sleeping then
		local animator: Animator? = humanoid:FindFirstChildOfClass("Animator")

		if animator then
			character:PivotTo(character:GetPivot() * CFrame.Angles(math.rad(90), 0, 0))
			humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
			humanoid:ChangeState(Enum.HumanoidStateType.Ragdoll)
			humanoid.WalkSpeed = 0

			for _, animation in animator:GetPlayingAnimationTracks() do
				animation:Stop(0)
			end
		end
	else
		humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		humanoid.WalkSpeed = 16
	end
end

local function Init()
	Players.LocalPlayer:GetAttributeChangedSignal("Sleeping"):Connect(OnSleepToggled)
end

Init()
return SleepClient
