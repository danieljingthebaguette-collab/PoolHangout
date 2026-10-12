--!strict
-- Every distance and speed here comes from Config, so these still hold if the table is scaled up.
local Config = require("../src/Shared/Config")
local Geometry = require("../src/Shared/Physics/Geometry")
local Simulate = require("../src/Shared/Physics/Simulate")

local LENGTH, WIDTH, RADIUS = Config.Table.Length, Config.Table.Width, Config.Table.BallRadius
local PHYSICS = Config.Physics
local layout = Geometry.build(Config.Table)
-- Where the long rails stop beside the foot-end corner pockets
local CORNER_RAIL_END_X = LENGTH / 2 - Config.Table.CornerPocketMouth / math.sqrt(2)

local function ball(id: number, x: number, y: number): Simulate.Ball
	return { id = id, x = x, y = y, vx = 0, vy = 0 }
end

-- The cue ball on the head line, plus a full rack.
local function rack(cueY: number): { Simulate.Ball }
	local balls = { ball(0, layout.headLineX, cueY) }
	for id, spot in layout.rack do
		table.insert(balls, ball(id, spot.x, spot.y))
	end
	return balls
end

-- A shot toward (dx, dy) that would roll `distance` before stopping, if nothing got in the way.
local function shotRolling(dx: number, dy: number, distance: number): Simulate.Shot
	local length = math.sqrt(dx * dx + dy * dy)
	local speed = math.sqrt(2 * PHYSICS.RollingSlowdown * distance)
	return { dirX = dx / length, dirY = dy / length, power = speed / PHYSICS.FullPowerSpeed }
end

-- Config with no rolling slowdown, so speeds right after a hit can be checked exactly.
local function frictionless(): Simulate.Params
	local physics = table.clone(PHYSICS)
	physics.RollingSlowdown = 0
	return { Table = Config.Table, Physics = physics }
end

local function stepUntil(sim: Simulate.Sim, condition: () -> boolean)
	repeat
		local done = Simulate.step(sim, 1)
	until done or condition()
end

local function degrees(x: number, y: number): number
	return math.deg(math.atan2(y, x))
end

-- Starting balls for a cut: the object ball at the center, the cue ball `runUp` back from the ghost ball,
-- coming in `cut` degrees off the line that sends the object ball along +x.
local function cutShot(cut: number, runUp: number): ({ Simulate.Ball }, number, number)
	local dirX, dirY = math.cos(math.rad(cut)), math.sin(math.rad(cut))
	return { ball(0, -2 * RADIUS - dirX * runUp, -dirY * runUp), ball(1, 0, 0) }, dirX, dirY
end

