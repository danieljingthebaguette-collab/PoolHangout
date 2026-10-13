--!strict
-- The aim indicator's preview must agree with the simulation it previews. Every distance comes from Config.
local Config = require("../src/Shared/Config")
local Geometry = require("../src/Shared/Physics/Geometry")
local Preview = require("../src/Shared/Physics/Preview")
local Simulate = require("../src/Shared/Physics/Simulate")

local LENGTH, WIDTH, RADIUS = Config.Table.Length, Config.Table.Width, Config.Table.BallRadius
local layout = Geometry.build(Config.Table)
local POWER = 0.5
-- The farthest a ball moves in one step at that power: how close a stepped contact can be to an exact one
local STEP_TRAVEL = POWER ^ Config.Physics.PowerCurve * Config.Physics.FullPowerSpeed * Config.Physics.TimeStep

local function ball(id: number, x: number, y: number): Simulate.Ball
	return { id = id, x = x, y = y, vx = 0, vy = 0 }
end

local function unit(dx: number, dy: number): (number, number)
	local length = math.sqrt(dx * dx + dy * dy)
	return dx / length, dy / length
end

-- Steps the shot until `changed` says something happened, and returns the cue ball at that step
local function simulateUntil(
	balls: { Simulate.Ball },
	dirX: number,
	dirY: number,
	changed: (Simulate.Sim) -> boolean
): (Simulate.Sim, Simulate.Ball)
	local sim = Simulate.start(balls, { dirX = dirX, dirY = dirY, power = POWER })
	repeat
		local done = Simulate.step(sim, 1)
	until done or changed(sim)
	return sim, sim.balls[1]
end

return function(test, check)
	test("a cut: the right ball, and it goes the way the target line shows", function()
		-- Ball 2 sits just off the path, and ball 1, behind it, is clipped on its edge first
		local dirX, dirY = unit(1, 0.1)
		local balls = { ball(0, -LENGTH / 4, 0), ball(1, 0, LENGTH / 40 + RADIUS), ball(2, LENGTH / 8, 3 * RADIUS) }
		local contact = Preview.firstContact(balls, dirX, dirY, Config.Table, layout)
		check.equal(contact.kind, "ball", "kind")
		check.equal(contact.ball, 1, "which ball")

		local sim = simulateUntil(balls, dirX, dirY, function(s)
			return s.balls[2].vx ~= 0 or s.balls[3].vx ~= 0
		end)
		local hit = sim.balls[2]
		check.truthy(hit.vx ~= 0 or hit.vy ~= 0, "ball 1 was hit first")
		local speed = math.sqrt(hit.vx * hit.vx + hit.vy * hit.vy)
		check.near(hit.vx / speed, contact.pushX :: number, 1e-6, "push x")
		check.near(hit.vy / speed, contact.pushY :: number, 1e-6, "push y")
		-- The ghost ball touches ball 1 and lies on the cue ball's path
		check.near(
			math.sqrt((contact.x - 0) ^ 2 + (contact.y - (LENGTH / 40 + RADIUS)) ^ 2),
			2 * RADIUS,
			1e-9,
			"touching"
		)
		check.near((contact.y - 0) * dirX - (contact.x + LENGTH / 4) * dirY, 0, 1e-9, "on the path")
	end)

	test("a rail: the line stops where the cue ball bounces", function()
		-- Shallow enough to meet the long rail past the side pocket
		local dirX, dirY = unit(1, 0.5)
		local balls = { ball(0, -LENGTH / 4, 0) }
		local contact = Preview.firstContact(balls, dirX, dirY, Config.Table, layout)
		check.equal(contact.kind, "rail", "kind")
		check.near(contact.y, WIDTH / 2 - RADIUS, 1e-9, "touches the long rail")

		local _, cue = simulateUntil(balls, dirX, dirY, function(s)
			return s.balls[1].vy < 0
		end)
		check.near(cue.x, contact.x, 2 * STEP_TRAVEL, "x")
		check.near(cue.y, contact.y, 2 * STEP_TRAVEL, "y")
	end)

	test("a pocket's jaw: the rail's rounded end stops the line, as in the simulation", function()
		-- Straight at the +y side pocket's jaw, striking its rounded end 5° off center. That's shallow enough to
		-- touch the jaw before the ball's center reaches the pocket's opening.
		local jawX = Config.Table.SidePocketMouth / 2
		local offCenter = math.rad(5)
		local balls = { ball(0, jawX - RADIUS * math.sin(offCenter), 0) }
		local contact = Preview.firstContact(balls, 0, 1, Config.Table, layout)
		check.equal(contact.kind, "rail", "kind")
		check.near(contact.y, WIDTH / 2 - RADIUS * math.cos(offCenter), 1e-9, "touches the jaw's rounded end")

		local _, cue = simulateUntil(balls, 0, 1, function(s)
			return s.balls[1].vx ~= 0 or s.balls[1].pocket ~= nil
		end)
		check.truthy(cue.pocket == nil, "bounced off rather than dropped")
		check.near(cue.y, contact.y, 2 * STEP_TRAVEL, "y")
	end)

	test("a pocket: the line stops where the cue ball drops", function()
		local corner = layout.pockets[6]
		local dirX, dirY = unit(corner.x, corner.y)
		local balls = { ball(0, 0, 0) }
		local contact = Preview.firstContact(balls, dirX, dirY, Config.Table, layout)
		check.equal(contact.kind, "pocket", "kind")

		local _, cue = simulateUntil(balls, dirX, dirY, function(s)
			return s.balls[1].pocket ~= nil
		end)
		check.equal(cue.pocket, 6, "drops in that corner")
		-- Simulate zeroes the speed when it drops, so compare the drop step's position
		check.near(math.sqrt((cue.x - contact.x) ^ 2 + (cue.y - contact.y) ^ 2), 0, 2 * STEP_TRAVEL, "where")
	end)
end
