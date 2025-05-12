export type MinigameSettings = {
	MaxStages: number,
	Leniency: number,
	BonusZone: number,
	PivotSpeed: number,
}

export type MinigameResult = {
	Bonuses: number,
	Successes: number,
	Failures: number,
}

return {
	BASE_DIFFICULTIES = {
		-- [TRASH LEVEL] = SECONDS
		--- Generally, higher level trash makes rummaging longer; incentives upgrading rummage speed
		[1] = {
			MaxStages = 3,
			Leniency = 40,
			BonusZone = 10,
			PivotSpeed = 150,
		},
		[2] = {
			MaxStages = 3,
			Leniency = 20,
			BonusZone = 5,
			PivotSpeed = 200,
		},
		[3] = {
			MaxStages = 3,
			Leniency = 10,
			BonusZone = 3,
			PivotSpeed = 250,
		},
		[4] = {
			MaxStages = 3,
			Leniency = 5,
			BonusZone = 1,
			PivotSpeed = 350,
		},
	},
}
