-- AbilityData: All tunable values for abilities live here, not in logic functions.
-- Adding a new ability = adding a new entry to this table. No controller changes needed.

local AbilityData = {
	["Slash"] = {
		DisplayName = "Slash",
		Damage = 25,
		ResourceCost = 20,
		Cooldown = 2,        -- seconds
		HitRange = 8,       -- radius in studs from the caster
		DamageType = "Physical",
	},
}

return AbilityData
