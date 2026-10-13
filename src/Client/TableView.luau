--!strict
-- Replays each shot on a table's ball parts by stepping the same simulation the server ran, in real time,
-- then snaps them to the server's final positions. Balls spin as they roll, sink into pockets, and click,
-- thud and drop with sound. The shooter's screen starts the shot itself the moment the cue strikes (predict),
-- then switches to the server's copy when it arrives.

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
	-- Where each ball was last drawn, by id, so only balls that moved get redrawn and spun
	shown: { [number]: { x: number, y: number } },
	-- How many of sim.events have played their sound
	heard: number,
	-- Balls sinking into a pocket, by id: how far through the drop, where it started and the pocket's middle
	drops: { [number]: { t: number, x: number, y: number, pocketX: number, pocketY: number } },
	-- Set while this screen started the shot itself and the server's copy hasn't arrived: the balls to put back,
	-- and when to give up on the server
	predicted: { balls: { Simulate.Ball }, giveUpAt: number }?,
}

local TableView = {}

local replays: { [Model]: Replay } = {}
-- Tables with a shot from start until the server sends its result: no new shot can start there
local busy: { [Model]: boolean } = {}
-- Each ball part's rotation relative to the felt, so it keeps its spin between replays
local spins: { [BasePart]: CFrame } = {}
local renderConnection: RBXScriptConnection? = nil

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

-- Plays a sound from a part. `share` is how hard, 0 to 1 of a full-power hit.
function TableView.playSound(part: BasePart, soundId: string, share: number)
	local sound = part:FindFirstChild(soundId) :: Sound?
	if not sound then
		local newSound = Instance.new("Sound")
		newSound.Name = soundId
		newSound.SoundId = soundId
		newSound.RollOffMode = Enum.RollOffMode.InverseTapered
		newSound.RollOffMinDistance = Config.Sounds.FullVolumeDistance
		newSound.RollOffMaxDistance = Config.Sounds.SilentDistance
		newSound.Parent = part
		sound = newSound
	end
	local played = sound :: Sound
	-- Square root, because loudness sounds even to the ear that way
	played.Volume = Config.Sounds.Volume * math.sqrt(math.clamp(share, 0, 1))
	played.TimePosition = 0
	played:Play()
end

-- Whether a shot is running on this table, from the cue's strike until the server sends the result
function TableView.isBusy(tableModel: Model): boolean
	return busy[tableModel] == true
end

local function place(view: View, part: BasePart, x: number, y: number, height: number)
	part.CFrame = TableSpace.toWorld(view.felt, x, y, height) * (spins[part] or CFrame.identity)
end

local function show(view: View, ball: Simulate.Ball, radius: number)
	local part = view.parts[ball.id]
	if part then
		place(view, part, ball.x, ball.y, radius)
		TableSpace.setShown(part, not ball.pocket)
	end
end

local function playEvents(replay: Replay)
	local events, physics = replay.sim.events, replay.sim.params.Physics
	for i = replay.heard + 1, #events do
		local event = events[i]
		local part = replay.view.parts[event.id]
		if part then
			local share = event.speed / physics.FullPowerSpeed
			local soundId = if event.kind == "rail"
				then Config.Sounds.RailHit
				elseif event.kind == "pocket" then Config.Sounds.Pocket
				elseif share < Config.Sounds.LightHitShare then Config.Sounds.BallHitLight
				else Config.Sounds.BallHit
			TableView.playSound(part, soundId, if event.kind == "pocket" then 1 else share)
		end
	end
	replay.heard = #events
end

