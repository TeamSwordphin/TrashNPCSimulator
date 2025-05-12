local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Freeze = require(ReplicatedStorage.Libraries.Freeze)
local Looks = require(ReplicatedStorage.Libraries.Loader).LoadChildren(script.Looks)

local Types = require(script.Parent.EntityTypes)
local EntityLooks = {}

local SEED = Random.new()

function EntityLooks:Generatelook(entity: Types.Entity)
	if entity.Model.Name ~= "NPC" then
		entity.Model:AddTag(entity.Model.Name)
		entity.Look = entity.Model.Name
		entity.LooksChanged:Fire(entity.Model.Name)
		return
	end

	local looks = Freeze.Dictionary.keys(Looks)
	local lookKey: string = looks[SEED:NextInteger(1, #looks)]
	local chosenLook = Looks[lookKey]

	local humanoid: Humanoid = entity.Model.Humanoid :: Humanoid
	local humanoidDescription: HumanoidDescription = Instance.new("HumanoidDescription")

	for key: string, value: any in chosenLook do
		local success, message = pcall(function()
			humanoidDescription[key] = value
		end)

		if not success then
			warn(message)
		end
	end

	humanoidDescription.Parent = humanoid
	humanoid:ApplyDescription(humanoidDescription)

	-- To ensure that the pathfinding doesn't become jittery when players get near
	local primaryPart: BasePart = entity.Model.PrimaryPart
	primaryPart:SetNetworkOwner(nil)

	local model: Model = humanoid.Parent :: Model
	model:AddTag(lookKey)

	entity.Look = lookKey
	entity.LooksChanged:Fire(lookKey)
end

return EntityLooks
