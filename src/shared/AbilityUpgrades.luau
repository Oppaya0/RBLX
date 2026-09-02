-- AbilityUpgrades: Declarative upgrade tree data.
-- Each upgrade can target a specific ability, grant tags for other upgrades'
-- category-based requirements, and have multiple levels with different values.
--
-- Requirements format: a list of AND-groups. Each group is satisfied if ANY
-- one of its conditions is met (OR within the group).
--   { anyOf = {"UpgradeId1", "UpgradeId2"} }   -- needs one of these specific upgrades
--   { anyOfTag = "Lightning" }                  -- needs any purchased upgrade with this tag

local AbilityUpgrades = {
	-- No prerequisite, single level, targets Slash.
	["ComboFinisher"] = {
		DisplayName = "Combo Finisher",
		TargetAbility = "Slash",
		Tags = {},
		MaxLevel = 1,
		Levels = {
			{ Description = "After 3 hits, the next Slash deals 100% bonus damage.", BonusDamagePercent = 100 },
		},
		Requirements = {},
	},

	-- No prerequisite, but grants a tag other upgrades can require.
	["ShockingEdge"] = {
		DisplayName = "Shocking Edge",
		TargetAbility = "Slash",
		Tags = { "Lightning" },
		MaxLevel = 1,
		Levels = {
			{ Description = "Slash applies a small Shock effect.", ShockStacks = 1 },
		},
		Requirements = {},
	},

	-- Hard-required single prerequisite (must own ComboFinisher first).
	["BackstabBonus"] = {
		DisplayName = "Backstab Bonus",
		TargetAbility = "Slash",
		Tags = {},
		MaxLevel = 1,
		Levels = {
			{ Description = "Backstabs deal 40% bonus damage.", BackstabDamagePercent = 40 },
		},
		Requirements = {
			{ anyOf = { "ComboFinisher" } },
		},
	},

	-- Category-based requirement: needs ANY upgrade tagged "Lightning".
	["ThunderCall"] = {
		DisplayName = "Thunder Call",
		TargetAbility = "Slash",
		Tags = { "Lightning" },
		MaxLevel = 1,
		Levels = {
			{ Description = "Combo finisher calls down a bolt of lightning.", LightningDamage = 30 },
		},
		Requirements = {
			{ anyOfTag = "Lightning" },
		},
	},

	-- Multi-level upgrade (2 levels, different values per level).
	["MultiStrike"] = {
		DisplayName = "Multi Strike",
		TargetAbility = "Slash",
		Tags = {},
		MaxLevel = 2,
		Levels = {
			{ Description = "Slash hits +1 extra nearby enemy.", ExtraTargets = 1 },
			{ Description = "Slash hits +2 extra nearby enemies.", ExtraTargets = 2 },
		},
		Requirements = {},
	},

	-- Compound requirement: (one of two named upgrades) AND (any Lightning-tagged upgrade).
	["StormFinisher"] = {
		DisplayName = "Storm Finisher",
		TargetAbility = "Slash",
		Tags = {},
		MaxLevel = 1,
		Levels = {
			{ Description = "Combo finisher unleashes a small storm burst.", StormDamage = 20 },
		},
		Requirements = {
			{ anyOf = { "ComboFinisher", "MultiStrike" } },
			{ anyOfTag = "Lightning" },
		},
	},

	-- Targets Dash instead of Slash, to prove the model isn't Slash-only.
	["QuickFeet"] = {
		DisplayName = "Quick Feet",
		TargetAbility = "Dash",
		Tags = {},
		MaxLevel = 1,
		Levels = {
			{ Description = "Dash cooldown reduced by 25%.", CooldownReductionPercent = 25 },
		},
		Requirements = {},
	},
}

return AbilityUpgrades