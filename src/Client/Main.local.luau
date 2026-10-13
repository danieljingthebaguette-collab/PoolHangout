--!strict
-- Starts the client's controllers.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PhysicsTestAccess = require(ReplicatedStorage.Shared.PhysicsTestAccess)

require(script.Parent.TableView).start()
if PhysicsTestAccess.canTest(Players.LocalPlayer) then
	local Hud = require(script.Parent.Hud)
	local PhysicsTestPanel = require(script.Parent.PhysicsTestPanel)
	PhysicsTestPanel.start()
	-- ponytail: shot controls only work on the test table until Match (Phase 2) tells them which table is yours
	local testTable = workspace:WaitForChild("Tables"):WaitForChild("Table1") :: Model
	-- What shows only in the top-down view
	require(script.Parent.ShotController).start(testTable, function(inView: boolean)
		Hud.showTable(inView)
		PhysicsTestPanel.show(inView)
	end)
	Hud.start(testTable)
end
