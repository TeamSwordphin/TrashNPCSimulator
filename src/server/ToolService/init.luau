local ServerComm = require(script.Parent.NetworkService)

local ToolService = {}

function ToolService:DestroyTool(player: Player, tool: string)
	assert(player, "Player must be passed!")
	assert(tool, "Tool name must be passed!")

	local character = player.Character

	if not character then
		return
	end

	if character:FindFirstChild(tool) then
		character[tool]:Destroy()
	else
		local toolInBackpack = player.Backpack:FindFirstChild(tool)

		if toolInBackpack then
			toolInBackpack:Destroy()
		end
	end
end

function ToolService:OnEquipToolRequest(player: Player, tool: string)
	assert(player, "Player must be passed!")

	if not tool then
		return
	end

	-- TO DO
end

local function OnRequestEquipTool(player: Player, tool: string)
	ToolService:OnEquipToolRequest(player, tool)
end

local function OnRequestUnequipTool(player: Player, tool: string)
	ToolService:DestroyTool(player, tool)
end

local function Init()
	ServerComm:BindFunction("RequestEquipItem", OnRequestEquipTool)
	ServerComm:BindFunction("RequestUnequipItem", OnRequestUnequipTool)
end

Init()
return ToolService
