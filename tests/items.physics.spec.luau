--!strict
-- What items change about how balls move: Power Shot's speed past full power, and Blast Ball. Every distance and
-- speed comes from Config.
local Config = require("../src/Shared/Config")
local Geometry = require("../src/Shared/Physics/Geometry")
local Preview = require("../src/Shared/Physics/Preview")
local Simulate = require("../src/Shared/Physics/Simulate")

local R = Config.Table.BallRadius
local FULL_SPEED = Config.Physics.FullPowerSpeed
local REACH = Config.Items.BlastReach * R
local STRONGEST = Config.Items.BlastPush * FULL_SPEED

local function ball(id: number, x: number, y: number): Simulate.Ball
	return { id = id, x = x, y = y, vx = 0, vy = 0 }
end

-- The cue ball heads straight at the 1 in the middle of the table. Around the 1: the 2 touching it, the 4 halfway
-- out to the blast's edge, and the 3 just past the edge. None of them is in the cue ball's way.
local function setup(): { Simulate.Ball }
	return {
		ball(0, -3, 0),
		ball(1, 0, 0),
		ball(2, 0, 2 * R + 0.001),
		ball(3, 0, -(REACH + 0.05)),
		ball(4, -0.001, -(2 * R + REACH) / 2),
	}
end
local SHOT: Simulate.Shot = { dirX = 1, dirY = 0, power = 0.3 }

local function find(sim: Simulate.Sim, id: number): Simulate.Ball
	for _, b in sim.balls do
		if b.id == id then
			return b
		end
	end
	error(`no ball {id}`)
end

-- Steps a shot until the cue ball's first hit, one step at a time
local function untilFirstHit(sim: Simulate.Sim)
	while not sim.firstHit and not Simulate.step(sim, 1) do
	end
end

local function speed(b: Simulate.Ball): number
	return math.sqrt(b.vx * b.vx + b.vy * b.vy)
end

