-- HUD: Full heads-up display for the vertical slice.
-- HP bar, Resource bar, and 4 ability slots with per-ability cooldown fill.
-- Reads resource/HP from server-authoritative sources only; never calculates them.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local abilityVisualRemote = ReplicatedStorage.Remotes.AbilityVisualRemote
local AbilityData = require(ReplicatedStorage.Shared.AbilityData)
local CharacterStats = require(ReplicatedStorage.Shared.CharacterStats)

local MAX_RESOURCE = CharacterStats.Base.Resource

-- Ordered list of abilities shown in the bar, with their key label and color.
-- Color matches the VFX colors used in AbilityVisuals, for visual consistency.
local ABILITY_SLOTS = {
	{ id = "Slash",     key = "Q",     color = Color3.new(1, 0.6, 0.2) },
	{ id = "Dash",      key = "SHIFT", color = Color3.new(0.3, 0.6, 1) },
	{ id = "Guard",     key = "F",     color = Color3.new(1, 0.85, 0.2) },
	{ id = "Whirlwind", key = "R",     color = Color3.new(0.8, 0.2, 1) },
}

-- === Root GUI ===
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AbilityHUD"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- === HP / Resource panel (top-left) ===
local statsPanel = Instance.new("Frame")
statsPanel.Size = UDim2.new(0, 250, 0, 74)
statsPanel.Position = UDim2.new(0, 10, 0, 10)
statsPanel.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
statsPanel.BackgroundTransparency = 0.3
statsPanel.BorderSizePixel = 0
statsPanel.Parent = screenGui

local statsCorner = Instance.new("UICorner")
statsCorner.CornerRadius = UDim.new(0, 8)
statsCorner.Parent = statsPanel

local hpLabel = Instance.new("TextLabel")
hpLabel.Size = UDim2.new(1, -20, 0, 18)
hpLabel.Position = UDim2.new(0, 10, 0, 6)
hpLabel.BackgroundTransparency = 1
hpLabel.Text = "HP: 100/100"
hpLabel.TextColor3 = Color3.new(1, 1, 1)
hpLabel.TextXAlignment = Enum.TextXAlignment.Left
hpLabel.Font = Enum.Font.GothamBold
hpLabel.TextSize = 13
hpLabel.Parent = statsPanel

local hpBarBg = Instance.new("Frame")
hpBarBg.Size = UDim2.new(1, -20, 0, 10)
hpBarBg.Position = UDim2.new(0, 10, 0, 26)
hpBarBg.BackgroundColor3 = Color3.new(0.2, 0, 0)
hpBarBg.BorderSizePixel = 0
hpBarBg.Parent = statsPanel

local hpBarBgCorner = Instance.new("UICorner")
hpBarBgCorner.CornerRadius = UDim.new(0, 4)
hpBarBgCorner.Parent = hpBarBg

local hpBarFill = Instance.new("Frame")
hpBarFill.Size = UDim2.new(1, 0, 1, 0)
hpBarFill.BackgroundColor3 = Color3.new(0.8, 0.1, 0.1)
hpBarFill.BorderSizePixel = 0
hpBarFill.Parent = hpBarBg

local hpBarFillCorner = Instance.new("UICorner")
hpBarFillCorner.CornerRadius = UDim.new(0, 4)
hpBarFillCorner.Parent = hpBarFill

local resourceLabel = Instance.new("TextLabel")
resourceLabel.Size = UDim2.new(1, -20, 0, 18)
resourceLabel.Position = UDim2.new(0, 10, 0, 40)
resourceLabel.BackgroundTransparency = 1
resourceLabel.Text = "Resource: 100/100"
resourceLabel.TextColor3 = Color3.new(1, 1, 1)
resourceLabel.TextXAlignment = Enum.TextXAlignment.Left
resourceLabel.Font = Enum.Font.GothamBold
resourceLabel.TextSize = 13
resourceLabel.Parent = statsPanel

local resourceBarBg = Instance.new("Frame")
resourceBarBg.Size = UDim2.new(1, -20, 0, 10)
resourceBarBg.Position = UDim2.new(0, 10, 0, 60)
resourceBarBg.BackgroundColor3 = Color3.new(0, 0, 0.2)
resourceBarBg.BorderSizePixel = 0
resourceBarBg.Parent = statsPanel

local resourceBarBgCorner = Instance.new("UICorner")
resourceBarBgCorner.CornerRadius = UDim.new(0, 4)
resourceBarBgCorner.Parent = resourceBarBg

local resourceBarFill = Instance.new("Frame")
resourceBarFill.Size = UDim2.new(1, 0, 1, 0)
resourceBarFill.BackgroundColor3 = Color3.new(0.2, 0.4, 1)
resourceBarFill.BorderSizePixel = 0
resourceBarFill.Parent = resourceBarBg

