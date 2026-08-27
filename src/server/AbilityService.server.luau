-- AbilityService: Server-side service that handles ability requests
-- and runs the centralized Heartbeat ticker for all players.

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AbilityController = require(script.Parent.AbilityController)
local CooldownManager = require(script.Parent.CooldownManager)
local CharacterStats = require(ReplicatedStorage.Shared.CharacterStats)

local abilityRemote = ReplicatedStorage.Remotes.AbilityRemote
local abilityVisualRemote = ReplicatedStorage.Remotes.AbilityVisualRemote

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
end)
