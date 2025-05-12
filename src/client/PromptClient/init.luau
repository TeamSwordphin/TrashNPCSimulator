--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Libraries.LemonSignal)
local LoadedPrompts = require(ReplicatedStorage.Libraries.Loader).LoadChildren(script.PromptTags)
local PlayerDataClient = require(ReplicatedStorage.Client.PlayerDataClient)

local PromptClient = {
	OnPromptTriggered = Signal.new(),
}

local function Init()
	if not PlayerDataClient.Loaded then
		PlayerDataClient.OnProfileLoaded:Wait()
	end

	for name: string, callback in LoadedPrompts do
		local function onCallbackTriggered(prompt: ProximityPrompt)
			prompt.Triggered:Connect(function()
				PromptClient.OnPromptTriggered:Fire(prompt)
			end)

			callback(prompt)
		end

		CollectionService:GetInstanceAddedSignal(name):Connect(onCallbackTriggered)

		for _, prompt: ProximityPrompt in CollectionService:GetTagged(name) do
			onCallbackTriggered(prompt)
		end
	end
end

Init()
return PromptClient