local resourceBarFillCorner = Instance.new("UICorner")
resourceBarFillCorner.CornerRadius = UDim.new(0, 4)
resourceBarFillCorner.Parent = resourceBarFill

-- === Ability bar (bottom-center) ===
local SLOT_SIZE = 64
local SLOT_GAP = 10
local totalWidth = (#ABILITY_SLOTS * SLOT_SIZE) + ((#ABILITY_SLOTS - 1) * SLOT_GAP)

local abilityBar = Instance.new("Frame")
abilityBar.Size = UDim2.new(0, totalWidth, 0, SLOT_SIZE + 20)
abilityBar.Position = UDim2.new(0.5, -totalWidth / 2, 1, -(SLOT_SIZE + 30))
abilityBar.BackgroundTransparency = 1
abilityBar.Parent = screenGui

-- Holds per-ability UI references and cooldown state, keyed by abilityId.
local abilitySlots = {}

for index, slotData in ipairs(ABILITY_SLOTS) do
	local ability = AbilityData[slotData.id]

	local slot = Instance.new("Frame")
	slot.Size = UDim2.new(0, SLOT_SIZE, 0, SLOT_SIZE)
	slot.Position = UDim2.new(0, (index - 1) * (SLOT_SIZE + SLOT_GAP), 0, 0)
	slot.BackgroundColor3 = slotData.color
	slot.BorderSizePixel = 0
	slot.Parent = abilityBar

	local slotCorner = Instance.new("UICorner")
	slotCorner.CornerRadius = UDim.new(0, 10)
	slotCorner.Parent = slot

	-- Cooldown overlay: dark frame that shrinks from top to bottom as cooldown ends.
	local overlay = Instance.new("Frame")
	overlay.Size = UDim2.new(1, 0, 0, 0)
	overlay.Position = UDim2.new(0, 0, 0, 0)
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 0.35
	overlay.BorderSizePixel = 0
	overlay.ZIndex = 2
	overlay.Parent = slot

	local overlayCorner = Instance.new("UICorner")
	overlayCorner.CornerRadius = UDim.new(0, 10)
	overlayCorner.Parent = overlay

	local cooldownText = Instance.new("TextLabel")
	cooldownText.Size = UDim2.new(1, 0, 1, 0)
	cooldownText.BackgroundTransparency = 1
	cooldownText.Text = ""
	cooldownText.TextColor3 = Color3.new(1, 1, 1)
	cooldownText.TextStrokeColor3 = Color3.new(0, 0, 0)
	cooldownText.TextStrokeTransparency = 0
	cooldownText.Font = Enum.Font.GothamBold
	cooldownText.TextSize = 20
	cooldownText.ZIndex = 3
	cooldownText.Parent = slot

	local keyLabel = Instance.new("TextLabel")
	keyLabel.Size = UDim2.new(1, 0, 0, 16)
	keyLabel.Position = UDim2.new(0, 0, 1, 2)
	keyLabel.BackgroundTransparency = 1
	keyLabel.Text = slotData.key
	keyLabel.TextColor3 = Color3.new(1, 1, 1)
	keyLabel.Font = Enum.Font.GothamBold
	keyLabel.TextSize = 12
	keyLabel.Parent = slot

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0, 16)
	nameLabel.Position = UDim2.new(0, 0, 1, 18)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = ability and ability.DisplayName or slotData.id
	nameLabel.TextColor3 = Color3.new(0.7, 0.7, 0.7)
	nameLabel.Font = Enum.Font.Gotham
	nameLabel.TextSize = 11
	nameLabel.Parent = slot

	abilitySlots[slotData.id] = {
		frame = slot,
		overlay = overlay,
		cooldownText = cooldownText,
		maxCooldown = ability and ability.Cooldown or 1,
		remaining = 0,
	}
end

-- === HP tracking ===
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

-- === Resource tracking ===
local function updateResource()
	local resource = player:GetAttribute("Resource") or MAX_RESOURCE
	resourceLabel.Text = string.format("Resource: %d/%d", math.floor(resource), MAX_RESOURCE)
	resourceBarFill.Size = UDim2.new(resource / MAX_RESOURCE, 0, 1, 0)
end

player:GetAttributeChangedSignal("Resource"):Connect(updateResource)
updateResource()

-- === Cooldown tracking (per-ability, client-side display only) ===
abilityVisualRemote.OnClientEvent:Connect(function(caster, abilityId, result)
	if caster ~= player then return end
	if not result or result.error then return end

	local slot = abilitySlots[abilityId]
	if slot and result.cooldown then
		slot.remaining = result.cooldown
	end
end)

