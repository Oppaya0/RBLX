-- CharacterStats: Pure data table for base character stats
-- Structured to support future multiplicative damage scaling:
--   finalDamage = baseDamage * (1 + A_total/100) * (1 + B_total/100) * (1 + C_total/100)
-- The three stat groups below are reserved placeholders. Add stats to them later
-- without changing any logic that reads from this module.

local CharacterStats = {
	Base = {
		HP = 100,
		Resource = 100,         -- mana/fury-like resource
		ResourceRegen = 5,      -- per second
		MoveSpeed = 16,
	},

	-- Reserved for future multiplicative damage scaling stat groups.
	-- Each group is a dictionary of stat names to values (currently empty).
	-- When populated, a helper function can sum each group and apply the formula above.
	StatGroups = {
		A = {},  -- Group A: e.g., flat damage bonuses, weapon damage
		B = {},  -- Group B: e.g., percentage damage bonuses, skill amplification
		C = {},  -- Group C: e.g., global multipliers, conditional bonuses
	},
}

return CharacterStats
