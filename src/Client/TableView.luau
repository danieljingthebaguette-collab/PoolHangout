--!strict
-- Replays each shot on a table's ball parts by stepping the same simulation the server ran, in real time,
-- then snaps them to the server's final positions.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Simulate = require(ReplicatedStorage.Shared.Physics.Simulate)
local TableSpace = require(ReplicatedStorage.Shared.TableSpace)

type View = { felt: BasePart, parts: { [number]: BasePart } }
type Replay = {
	view: View,
	sim: Simulate.Sim,
	elapsed: number,
	-- Where each ball was last drawn, by its index in sim.balls, so only balls that moved get redrawn
	shown: { { x: number, y: number } },
}

local TableView = {}

-- The table's felt and ball parts, or nil while the table hasn't streamed in
local function findView(tableModel: Model?): View?
	local felt = tableModel and tableModel:FindFirstChild("Felt")
	local folder = tableModel and tableModel:FindFirstChild("Balls")
	if not (felt and felt:IsA("BasePart") and folder) then
		return nil
	end
	local parts: { [number]: BasePart } = {}
	for _, part in folder:GetChildren() do
		local id = tonumber(string.match(part.Name, "^Ball(%d+)$"))
		if id and part:IsA("BasePart") then
			parts[id] = part
		end
	end
	return { felt = felt, parts = parts }
end

local function show(view: View, ball: Simulate.Ball, radius: number)
	local part = view.parts[ball.id]
	if part then
		part.CFrame = TableSpace.toWorld(view.felt, ball.x, ball.y, radius)
		part.Transparency = if ball.pocket then 1 else 0
	end
end

function TableView.start()
	local replays: { [Model]: Replay } = {}
	local renderConnection: RBXScriptConnection? = nil

	local function render(dt: number)
		for tableModel, replay in replays do
			local sim = replay.sim
			replay.elapsed += dt
			local done = Simulate.step(sim, math.floor(replay.elapsed / sim.params.Physics.TimeStep) - sim.steps)
			for i, ball in sim.balls do
				local shown = replay.shown[i]
				if ball.x ~= shown.x or ball.y ~= shown.y then
					shown.x, shown.y = ball.x, ball.y
					show(replay.view, ball, sim.params.Table.BallRadius)
				end
			end
			if done then
				replays[tableModel] = nil
			end
		end
		if next(replays) == nil and renderConnection then
			renderConnection:Disconnect()
			renderConnection = nil
		end
	end

	Remotes.ShotStarted.OnClientEvent:Connect(
		function(tableModel: Model?, balls: { Simulate.Ball }, shot: Simulate.Shot, params: Simulate.Params)
			local view = findView(tableModel)
			if not (tableModel and view) then
				return
			end
			local sim = Simulate.start(balls, shot, params)
			local shown = {}
			for i, ball in sim.balls do
				shown[i] = { x = ball.x, y = ball.y }
			end
			replays[tableModel] = { view = view, sim = sim, elapsed = 0, shown = shown }
			if not renderConnection then
				renderConnection = RunService.RenderStepped:Connect(render)
			end
		end
	)

	Remotes.ShotResolved.OnClientEvent:Connect(function(tableModel: Model?, balls: { Simulate.Ball })
		local view = findView(tableModel)
		if not (tableModel and view) then
			return
		end
		-- Normally the replay has already finished. If this screen fell behind, stop it here.
		replays[tableModel] = nil
		for _, ball in balls do
			show(view, ball, Config.Table.BallRadius)
		end
	end)
end

return TableView
