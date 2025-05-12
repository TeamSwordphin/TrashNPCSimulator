--[[

	How the player's save will look. Adding more keys to this will reconcile changes to the player's saves.

	See below for more information
	https://madstudioroblox.github.io/ProfileService/

]]

local RunService = game:GetService("RunService")

return {
	CarryCapacity = 1,
	RummageSpeedScale = 1,
	ChanceRareItems = 1,
	ChanceNPCDropItems = 1,
	TrashLevelAccess = 1,

	Energy = 5,
	EnergyLastUseTime = 0,

	SleepItemEquippedID = 0,
	SleepItemsPurchased = { 0 },

	Money = RunService:IsStudio() and 100000 or 10,
	TotalLifetimeMoneyEarned = 0,

	Settings = {
		Volume = 100,
	},

	CurrentQuestId = 0,

	Inventory = {},
	ShopPurchases = {},
	CharacterStats = {},

	TutorialStage = 1,

	LastDailyGiftRedeemed = 0,
	CurrentDailyGiftIndex = 1,
}
