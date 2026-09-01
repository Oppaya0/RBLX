-- AbilityVisuals: Client-side visual feedback.
-- Listens for server events and renders damage numbers + simple ability VFX.
-- The client NEVER calculates damage ? it only displays what the server sends.
-- Note: these are code-only VFX (Tween-based), not skeletal animations.
-- Real skeletal animations require an Animation asset made in the Animation Editor
-- and played via Animator:LoadAnimation ? that's a separate workflow, not covered here.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local abilityVisualRemote = ReplicatedStorage.Remotes.AbilityVisualRemote
local AbilityData = require(ReplicatedStorage.Shared.AbilityData)

local function ShowDamageText(character, damage)
	local rootPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head")
	if not rootPart then return end

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 100, 0, 50)
	billboard.StudsOffset = Vector3.new(math.random(-15, 15) / 10, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = rootPart

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "-" .. tostring(damage)
	label.TextColor3 = Color3.new(1, 0.3, 0.3)
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.TextStrokeTransparency = 0
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.Parent = billboard

	local startTime = os.clock()
	local duration = 1.2
	task.spawn(function()
		while os.clock() - startTime < duration do
			local alpha = (os.clock() - startTime) / duration
			billboard.StudsOffset = Vector3.new(billboard.StudsOffset.X, 3 + alpha * 4, 0)
			label.TextTransparency = alpha
			label.TextStrokeTransparency = alpha
			task.wait()
		end
		billboard:Destroy()
	end)
end

-- Brief colored highlight flash on the caster's model.
local function FlashHighlight(character, color, duration)
	if not character then return end
	local highlight = Instance.new("Highlight")
	highlight.FillColor = color
	highlight.FillTransparency = 0.3
	highlight.OutlineTransparency = 0
	highlight.Parent = character

	local tween = TweenService:Create(highlight, TweenInfo.new(duration), { FillTransparency = 1, OutlineTransparency = 1 })
	tween:Play()
	tween.Completed:Connect(function()
		highlight:Destroy()
	end)
end

-- Expanding ring VFX centered on the caster, radius matches the ability's HitRange.
local function ExpandingRing(character, color, targetRadius, duration)
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	local ring = Instance.new("Part")
	ring.Shape = Enum.PartType.Cylinder
	ring.Anchored = true
	ring.CanCollide = false
	ring.Material = Enum.Material.Neon
	ring.Color = color
	ring.Size = Vector3.new(0.2, 1, 1)
	ring.CFrame = rootPart.CFrame * CFrame.Angles(0, 0, math.rad(90))
	ring.Transparency = 0.4
	ring.Parent = Workspace

	local tween = TweenService:Create(ring, TweenInfo.new(duration, Enum.EasingStyle.Quad), {
		Size = Vector3.new(0.2, targetRadius * 2, targetRadius * 2),
		Transparency = 1,
	})
	tween:Play()
	tween.Completed:Connect(function()
		ring:Destroy()
	end)
end

-- Plays the appropriate simple VFX based on the ability that was cast.
local function PlayAbilityVFX(casterCharacter, abilityId, abilityType)
	if not casterCharacter then return end

	if abilityType == "Attack" then
		FlashHighlight(casterCharacter, Color3.new(1, 0.6, 0.2), 0.15)
	elseif abilityType == "Dodge" then
		FlashHighlight(casterCharacter, Color3.new(0.3, 0.6, 1), 0.2)
	elseif abilityType == "Defense" then
		ExpandingRing(casterCharacter, Color3.new(1, 0.85, 0.2), 6, 0.4)
	elseif abilityType == "Ultimate" then
		local ability = AbilityData[abilityId]
		ExpandingRing(casterCharacter, Color3.new(0.8, 0.2, 1), ability and ability.HitRange or 10, 0.5)
	end
end

abilityVisualRemote.OnClientEvent:Connect(function(caster, abilityId, result)
	if not result then return end
	if result.error then return end

	PlayAbilityVFX(caster and caster.Character, abilityId, result.abilityType)

	if result.hits then
		for _, hit in ipairs(result.hits) do
			local character = Workspace:FindFirstChild(hit.name)
			if character then
				ShowDamageText(character, hit.damage)
			end
		end
	end
end)

return true