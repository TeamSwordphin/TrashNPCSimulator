--!strict

local COLORS = {
	Color3.fromRGB(255, 0, 0),
	Color3.fromRGB(0, 255, 0),
	Color3.fromRGB(0, 0, 255),
	Color3.fromRGB(255, 115, 0),
	Color3.fromRGB(217, 255, 5),
}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local Entity = require(ServerStorage.EntityServer.Entity)
local PlayerDataService = require(ServerScriptService.Server.PlayerDataService)
local TrashItemData = require(ReplicatedStorage.Modules.TrashItemData)
local NPCLooterService = require(ServerScriptService.Server.NPCLooterService)
local PlayerLooterService = require(ServerScriptService.Server.PlayerLooterService)

local SEED = Random.new()

local function GrantHighlightColor(model: Instance)
	for _, highlight in model:GetChildren() do
		if highlight:HasTag("_RadioactiveHighlight") then
			highlight:Destroy()
		end
	end

	local highlight: Highlight = Instance.new("Highlight")
	highlight.OutlineTransparency = 1
	highlight.FillTransparency = 0.7
	highlight.FillColor = COLORS[SEED:NextInteger(1, #COLORS)]
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight:AddTag("_RadioactiveHighlight")
	highlight.Parent = model
end

local Item = {}

function Item:Activate(character)
	GrantHighlightColor(character)
end

function Item:Create(player: Player, tool: Tool)
	local profileExport: PlayerDataService.ProfileExport? = PlayerDataService:GetProfile(player)
	local primaryPart: BasePart = tool.PrimaryPart :: BasePart
	local debounce: boolean = true

	primaryPart.Touched:Connect(function(hit)
		if not debounce then
			return
		else
			debounce = false
			task.delay(1, function()
				debounce = true
			end)
		end

		local entity = Entity:GetEntityFromModel(hit.Parent :: Instance)

		if entity and profileExport then
			local inventory = profileExport:Get("Inventory")

			for inventoryIndex, itemIndex in inventory do
				local itemInformation: TrashItemData.ItemData? = TrashItemData:Get(itemIndex)

				if itemInformation and itemInformation.Name == tool.Name then
					table.remove(inventory, inventoryIndex)
					break
				end
			end

			tool:Destroy()
			GrantHighlightColor(hit.Parent :: Instance)
			profileExport:Set("Inventory", inventory)
			NPCLooterService:DropLoot(player, entity)
		else
			local targetPlayer: Player? = Players:GetPlayerFromCharacter(hit.Parent)

			if not targetPlayer or targetPlayer == player then
				return
			end

			Item:Activate(targetPlayer.Character :: Model)
			PlayerLooterService:DropLoot(player, targetPlayer)
		end
	end)
end

return Item
