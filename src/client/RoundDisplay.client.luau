-- Round Display

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local playerGui: PlayerGui = localPlayer:WaitForChild("PlayerGui", math.huge)
local roundDisplay = playerGui:WaitForChild("RoundDisplay", math.huge)

local statusText: TextLabel = roundDisplay.Status
local timer: TextLabel = roundDisplay.Time.TimeLeft

local _STATUS = ReplicatedStorage:WaitForChild("STATUS", math.huge)
local _TIMER = ReplicatedStorage:WaitForChild("TIMER", math.huge)

RunService.Heartbeat:Connect(function()
    statusText.Text = _STATUS.Value
    timer.Text = tostring(_TIMER.Value)
end)