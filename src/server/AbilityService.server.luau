-- AbilityService: Server-side service that handles ability requests
-- and runs the centralized Heartbeat ticker for all players.

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerStats = require(script.Parent.PlayerStats)
local AbilityController = require(script.Parent.AbilityController)
local CooldownManager = require(script.Parent.CooldownManager)
local UpgradeManager = require(script.Parent.UpgradeManager)
local CharacterStats = require(ReplicatedStorage.Shared.CharacterStats)

local abilityRemote = ReplicatedStorage.Remotes.AbilityRemote
local abilityVisualRemote = ReplicatedStorage.Remotes.AbilityVisualRemote

-- TEMPORARY (test-only): manually create this RemoteEvent in Studio under
-- ReplicatedStorage/Remotes, same place as the two above. Used only to test
-- UpgradeManager.Purchase/CanPurchase in isolation, before any upgrade
-- effect is wired into AbilityController. Remove once real upgrade UI exists.
local upgradeRemote = ReplicatedStorage.Remotes.UpgradeRemote

-- Handle ability cast requests from clients
abilityRemote.OnServerEvent:Connect(function(player, abilityId, castSource)
	-- castSource is reserved for future use ("Manual", "Passive", "AutoCast")
	castSource = castSource or "Manual"

	local success, result = AbilityController.TryCast(player, abilityId, castSource)

	if success then
		-- Fire visual feedback to all clients (everyone sees the damage numbers)
		abilityVisualRemote:FireAllClients(player, abilityId, result)
	else
		-- Fire failure feedback only to the casting player
		abilityVisualRemote:FireClient(player, abilityId, result)
	end
end)

-- TEMPORARY (test-only): handles "Purchase" requests from UpgradeTestInput.client.luau.
-- Only exercises UpgradeManager.Purchase/CanPurchase -- does NOT touch AbilityController.
upgradeRemote.OnServerEvent:Connect(function(player, action, upgradeId)
	if action ~= "Purchase" then
		return
	end

	local success, reason = UpgradeManager.Purchase(player, upgradeId)
	local newLevel = UpgradeManager.GetLevel(player, upgradeId)

	print(string.format(
		"[UpgradeTest] %s -> %s: success=%s reason=%s newLevel=%d",
		player.Name,
		tostring(upgradeId),
		tostring(success),
		tostring(reason),
		newLevel
	))

	upgradeRemote:FireClient(player, "Result", upgradeId, success, reason, newLevel)
end)

-- Centralized Heartbeat ticker: single loop for ALL players.
-- No per-player while-loops. This scales to any player count.
RunService.Heartbeat:Connect(function(deltaTime)
	CooldownManager.Tick(deltaTime)
	AbilityController.TickResource(deltaTime)
end)

-- Set up character stats when a player joins or respawns
local function setupCharacter(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = CharacterStats.Base.MoveSpeed
	end
end

local function onPlayerAdded(player)
	player:SetAttribute("Resource", CharacterStats.Base.Resource)

	player.CharacterAdded:Connect(function(character)
		setupCharacter(character)
	end)

	if player.Character then
		setupCharacter(player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

-- Cleanup when players leave
Players.PlayerRemoving:Connect(function(player)
	AbilityController.ClearPlayer(player)
	PlayerStats.ClearPlayer(player)
	UpgradeManager.ClearPlayer(player) -- was missing; per-player state must always be cleared
end)