return function(test, check)
	test("past full power, with Power Shot, the cue ball leaves at that many times full-power speed", function()
		local top = Config.Items.PowerShotMax
		for _, power in { 1, 1.25, top } do
			local sim = Simulate.start({ ball(0, 0, 0) }, { dirX = 1, dirY = 0, power = power })
			check.near(find(sim, 0).vx, power * FULL_SPEED, 1e-9, `power {power}`)
		end
	end)

	test(
		"a blast pushes balls near the hit ball straight away from it, hardest touching, fading out at its edge",
		function()
			local sim = Simulate.start(setup(), SHOT, nil, { blast = true })
			untilFirstHit(sim)
			check.equal(sim.firstHit, 1)
			check.equal(sim.blast and sim.blast.id, 1, "it went off round the hit ball")
			local touching, halfway, past = find(sim, 2), find(sim, 4), find(sim, 3)
			check.near(speed(touching), STRONGEST, STRONGEST * 0.01, "touching: the full push")
			-- The hit ball has moved a hair by the instant of the blast, under a degree here
			check.near(touching.vx / speed(touching), 0, 0.03, "straight away from the hit ball")
			check.truthy(touching.vy > 0)
			check.near(speed(halfway), STRONGEST / 2, STRONGEST * 0.01, "halfway out: half")
			check.truthy(halfway.vy < 0, "away from the hit ball")
			check.equal(speed(past), 0, "past the edge: nothing")
		end
	)

	test("the blast never pushes the cue ball or the hit ball", function()
		local blasted = Simulate.start(setup(), SHOT, nil, { blast = true })
		local plain = Simulate.start(setup(), SHOT)
		untilFirstHit(blasted)
		untilFirstHit(plain)
		for _, id in { 0, 1 } do
			check.equal(find(blasted, id).vx, find(plain, id).vx, `ball {id}`)
			check.equal(find(blasted, id).vy, find(plain, id).vy, `ball {id}`)
		end
	end)

	test("without Blast Ball nothing near the hit ball moves", function()
		local sim = Simulate.run(setup(), SHOT)
		check.equal(sim.blast, nil)
		for _, id in { 2, 3, 4 } do
			local start = setup()[id + 1]
			check.equal(find(sim, id).x, start.x, `ball {id}`)
			check.equal(find(sim, id).y, start.y, `ball {id}`)
		end
	end)

	test("a cue ball that hits nothing sets off no blast", function()
		local balls = setup()
		balls[1] = ball(0, -3, 3) -- along y = 3, clear of every ball
		local sim = Simulate.run(balls, SHOT, nil, { blast = true })
		check.equal(sim.firstHit, nil)
		check.equal(sim.blast, nil)
		check.equal(find(sim, 2).y, balls[3].y, "the 2 stays put")
	end)

	test("a blast shot comes out the same every time", function()
		local a = Simulate.run(setup(), SHOT, nil, { blast = true })
		local b = Simulate.run(setup(), SHOT, nil, { blast = true })
		for i, first in a.balls do
			check.equal(first.x, b.balls[i].x)
			check.equal(first.y, b.balls[i].y)
			check.equal(first.pocket, b.balls[i].pocket)
		end
	end)

	-- Frozen balls, pocket lids and oil

	test(
		"a ball rolling into a frozen ball bounces straight back off it like a rail, and the frozen ball stays put",
		function()
			local balls = { ball(0, -3, 0), ball(1, 0, 0) }
			local sim = Simulate.start(balls, SHOT, nil, { frozen = { 1 } })
			local before = 0
			while not sim.firstHit and not Simulate.step(sim, 1) do
				before = if sim.firstHit then before else speed(find(sim, 0))
			end
			check.equal(sim.firstHit, 1, "it counts as the first ball hit, for the rules")
			local cue = find(sim, 0)
			check.truthy(cue.vx < 0, "back the way it came")
			check.near(speed(cue) / before, Config.Physics.RailBounce, 0.01, "keeping RailBounce of its speed")
			Simulate.step(sim, math.huge)
			check.equal(find(sim, 1).x, 0, "the frozen ball never moved")
			check.equal(find(sim, 1).y, 0)
			check.equal(find(sim, 1).pocket, nil)
		end
	)

	test("a ball glancing off a frozen ball comes off at the angle it hit", function()
		local balls = { ball(0, -3, -R), ball(1, 0, 0) }
		local sim = Simulate.start(balls, SHOT, nil, { frozen = { 1 } })
		untilFirstHit(sim)
		Simulate.step(sim, 1)
		local cue = find(sim, 0)
		-- Half a ball off center, it meets the frozen ball's surface 30 degrees off head-on, so like a rail hit at 30
		-- degrees it turns 180 - 2 × 30 = 120 degrees from its path
		check.near(math.deg(math.atan2(math.abs(cue.vy), cue.vx)), 120, 1, "reflected about the line of centers")
	end)

	test("a blast never pushes a frozen ball", function()
		local sim = Simulate.run(setup(), SHOT, nil, { blast = true, frozen = { 2 } })
		check.equal(find(sim, 2).x, 0)
		check.equal(find(sim, 2).y, 2 * R + 0.001)
		check.truthy(find(sim, 4).y ~= setup()[5].y, "an unfrozen one nearby still moves")
	end)

	test("a pocket with a lid takes no ball: it bounces off the lid like a rail", function()
		local halfX, halfY = Config.Table.Length / 2, Config.Table.Width / 2
		-- Into the foot +y corner (pocket 6) and the +y side pocket (pocket 5)
		local cases = {
			{ pocket = 6, from = { halfX - 2, halfY - 2 }, dir = { math.sqrt(0.5), math.sqrt(0.5) } },
			{ pocket = 5, from = { 0, 0 }, dir = { 0, 1 } },
		}
		for _, case in cases do
			local shot = { dirX = case.dir[1], dirY = case.dir[2], power = 0.3 }
			local open = Simulate.run({ ball(0, case.from[1], case.from[2]) }, shot)
			check.equal(find(open, 0).pocket, case.pocket, `pocket {case.pocket} open: it drops`)
			local lidded = Simulate.run(
				{ ball(0, case.from[1], case.from[2]) },
				shot,
				nil,
				{ blocked = { case.pocket } }
			)
			check.equal(find(lidded, 0).pocket, nil, `pocket {case.pocket} blocked: it doesn't`)
			local railHits = 0
			for _, event in lidded.events do
				railHits += if event.kind == "rail" then 1 else 0
			end
			check.truthy(railHits > 0, "it bounced")
		end
	end)

	test("on oil a ball slows at OilSlowdown of the normal rate, and two patches slow it no less than one", function()
		local function lostOver(steps: number, oil: { { x: number, y: number } }?): number
			local sim = Simulate.start({ ball(0, 0, 0) }, { dirX = 1, dirY = 0, power = 0 }, nil, { oil = oil })
			local start = speed(find(sim, 0))
			Simulate.step(sim, steps)
			return start - speed(find(sim, 0))
		end
		-- Few enough steps that the softest shot stays well inside the patch
		local plain = lostOver(100)
		local oiled = lostOver(100, { { x = 0, y = 0 } })
		check.near(oiled / plain, Config.Items.OilSlowdown, 1e-6)
		check.near(lostOver(100, { { x = 0, y = 0 }, { x = 0.1, y = 0 } }), oiled, 1e-9, "patches don't stack")
		local far = Simulate.run(
			{ ball(0, -6, 0) },
			{ dirX = 1, dirY = 0, power = 0 },
			nil,
			{ oil = { { x = -5, y = 0 } } }
		)
		local near = Simulate.run({ ball(0, -6, 0) }, { dirX = 1, dirY = 0, power = 0 })
		check.truthy(find(far, 0).x > find(near, 0).x, "crossing a patch, it rolls farther")
	end)

	test("the aim indicator stops at a frozen ball or a lid, like a wall", function()
		local layout = Geometry.build(Config.Table)
		local balls = { { id = 0, x = -3, y = 0 }, { id = 1, x = 0, y = 0 } }
		local normal = Preview.firstContact(balls, 1, 0, Config.Table, layout, Config.Physics)
		check.equal(normal.kind, "ball")
		local frozen = Preview.firstContact(balls, 1, 0, Config.Table, layout, Config.Physics, { frozen = { 1 } })
		check.equal(frozen.kind, "rail", "a frozen ball is a wall")
		check.equal(frozen.ball, nil, "with no bounce lines")
		check.near(frozen.x, normal.x, 1e-9, "at the same spot")
		-- Straight at the +y side pocket
		local toPocket = { { id = 0, x = 0, y = 0 } }
		check.equal(Preview.firstContact(toPocket, 0, 1, Config.Table, layout, Config.Physics).kind, "pocket")
		local lidded = Preview.firstContact(toPocket, 0, 1, Config.Table, layout, Config.Physics, { blocked = { 5 } })
		check.equal(lidded.kind, "rail", "a lid is a rail")
		check.near(lidded.y, Config.Table.Width / 2 - R, 1e-6, "touching the lid")
	end)
end
