-- UpgradeTestInput: TEMPORARY test-only script.
-- Press 1-7 to try purchasing one of the 7 upgrades from AbilityUpgrades,
-- purely to test UpgradeManager's validation logic (requirements, tags,
-- levels) before any upgrade effect touches AbilityController.
-- DELETE this file once a real upgrade UI exists.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local upgradeRemote = ReplicatedStorage.Remotes.UpgradeRemote

local keyToUpgradeId = {
	[Enum.KeyCode.One] = "ComboFinisher",
	[Enum.KeyCode.Two] = "ShockingEdge",
	[Enum.KeyCode.Three] = "BackstabBonus",
	[Enum.KeyCode.Four] = "ThunderCall",
	[Enum.KeyCode.Five] = "MultiStrike",
	[Enum.KeyCode.Six] = "StormFinisher",
	[Enum.KeyCode.Seven] = "QuickFeet",
}

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent then
		return
	end

	local upgradeId = keyToUpgradeId[input.KeyCode]
	if upgradeId then
		upgradeRemote:FireServer("Purchase", upgradeId)
	end
end)

upgradeRemote.OnClientEvent:Connect(function(action, upgradeId, success, reason, newLevel)
	if action ~= "Result" then
		return
	end

	if success then
		print(string.format("[UpgradeTest] Bought %s -> level %d", upgradeId, newLevel))
	else
		warn(string.format("[UpgradeTest] Failed %s: %s", upgradeId, tostring(reason)))
	end
end)
