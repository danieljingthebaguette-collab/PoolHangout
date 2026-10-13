--!strict
-- Starts the server's services.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
-- Creates every remote before any client looks for them
require(ReplicatedStorage.Shared.Remotes)

if Config.Debug.PhysicsTest and (RunService:IsStudio() or Config.Debug.PhysicsTestLive) then
	require(script.Parent.PhysicsTest).start()
end
