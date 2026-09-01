-- AbilityData: All tunable values for abilities live here, not in logic functions.
-- Adding a new ability = adding a new entry to this table. No controller changes needed.

local AbilityData = {
	["Slash"] = {
		DisplayName = "Slash",
		Type = "Attack",
		Damage = 25,
		ResourceCost = 20,
		Cooldown = 2,
		HitRange = 8,
		DamageType = "Physical",
	},

	["Dash"] = {
		DisplayName = "Dash",
		Type = "Dodge",
		Damage = 0,
		ResourceCost = 15,
		Cooldown = 4,
		HitRange = 0,
		DashDistance = 20,   -- studs
		DashDuration = 0.2,  -- seconds
	},

	["Guard"] = {
		DisplayName = "Guard",
		Type = "Defense",
		Damage = 0,
		ResourceCost = 25,
		Cooldown = 6,
		HitRange = 0,
		ShieldDuration = 3,  -- seconds
	},

	["Whirlwind"] = {
		DisplayName = "Whirlwind",
		Type = "Ultimate",
		Damage = 45,
		ResourceCost = 60,
		Cooldown = 10,
		HitRange = 14,
		DamageType = "Physical",
	},
}

return AbilityData