-- Data Handler

local Players = game:GetService("Players")

local Service = {}

function Service.onPlayerAdded(player: Player)
    print(player.Name, "Joined")
end
function Service.onPlayerRemoved(player: Player)
    print(player.Name, "Left")
end
function Service.init()
    Players.PlayerAdded:Connect(Service.onPlayerAdded)
    Players.PlayerRemoving:Connect(Service.onPlayerRemoved)
    for _, player: Player in next, Players:GetPlayers() do
        Service.onPlayerAdded(player)
    end
end

return Service