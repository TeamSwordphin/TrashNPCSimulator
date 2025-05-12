local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataClient = require(ReplicatedStorage.Client.PlayerDataClient)
local Frame

local function OnProfileKeyChanged(newMoneyValue: number)
	Frame.TextLabel.Text = `Money: {newMoneyValue}`
end

return function(frame)
	Frame = frame

	PlayerDataClient.OnKeyChanged:Connect(function(key: string, value: any)
		if key == "Money" then
			OnProfileKeyChanged(value)
		end
	end)

	OnProfileKeyChanged(PlayerDataClient.Profile.Money)
end
