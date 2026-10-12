--!strict
-- Starts the client's controllers.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Theme = require(ReplicatedStorage.Shared.Theme)

require(script.Parent.TableView).start()
if Config.Debug.PhysicsTest and RunService:IsStudio() then
	require(script.Parent.PhysicsTestPanel).start()
	-- ponytail: shot controls only work on the test table until Match (Phase 2) tells them which table is yours
	local testTable = workspace:WaitForChild("Tables"):WaitForChild("Table1") :: Model
	require(script.Parent.ShotController).start(testTable, Theme.Ui.PanelWidth + 2 * Theme.Ui.Padding)
end
