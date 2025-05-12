--[[

	ID = Mainly used for organization purposes like GUI ordering.
	Name = Self explanatory
	Description = Self explanatory

	DisplayCoefficient = The multiplier to do when NPCUpgradePrompt shows the values
	BaseValue = The value to start off with
	MaxLevel = How much times this stat can be upgraded

	CostPerLevel = Self explanatory
	ValuePerLevel = BaseValue + (ValuePerLevel * CurrentLevel)

]]

return {
	CarryCapacity = {
		ID = 1,
		Name = "Carry Capacity",
		Description = "Number of items the player can carry",

		DisplayCoefficient = 1,
		BaseValue = 3,
		MaxLevel = 6,

		CostPerLevel = 500,
		ValuePerLevel = 1,
	},

	RummageSpeedScale = {
		ID = 2,
		Name = "Trash Rummaging Speed",
		Description = "Increases the zone size in Trash Minigame",

		DisplayCoefficient = 100,
		BaseValue = 1,
		MaxLevel = 250,

		CostPerLevel = 10,
		ValuePerLevel = 0.05,
	},

	ChanceRareItems = {
		ID = 3,
		Name = "Rare Drop Chance",
		Description = "Increases bonus zone in Trash Minigame; chance of rare items increases",

		DisplayCoefficient = 100,
		BaseValue = 1,
		MaxLevel = 500,

		CostPerLevel = 200,
		ValuePerLevel = 0.02,
	},

	ChanceNPCDropItems = {
		ID = 4,
		Name = "NPC Drop Chance",
		Description = "Increases the chance of rare items dropping from NPCs after pranks",

		DisplayCoefficient = 100,
		BaseValue = 1,
		MaxLevel = 1000,

		CostPerLevel = 300,
		ValuePerLevel = 0.02,
	},

	TrashLevelAccess = {
		ID = 5,
		Name = "Trash Level Access",
		Description = "Increases the level of trash players can access",

		DisplayCoefficient = 1,
		BaseValue = 1,
		MaxLevel = 5,

		CostPerLevel = 1000,
		ValuePerLevel = 1,
	},
}
