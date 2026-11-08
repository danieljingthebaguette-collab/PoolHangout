--!strict
-- Rebuilds every greybox table in Workspace.Tables from Config, with src/Server/TableBuilder.luau, which the physics
-- test mode also runs live for its pocket sliders. Makes any table in TABLES that's missing first: a Model with a Felt
-- at its spot and its Mode, which sets its seats. Phase 4's arena builder takes over placing the tables.
--
-- Not synced to Studio. Run it in Studio's command bar in edit mode, or have Claude run it through the MCP's
-- execute_luau. Undo works (Ctrl+Z). Save the place afterwards.

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Copies, so this run gets Config and the builder as they are on disk now, not ones Studio required before an edit
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):Clone()) :: any
local TableBuilder = require(ServerScriptService:WaitForChild("Server"):WaitForChild("TableBuilder"):Clone()) :: any

-- Where each table's felt centre sits, and its Mode. Table1 is the 1v1 table; Table2, beside it on the test floor,
-- the 2v2 one.
local TABLES = {
	{ name = "Table1", mode = "1v1", position = Vector3.new(0, 2.3, -15) },
	{ name = "Table2", mode = "2v2", position = Vector3.new(22, 2.3, -15) },
}

local tables = workspace:WaitForChild("Tables")
local recording = ChangeHistoryService:TryBeginRecording("Rebuild tables")
for _, spec in TABLES do
	local tableModel = tables:FindFirstChild(spec.name) :: Model?
	if not tableModel then
		local model = Instance.new("Model")
		model.Name = spec.name
		local felt = Instance.new("Part")
		felt.Name = "Felt"
		felt.Anchored = true
		-- The builder keeps the felt's top where it is: 0.4 thick like Table1's, so both tops sit at the same height
		felt.Size = Vector3.new(Config.Table.Length, 0.4, Config.Table.Width)
		felt.Position = spec.position
		felt.Parent = model
		model.Parent = tables
		tableModel = model
	end
	local built = tableModel :: Model
	built:SetAttribute("Mode", spec.mode)
	local count = TableBuilder.build(built, Config.Table)
	print(`Rebuilt {spec.name} ({spec.mode}) with {count} parts.`)
end
if recording then
	ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Commit)
end
print("Save the place.")
