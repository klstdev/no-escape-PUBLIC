local rs = game:GetService("ReplicatedStorage")
local gui = script.Parent
local timer = gui:WaitForChild("TimerText")
local status = gui:WaitForChild("Status")

local statusvalue = rs:WaitForChild("Status")
local timervalue = rs:WaitForChild("Timer")

local function formatTime(seconds)
	return string.format("%02d:%02d", math.floor(seconds / 60), seconds % 60)
end

local function updateStatus()
	status.Text = statusvalue.Value
end

local function updateTimer()
	timer.Text = formatTime(timervalue.Value)
end

updateStatus()
updateTimer()
statusvalue.Changed:Connect(updateStatus)
timervalue.Changed:Connect(updateTimer)
