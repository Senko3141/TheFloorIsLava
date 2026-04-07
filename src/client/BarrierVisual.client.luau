-- Distance Fade

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local distance_fade = require(ReplicatedStorage.Packages["distance-fade"])

local _barriers = {}

local DEFAULT_SETTINGS = {
	["DistanceOuter"] = 16, -- Distance at which the effect starts to appear
	["DistanceInner"] = 4, -- Distance at which the effect is fully visible
	["EffectRadius"] = 16, -- Size of the effect when in range
	["EffectRadiusMin"] = 0, -- Size of the effect when out of range
	["EdgeDistanceCalculations"] = false, -- When set to true, distance to target is calculated from the face edges rather than the face itself. Can be more accurate in certain cases
	["Texture"] = "rbxassetid://18838056070", -- TextureId
	["TextureTransparency"] = 0, -- Transparency of the texture when in range
	["TextureTransparencyMin"] = 1, -- Transparency of the texture when out of range
	["BackgroundTransparency"] = 1, -- Transparency of the texture background when in range
	["BackgroundTransparencyMin"] = 1, -- Transparency of the texture background when out of range
	["TextureColor"] = Color3.fromRGB(41, 134, 255), -- Color of the texture
	["BackgroundColor"] = Color3.fromRGB(255, 255, 255), -- Color of the texture background
	["TextureSize"] = Vector2.new(8, 8), -- Size of the texture in studs per tile. Can potentially cause clipping issues if greater than EffectRadius * 2
	["TextureOffset"] = Vector2.new(0, 0), -- Texture offset in studs
	-- SurfaceGui settings
	["ZOffset"] = 0,
	["AlwaysOnTop"] = false,
	["Brightness"] = 1,
	["LightInfluence"] = 0,
	["MaxDistance"] = 1000,
	["PixelsPerStud"] = 100,
	["SizingMode"] = Enum.SurfaceGuiSizingMode.PixelsPerStud
}

task.wait(3)

for _,v in workspace:GetDescendants() do
    if v.Name == "_BARRIER" then
        table.insert(_barriers, v)
    end
end

local distanceFadeObj = distance_fade.new()
distanceFadeObj:UpdateSettings(DEFAULT_SETTINGS)

for _, partToAdd in pairs(_barriers) do
    distanceFadeObj:AddFace(partToAdd, Enum.NormalId.Front)
    distanceFadeObj:AddFace(partToAdd, Enum.NormalId.Back)
    distanceFadeObj:AddFace(partToAdd, Enum.NormalId.Left)
    distanceFadeObj:AddFace(partToAdd, Enum.NormalId.Right)
end

RunService.Heartbeat:Connect(function()
	distanceFadeObj:Step()
end)