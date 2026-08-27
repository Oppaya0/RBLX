-- AbilityController: Server-side ability validation and execution.
-- Single entry point: TryCast(player, abilityId, castSource)
-- castSource: "Manual", "Passive", or "AutoCast" (reserved for future paid auto-cast feature).
-- The server is the sole authority on cooldowns, resource, and damage.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local AbilityData = require(ReplicatedStorage.Shared.AbilityData)
local CharacterStats = require(ReplicatedStorage.Shared.CharacterStats)
local CooldownManager = require(script.Parent.CooldownManager)

local AbilityController = {}

-- Player resource state: { [Player] = currentResource }
local playerResources = {}

local function getBaseMaxResource()
	return CharacterStats.Base.Resource
end

local function GetResource(player)
	if not playerResources[player] then
		playerResources[player] = getBaseMaxResource()
		player:SetAttribute("Resource", getBaseMaxResource())
	end
	return playerResources[player]
end

local function SetResource(player, value)
	local maxRes = getBaseMaxResource()
	local clamped = math.clamp(value, 0, maxRes)
	playerResources[player] = clamped
	player:SetAttribute("Resource", math.floor(clamped))
end

-- Find valid targets within hit range using GetPartBoundsInRadius (OverlapParams-style).
-- Returns array of { character, humanoid } for all Humanoids in range.
local function FindTargets(character, hitRange)
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return {} end

	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = { character }

	local parts = Workspace:GetPartBoundsInRadius(rootPart.Position, hitRange, overlapParams)

	local targets = {}
	local seen = {}
	for _, part in ipairs(parts) do
		local targetChar = part.Parent
		if targetChar and not seen[targetChar] then
			local humanoid = targetChar:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				seen[targetChar] = true
				table.insert(targets, { character = targetChar, humanoid = humanoid })
			end
		end
	end
	return targets
end

-- Main entry point for ability casting. Returns success (bool), result (table).
function AbilityController.TryCast(player, abilityId, castSource)
	-- castSource is reserved for future use ("Manual", "Passive", "AutoCast")
	local ability = AbilityData[abilityId]
	if not ability then
		return false, { error = "Unknown ability" }
	end

	local character = player.Character
	if not character then
		return false, { error = "No character" }
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false, { error = "Player dead" }
	end

	-- Check cooldown
	if not CooldownManager.CanCast(player, abilityId) then
		return false, { error = "On cooldown" }
	end

	-- Check resource
	local currentResource = GetResource(player)
	if currentResource < ability.ResourceCost then
		return false, { error = "Not enough resource" }
	end
 
	-- All checks passed � execute the ability
	SetResource(player, currentResource - ability.ResourceCost)
	CooldownManager.SetCooldown(player, abilityId, ability.Cooldown)

	-- Find targets and deal damage
	local targets = FindTargets(character, ability.HitRange)
	local hitResults = {}
	for _, target in ipairs(targets) do
		target.humanoid:TakeDamage(ability.Damage)
		table.insert(hitResults, {
			name = target.character.Name,
			damage = ability.Damage,
			health = target.humanoid.Health,
	})
	end

	return true, { hits = hitResults, cooldown = ability.Cooldown }
end

-- Regenerate resource for all players. Called from the centralized Heartbeat ticker.
function AbilityController.TickResource(deltaTime)
	local regen = CharacterStats.Base.ResourceRegen
	for player, _ in pairs(playerResources) do
		if player.Parent and player.Character then
			local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				local oldResource = playerResources[player]
				local newResource = math.clamp(oldResource + regen * deltaTime, 0, getBaseMaxResource())
				playerResources[player] = newResource
				-- Only replicate when the integer value changes (reduces network traffic)
				if math.floor(newResource) ~= math.floor(oldResource) then
					player:SetAttribute("Resource", math.floor(newResource))
				end
			end
		end
	end
end

function AbilityController.ClearPlayer(player)
	playerResources[player] = nil
	CooldownManager.ClearPlayer(player)
end

return AbilityController
