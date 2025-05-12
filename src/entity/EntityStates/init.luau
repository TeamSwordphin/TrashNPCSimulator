--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(script.Parent.EntityTypes)
local States = require(ReplicatedStorage.Libraries.Loader).LoadChildren(script.States)
local Janitor = require(ReplicatedStorage.Libraries.Janitor)

local EntityStates = { States = States }

local JanitorStates: { [Types.Entity]: { [string]: any } } = {}

function EntityStates:ActivateStateListeners(entity: Types.Entity)
	entity.StateChanged:Connect(function(oldState: string, newState: string)
		if not JanitorStates[entity] then
			JanitorStates[entity] = {}

			entity.Destroyed:Connect(function()
				for state, janitor in JanitorStates[entity] do
					if janitor.Destroy then
						States[state]:Cleanup(entity, janitor)
					end
				end

				JanitorStates[entity] = nil
			end)
		end

		local oldJanitor = JanitorStates[entity][oldState] or Janitor.new()

		local newJanitor = Janitor.new()
		JanitorStates[entity][newState] = newJanitor

		States[oldState]:Cleanup(entity, oldJanitor)
		States[newState]:Activate(entity, newJanitor)
	end)
end

function EntityStates:GetState(state: string)
	return States[state]
end

return EntityStates
