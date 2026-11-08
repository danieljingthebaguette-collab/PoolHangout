--!strict
-- What items change about how balls move: Power Shot's speed past full power, and Blast Ball. Every distance and
-- speed comes from Config.
local Config = require("../src/Shared/Config")
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
end
