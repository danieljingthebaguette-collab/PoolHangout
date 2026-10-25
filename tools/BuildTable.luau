--!strict
-- Rebuilds the greybox Table1 in the place from Config, with src/Server/TableBuilder.luau, which the physics test
-- mode also runs live for its pocket sliders.
--
-- Not synced to Studio. Run it in Studio's command bar in edit mode, or have Claude run it through the MCP's
-- execute_luau. Undo works (Ctrl+Z). Save the place afterwards.

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Copies, so this run gets Config and the builder as they are on disk now, not ones Studio required before an edit
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):Clone()) :: any
local TableBuilder = require(ServerScriptService:WaitForChild("Server"):WaitForChild("TableBuilder"):Clone()) :: any

local tableModel = workspace:WaitForChild("Tables"):WaitForChild("Table1") :: Model
tableModel:WaitForChild("Felt")

local recording = ChangeHistoryService:TryBeginRecording("Rebuild Table1")
local count = TableBuilder.build(tableModel, Config.Table)
if recording then
	ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Commit)
end
print(`Rebuilt Table1 with {count} parts. Save the place.`)