return function(test, check)
	test("a ball rolls straight and stops where the rolling slowdown says", function()
		local sim = Simulate.run({ ball(0, layout.headLineX, 0) }, shotRolling(1, 0, LENGTH / 2))
		check.near(sim.balls[1].x, layout.headLineX + LENGTH / 2, RADIUS / 10, "x")
		check.equal(sim.balls[1].y, 0, "y")
	end)

	test("a cut shot sends the object ball along the line of centers, even at full power", function()
		for _, cut in { 15, 30, 45, 60, 75 } do
			local balls, dirX, dirY = cutShot(cut, WIDTH / 4)
			local sim = Simulate.start(balls, { dirX = dirX, dirY = dirY, power = 1 })
			local object = sim.balls[2]
			stepUntil(sim, function()
				return object.vx ~= 0
			end)
			check.near(degrees(object.vx, object.vy), 0, 0.01, `{cut}° cut`)
		end
	end)

	test("Follow: a ball rolling into another keeps some of its forward roll", function()
		local keep = 1 - (1 - PHYSICS.Follow) * (1 + PHYSICS.BallBounce) / 2
		local speed = PHYSICS.FullPowerSpeed / 2

		local sim = Simulate.start(
			{ ball(0, layout.headLineX, 0), ball(1, 0, 0) },
			{ dirX = 1, dirY = 0, power = 0.5 },
			frictionless()
		)
		local cue, object = sim.balls[1], sim.balls[2]
		stepUntil(sim, function()
			return object.vx ~= 0
		end)
		check.near(cue.vx / speed, keep, 1e-9, "straight hit, cue ball")
		check.near(object.vx / speed, (1 + PHYSICS.BallBounce) / 2, 1e-9, "straight hit, object ball")

		-- With no follow a half-ball hit sends the cue ball off almost square to the object ball; follow bends it forward
		local balls, dirX, dirY = cutShot(30, WIDTH / 4)
		sim = Simulate.start(balls, { dirX = dirX, dirY = dirY, power = 0.5 }, frictionless())
		cue, object = sim.balls[1], sim.balls[2]
		stepUntil(sim, function()
			return object.vx ~= 0
		end)
		check.near(degrees(cue.vx, cue.vy), degrees(keep * dirX, dirY), 0.01, "half-ball hit, cue ball")
	end)

	test("a rail bounce mirrors the angle and keeps RailBounce of the speed", function()
		-- 45° into the +y long rail, touching it at x = LENGTH / 4
		local touchY = WIDTH / 2 - RADIUS
		local diagonal = math.sqrt(0.5)
		local sim = Simulate.start(
			{ ball(0, LENGTH / 4 - touchY, 0) },
			{ dirX = diagonal, dirY = diagonal, power = 0.5 },
			frictionless()
		)
		local cue = sim.balls[1]
		stepUntil(sim, function()
			return cue.vy < 0
		end)
		local speed = PHYSICS.FullPowerSpeed / 2 * PHYSICS.RailBounce
		check.near(cue.vx, speed * diagonal, 1e-9, "vx")
		check.near(cue.vy, -speed * diagonal, 1e-9, "vy")
		-- Bouncing from the exact point it touched the rail puts it on the mirrored path
		check.near(cue.x + cue.y, LENGTH / 4 + touchY, 1e-9, "path")
	end)

	test("balls drop into the side and corner pockets", function()
		local cases = {
			{ name = "straight into a side pocket", x = 0, y = 0, dx = 0, dy = 1, pocket = 5 },
			{ name = "straight into a corner pocket", x = LENGTH / 2 - WIDTH / 2, y = 0, dx = 1, dy = 1, pocket = 6 },
			{
				name = "along the rail into a corner",
				x = LENGTH / 4,
				y = WIDTH / 2 - RADIUS,
				dx = 1,
				dy = 0,
				pocket = 6,
			},
			{
				-- Its center reaches the cushion line just past the rail's end, where there's no rail to bounce off
				name = "just past the end of a rail into a corner",
				x = CORNER_RAIL_END_X + RADIUS / 2 - WIDTH / 4,
				y = WIDTH / 2 - RADIUS - WIDTH / 4,
				dx = 1,
				dy = 1,
				pocket = 6,
			},
		}
		for _, case in cases do
			local sim = Simulate.run({ ball(0, case.x, case.y) }, shotRolling(case.dx, case.dy, LENGTH))
			check.equal(sim.balls[1].pocket, case.pocket, case.name)
		end
	end)

	test("a ball that clips the very end of a rail at a pocket stays on the table", function()
		-- Straight at the +y long rail just past its corner end, so it hits the pocket's jaw
		local sim = Simulate.run({ ball(0, CORNER_RAIL_END_X + RADIUS / 10, 0) }, shotRolling(0, 1, WIDTH * 3 / 4))
		check.equal(sim.balls[1].pocket, nil, "pocket")
		check.truthy(sim.balls[1].y < WIDTH / 2 - RADIUS, "bounced back onto the table")
	end)

	test("rack balls sit two radii plus RackGap apart", function()
		local tableParams = table.clone(Config.Table)
		tableParams.RackGap = RADIUS / 10
		local spots = Geometry.build(tableParams).rack
		-- The apex, the two balls behind it, and the pair next to each other in that row
		for _, pair in { { 1, 2 }, { 1, 3 }, { 2, 3 } } do
			local a, b = spots[pair[1]], spots[pair[2]]
			local distance = math.sqrt((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2)
			check.near(distance, 2 * RADIUS + tableParams.RackGap, 1e-9, `balls {pair[1]} and {pair[2]}`)
		end
		check.equal(spots[1].x, LENGTH / 4, "apex on the foot spot")
	end)

	test("over 100 breaks, no ball leaves the table and none end up overlapping", function()
		local apex = layout.rack[1]
		for i = 0, 99 do
			local cueY = (i % 10 / 9 - 0.5) * WIDTH / 2
			local dx, dy = apex.x - layout.headLineX, apex.y - cueY
			local length = math.sqrt(dx * dx + dy * dy)
			local power = 0.4 + 0.6 * (i // 10) / 9
			local sim = Simulate.run(rack(cueY), { dirX = dx / length, dirY = dy / length, power = power })
			for j, a in sim.balls do
				if a.pocket then
					continue
				end
				check.truthy(
					math.abs(a.x) <= LENGTH / 2 and math.abs(a.y) <= WIDTH / 2,
					`break {i}: ball {a.id} off the table`
				)
				for k = j + 1, #sim.balls do
					local b = sim.balls[k]
					if b.pocket == nil then
						local distance = math.sqrt((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2)
						check.truthy(distance > 2 * RADIUS * 0.999, `break {i}: balls {a.id} and {b.id} overlap`)
					end
				end
			end
		end
	end)

	test("stepping a shot in slices matches running it at once, and the starting balls stay put", function()
		local start = rack(0)
		local shot = { dirX = 1, dirY = 0, power = 1 }
		local whole = Simulate.run(start, shot)
		local sliced = Simulate.start(start, shot)
		repeat
			local done = Simulate.step(sliced, 7)
		until done
		check.equal(sliced.steps, whole.steps, "steps")
		for i, b in whole.balls do
			check.equal(sliced.balls[i].x, b.x, `ball {b.id} x`)
			check.equal(sliced.balls[i].y, b.y, `ball {b.id} y`)
			check.equal(sliced.balls[i].pocket, b.pocket, `ball {b.id} pocket`)
		end
		check.equal(start[1].x, layout.headLineX, "starting cue ball x")
		check.equal(start[1].vx, 0, "starting cue ball vx")
	end)

	test("a full-power break takes under 50 ms to simulate", function()
		local fastest = math.huge
		for _ = 1, 3 do
			local started = os.clock()
			Simulate.run(rack(0), { dirX = 1, dirY = 0, power = 1 })
			fastest = math.min(fastest, os.clock() - started)
		end
		check.truthy(fastest < 0.05, `took {math.round(fastest * 1000)} ms`)
	end)
end
