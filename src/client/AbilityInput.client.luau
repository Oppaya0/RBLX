-- AbilityInput: Client-side input handler.
-- Captures key presses and fires RemoteEvent to server. Client never decides damage or cooldown.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local abilityRemote = ReplicatedStorage.Remotes.AbilityRemote

-- Key -> AbilityId map. Add new abilities here, no other code needs to change.
local KEY_BINDINGS = {
	[Enum.KeyCode.Q] = "Slash",
	[Enum.KeyCode.LeftShift] = "Dash",
	[Enum.KeyCode.F] = "Guard",
	[Enum.KeyCode.R] = "Whirlwind",
}

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	local abilityId = KEY_BINDINGS[input.KeyCode]
	if abilityId then
		abilityRemote:FireServer(abilityId, "Manual")
	end
end)

return true