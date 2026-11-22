local Players = game:GetService("Players")

local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui"):WaitForChild("Shop")

local part = workspace:WaitForChild("Shop")
local prompt = part:WaitForChild("ProximityPrompt")

prompt.Triggered:Connect(function()
	gui.Enabled = not gui.Enabled 
end)
