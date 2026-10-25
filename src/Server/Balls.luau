--!strict
-- Each table's ball parts and where its balls rest. The server makes the parts and moves them only between shots;
-- during a shot every screen moves them itself. A shot is simulated here a slice per frame, sent to every screen to
-- replay, and returns once they've all had time to play it. Games (Match) and the physics test mode both shoot
-- through here, so a table only ever has one shot rolling.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local EightBall = require(ReplicatedStorage.Shared.Rules.EightBall)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Simulate = require(ReplicatedStorage.Shared.Physics.Simulate)
local TableSpace = require(ReplicatedStorage.Shared.TableSpace)
local Theme = require(ReplicatedStorage.Shared.Theme)

local Balls = {}

local parts: { [Model]: { [number]: BasePart } } = {}
local resting: { [Model]: { Simulate.Ball } } = {}
-- Tables with a shot from its start until its balls are placed at rest again
local rolling: { [Model]: boolean } = {}

-- Placeholder markings, welded on, so you can see a ball roll. Phase 4's final balls replace them.
local function addMarks(ball: Part, id: number)
	local radius = ball.Size.X / 2
	local marks = Theme.BallMarks
	local function mark(color: Color3, size: Vector3, offset: CFrame)
		local part = Instance.new("Part")
		part.Name = "Mark"
		part.Shape = Enum.PartType.Cylinder
		part.Size = size
		part.Color = color
		part.CFrame = ball.CFrame * offset
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.CastShadow = false
		part.Massless = true
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = ball
		weld.Part1 = part
		weld.Parent = part
		part.Parent = ball
	end
	if id >= 9 then
		-- A white ball with a band of color around it
		ball.Color = Theme.Colors.BallMark
		local width, across = marks.BandWidth * radius, marks.BandDiameter * radius
		mark(Theme.BallColors[id], Vector3.new(width, across, across), CFrame.Angles(0, math.rad(90), 0))
	else
		ball.Color = Theme.BallColors[id]
		local color = if id == 0 then Theme.Colors.CueBallMark else Theme.Colors.BallMark
		local thickness, diameter = marks.DotThickness * radius, marks.DotDiameter * radius
		for _, side in { 1, -1 } do
			-- A flat dot on the top or bottom of the ball, its face just above the surface and its edge sunk in.
			-- Cylinders run along their X axis.
			local out = radius * (1 + marks.DotRaise) - thickness / 2
			local offset = CFrame.new(0, side * out, 0) * CFrame.Angles(0, 0, math.rad(90))
			mark(color, Vector3.new(thickness, diameter, diameter), offset)
		end
	end
end

-- Makes the table's 16 ball parts, in a Balls folder. Place them before anyone shoots.
function Balls.create(tableModel: Model)
	local radius = Config.Table.BallRadius
	local folder = Instance.new("Folder")
	folder.Name = "Balls"
	parts[tableModel] = {}
	for id = 0, 15 do
		local part = Instance.new("Part")
		part.Name = `Ball{id}`
		part.Shape = Enum.PartType.Ball
		part.Size = Vector3.one * 2 * radius
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		addMarks(part, id)
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
	if cueX == nil and cueY == nil then
		return true
	end
	local balls = resting[tableModel]
	if
		not ballInHand
		or typeof(cueX) ~= "number"
		or typeof(cueY) ~= "number"
		or not EightBall.canPlaceCue(balls, cueX, cueY, tableParams)
	then
		return false
	end
	local placed: { Simulate.Ball } = {}
	for i, ball in balls do
		placed[i] = if ball.id == 0 then { id = 0, x = cueX, y = cueY, vx = 0, vy = 0 } else ball
	end
	Balls.place(tableModel, placed)
	return true
end

-- Plays a shot from where the balls rest and returns the finished simulation once every screen has replayed it.
-- Yields. The table counts as rolling until the caller places the balls again.
function Balls.shoot(tableModel: Model, shot: Simulate.Shot, params: Simulate.Params): Simulate.Sim
	rolling[tableModel] = true
	local start = resting[tableModel]
	local sim = Simulate.start(start, shot, params)
	Remotes.ShotStarted:FireAllClients(tableModel, start, shot, params)
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
			if #sunk > 0 then table.concat(sunk, ", ") else "nothing"
		)
	end
	return sim
end

return Balls
