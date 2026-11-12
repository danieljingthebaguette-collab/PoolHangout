--!strict
-- Starts the server's services.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
-- Creates every remote before any client looks for them
require(ReplicatedStorage.Shared.Remotes)

-- Roblox keeps a leaver's Player and each replaced character in memory, with everything connected to them, unless
-- they're destroyed. Workspace.PlayerCharacterDestroyBehavior would do it, but this Studio doesn't have it yet, so
-- this is Roblox's manual way (performance-optimization/improve.md), after every other handler has run.
Players.PlayerAdded:Connect(function(player: Player)
	player.CharacterRemoving:Connect(function(character: Model)
		task.defer(character.Destroy, character)
	end)
end)
Players.PlayerRemoving:Connect(function(player: Player)
	task.defer(player.Destroy, player)
end)

-- Loads each player's saved record and keeps it saved
require(script.Parent.PlayerData).start()
-- Makes every table's balls, which the test mode then uses
require(script.Parent.TableService).start()
if Config.Debug.PhysicsTest and (RunService:IsStudio() or Config.Debug.PhysicsTestLive) then
	require(script.Parent.PhysicsTest).start()
end
