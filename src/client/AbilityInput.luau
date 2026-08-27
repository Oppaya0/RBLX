-- AbilityInput: Client-side input handler.
-- Captures key press and fires RemoteEvent to server. Client never decides damage or cooldown.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local abilityRemote = ReplicatedStorage.Remotes.AbilityRemote

local ABILITY_KEY = Enum.KeyCode.Q
local ABILITY_ID = "Slash"

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == ABILITY_KEY then
		abilityRemote:FireServer(ABILITY_ID, "Manual")
	end
end)

return true
 