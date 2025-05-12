--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Entity = require(ServerStorage.EntityServer.Entity)
local NPCSettings = require(ReplicatedStorage.Settings.NPCSettings)

local CopService = {}

function CopService:Alert(suspect: Player)
	if not suspect then
		warn("Suspect was not passed. Not alerting any cops.")
		return
	end

	local character = suspect.Character

	if character then
		local rootPart: BasePart? = character.PrimaryPart

		if rootPart then
			for _, cop in CollectionService:GetTagged("Cop") do
				local distance: number = (cop.PrimaryPart.Position - rootPart.Position).Magnitude

				if distance <= NPCSettings.COP_SETTINGS.Range then
					local entityCop = Entity:GetEntityFromModel(cop)

					if not entityCop then
						continue
					end

					entityCop.Target = character
					entityCop:SetState("Chase")
				end
			end
		end
	end
end

return CopService
