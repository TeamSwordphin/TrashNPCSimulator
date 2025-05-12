--!strict

local NetworkService = require(script.Parent.NetworkService)

local NotificationReplicator = NetworkService:CreateSignal("NotificationReplicate")

local NotificationReplicatorService = {}

function NotificationReplicatorService:Send(player: Player, message: string)
	NotificationReplicator:Fire(player, message)
end

function NotificationReplicatorService:SendAll(message: string)
	NotificationReplicator:FireAll(message)
end

return NotificationReplicatorService
