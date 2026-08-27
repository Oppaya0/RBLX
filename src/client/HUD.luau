-- HUD: Minimal heads-up display for the vertical slice.
-- Shows HP bar, Resource bar, and ability cooldown status.
-- Reads resource from a server-set player attribute (server is the authority).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local abilityVisualRemote = ReplicatedStorage.Remotes.AbilityVisualRemote

local MAX_RESOURCE = 100

-- Create the HUD GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AbilityHUD"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local container = Instance.new("Frame")
container.Size = UDim2.new(0, 250, 0, 120)
container.Position = UDim2.new(0, 10, 1, -130)
container.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
container.BackgroundTransparency = 0.3
container.BorderSizePixel = 2
container.BorderColor3 = Color3.new(0.3, 0.3, 0.3)
container.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = container

-- HP label and bar
local hpLabel = Instance.new("TextLabel")
hpLabel.Size = UDim2.new(1, -20, 0, 20)
hpLabel.Position = UDim2.new(0, 10, 0, 10)
hpLabel.BackgroundTransparency = 1
hpLabel.Text = "HP: 100/100"
hpLabel.TextColor3 = Color3.new(1, 1, 1)
hpLabel.TextXAlignment = Enum.TextXAlignment.Left
hpLabel.Font = Enum.Font.GothamBold
hpLabel.TextSize = 14
hpLabel.Parent = container

local hpBarBg = Instance.new("Frame")
hpBarBg.Size = UDim2.new(1, -20, 0, 12)
hpBarBg.Position = UDim2.new(0, 10, 0, 32)
hpBarBg.BackgroundColor3 = Color3.new(0.2, 0, 0)
hpBarBg.BorderSizePixel = 0
hpBarBg.Parent = container

local hpBarFill = Instance.new("Frame")
hpBarFill.Size = UDim2.new(1, 0, 1, 0)
hpBarFill.BackgroundColor3 = Color3.new(0.8, 0.1, 0.1)
hpBarFill.BorderSizePixel = 0
hpBarFill.Parent = hpBarBg

-- Resource label and bar
local resourceLabel = Instance.new("TextLabel")
resourceLabel.Size = UDim2.new(1, -20, 0, 20)
resourceLabel.Position = UDim2.new(0, 10, 0, 52)
resourceLabel.BackgroundTransparency = 1
resourceLabel.Text = "Resource: 100/100"
resourceLabel.TextColor3 = Color3.new(1, 1, 1)
resourceLabel.TextXAlignment = Enum.TextXAlignment.Left
resourceLabel.Font = Enum.Font.GothamBold
resourceLabel.TextSize = 14
resourceLabel.Parent = container

local resourceBarBg = Instance.new("Frame")
resourceBarBg.Size = UDim2.new(1, -20, 0, 12)
resourceBarBg.Position = UDim2.new(0, 10, 0, 74)
resourceBarBg.BackgroundColor3 = Color3.new(0, 0, 0.2)
resourceBarBg.BorderSizePixel = 0
resourceBarBg.Parent = container

local resourceBarFill = Instance.new("Frame")
resourceBarFill.Size = UDim2.new(1, 0, 1, 0)
resourceBarFill.BackgroundColor3 = Color3.new(0.2, 0.4, 1)
resourceBarFill.BorderSizePixel = 0
resourceBarFill.Parent = resourceBarBg

-- Ability cooldown indicator
local abilityLabel = Instance.new("TextLabel")
abilityLabel.Size = UDim2.new(1, -20, 0, 20)
abilityLabel.Position = UDim2.new(0, 10, 0, 94)
abilityLabel.BackgroundTransparency = 1
abilityLabel.Text = "[Q] Slash - Ready"
abilityLabel.TextColor3 = Color3.new(0, 1, 0)
abilityLabel.TextXAlignment = Enum.TextXAlignment.Left
abilityLabel.Font = Enum.Font.GothamBold
abilityLabel.TextSize = 14
abilityLabel.Parent = container

-- Update HP bar when character spawns/respawns
local function setupCharacter(character)
	local humanoid = character:WaitForChild("Humanoid")

	local function updateHP()
		local hp = math.max(0, humanoid.Health)
		local maxHp = humanoid.MaxHealth
		hpLabel.Text = string.format("HP: %d/%d", math.ceil(hp), maxHp)
		hpBarFill.Size = UDim2.new(hp / maxHp, 0, 1, 0)
	end

	humanoid.HealthChanged:Connect(updateHP)
	updateHP()
end

if player.Character then
	setupCharacter(player.Character)
end
player.CharacterAdded:Connect(setupCharacter)

-- Update resource bar from server-set attribute
local function updateResource()
	local resource = player:GetAttribute("Resource") or MAX_RESOURCE
	resourceLabel.Text = string.format("Resource: %d/%d", math.floor(resource), MAX_RESOURCE)
	resourceBarFill.Size = UDim2.new(resource / MAX_RESOURCE, 0, 1, 0)
end

player:GetAttributeChangedSignal("Resource"):Connect(updateResource)
updateResource()

-- Track cooldown locally for display (server is still the authority)
local cooldownRemaining = 0

abilityVisualRemote.OnClientEvent:Connect(function(caster, abilityId, result)
	if caster ~= player then return end
	if not result or result.error then return end
	if result.cooldown then
		cooldownRemaining = result.cooldown
	end
end)

-- Countdown using Heartbeat (no per-player while-loop on server; this is client-side only)
RunService.Heartbeat:Connect(function(deltaTime)
	if cooldownRemaining > 0 then
		cooldownRemaining = math.max(0, cooldownRemaining - deltaTime)
		if cooldownRemaining > 0 then
			abilityLabel.Text = string.format("[Q] Slash - %.1fs", cooldownRemaining)
			abilityLabel.TextColor3 = Color3.new(1, 0.5, 0)
		else
			abilityLabel.Text = "[Q] Slash - Ready"
			abilityLabel.TextColor3 = Color3.new(0, 1, 0)
		end
	end
end)
