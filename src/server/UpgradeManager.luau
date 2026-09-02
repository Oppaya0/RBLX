-- UpgradeManager: Tracks each player's purchased upgrades and tag counts,
-- and validates purchases against AbilityUpgrades' Requirements.
-- This does NOT yet apply upgrade effects to abilities -- that's the next
-- step once the data model itself is confirmed to be the right shape.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AbilityUpgrades = require(ReplicatedStorage.Shared.AbilityUpgrades)

local UpgradeManager = {}

-- [Player] = { purchasedLevels = { [upgradeId] = level }, tagCounts = { [tag] = count } }
local playerUpgradeState = {}

local function getState(player)
	if not playerUpgradeState[player] then
		playerUpgradeState[player] = { purchasedLevels = {}, tagCounts = {} }
	end
	return playerUpgradeState[player]
end

local function requirementGroupSatisfied(group, state)
	if group.anyOf then
		for _, requiredId in ipairs(group.anyOf) do
			if state.purchasedLevels[requiredId] then
				return true
			end
		end
		return false
	end

	if group.anyOfTag then
		return (state.tagCounts[group.anyOfTag] or 0) > 0
	end

	warn("UpgradeManager: malformed requirement group")
	return false
end

function UpgradeManager.CanPurchase(player, upgradeId)
	local upgrade = AbilityUpgrades[upgradeId]
	if not upgrade then
		return false, "Unknown upgrade"
	end

	local state = getState(player)
	local currentLevel = state.purchasedLevels[upgradeId] or 0

	if currentLevel >= upgrade.MaxLevel then
		return false, "Already at max level"
	end

	for _, group in ipairs(upgrade.Requirements) do
		if not requirementGroupSatisfied(group, state) then
			return false, "Requirements not met"
		end
	end

	return true
end

function UpgradeManager.Purchase(player, upgradeId)
	local canBuy, reason = UpgradeManager.CanPurchase(player, upgradeId)
	if not canBuy then
		return false, reason
	end

	local upgrade = AbilityUpgrades[upgradeId]
	local state = getState(player)

	state.purchasedLevels[upgradeId] = (state.purchasedLevels[upgradeId] or 0) + 1

	-- Grant this upgrade's tags so other upgrades' anyOfTag requirements can see them.
	for _, tag in ipairs(upgrade.Tags) do
		state.tagCounts[tag] = (state.tagCounts[tag] or 0) + 1
	end

	return true
end

function UpgradeManager.GetLevel(player, upgradeId)
	local state = getState(player)
	return state.purchasedLevels[upgradeId] or 0
end

function UpgradeManager.ClearPlayer(player)
	playerUpgradeState[player] = nil
end

return UpgradeManager