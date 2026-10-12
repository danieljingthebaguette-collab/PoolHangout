--!strict
-- Starts the client's controllers.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)

require(script.Parent.TableView).start()
if Config.Debug.PhysicsTest and RunService:IsStudio() then
	require(script.Parent.PhysicsTestPanel).start()
end