-- Draws one frame of a replay. Returns true once it's over and nothing is still sinking.
local function advance(replay: Replay, dt: number): boolean
	local sim, view = replay.sim, replay.view
	local radius = sim.params.Table.BallRadius
	replay.elapsed += dt
	local done = Simulate.step(sim, math.floor(replay.elapsed / sim.params.Physics.TimeStep) - sim.steps)
	playEvents(replay)

	for _, ball in sim.balls do
		local part, shown = view.parts[ball.id], replay.shown[ball.id]
		if not part then
			continue
		end
		if ball.pocket then
			if not replay.drops[ball.id] and part.Transparency ~= 1 then
				local pocket = sim.layout.pockets[ball.pocket]
				replay.drops[ball.id] = { t = 0, x = ball.x, y = ball.y, pocketX = pocket.x, pocketY = pocket.y }
			end
		elseif not shown or ball.x ~= shown.x or ball.y ~= shown.y then
			if shown then
				-- Rolling without slipping: it turns by the distance it moved, around the axis across its path
				local dx, dy = ball.x - shown.x, ball.y - shown.y
				local distance = math.sqrt(dx * dx + dy * dy)
				local turn = CFrame.fromAxisAngle(Vector3.new(dy, 0, -dx).Unit, distance / radius)
				spins[part] = (turn * (spins[part] or CFrame.identity)).Rotation
			end
			replay.shown[ball.id] = { x = ball.x, y = ball.y }
			place(view, part, ball.x, ball.y, radius)
		end
	end

	-- Sinking: slide to the pocket's middle and drop below the felt, faster as it falls, then hide
	local sinking = false
	for id, drop in replay.drops do
		local part = view.parts[id]
		if drop.t >= 1 or not part then
			continue
		end
		drop.t = math.min(drop.t + dt / Config.Shot.DropSeconds, 1)
		local fall = drop.t * drop.t
		place(
			view,
			part,
			drop.x + (drop.pocketX - drop.x) * drop.t,
			drop.y + (drop.pocketY - drop.y) * drop.t,
			radius - fall * Config.Shot.DropDepth * radius
		)
		if drop.t >= 1 then
			TableSpace.setShown(part, false)
		else
			sinking = true
		end
	end
	return done and not sinking
end

local function render(dt: number)
	for tableModel, replay in replays do
		local over = advance(replay, dt)
		local predicted = replay.predicted
		if predicted and os.clock() > predicted.giveUpAt then
			-- The server never started this shot, so it didn't happen: put the balls back
			for _, ball in predicted.balls do
				show(replay.view, ball, replay.sim.params.Table.BallRadius)
			end
			replays[tableModel] = nil
			busy[tableModel] = nil
		elseif over and not predicted then
			replays[tableModel] = nil
		end
	end
	if next(replays) == nil and renderConnection then
		renderConnection:Disconnect()
		renderConnection = nil
	end
end

local function play(tableModel: Model, replay: Replay)
	replays[tableModel] = replay
	busy[tableModel] = true
	if not renderConnection then
		renderConnection = RunService.RenderStepped:Connect(render)
	end
end

local function newReplay(view: View, sim: Simulate.Sim): Replay
	for _, part in view.parts do
		-- Start from the spin the part shows now. After a rack the server's placement has none.
		spins[part] = (view.felt.CFrame:ToObjectSpace(part.CFrame)).Rotation
	end
	return { view = view, sim = sim, elapsed = 0, shown = {}, heard = 0, drops = {}, predicted = nil }
end

-- Starts a shot on this screen before the server's copy arrives, from the balls as they're shown
function TableView.predict(tableModel: Model, shot: Simulate.Shot, params: Simulate.Params)
	local view = findView(tableModel)
	if not view or busy[tableModel] then
		return
	end
	local balls: { Simulate.Ball } = {}
	for id, part in view.parts do
		if part.Transparency ~= 1 then
			local x, y = TableSpace.toTable(view.felt, part.Position)
			table.insert(balls, { id = id, x = x, y = y, vx = 0, vy = 0 })
		end
	end
	local replay = newReplay(view, Simulate.start(balls, shot, params))
	replay.predicted = { balls = balls, giveUpAt = os.clock() + Config.Shot.PredictTimeoutSeconds }
	play(tableModel, replay)
end

function TableView.start()
	Remotes.ShotStarted.OnClientEvent:Connect(
		function(tableModel: Model?, balls: { Simulate.Ball }, shot: Simulate.Shot, params: Simulate.Params)
			local view = findView(tableModel)
			if not (tableModel and view) then
				return
			end
			local sim = Simulate.start(balls, shot, params)
			local current = replays[tableModel]
			if current and current.predicted then
				-- Switch to the server's exact numbers at the same moment, so the rest of the shot matches it.
				-- The server's copy is already a little way in, so its sounds up to now have played.
				Simulate.step(sim, math.floor(current.elapsed / params.Physics.TimeStep))
				current.sim = sim
				current.heard = #sim.events
				current.predicted = nil
			else
				play(tableModel, newReplay(view, sim))
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
		busy[tableModel] = nil
		for _, ball in balls do
			show(view, ball, Config.Table.BallRadius)
		end
	end)
end

return TableView
