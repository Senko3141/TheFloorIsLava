-- Round Service

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage.Shared
local Packages = ReplicatedStorage.Packages

local Janitor = require(Packages.Janitor)
local GameValues = require(Shared.GameValues)

local TIMER = Instance.new("IntValue")
TIMER.Name = "TIMER"
TIMER.Value = 0
TIMER.Parent = ReplicatedStorage

local STATUS = Instance.new("StringValue")
STATUS.Name = "STATUS"
STATUS.Value = ""
STATUS.Parent = ReplicatedStorage

local Service = {}
local random = Random.new()

function Service.getRandomLocationOnPart(basePart: BasePart): Vector3
	local halfSize = basePart.Size / 2
	local localX = random:NextNumber(-halfSize.X, halfSize.X)
	local localZ = random:NextNumber(-halfSize.Z, halfSize.Z)
	local localPosition = Vector3.new(localX, halfSize.Y, localZ)
	return basePart.CFrame:PointToWorldSpace(localPosition)
end

function Service.isEnoughPlayers(): boolean
	return #Players:GetPlayers() >= GameValues.REQUIRED_PLAYERS
end
function Service.init()
	task.spawn(function()
		while true do
			while true do

				STATUS.Value = "WAITING FOR PLAYERS"

				-- Checking If Another Players to Start
				if Service.isEnoughPlayers() then
					-- Countdown
					TIMER.Value = GameValues.INTERMISSION_COUNTDOWN
					STATUS.Value = "INTERMISSION"
					for i = GameValues.INTERMISSION_COUNTDOWN, 1, -1 do
						TIMER.Value -= 1
						task.wait(1)
					end
				else
					break
				end

				-- Starting Game
				if Service.isEnoughPlayers() then
					TIMER.Value = GameValues.GAME_START_COUNTDOWN
					STATUS.Value = "GAME STARTING"
					for i = GameValues.GAME_START_COUNTDOWN, 1, -1 do
						TIMER.Value -= 1
						task.wait(1)
					end
				else
					break
				end

				-- Checking if Enough
				for _, player: Player in Players:GetPlayers() do
					if player.Character then
						for _, v in player.Character:GetDescendants() do
							local s, _ = pcall(function()
								local _ = v.CollisionGroup
							end)
							if s then
								v.CollisionGroup = "Players"
							end
						end
						CollectionService:AddTag(player.Character, "GameTag")
					end
				end

				while true do
					if Service.isEnoughPlayers() then
						-- Teleport Players To Map

						for _, character: Model in CollectionService:GetTagged("GameTag") do
							local randomSpawn = workspace.World.GameMap.SpawnPart.Position
							character:PivotTo(CFrame.new(randomSpawn))
						end

						-- Generate Random Platforms (playerCount-1), At Least One Player Dies

						local platforms = {}
						local platformsFolder = workspace.World.GameMap.Platforms
						local playersInGame = #CollectionService:GetTagged("GameTag")
						local platformsToGenerate = math.clamp(playersInGame - 1, 1, math.huge)

						for i = 1, platformsToGenerate do
							local pf = Instance.new("Part")
							pf.Name = "PLATFORM/" .. i
							pf.Size = Vector3.new(5, 10, 5)
							pf.Anchored = true
							pf.Position = Service.getRandomLocationOnPart(workspace.World.GameMap.Baseplate)
								+ Vector3.new(0, 5, 0)
							pf.CollisionGroup = "Platforms"
							pf.Parent = platformsFolder

							local handler = Janitor.new()
							handler:Add(pf.Touched:Connect(function(hit)
								if not hit.Parent then
									return
								end
								local humanoid = hit.Parent:FindFirstChild("Humanoid")
								if not humanoid then
									return
								end
								if not CollectionService:HasTag(hit.Parent, "GameTag") then
									return
								end
								if pf:GetAttribute("TAKEN") then
									return
								end

								local hitPos = hit.Position
								local topY = pf.Position.Y + pf.Size.Y / 2
								local localHit = pf.CFrame:PointToObjectSpace(hitPos)

								local isAboveTop = hitPos.Y > topY - 0.5
								local isCenterX = math.abs(localHit.X) <= pf.Size.X * 0.4
								local isCenterZ = math.abs(localHit.Z) <= pf.Size.Z * 0.4

								if not (isAboveTop and isCenterX and isCenterZ) then
									return
								end

								hit.Parent.Humanoid.WalkSpeed = 0
								hit.Parent.Humanoid.JumpPower = 0
								hit.Parent.Humanoid.AutoRotate = false
								hit.Parent:PivotTo(pf.CFrame * CFrame.new(0, 5, 0))
								pf:SetAttribute("TAKEN", hit.Parent.Name)
								pf.CollisionGroup = "NoCollide"

								for _, v in hit.Parent:GetDescendants() do
									local s, _ = pcall(function()
										local _ = v.CollisionGroup
									end)
									if s then
										v.CollisionGroup = "OnPlatform"
									end
								end
							end))
							table.insert(platforms, handler)
						end

						-- Wait For All Platforms To Be Taken
						TIMER.Value = GameValues.ROUND_TIMER

						for i = GameValues.ROUND_TIMER, 1, -1 do
							TIMER.Value -= 1
							STATUS.Value = "ROUND IN PROGRESS"

							-- Checking if All Platforms Taken
							local allTaken = false
							for _, pf in platformsFolder:GetChildren() do
								if pf:IsA("Part") and pf:GetAttribute("TAKEN") then
									allTaken = true
								else
									allTaken = false
									break
								end
							end
							if allTaken then
								break
							end
							task.wait(1)
						end

						--- Cleanup
						for _, handler in platforms do
							if handler then
								handler:Destroy()
							end
						end

						-- Raise Lava

						local lavaPart = workspace.World.GameMap.Lava
						local riseDuration = 3

						lavaPart.Transparency = 0
						TweenService:Create(lavaPart, TweenInfo.new(riseDuration), {
							Position = lavaPart.Position + Vector3.new(0, 9 / 2, 0),
							Size = lavaPart.Size + Vector3.new(0, 9, 0),
						}):Play()

						task.wait(riseDuration)

						local playersOnPlatform = {}
						for _, pf in platformsFolder:GetChildren() do
							if pf:IsA("Part") and pf:GetAttribute("TAKEN") then
								table.insert(playersOnPlatform, pf:GetAttribute("TAKEN"))
							end
						end
						for _, player: Player in Players:GetPlayers() do
							if table.find(playersOnPlatform, player.Name) then
							else
								CollectionService:RemoveTag(player.Character, "GameTag")
								if player.Character then
									local hitCharacter = player.Character
									hitCharacter.Humanoid:TakeDamage(math.huge)
								end
							end
						end

						table.clear(platforms)

						task.wait(3)

						lavaPart.Position = lavaPart.Position - Vector3.new(0, 9 / 2, 0)
						lavaPart.Size = lavaPart.Size - Vector3.new(0, 9, 0)
						lavaPart.Transparency = 1

						platformsFolder:ClearAllChildren()

						for _, player: Player in Players:GetPlayers() do
							if player.Character then
								for _, v in player.Character:GetDescendants() do
									local s, _ = pcall(function()
										local _ = v.CollisionGroup
									end)
									if s then
										v.CollisionGroup = "Players"
									end
								end
								local character = player.Character
								character.Humanoid.WalkSpeed = 16
								character.Humanoid.JumpPower = 50
								character.Humanoid.AutoRotate = true
							end
						end

						-- Checking If One Left

						if #CollectionService:GetTagged("GameTag") <= 1 then
							break
						end
					end
					task.wait(1)
				end

				-- Getting Winner
				local winner = CollectionService:GetTagged("GameTag")[1]
				print(winner)

				-- Displaying Winner
				TIMER.Value = GameValues.WINNER_COUNTDOWN
				STATUS.Value = winner.Name .. " wins!"
				for i = GameValues.WINNER_COUNTDOWN, 1, -1 do
					TIMER.Value -= 1
					task.wait(1)
				end

				-- Refreshing Everyone
				for _, player: Player in Players:GetPlayers() do
					if player.Character then
						CollectionService:RemoveTag(player.Character, "GameTag")
						player:LoadCharacterAsync()
					end
				end

				-- Ending Game
				TIMER.Value = GameValues.END_COUNTDOWN
				STATUS.Value = "Game Over"
				for i = GameValues.END_COUNTDOWN, 1, -1 do
					TIMER.Value -= 1
					task.wait(1)
				end

				task.wait(1)
			end
			task.wait(1)
		end
	end)
end

return Service
