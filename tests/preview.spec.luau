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
local SOFT = Config.Physics.SoftestShot
local STEP_TRAVEL = (SOFT + (1 - SOFT) * POWER ^ Config.Physics.PowerCurve)
	* Config.Physics.FullPowerSpeed
	* Config.Physics.TimeStep

local function ball(id: number, x: number, y: number): Simulate.Ball
	return { id = id, x = x, y = y, vx = 0, vy = 0 }
end

local function unit(dx: number, dy: number): (number, number)
	local length = math.sqrt(dx * dx + dy * dy)
	return dx / length, dy / length
end

-- Config's physics with no slowdown, so speeds right after a hit compare exactly, plus any changes
local function frictionless(changes: { [string]: number }?): Simulate.Params
	local physics = table.clone(Config.Physics) :: any
	physics.RollingSlowdown = 0
	physics.SpeedDrag = 0
	for name, value in changes or {} do
		physics[name] = value
	end
	return { Table = Config.Table, Physics = physics }
end

-- The object ball at the table's center, and the cue ball coming in `cut` degrees off the line that sends the
-- object ball along +x. 0 is a full hit.
local function cutShot(cut: number): ({ Simulate.Ball }, number, number)
	local dirX, dirY = math.cos(math.rad(cut)), math.sin(math.rad(cut))
	local runUp = WIDTH / 4
	return { ball(0, -2 * RADIUS - dirX * runUp, -dirY * runUp), ball(1, 0, 0) }, dirX, dirY
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
		local contact = Preview.firstContact(balls, dirX, dirY, Config.Table, layout, Config.Physics)
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

	test("after a hit, both balls go where the indicator's lines show, at the speeds they're sized by", function()
		-- Config's own physics, a perfectly elastic hit, and a hit with natural-roll follow
		for _, changes in { {}, { BallBounce = 1 }, { Follow = 0.29 } } do
			local params = frictionless(changes)
			for _, cut in { 0, 15, 30, 45, 60, 75, 85 } do
				local name = `{cut}° cut, BallBounce {params.Physics.BallBounce}, Follow {params.Physics.Follow}`
				local balls, dirX, dirY = cutShot(cut)
				local contact = Preview.firstContact(balls, dirX, dirY, Config.Table, layout, params.Physics)
				local hit = contact.hit :: Preview.Hit
				check.equal(contact.ball, 1, `{name}: which ball`)

				-- The same shot in the simulation, right after the hit
				local sim = Simulate.start(balls, { dirX = dirX, dirY = dirY, power = POWER }, params)
				local cue, object = sim.balls[1], sim.balls[2]
				local speed = math.sqrt(cue.vx * cue.vx + cue.vy * cue.vy)
				repeat
					local done = Simulate.step(sim, 1)
				until done or object.vx ~= 0 or object.vy ~= 0

				local objectSpeed = math.sqrt(object.vx * object.vx + object.vy * object.vy)
				check.near(object.vx / objectSpeed, contact.pushX :: number, 1e-6, `{name}: yellow line x`)
				check.near(object.vy / objectSpeed, contact.pushY :: number, 1e-6, `{name}: yellow line y`)
				check.near(objectSpeed / speed, hit.ballShare, 1e-6, `{name}: yellow line's share`)
				local cueSpeed = math.sqrt(cue.vx * cue.vx + cue.vy * cue.vy)
				check.near(cueSpeed / speed, hit.cueShare, 1e-6, `{name}: white line's share`)
				-- A cue ball stopped dead has no direction to check
				if cueSpeed > 1e-9 then
					check.near(cue.vx / cueSpeed, hit.cueX, 1e-6, `{name}: white line x`)
					check.near(cue.vy / cueSpeed, hit.cueY, 1e-6, `{name}: white line y`)
				end
			end
		end
	end)

	test("a full hit draws a long yellow line and a short white one; a thin cut the opposite", function()
		local full = Preview.hit(1, 0, 1, 0, Config.Physics)
		check.truthy(full.ballShare > 0.9 and full.cueShare < 0.1, "full hit")
		local balls, dirX, dirY = cutShot(80)
		local contact = Preview.firstContact(balls, dirX, dirY, Config.Table, layout, Config.Physics)
		local hit = contact.hit :: Preview.Hit
		check.truthy(hit.cueShare > 0.9 and hit.ballShare < 0.2, "thin cut")
	end)

	test("with BallBounce under 1, the white line drifts just forward of the tangent line", function()
		-- A half-ball hit: the object ball leaves along +x, so the tangent line runs along y and forward is +x
		local half = Preview.hit(math.cos(math.rad(30)), math.sin(math.rad(30)), 1, 0, Config.Physics)
		check.truthy(half.cueX > 0, "forward of the tangent line")
		local drift = math.deg(math.atan2(half.cueX, half.cueY))
		check.truthy(drift > 1 and drift < 5, `drifts {drift}°, a few degrees`)
		local elastic =
			Preview.hit(math.cos(math.rad(30)), math.sin(math.rad(30)), 1, 0, { BallBounce = 1, Follow = 0 })
		check.near(elastic.cueX, 0, 1e-12, "exactly along the tangent line when elastic")
	end)

	test("a rail: the line stops where the cue ball bounces", function()
		-- Shallow enough to meet the long rail past the side pocket
		local dirX, dirY = unit(1, 0.5)
		local balls = { ball(0, -LENGTH / 4, 0) }
		local contact = Preview.firstContact(balls, dirX, dirY, Config.Table, layout, Config.Physics)
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
		local contact = Preview.firstContact(balls, 0, 1, Config.Table, layout, Config.Physics)
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
		-- Straight down the corner's diagonal, a quarter of the table's width out along each rail
		local dirX, dirY = unit(1, 1)
		local balls = { ball(0, corner.x - WIDTH / 4, corner.y - WIDTH / 4) }
		local contact = Preview.firstContact(balls, dirX, dirY, Config.Table, layout, Config.Physics)
		check.equal(contact.kind, "pocket", "kind")

		local _, cue = simulateUntil(balls, dirX, dirY, function(s)
			return s.balls[1].pocket ~= nil
		end)
		check.equal(cue.pocket, 6, "drops in that corner")
		-- Simulate zeroes the speed when it drops, so compare the drop step's position
		check.near(math.sqrt((cue.x - contact.x) ^ 2 + (cue.y - contact.y) ^ 2), 0, 2 * STEP_TRAVEL, "where")
	end)

	test("the pocket a ball points at is the one nearest its path, by angle", function()
		-- Pocket ids: 1–3 along the −y side from the head end, 4–6 along the +y side
		check.equal(Preview.aimedPocket(layout, 0, 0, unit(LENGTH, WIDTH)), 6, "the foot-end corner")
		check.equal(Preview.aimedPocket(layout, 0, 0, 0, 1), 5, "the side pocket")
		check.equal(Preview.aimedPocket(layout, 0, 0, unit(-LENGTH, -WIDTH * 0.9)), 1, "near the head-end corner")
	end)
end
