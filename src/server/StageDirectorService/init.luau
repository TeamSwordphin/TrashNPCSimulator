local PlayerDataService = require(script.Parent.PlayerDataService)
local ServerComm = require(script.Parent.NetworkService)

local StageDirectorService = {}

local function RequestStageDirectorNextStage(player: Player)
	assert(player, "Player must be passed!")

	local profile = PlayerDataService:GetProfile(player)

	if profile then
		profile:Set("TutorialStage", profile:Get("TutorialStage") + 1)

		return { Success = true, Stage = profile:Get("TutorialStage") }
	end

	return { Success = false }
end

function StageDirectorService:NextStage(player: Player)
	return RequestStageDirectorNextStage(player)
end

local function Init()
	ServerComm:BindFunction("RequestStageDirectorNextStage", RequestStageDirectorNextStage)
end

Init()
return StageDirectorService
