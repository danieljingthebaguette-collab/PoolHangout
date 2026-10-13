--!strict
-- Physics test mode (see Config.Debug.PhysicsTest and PhysicsTestLive): racks Table1 when a player asks,
-- shoots the cue ball the way they aimed, and keeps the sliders' values. Any player PhysicsTestAccess allows
-- may rack or shoot while the balls are still, and move a slider any time.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Geometry = require(ReplicatedStorage.Shared.Physics.Geometry)
local PhysicsTestAccess = require(ReplicatedStorage.Shared.PhysicsTestAccess)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Simulate = require(ReplicatedStorage.Shared.Physics.Simulate)
local TableSpace = require(ReplicatedStorage.Shared.TableSpace)
local Theme = require(ReplicatedStorage.Shared.Theme)

local PhysicsTest = {}

local function isFinite(value: number): boolean
	return value == value and math.abs(value) ~= math.huge
end

-- Placeholder markings, welded on, so you can see a ball roll. The commissioned balls replace them.
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
			-- A flat dot resting on the top or bottom of the ball. Cylinders run along their X axis.
			local offset = CFrame.new(0, side * (radius + thickness / 2), 0) * CFrame.Angles(0, 0, math.rad(90))
			mark(color, Vector3.new(thickness, diameter, diameter), offset)
		end
	end
end

function PhysicsTest.start()
	local tableModel = workspace:WaitForChild("Tables"):WaitForChild("Table1") :: Model
	local felt = tableModel:WaitForChild("Felt") :: BasePart
	local radius = Config.Table.BallRadius
	local balls: { Simulate.Ball } = {}
	local parts: { [number]: BasePart } = {}
	-- True from a shot's start until its result is sent, so the balls can't be racked or shot mid-roll
	local rolling = false

	local folder = Instance.new("Folder")
	folder.Name = "Balls"
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
		parts[id] = part
	end
	folder.Parent = tableModel

	local function place()
		for _, ball in balls do
			parts[ball.id].CFrame = TableSpace.toWorld(felt, ball.x, ball.y, radius)
			TableSpace.setShown(parts[ball.id], not ball.pocket)
		end
	end

	for _, slider in Config.Debug.TestSliders do
		Remotes.TestTune:SetAttribute(slider.name, (Config :: any)[slider.group][slider.name])
	end

	local function rack()
		local layout = Geometry.build(PhysicsTestAccess.params().Table)
		balls = { { id = 0, x = layout.headLineX, y = 0, vx = 0, vy = 0 } }
		for id, spot in layout.rack do
			table.insert(balls, { id = id, x = spot.x, y = spot.y, vx = 0, vy = 0 })
		end
		place()
	end
	rack()

	Remotes.TestRack.OnServerEvent:Connect(function(player: Player)
		if not rolling and PhysicsTestAccess.canTest(player) then
			rack()
		end
	end)

	Remotes.TestTune.OnServerEvent:Connect(function(player: Player, name: unknown, value: unknown)
		if typeof(value) ~= "number" or not PhysicsTestAccess.canTest(player) then
			return
		end
		for _, slider in Config.Debug.TestSliders do
			-- NaN fails both comparisons
			if slider.name == name and value >= slider.min and value <= slider.max then
				Remotes.TestTune:SetAttribute(slider.name, value)
			end
		end
	end)

	Remotes.TestShoot.OnServerEvent:Connect(function(player: Player, dirX: unknown, dirY: unknown, power: unknown)
		if rolling or typeof(dirX) ~= "number" or typeof(dirY) ~= "number" or typeof(power) ~= "number" then
			return
		end
		if not PhysicsTestAccess.canTest(player) then
			return
		end
		local length = math.sqrt(dirX * dirX + dirY * dirY)
		if not (isFinite(length) and length > 0 and power >= 0 and power <= 1) then
			return
		end

		rolling = true
		local params = PhysicsTestAccess.params()
		local shot: Simulate.Shot = { dirX = dirX / length, dirY = dirY / length, power = power }
		local sim = Simulate.start(balls, shot, params)
		Remotes.ShotStarted:FireAllClients(tableModel, balls, shot, params)
		local startedAt = workspace:GetServerTimeNow()
		while not Simulate.step(sim, Config.Shot.ServerStepsPerFrame) do
			task.wait()
		end
		-- Hold the result until every screen has finished replaying the shot
		local duration = sim.steps * params.Physics.TimeStep
		task.wait(startedAt + duration + Config.Shot.ResolveBufferSeconds - workspace:GetServerTimeNow())

		balls = sim.balls
		if Config.Debug.LogShots and RunService:IsStudio() then
			local sunk = {}
			for _, ball in balls do
				if ball.pocket then
					table.insert(sunk, `{ball.id} in pocket {ball.pocket}`)
				end
			end
			print(
				`[PhysicsTest] shot ({string.format("%.3f, %.3f", shot.dirX, shot.dirY)}) at power`,
				`{string.format("%.2f", power)}: rolled {string.format("%.2f", duration)} s, sunk:`,
				if #sunk > 0 then table.concat(sunk, ", ") else "nothing"
			)
		end
		-- The cue ball sorts first. A sunk one comes back on the head line so testing can go on.
		-- ponytail: no check for a ball already sitting there; press R if one is.
		local cue = balls[1]
		if cue.pocket then
			cue.pocket = nil
			cue.x, cue.y = Geometry.build(params.Table).headLineX, 0
		end
		place()
		Remotes.ShotResolved:FireAllClients(tableModel, balls)
		rolling = false
	end)
end

return PhysicsTest
