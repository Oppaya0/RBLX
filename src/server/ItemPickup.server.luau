-- ItemPickup: Generic pickup system for any Part tagged "DamagePickup" in Studio.
-- No script changes needed to add new pickups ? just tag a Part and set its Attributes.

local CollectionService = game:GetService("CollectionService")

local PlayerStats = require(script.Parent.PlayerStats)

local PICKUP_TAG = "DamagePickup"

local function setupPickup(part)
	if not part:IsA("BasePart") then return end

	local prompt = part:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Pick Up"
		prompt.ObjectText = part.Name
		prompt.HoldDuration = 0.3
		prompt.MaxActivationDistance = 8
		prompt.Parent = part
	end

	prompt.Triggered:Connect(function(player)
		local group = part:GetAttribute("StatGroup") or "A"
		local amount = part:GetAttribute("StatAmount") or 0
		if amount > 0 then
			PlayerStats.AddStat(player, group, amount)
			part:Destroy()
		end
	end)
end

for _, part in ipairs(CollectionService:GetTagged(PICKUP_TAG)) do
	setupPickup(part)
end

CollectionService:GetInstanceAddedSignal(PICKUP_TAG):Connect(setupPickup)