RunService.Heartbeat:Connect(function(deltaTime)
	for _, slot in pairs(abilitySlots) do
		if slot.remaining > 0 then
			slot.remaining = math.max(0, slot.remaining - deltaTime)
			local alpha = slot.remaining / slot.maxCooldown
			slot.overlay.Size = UDim2.new(1, 0, alpha, 0)
			if slot.remaining > 0 then
				slot.cooldownText.Text = string.format("%.1f", slot.remaining)
			else
				slot.cooldownText.Text = ""
				slot.overlay.Size = UDim2.new(1, 0, 0, 0)
			end
		end
	end
end)

-- === Tooltip on hover ===
local tooltip = Instance.new("Frame")
tooltip.Size = UDim2.new(0, 220, 0, 90)
tooltip.BackgroundColor3 = Color3.new(0.05, 0.05, 0.05)
tooltip.BackgroundTransparency = 0.1
tooltip.BorderSizePixel = 0
tooltip.Visible = false
tooltip.ZIndex = 10
tooltip.Parent = screenGui

local tooltipCorner = Instance.new("UICorner")
tooltipCorner.CornerRadius = UDim.new(0, 8)
tooltipCorner.Parent = tooltip

local tooltipText = Instance.new("TextLabel")
tooltipText.Size = UDim2.new(1, -16, 1, -16)
tooltipText.Position = UDim2.new(0, 8, 0, 8)
tooltipText.BackgroundTransparency = 1
tooltipText.TextColor3 = Color3.new(1, 1, 1)
tooltipText.TextXAlignment = Enum.TextXAlignment.Left
tooltipText.TextYAlignment = Enum.TextYAlignment.Top
tooltipText.TextWrapped = true
tooltipText.Font = Enum.Font.Gotham
tooltipText.TextSize = 13
tooltipText.ZIndex = 11
tooltipText.Parent = tooltip

for _, slotData in ipairs(ABILITY_SLOTS) do
	local ability = AbilityData[slotData.id]
	local slotFrame = abilityBar:FindFirstChild(nil) -- placeholder, replaced below
end

-- Re-fetch actual slot frames by index since they were created positionally above.
for index, slotData in ipairs(ABILITY_SLOTS) do
	local slotFrame = abilityBar:GetChildren()[index]
	if slotFrame then
		local ability = AbilityData[slotData.id]
		slotFrame.MouseEnter:Connect(function()
			local lines = {
				ability.DisplayName,
				ability.Description,
				string.format("Cooldown: %.1fs   Cost: %d", ability.Cooldown, ability.ResourceCost),
			}
			if ability.Damage and ability.Damage > 0 then
				table.insert(lines, 3, string.format("Base Damage: %d", ability.Damage))
			end
			tooltipText.Text = table.concat(lines, "\n")
			tooltip.Position = UDim2.new(0.5, -110, 1, -(SLOT_SIZE + 30 + 100))
			tooltip.Visible = true
		end)
		slotFrame.MouseLeave:Connect(function()
			tooltip.Visible = false
		end)
	end
end

-- === Tooltip on hover: shows description, base damage, cooldown, and resource cost ===
local tooltip = Instance.new("Frame")
tooltip.Size = UDim2.new(0, 220, 0, 90)
tooltip.BackgroundColor3 = Color3.new(0.05, 0.05, 0.05)
tooltip.BackgroundTransparency = 0.1
tooltip.BorderSizePixel = 0
tooltip.Visible = false
tooltip.ZIndex = 10
tooltip.Parent = screenGui

local tooltipCorner = Instance.new("UICorner")
tooltipCorner.CornerRadius = UDim.new(0, 8)
tooltipCorner.Parent = tooltip

local tooltipText = Instance.new("TextLabel")
tooltipText.Size = UDim2.new(1, -16, 1, -16)
tooltipText.Position = UDim2.new(0, 8, 0, 8)
tooltipText.BackgroundTransparency = 1
tooltipText.TextColor3 = Color3.new(1, 1, 1)
tooltipText.TextXAlignment = Enum.TextXAlignment.Left
tooltipText.TextYAlignment = Enum.TextYAlignment.Top
tooltipText.TextWrapped = true
tooltipText.Font = Enum.Font.Gotham
tooltipText.TextSize = 13
tooltipText.ZIndex = 11
tooltipText.Parent = tooltip

for slotId, slot in pairs(abilitySlots) do
	local ability = AbilityData[slotId]
	if slot.frame and ability then
		slot.frame.MouseEnter:Connect(function()
			local lines = { ability.DisplayName, ability.Description }
			if ability.Damage and ability.Damage > 0 then
				table.insert(lines, string.format("Base Damage: %d", ability.Damage))
			end
			table.insert(lines, string.format("Cooldown: %.1fs   Cost: %d", ability.Cooldown, ability.ResourceCost))
			tooltipText.Text = table.concat(lines, "\n")
			tooltip.Position = UDim2.new(0.5, -110, 1, -(SLOT_SIZE + 30 + 100))
			tooltip.Visible = true
		end)
		slot.frame.MouseLeave:Connect(function()
			tooltip.Visible = false
		end)
	end
end

return true