-- PlayerStats: Tracks each player's bonus stat groups (A/B/C), gained from gear/pickups.
-- Combines with base ability damage using the multiplicative formula:
--   finalDamage = baseDamage * (1 + A/100) * (1 + B/100) * (1 + C/100)
-- This is the same formula placeholder set up in CharacterStats.StatGroups.

local PlayerStats = {}

-- [Player] = { A = number, B = number, C = number }
local playerStatTotals = {}

local function getTotals(player)
	if not playerStatTotals[player] then
		playerStatTotals[player] = { A = 0, B = 0, C = 0 }
	end
	return playerStatTotals[player]
end

function PlayerStats.GetMultiplier(player)
	local totals = getTotals(player)
	return (1 + totals.A / 100) * (1 + totals.B / 100) * (1 + totals.C / 100)
end

-- Adds a flat amount to one of the three stat groups ("A", "B", or "C").
function PlayerStats.AddStat(player, group, amount)
	local totals = getTotals(player)
	if totals[group] == nil then
		warn("PlayerStats.AddStat: unknown stat group '" .. tostring(group) .. "'")
		return
	end
	totals[group] += amount

	-- Expose the combined bonus as a percentage, useful for future UI display.
	local multiplier = PlayerStats.GetMultiplier(player)
	player:SetAttribute("DamageBonusPercent", math.floor((multiplier - 1) * 100 + 0.5))
end

function PlayerStats.ClearPlayer(player)
	playerStatTotals[player] = nil
end

return PlayerStats