local DANCE_DURATION = 30
local DANCE_ANIMATION_IDS = {
	"rbxassetid://5917459365",
	"rbxassetid://11753474067",
	"rbxassetid://14899980745",
	"rbxassetid://134283166482394",
	"rbxassetid://10714068222",
	"rbxassetid://10714394082",
	"rbxassetid://16270690701",
}
local SECONDS_BEFORE_WALKING = 6

local ServerStorage = game:GetService("ServerStorage")

local Types = require(ServerStorage.EntityServer.EntityTypes)

local State = {}

local SEED = Random.new()

function State:Cleanup(entity, janitor)
	janitor:Destroy()
end

function State:Activate(entity: Types.Entity, janitor)
	local humanoid: Humanoid = entity.Model.Humanoid
	local animator: Animator? = humanoid:FindFirstChild("Animator") :: Animator

	if animator then
		local animationObject: Animation = Instance.new("Animation")
		animationObject.AnimationId = DANCE_ANIMATION_IDS[SEED:NextInteger(1, #DANCE_ANIMATION_IDS)]

		local animation: AnimationTrack = animator:LoadAnimation(animationObject)
		animation.Looped = true
		animation:Play()

		task.delay(DANCE_DURATION, function()
			if animation and animation.Stop and animation.Destroy then
				animation:Stop()
				animation:Destroy()
				animationObject:Destroy()
			end
		end)

		task.wait(SECONDS_BEFORE_WALKING)

		entity:SetState("Walking")
	end
end

function State:GetDanceAnimations(): { string }
	return DANCE_ANIMATION_IDS
end

function State:GetDuration(): number
	return DANCE_DURATION
end

return State
