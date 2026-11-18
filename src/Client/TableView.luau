--!strict
-- Replays each shot on a table's ball parts by stepping the same simulation the server ran, in real time,
-- then snaps them to the server's final positions. Balls spin as they roll, sink into pockets, and click,
-- thud and drop with sound and a small effect (Effects). The shooter's screen starts the shot itself the moment the cue strikes (predict),
-- then switches to the server's copy when it arrives. Each screen draws its own soft shadows under the balls, and an
-- ink edge on each ball's outline, always facing the camera.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Simulate = require(ReplicatedStorage.Shared.Physics.Simulate)
local TableSpace = require(ReplicatedStorage.Shared.TableSpace)
local Theme = require(ReplicatedStorage.Shared.Theme)
local Effects = require(script.Parent.Effects)

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

-- Share of its radius above the felt below which a ball counts as sinking. Just under 1, since a resting ball's
-- height is its radius give or take rounding.
local SINKING = 0.99

local replays: { [Model]: Replay } = {}
-- Tables with a shot from start until the server sends its result: no new shot can start there
local busy: { [Model]: boolean } = {}
-- Each ball part's rotation relative to the felt, so it keeps its spin between replays
local spins: { [BasePart]: CFrame } = {}
local renderConnection: RBXScriptConnection? = nil
-- The settings' sound volume, 0 to 1
local volume = 1
-- Shadows show only in the top-down view; in the normal view Roblox's own shadows are enough. Each shadow's update
-- function, so they can all be redrawn when that changes.
local shadowsShown = false
-- Which way the shadows fall in table space: down and right on screen, so it turns with the top-down view
local shadowTurn = 1
local shadowUpdates: { [BasePart]: () -> () } = {}
-- Each ball's ink edge, by ball part
type Edge = { part: Part, gui: SurfaceGui }
local edges: { [BasePart]: Edge } = {}

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

-- Plays one of Config.Sounds from a part, by its name there, like "RailHit". `share` is how hard, 0 to 1 of a
-- full-power hit.
function TableView.playSound(part: BasePart, name: string, share: number)
	local sound = part:FindFirstChild(name) :: Sound?
	if not sound then
		local newSound = Instance.new("Sound")
		newSound.Name = name
		newSound.SoundId = (Config.Sounds :: any)[name]
		newSound.RollOffMode = Enum.RollOffMode.InverseTapered
		newSound.RollOffMinDistance = Config.Sounds.FullVolumeDistance
		newSound.RollOffMaxDistance = Config.Sounds.SilentDistance
		newSound.Parent = part
		sound = newSound
	end
	local played = sound :: Sound
	-- Square root, because loudness sounds even to the ear that way
	played.Volume = volume * Config.Sounds.Volume * math.sqrt(math.clamp(share, 0, 1))
	played.TimePosition = 0
	played:Play()
end

-- The settings' sound volume for every game sound, 0 to 1
function TableView.setVolume(share: number)
	volume = math.clamp(share, 0, 1)
end

