-- Init

local services = {}
local folder = script.Services

local startTime = os.clock()

for _, v in folder:GetChildren() do
    if v:IsA("ModuleScript") then
        services[v.Name] = require(v)
    end
end

for _, module in services do
    if module.init then
        module.init()
    end
end

warn("Server inititated in ".. os.clock()-startTime.."s")