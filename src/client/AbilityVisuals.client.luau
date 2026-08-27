-- AbilityVisuals: Client-side visual feedback.
-- Listens for server events and renders floating damage numbers.
-- The client NEVER calculates damage ? it only displays what the server sends.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local abilityVisualRemote = ReplicatedStorage.Remotes.AbilityVisualRemote

-- Create floating damage text above a character
local function ShowDamageText(character, damage)
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		rootPart = character:FindFirstChild("Head")
	end
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

	-- Animate upward and fade out
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

abilityVisualRemote.OnClientEvent:Connect(function(caster, abilityId, result)
	if not result then return end

	if result.error then
		-- Could show error feedback to the player here
		return
	end

	-- Show damage numbers for each hit target
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