-- Shows the balls' shadows in the top-down view and hides them in the normal view
-- The top-down view is turned round for this player (the felt's +Z side at the top), so the shadows turn with it
function TableView.turnShadows(turned: boolean)
	shadowTurn = if turned then -1 else 1
	for _, update in shadowUpdates do
		update()
	end
end

function TableView.showShadows(visible: boolean)
	shadowsShown = visible
	for _, update in shadowUpdates do
		update()
	end
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

-- Plays the sounds and effects of this frame's new events: only the loudest few, so a break doesn't fire dozens at once
local function playEvents(replay: Replay)
	local events, physics = replay.sim.events, replay.sim.params.Physics
	local sounds: { { part: BasePart, name: string, share: number, kind: string } } = {}
	for i = replay.heard + 1, #events do
		local event = events[i]
		local part = replay.view.parts[event.id]
		if part then
			local share = if event.kind == "pocket" then 1 else event.speed / physics.FullPowerSpeed
			local name = if event.kind == "rail"
				then "RailHit"
				elseif event.kind == "pocket" then "Pocket"
				elseif share < Config.Sounds.LightHitShare then "BallHitLight"
				else "BallHit"
			table.insert(sounds, { part = part, name = name, share = share, kind = event.kind :: string })
		end
	end
	replay.heard = #events
	table.sort(sounds, function(a, b): boolean
		return a.share > b.share
	end)
	for i = 1, math.min(#sounds, Config.Sounds.MaxPerFrame) do
		local sound = sounds[i]
		TableView.playSound(sound.part, sound.name, sound.share)
		Effects.hit(sound.kind, sound.part, replay.view.felt, sound.share)
	end
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

-- Starts a shot on this screen before the server's copy arrives, from the balls as they're shown, with what this
-- screen knows items change about it
function TableView.predict(tableModel: Model, shot: Simulate.Shot, params: Simulate.Params, effects: Simulate.Effects?)
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
	local replay = newReplay(view, Simulate.start(balls, shot, params, effects))
	replay.predicted = { balls = balls, giveUpAt = os.clock() + Config.Shot.PredictTimeoutSeconds }
	play(tableModel, replay)
end

-- A ball's ink edge on this screen: a ring on its outline. It's a flat see-through part, moved with the ball the
-- same way its shadow is and turned to the camera every frame. (A BillboardGui lags a frame behind a moving ball.)
local function addEdge(ball: BasePart, folder: Folder): Edge
	local marks = Theme.BallMarks
	local radius = ball.Size.X / 2
	local part = Instance.new("Part")
	part.Name = ball.Name .. "Edge"
	part.Size = Vector3.new(marks.EdgeDiameter * radius, marks.EdgeDiameter * radius, 0.001)
	part.Transparency = 1
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = marks.GuiPixels / radius
	gui.LightInfluence = marks.EdgeLightInfluence
	local ring = Instance.new("Frame")
	ring.Size = UDim2.fromScale(1, 1)
	ring.BackgroundTransparency = 1
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = ring
	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.Colors.BallInk
	stroke.Thickness = marks.EdgeThickness * marks.GuiPixels
	-- Inside the circle, so the edge doesn't make the ball look bigger
	stroke.BorderStrokePosition = Enum.BorderStrokePosition.Inner
	stroke.Parent = ring
	ring.Parent = gui
	gui.Parent = part
	part.Parent = folder
	local edge = { part = part, gui = gui }
	edges[ball] = edge
	ball.Destroying:Connect(function()
		edges[ball] = nil
		part:Destroy()
	end)
	return edge
end

-- Puts an edge in front of its ball's center, toward the camera
local function placeEdge(ball: BasePart, edge: Edge)
	local camera = workspace.CurrentCamera
	local eye = camera.CFrame.Position
	local center = ball.Position + (eye - ball.Position).Unit * (Theme.BallMarks.EdgeRaise * ball.Size.X / 2)
	-- A part's front is the way it looks, which is where the gui is
	edge.part.CFrame = CFrame.lookAt(center, eye, camera.CFrame.UpVector)
end

-- Every frame, for the camera's moves: turns each edge to the camera
local function drawEdges()
	for ball, edge in edges do
		if edge.gui.Enabled then
			placeEdge(ball, edge)
		end
	end
end

-- A soft shadow on the felt under a ball part, following it wherever it's moved: by a replay here or by the server.
-- It also moves the ball's ink edge with it, and hides it whenever the ball is hidden or sinking.
local function addShadow(felt: BasePart, ball: BasePart, folder: Folder, edge: Edge)
	local radius = ball.Size.X / 2
	local shadow = Instance.new("Part")
	shadow.Name = ball.Name
	shadow.Shape = Enum.PartType.Cylinder
	shadow.Size = Vector3.new(0.01, Theme.BallShadow.Diameter * radius, Theme.BallShadow.Diameter * radius)
	shadow.Color = Theme.Colors.BallShadow
	shadow.Material = Enum.Material.SmoothPlastic
	shadow.Anchored = true
	shadow.CanCollide = false
	shadow.CanTouch = false
	shadow.CanQuery = false
	shadow.CastShadow = false
	local offset = Theme.BallShadow.Offset * radius
	local function follow()
		local x, y = TableSpace.toTable(felt, ball.Position)
		-- Lying flat on the felt. Cylinders run along their X axis.
		local shift = offset * shadowTurn
		shadow.CFrame = TableSpace.toWorld(felt, x + shift, y + shift, 0.005) * CFrame.Angles(0, 0, math.rad(90))
		-- Gone as soon as the ball starts sinking into a pocket, since it's no longer on the felt
		local height = felt.CFrame:PointToObjectSpace(ball.Position).Y - felt.Size.Y / 2
		local sinking = height < radius * SINKING
		local gone = ball.Transparency == 1 or sinking
		edge.gui.Enabled = not gone
		if not gone then
			placeEdge(ball, edge)
		end
		shadow.Transparency = if gone or not shadowsShown then 1 else Theme.BallShadow.Transparency
	end
	shadowUpdates[shadow] = follow
	follow()
	ball:GetPropertyChangedSignal("CFrame"):Connect(follow)
	ball:GetPropertyChangedSignal("Transparency"):Connect(follow)
	ball.Destroying:Connect(function()
		shadowUpdates[shadow] = nil
		shadow:Destroy()
	end)
	shadow.Parent = folder
end

-- Shadows and ink edges for every table's balls, as each table's Balls folder and ball parts arrive
local function watchShadows(tableModel: Instance)
	local felt = tableModel:WaitForChild("Felt") :: BasePart
	local folder = Instance.new("Folder")
	folder.Name = "Shadows"
	folder.Parent = tableModel
	local function watchBalls(balls: Instance)
		if balls.Name ~= "Balls" then
			return
		end
		for _, ball in balls:GetChildren() do
			if ball:IsA("BasePart") then
				addShadow(felt, ball, folder, addEdge(ball, folder))
			end
		end
		balls.ChildAdded:Connect(function(ball: Instance)
			if ball:IsA("BasePart") then
				addShadow(felt, ball, folder, addEdge(ball, folder))
			end
		end)
	end
	for _, child in tableModel:GetChildren() do
		watchBalls(child)
	end
	tableModel.ChildAdded:Connect(watchBalls)
end

function TableView.start()
	task.spawn(function()
		for _, tableModel in workspace:WaitForChild("Tables"):GetChildren() do
			task.spawn(watchShadows, tableModel)
		end
	end)
	-- After the top-down camera's update (Camera + 1), so the edges turn to this frame's camera
	RunService:BindToRenderStep("TableViewEdges", Enum.RenderPriority.Camera.Value + 2, drawEdges)
	Remotes.ShotStarted.OnClientEvent:Connect(
		function(
			tableModel: Model?,
			balls: { Simulate.Ball },
			shot: Simulate.Shot,
			params: Simulate.Params,
			effects: Simulate.Effects?
		)
			local view = findView(tableModel)
			if not (tableModel and view) then
				return
			end
			local sim = Simulate.start(balls, shot, params, effects)
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
