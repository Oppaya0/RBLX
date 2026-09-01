local AbilityData = {
	["Slash"] = {
		DisplayName = "Slash",
		Description = "A quick melee strike in a short radius around you.",
		Type = "Attack",
		Damage = 25,
		ResourceCost = 20,
		Cooldown = 2,
		HitRange = 8,
		DamageType = "Physical",
	},

	["Dash"] = {
		DisplayName = "Dash",
		Description = "Quickly dash forward in the direction you're facing.",
		Type = "Dodge",
		Damage = 0,
		ResourceCost = 15,
		Cooldown = 4,
		HitRange = 0,
		DashDistance = 20,
		DashDuration = 0.2,
	},

	["Guard"] = {
		DisplayName = "Guard",
		Description = "Raise your guard, marking yourself as shielded for a short time.",
		Type = "Defense",
		Damage = 0,
		ResourceCost = 25,
		Cooldown = 6,
		HitRange = 0,
		ShieldDuration = 3,
	},

	["Whirlwind"] = {
		DisplayName = "Whirlwind",
		Description = "A powerful spinning strike hitting everything in a wide radius.",
		Type = "Ultimate",
		Damage = 45,
		ResourceCost = 60,
		Cooldown = 10,
		HitRange = 14,
		DamageType = "Physical",
	},
}

return AbilityData