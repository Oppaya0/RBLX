-- AbilityController: Server-side ability validation and execution.
-- Single entry point: TryCast(player, abilityId, castSource)
-- castSource: "Manual", "Passive", or "AutoCast" (reserved for future paid auto-cast feature).
-- The server is the sole authority on cooldowns, resource, and damage.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local PlayerStats = require(script.Parent.PlayerStats)
local AbilityData = require(ReplicatedStorage.Shared.AbilityData)
local CharacterStats = require(ReplicatedStorage.Shared.CharacterStats)
local CooldownManager = require(script.Parent.CooldownManager)

local AbilityController = {}

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

-- Dodge-type abilities: push the character forward using a temporary BodyVelocity.
local function DashCharacter(character, distance, duration)
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	local direction = rootPart.CFrame.LookVector
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(1e5, 0, 1e5)
	bodyVelocity.Velocity = direction * (distance / duration)
	bodyVelocity.Name = "DashVelocity"
	bodyVelocity.Parent = rootPart

	task.delay(duration, function()
		if bodyVelocity and bodyVelocity.Parent then
			bodyVelocity:Destroy()
		end
	end)
end

-- Defense-type abilities: mark the player as shielded for a duration.
-- (Placeholder flag for now ? incoming damage reduction will read this once NPCs can hit back.)
local function ApplyShield(player, duration)
	player:SetAttribute("Shielded", true)
	task.delay(duration, function()
		if player.Parent then
			player:SetAttribute("Shielded", false)
		end
	end)
end

function AbilityController.TryCast(player, abilityId, castSource)
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

	if not CooldownManager.CanCast(player, abilityId) then
		return false, { error = "On cooldown" }
	end

	local currentResource = GetResource(player)
	if currentResource < ability.ResourceCost then
		return false, { error = "Not enough resource" }
	end

	-- All checks passed ? spend resource and start cooldown before any effect runs.
	SetResource(player, currentResource - ability.ResourceCost)
	CooldownManager.SetCooldown(player, abilityId, ability.Cooldown)

	if ability.Type == "Dodge" then
		DashCharacter(character, ability.DashDistance, ability.DashDuration)
		return true, { hits = {}, cooldown = ability.Cooldown, abilityType = ability.Type }
	end

	if ability.Type == "Defense" then
		ApplyShield(player, ability.ShieldDuration)
		return true, { hits = {}, cooldown = ability.Cooldown, abilityType = ability.Type }
	end

	-- Attack and Ultimate both deal damage in a radius; only the numbers differ.
	local multiplier = PlayerStats.GetMultiplier(player)
	local finalDamage = math.floor(ability.Damage * multiplier + 0.5)

	local targets = FindTargets(character, ability.HitRange)
	local hitResults = {}
	for _, target in ipairs(targets) do
		target.humanoid:TakeDamage(finalDamage)
		table.insert(hitResults, {
			name = target.character.Name,
			damage = finalDamage,
			health = target.humanoid.Health,
		})
	end

	return true, { hits = hitResults, cooldown = ability.Cooldown, abilityType = ability.Type }
end

function AbilityController.TickResource(deltaTime)
	local regen = CharacterStats.Base.ResourceRegen
	for player, _ in pairs(playerResources) do
		if player.Parent and player.Character then
			local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				local oldResource = playerResources[player]
				local newResource = math.clamp(oldResource + regen * deltaTime, 0, getBaseMaxResource())
				playerResources[player] = newResource
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