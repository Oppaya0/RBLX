-- CooldownManager: Centralized cooldown state for all players.
-- Designed to be ticked by a single Heartbeat loop in AbilityService,
-- NOT per-player while-loops. Scales to any player count with one iteration per frame.

local CooldownManager = {}

-- State: { [Player] = { [abilityId] = cooldownRemaining } }
local playerCooldowns = {}

function CooldownManager.GetState(player)
	if not playerCooldowns[player] then
		playerCooldowns[player] = {}
	end
	return playerCooldowns[player]
end

function CooldownManager.CanCast(player, abilityId)
	local state = CooldownManager.GetState(player)
	local remaining = state[abilityId] or 0
	return remaining <= 0
end

function CooldownManager.SetCooldown(player, abilityId, duration)
	local state = CooldownManager.GetState(player)
	state[abilityId] = duration
end

function CooldownManager.GetRemaining(player, abilityId)
	local state = CooldownManager.GetState(player)
	return state[abilityId] or 0
end

-- Called once per Heartbeat from AbilityService. Single loop over all players.
function CooldownManager.Tick(deltaTime)
	for _player, abilities in pairs(playerCooldowns) do
		for abilityId, remaining in pairs(abilities) do
			local newRemaining = remaining - deltaTime
			if newRemaining <= 0 then
				abilities[abilityId] = nil
			else
				abilities[abilityId] = newRemaining
			end
		end
	end
end

function CooldownManager.ClearPlayer(player)
	playerCooldowns[player] = nil
end

return CooldownManager
