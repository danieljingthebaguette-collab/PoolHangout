--!strict
-- Starts the client's controllers.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PhysicsTestAccess = require(ReplicatedStorage.Shared.PhysicsTestAccess)
local Theme = require(ReplicatedStorage.Shared.Theme)

require(script.Parent.TableView).start()
if PhysicsTestAccess.canTest(Players.LocalPlayer) then
	require(script.Parent.PhysicsTestPanel).start()
	-- ponytail: shot controls only work on the test table until Match (Phase 2) tells them which table is yours
	local testTable = workspace:WaitForChild("Tables"):WaitForChild("Table1") :: Model
	require(script.Parent.ShotController).start(testTable, Theme.Ui.PanelWidth + 2 * Theme.Ui.Padding)
end
