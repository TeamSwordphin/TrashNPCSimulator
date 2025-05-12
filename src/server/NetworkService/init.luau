--[[

	API: https://sleitnick.github.io/RbxUtil/api/Comm

]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerCommFile = require(ReplicatedStorage.Libraries.Comm).ServerComm

return ServerCommFile.new(ReplicatedStorage)
