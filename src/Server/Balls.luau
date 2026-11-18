--!strict
-- Each table's ball parts and where its balls rest. The server makes the parts and moves them only between shots;
-- during a shot every screen moves them itself. A shot is simulated here a slice per frame, sent to every screen to
-- replay, and returns once they've all had time to play it. Games (Match) and the physics test mode both shoot
-- through here, so a table only ever has one shot rolling.

local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Simulate = require(ReplicatedStorage.Shared.Physics.Simulate)
local TableFlow = require(ReplicatedStorage.Shared.Rules.TableFlow)
local TableSpace = require(ReplicatedStorage.Shared.TableSpace)
local Theme = require(ReplicatedStorage.Shared.Theme)

local Balls = {}

local parts: { [Model]: { [number]: BasePart } } = {}
local resting: { [Model]: { Simulate.Ball } } = {}
-- Tables with a shot from its start until its balls are placed at rest again
local rolling: { [Model]: boolean } = {}

-- The balls' sphere mesh (Theme.BallMesh), made by the first Balls.create; each ball is a copy. False once it has
-- failed to load, so balls are plain sphere parts instead.
local sphere: MeshPart | false | nil = nil
local random = Random.new()

local function loadSphere(): MeshPart | false
	local ok, result = pcall(function(): MeshPart
		return AssetService:CreateMeshPartAsync(Content.fromUri(Theme.BallMesh), {
			CollisionFidelity = Enum.CollisionFidelity.Box,
			RenderFidelity = Enum.RenderFidelity.Automatic,
		})
	end)
	if not ok then
		warn(`[Balls] the ball mesh didn't load, so balls are plain spheres: {result}`)
		return false
	end
	return result
end

-- One ball: a copy of the sphere mesh wearing the ball's texture, its paint, numbers and dots in one picture. Under
-- the texture it keeps the ball's main color (a stripe's band color), which shows while the texture loads.
local function newBall(id: number): BasePart
	if sphere == nil then
		sphere = loadSphere()
	end
	local part: BasePart
	if sphere then
		local copy = sphere:Clone()
		copy.TextureID = Theme.BallTextures[id]
		part = copy
	else
		local plain = Instance.new("Part")
		plain.Shape = Enum.PartType.Ball
		part = plain
	end
	part.Name = `Ball{id}`
	part.Size = Vector3.one * 2 * Config.Table.BallRadius
	part.Color = Theme.BallColors[id]
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	return part
end

-- Makes the table's 16 ball parts, in a Balls folder. Place them before anyone shoots. The first call yields while
-- the ball mesh loads.
function Balls.create(tableModel: Model)
	local folder = Instance.new("Folder")
	folder.Name = "Balls"
	parts[tableModel] = {}
	for id = 0, 15 do
		local part = newBall(id)
		part.Parent = folder
		parts[tableModel][id] = part
	end
	folder.Parent = tableModel
end

-- The balls as they rest now. Don't change them; place a new list instead.
function Balls.get(tableModel: Model): { Simulate.Ball }
	return resting[tableModel]
end

function Balls.isRolling(tableModel: Model): boolean
	return rolling[tableModel] == true
end

-- Puts the balls at rest at these spots, hiding the pocketed ones. This ends the shot that was rolling, if any.
function Balls.place(tableModel: Model, balls: { Simulate.Ball })
	resting[tableModel] = balls
	rolling[tableModel] = nil
	local felt = tableModel:FindFirstChild("Felt") :: BasePart
	for _, ball in balls do
		local part = parts[tableModel][ball.id]
		part.CFrame = TableSpace.toWorld(felt, ball.x, ball.y, Config.Table.BallRadius)
		TableSpace.setShown(part, not ball.pocket)
	end
end

-- Puts a fresh rack on the table, like Balls.place, with each numbered ball turned so one of its numbers faces
-- straight up, spun at random around the vertical, so the rack shows its numbers before the break. Only the parts
-- turn: the physics never sees a ball's turn.
function Balls.rack(tableModel: Model, balls: { Simulate.Ball })
	Balls.place(tableModel, balls)
	for _, ball in balls do
		if ball.id ~= 0 then
			local part = parts[tableModel][ball.id]
			-- The number circles sit on the ball's X axis, which a quarter turn round Z points up
			part.CFrame *= CFrame.Angles(0, random:NextNumber(0, 2 * math.pi), 0) * CFrame.Angles(0, 0, math.pi / 2)
		end
	end
end

-- Puts the cue ball where a client placed it, the one position the server takes from a client. False, changing
-- nothing, unless the shooter has ball in hand and it's a pair of numbers the rules allow. No spot (nil, nil) leaves
-- it where it is, which is the only choice without ball in hand, like on the break.
function Balls.placeCue(
	tableModel: Model,
	ballInHand: boolean,
	cueX: unknown,
	cueY: unknown,
	tableParams: typeof(Config.Table)
): boolean
	local balls = resting[tableModel]
	if not TableFlow.cueSpotAllowed(ballInHand, cueX, cueY, balls, tableParams) then
		return false
	elseif cueX == nil or cueY == nil then
		return true
	end
	local placed: { Simulate.Ball } = {}
	for i, ball in balls do
		placed[i] = if ball.id == 0 then { id = 0, x = cueX :: number, y = cueY :: number, vx = 0, vy = 0 } else ball
	end
	Balls.place(tableModel, placed)
	return true
end

-- Plays a shot from where the balls rest, with what any items change about it, and returns the finished simulation
-- once every screen has replayed it. Yields. The table counts as rolling until the caller places the balls again.
function Balls.shoot(
	tableModel: Model,
	shot: Simulate.Shot,
	params: Simulate.Params,
	effects: Simulate.Effects?
): Simulate.Sim
	rolling[tableModel] = true
	local start = resting[tableModel]
	-- The cue ball's speed is worked out once, here, and goes with the shot, so every screen starts it at exactly
	-- this speed
	local sent = table.clone(shot)
	sent.speed = Simulate.speed(shot, params)
	local sim = Simulate.start(start, sent, params, effects)
	Remotes.ShotStarted:FireAllClients(tableModel, start, sent, params, effects or {})
	local startedAt = workspace:GetServerTimeNow()
	while not Simulate.step(sim, Config.Shot.ServerStepsPerFrame) do
		task.wait()
	end
	-- Hold the result until every screen has finished replaying the shot
	local duration = sim.steps * params.Physics.TimeStep
	task.wait(startedAt + duration + Config.Shot.ResolveBufferSeconds - workspace:GetServerTimeNow())

	if Config.Debug.LogShots and RunService:IsStudio() then
		local sunk = {}
		for _, drop in Simulate.dropped(sim) do
			table.insert(sunk, `{drop.id} in pocket {drop.pocket}`)
		end
		print(
			`[{tableModel.Name}] {if shot.isBreak then "break" else "shot"} ({string.format(
				"%.3f, %.3f",
				shot.dirX,
				shot.dirY
			)}) at power`,
			`{string.format("%.2f", shot.power)}: rolled {string.format("%.2f", duration)} s,`,
			`hit {sim.firstHit or "nothing"} first, sunk:`,
			if #sunk > 0 then table.concat(sunk, ", ") else "nothing",
			if sim.blast then `(blast round {sim.blast.id})` else ""
		)
	end
	return sim
end

return Balls
