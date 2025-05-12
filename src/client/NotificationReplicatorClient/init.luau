--!strict

local NotificationClient = require(script.Parent.NotificationClient)
local NetworkClient = require(script.Parent.NetworkClient)

NetworkClient:GetSignal("NotificationReplicate"):Connect(function(message: string)
	NotificationClient(message)
end)

return {}
