--[[

	API: https://sleitnick.github.io/RbxUtil/api/Comm

]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClientCommFile = require(ReplicatedStorage.Libraries.Comm).ClientComm

return ClientCommFile.new(ReplicatedStorage)
