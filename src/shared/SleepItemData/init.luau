--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Loader = require(ReplicatedStorage.Libraries.Loader)

local Beds = Loader.LoadChildren(script.Beds)

export type SleepItemData = {
	Name: string,
	Description: string,
	Image: string,
	SleepQuality: number,
	Price: number,
	Model: string?,
}

local SleepData = {}

function SleepData:Get(sleepItemIndex: number): SleepItemData?
	assert(typeof(sleepItemIndex) == "number", "Index must be passed as a number!")

	return Beds[tostring(sleepItemIndex)]
end

function SleepData:GetAll()
	return Beds
end

return SleepData
