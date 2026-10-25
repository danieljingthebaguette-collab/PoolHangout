--!strict
-- Starts the client's controllers.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PhysicsTestAccess = require(ReplicatedStorage.Shared.PhysicsTestAccess)
local Hud = require(script.Parent.Hud)
local PhysicsTestPanel = require(script.Parent.PhysicsTestPanel)
local TableView = require(script.Parent.TableView)

TableView.start()
local testMode = PhysicsTestAccess.canTest(Players.LocalPlayer)
if testMode then
	PhysicsTestPanel.start()
end
-- ponytail: the shot controls know only Table1 until Phase 3 builds all 8 and TurnStarted picks yours
local tableModel = workspace:WaitForChild("Tables"):WaitForChild("Table1") :: Model
-- What shows only in the top-down view
require(script.Parent.ShotController).start(tableModel, testMode, function(inView: boolean)
	Hud.showTable(inView)
	if testMode then
		PhysicsTestPanel.show(inView)
	end
	TableView.showShadows(inView)
end)
Hud.start(tableModel)
