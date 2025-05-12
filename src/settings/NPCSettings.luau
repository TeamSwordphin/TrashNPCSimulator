return {
	WALK_SPEED_RANGE_SCALES = {
		Minimum = 0.2,
		Maximum = 0.6,
	},

	SHOW_STATE_ABOVE_HEAD = true,

	COP_SETTINGS = {
		Range = 200, --- 360 degrees
		RunMultiplier = 4, --- How fast they go in relation to their normal run speed
		Health = 100,
		Damage = 25,
		RangeToDamage = 5,
		DamageCooldown = 1,

		ChaseOnNPCPranks = true, -- Will chase players if they prank NPC
		ChaseOnPlayerPranks = true, -- Will chase players if they prank another player
	},

	STRAYS_SETTINGS = {
		Range = 50,
		RunMultiplier = 2,
		Health = 100,
		Damage = 25,
		RangeToDamage = 5,
		DamageCooldown = 1,
	},
}
