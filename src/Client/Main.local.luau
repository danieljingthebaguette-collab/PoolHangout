--!strict
-- Starts the client's controllers. The shot controls and HUD follow one table at a time (ActiveTable): the one this
-- player is playing at, else the one they've joined, else the nearest.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PhysicsTestAccess = require(ReplicatedStorage.Shared.PhysicsTestAccess)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local ActiveTable = require(script.Parent.ActiveTable)
local Hud = require(script.Parent.Hud)
local PhysicsTestPanel = require(script.Parent.PhysicsTestPanel)
local ShotController = require(script.Parent.ShotController)
local TableView = require(script.Parent.TableView)

TableView.start()
ActiveTable.start()
local canTest = PhysicsTestAccess.canTest(Players.LocalPlayer)
if canTest then
	PhysicsTestPanel.start()
end

-- The physics test mode only runs on Table1
local function testsHere(tableModel: Model): boolean
	return canTest and tableModel.Name == "Table1"
end

local tableModel = ActiveTable.get()
-- What shows only in the top-down view
local function onView(inView: boolean)
	Hud.showTable(inView)
	if canTest then
		PhysicsTestPanel.show(inView and testsHere(tableModel))
	end
	TableView.showShadows(inView)
end
local controls = ShotController.start(tableModel, testsHere(tableModel), onView)
Hud.start(tableModel)

ActiveTable.onChanged(function(newTable: Model)
	tableModel = newTable
	controls.destroy()
	controls = ShotController.start(newTable, testsHere(newTable), onView)
	Hud.setTable(newTable)
	-- The new table's turn, if a game is on there
	Remotes.ClientReady:FireServer()
end)

-- Everything listens now, so the server can tell this screen about games already on
Remotes.ClientReady:FireServer()
