--!strict

type Results = {
	Success: boolean,
}

local NetworkClient = require(script.Parent.NetworkClient)
local CommObject = NetworkClient:BuildObject()

local PlayerUpgradeClient = {}

function PlayerUpgradeClient:Upgrade(key: string): Results
	return CommObject:RequestUpgradeStat(key)
end

return PlayerUpgradeClient
