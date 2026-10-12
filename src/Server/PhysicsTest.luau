--!strict
-- Physics test mode (Studio only, see Config.Debug.PhysicsTest): racks Table1 when a player asks and
-- shoots the cue ball the way they clicked. Any player may do either while the balls are still.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Geometry = require(ReplicatedStorage.Shared.Physics.Geometry)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Simulate = require(ReplicatedStorage.Shared.Physics.Simulate)
local TableSpace = require(ReplicatedStorage.Shared.TableSpace)
local Theme = require(ReplicatedStorage.Shared.Theme)

local PhysicsTest = {}

local function isFinite(value: number): boolean
	return value == value and math.abs(value) ~= math.huge
end

function PhysicsTest.start()
	local tableModel = workspace:WaitForChild("Tables"):WaitForChild("Table1") :: Model
	local felt = tableModel:WaitForChild("Felt") :: BasePart
	local params: Simulate.Params = { Table = Config.Table, Physics = Config.Physics }
	local radius = params.Table.BallRadius
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
		part.Color = Theme.BallColors[id]
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.Parent = folder
		parts[id] = part
	end
	folder.Parent = tableModel

	local function place()
		for _, ball in balls do
			parts[ball.id].CFrame = TableSpace.toWorld(felt, ball.x, ball.y, radius)
			parts[ball.id].Transparency = if ball.pocket then 1 else 0
		end
	end

	local function rack()
		local layout = Geometry.build(params.Table)
		balls = { { id = 0, x = layout.headLineX, y = 0, vx = 0, vy = 0 } }
		for id, spot in layout.rack do
			table.insert(balls, { id = id, x = spot.x, y = spot.y, vx = 0, vy = 0 })
		end
		place()
	end
	rack()

	Remotes.TestRack.OnServerEvent:Connect(function()
		if not rolling then
			rack()
		end
	end)

	Remotes.TestShoot.OnServerEvent:Connect(function(_player: Player, dirX: unknown, dirY: unknown, power: unknown)
		if rolling or typeof(dirX) ~= "number" or typeof(dirY) ~= "number" or typeof(power) ~= "number" then
			return
		end
		local length = math.sqrt(dirX * dirX + dirY * dirY)
		if not (isFinite(length) and length > 0 and power >= 0 and power <= 1) then
			return
		end

		rolling = true
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
		if Config.Debug.LogShots then
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
