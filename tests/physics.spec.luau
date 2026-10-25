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
	return {
		dirX = dx / length,
		dirY = dy / length,
		power = (speed / PHYSICS.FullPowerSpeed) ^ (1 / PHYSICS.PowerCurve),
	}
end

-- Config with no rolling slowdown, so speeds right after a hit can be checked exactly, plus any other changes.
local function frictionless(changes: { [string]: number }?): Simulate.Params
	local physics = table.clone(PHYSICS) :: any
	physics.RollingSlowdown = 0
	for name, value in changes or {} do
		physics[name] = value
	end
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
		-- Config has no follow, like 8 Ball Duels, so this tests the setting at natural roll
		local follow = 0.29
		local params = frictionless({ Follow = follow })
		local keep = 1 - (1 - follow) * (1 + PHYSICS.BallBounce) / 2
		local speed = PHYSICS.FullPowerSpeed * 0.5 ^ PHYSICS.PowerCurve

		local sim = Simulate.start(
			{ ball(0, layout.headLineX, 0), ball(1, 0, 0) },
			{ dirX = 1, dirY = 0, power = 0.5 },
			params
		)
		local cue, object = sim.balls[1], sim.balls[2]
		stepUntil(sim, function()
			return object.vx ~= 0
		end)
		check.near(cue.vx / speed, keep, 1e-9, "straight hit, cue ball")
		check.near(object.vx / speed, (1 + PHYSICS.BallBounce) / 2, 1e-9, "straight hit, object ball")

		-- With no follow a half-ball hit sends the cue ball off almost square to the object ball; follow bends it forward
		local balls, dirX, dirY = cutShot(30, WIDTH / 4)
		sim = Simulate.start(balls, { dirX = dirX, dirY = dirY, power = 0.5 }, params)
		cue, object = sim.balls[1], sim.balls[2]
		stepUntil(sim, function()
			return object.vx ~= 0
		end)
		check.near(degrees(cue.vx, cue.vy), degrees(keep * dirX, dirY), 0.01, "half-ball hit, cue ball")
	end)

	test("a full straight hit stops the cue ball almost dead", function()
		local sim = Simulate.start(
			{ ball(0, layout.headLineX, 0), ball(1, 0, 0) },
			{ dirX = 1, dirY = 0, power = 1 },
			frictionless()
		)
		local cue, object = sim.balls[1], sim.balls[2]
		stepUntil(sim, function()
			return object.vx ~= 0
		end)
		-- With no follow it keeps only what BallBounce leaves: (1 - 0.94) / 2, 3% of its speed
		check.near(cue.vx / PHYSICS.FullPowerSpeed, (1 - PHYSICS.BallBounce) / 2, 1e-9, "cue ball's share kept")
		check.truthy(cue.vx / PHYSICS.FullPowerSpeed <= 0.05, "almost dead")
	end)

	test("a cut sends the cue ball along the tangent line, with no curve after", function()
		-- Exactly along the tangent with a perfectly elastic hit; Config's BallBounce leaves a small nudge forward
		for _, bounce in { 1, PHYSICS.BallBounce } do
			for _, cut in { 15, 30, 45, 60, 75 } do
				local balls, dirX, dirY = cutShot(cut, WIDTH / 4)
				local sim = Simulate.start(
					balls,
					{ dirX = dirX, dirY = dirY, power = 1 },
					frictionless({ BallBounce = bounce })
				)
				local cue, object = sim.balls[1], sim.balls[2]
				stepUntil(sim, function()
					return object.vx ~= 0
				end)
				-- The object ball leaves along +x, the line of centers; the tangent line is square to it
				local speed = PHYSICS.FullPowerSpeed
				check.near(cue.vy, speed * dirY, 1e-9, `{cut}° cut, bounce {bounce}: along the tangent`)
				check.near(cue.vx, speed * dirX * (1 - bounce) / 2, 1e-9, `{cut}° cut, bounce {bounce}: nudge`)
				-- No curve: still heading the same way a while later
				local heading = degrees(cue.vx, cue.vy)
				Simulate.step(sim, 100)
				if not cue.pocket and cue.vx ~= 0 then
					check.near(degrees(cue.vx, cue.vy), heading, 1e-6, `{cut}° cut: no curve`)
				end
			end
		end
	end)

	test("the break gets BreakPower times a normal shot's full power", function()
		local sim = Simulate.start({ ball(0, 0, 0) }, { dirX = 1, dirY = 0, power = 1, isBreak = true })
		check.near(sim.balls[1].vx, PHYSICS.FullPowerSpeed * PHYSICS.BreakPower, 1e-9, "break")
		check.truthy(sim.balls[1].vx >= 74, "about 75 studs/s, like 8 Ball Duels")
	end)

	test("fast balls can't pass through a ball or a rail", function()
		-- Twice the fastest break the sliders allow
		local top = {}
		for _, slider in Config.Debug.TestSliders do
			top[slider.name] = slider.max
		end
		local fastest = 2 * top.FullPowerSpeed * top.BreakPower
		local params = frictionless({ FullPowerSpeed = fastest, RollingSlowdown = PHYSICS.RollingSlowdown })

		local sim = Simulate.run(
			{ ball(0, layout.headLineX, 0), ball(1, 0, 0) },
			{ dirX = 1, dirY = 0, power = 1 },
			params
		)
		check.equal(sim.events[1].kind, "ball", "the cue ball hits ball 1 first")
		check.equal(sim.events[1].id, 0, "the cue ball hits ball 1 first")

		-- Straight at the long rail, well away from the pockets
		sim = Simulate.run({ ball(0, LENGTH / 4, 0) }, { dirX = 0, dirY = 1, power = 1 }, params)
		check.equal(sim.events[1].kind, "rail", "bounces off the rail")
		for _, b in sim.balls do
			check.truthy(
				math.abs(b.x) <= LENGTH / 2 and math.abs(b.y) <= WIDTH / 2 or b.pocket ~= nil,
				"stays on the table"
			)
		end
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
		local speed = PHYSICS.FullPowerSpeed * 0.5 ^ PHYSICS.PowerCurve * PHYSICS.RailBounce
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

	test("balls already down stay down, and only the balls this shot drops are reported", function()
		local balls = { ball(0, 0, 0), ball(3, -LENGTH / 2, -WIDTH / 2), ball(5, LENGTH / 4, -WIDTH / 4) }
		balls[2].pocket = 1
		local cases = {
			{ name = "a shot that drops the cue ball", shot = shotRolling(0, 1, LENGTH), dropped = { 0 } },
			{ name = "a shot that drops nothing", shot = shotRolling(0, 1, WIDTH / 4), dropped = {} },
		}
		for _, case in cases do
			local sim = Simulate.run(balls, case.shot)
			local dropped = Simulate.dropped(sim)
			check.equal(#dropped, #case.dropped, case.name)
			for i, id in case.dropped do
				check.equal(dropped[i].id, id, case.name)
				check.equal(dropped[i].pocket, 5, case.name)
			end
			local three = sim.balls[2]
			check.equal(three.pocket, 1, `{case.name}: ball 3's pocket`)
			check.equal(three.x, balls[2].x, `{case.name}: ball 3 stays put`)
			check.equal(three.y, balls[2].y, `{case.name}: ball 3 stays put`)
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

	test("over 100 breaks at break power, no ball leaves the table and none end up overlapping", function()
		local apex = layout.rack[1]
		for i = 0, 99 do
			local cueY = (i % 10 / 9 - 0.5) * WIDTH / 2
			local dx, dy = apex.x - layout.headLineX, apex.y - cueY
			local length = math.sqrt(dx * dx + dy * dy)
			local power = 0.4 + 0.6 * (i // 10) / 9
			local shot = { dirX = dx / length, dirY = dy / length, power = power, isBreak = true }
			local sim = Simulate.run(rack(cueY), shot)
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

	test("a shot records each ball hit, rail hit and pocket drop once, in order", function()
		local function events(balls: { Simulate.Ball }, shot: Simulate.Shot, params: Simulate.Params?): string
			local sim = Simulate.run(balls, shot, params)
			local kinds = {}
			for _, event in sim.events do
				check.truthy(event.speed > 0, `{event.kind} {event.id} speed`)
				table.insert(kinds, `{event.kind} {event.id}`)
			end
			return table.concat(kinds, ", ")
		end
		-- Straight into ball 1, which drops in the +y side pocket, and with some follow the cue ball rolls in after it
		local potted =
			events({ ball(0, 0, -WIDTH / 4), ball(1, 0, 0) }, shotRolling(0, 1, WIDTH), frictionless({ Follow = 0.29 }))
		check.equal(potted, "ball 0, pocket 1, pocket 0", "pot")
		-- Just reaches the +y long rail, comes off it and stops
		local banked = events({ ball(0, -LENGTH / 4, 0) }, shotRolling(0, 1, WIDTH / 2 - RADIUS + WIDTH / 8))
		check.equal(banked, "rail 0", "rail")
	end)

	test(
		"a shot records the first ball the cue ball touches, not a ball that ball hits, and nil if it touches none",
		function()
			-- The cue ball hits 5, which runs on into 2
			local balls = { ball(0, -4, 0), ball(2, 0, 0), ball(5, -2, 0) }
			check.equal(Simulate.run(balls, shotRolling(1, 0, LENGTH)).firstHit, 5)
			check.equal(Simulate.run({ ball(0, -4, 0) }, shotRolling(1, 0, 2)).firstHit, nil)
		end
	)

	test("8 Ball Duels' rail-to-rail shot: same timings and stopping spot", function()
		-- Measured from a recording: a ball leaves a long rail straight across at 12.6 studs/s, reaches the far rail
		-- after 0.62 s, comes back to the first rail 1.02 s later, and stops 2.57 s after that, 6.2 studs out
		local physics = table.clone(PHYSICS) :: any
		physics.FullPowerSpeed = 12.6
		local startY = -WIDTH / 2 + RADIUS
		local sim = Simulate.run(
			{ ball(0, LENGTH / 4, startY) },
			{ dirX = 0, dirY = 1, power = 1 },
			{ Table = Config.Table, Physics = physics }
		)
		local rails = {}
		for _, event in sim.events do
			if event.kind == "rail" then
				table.insert(rails, event.time)
			end
		end
		check.equal(#rails, 2, "rail hits")
		local stopped = sim.steps * PHYSICS.TimeStep
		check.near(rails[1], 0.62, 0.02, "reaches the far rail")
		check.near(rails[2] - rails[1], 1.02, 0.03, "back to the first rail")
		check.near(stopped - rails[2], 2.57, 0.05, "then stops")
		check.near(sim.balls[1].y - startY, 6.2, 0.25, "studs out from the rail")
	end)

	test("SpeedDrag: fast balls lose speed quicker, slow rolls barely change", function()
		local drag = 0.05
		local physics = table.clone(PHYSICS) :: any
		physics.SpeedDrag = drag
		for _, speed in { 20, 1 } do
			physics.FullPowerSpeed = speed
			local sim = Simulate.start({ ball(0, 0, 0) }, { dirX = 1, dirY = 0, power = 1 }, {
				Table = Config.Table,
				Physics = physics,
			})
			Simulate.step(sim, 1)
			local lost = (speed - sim.balls[1].vx) / PHYSICS.TimeStep
			check.near(lost, PHYSICS.RollingSlowdown + drag * speed, 1e-6, `slowdown at {speed} studs/s`)
		end
	end)

	test("PowerCurve: half a pull gives half ^ PowerCurve of full speed", function()
		for _, curve in { 1, 2 } do
			local physics = table.clone(PHYSICS)
			physics.PowerCurve = curve
			local sim = Simulate.start({ ball(0, 0, 0) }, { dirX = 1, dirY = 0, power = 0.5 }, {
				Table = Config.Table,
				Physics = physics,
			})
			check.near(sim.balls[1].vx, PHYSICS.FullPowerSpeed * 0.5 ^ curve, 1e-9, `curve {curve}`)
		end
	end)

	test("a full-power break takes under 50 ms to simulate", function()
		local fastest = math.huge
		for _ = 1, 3 do
			local started = os.clock()
			Simulate.run(rack(0), { dirX = 1, dirY = 0, power = 1, isBreak = true })
			fastest = math.min(fastest, os.clock() - started)
		end
		check.truthy(fastest < 0.05, `took {math.round(fastest * 1000)} ms`)
	end)
end
