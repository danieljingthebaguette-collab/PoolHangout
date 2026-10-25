--!strict
local Config = require("../src/Shared/Config")
local EightBall = require("../src/Shared/Rules/EightBall")
local Geometry = require("../src/Shared/Physics/Geometry")

-- Stand-ins for the server's random picks: always the first choice, always the last, and a fixed jumble
local function first(_: number): number
	return 1
end
local function last(n: number): number
	return n
end
local function jumble(): (number) -> number
	local seed = 7
	return function(n: number): number
		seed = (seed * 1103515245 + 12345) % 2147483648
		return seed % n + 1
	end
end

return function(test, check)
	local layout = Geometry.build(Config.Table)
	local radius = Config.Table.BallRadius
	local tableParams = Config.Table

	-- The id of the ball on a rack spot
	local function idAt(balls: { EightBall.Ball }, spot: { x: number, y: number }): number?
		for _, ball in balls do
			if ball.x == spot.x and ball.y == spot.y then
				return ball.id
			end
		end
		return nil
	end

	test("the rack holds every ball once, sorted by id, with the cue ball in the middle of the head line", function()
		for _, pick in { first, last, jumble() } do
			local balls = EightBall.rack(layout, pick)
			check.equal(#balls, 16)
			for i, ball in balls do
				check.equal(ball.id, i - 1)
			end
			check.equal(balls[1].x, layout.headLineX)
			check.equal(balls[1].y, 0)
		end
	end)

	test("the 8 sits in the middle of the rack, with a solid and a stripe in the back corners", function()
		-- Geometry's order: spot 5 is the third row's middle, and 11 and 15 the back row's ends
		check.equal(layout.rack[5].y, 0)
		check.equal(layout.rack[11].x, layout.rack[15].x)
		check.equal(layout.rack[11].y, -layout.rack[15].y)
		for _, pick in { first, last, jumble() } do
			local balls = EightBall.rack(layout, pick)
			check.equal(idAt(balls, layout.rack[5]), 8)
			local a, b = idAt(balls, layout.rack[11]) :: number, idAt(balls, layout.rack[15]) :: number
			check.truthy((a < 8) ~= (b < 8), `back corners hold {a} and {b}`)
		end
	end)

	test("the 12 balls besides the 8 and the back corners are shuffled, not grouped by type", function()
		-- Six solids and six stripes go on those 12 spots, so over many racks each spot holds a solid about half the time
		math.randomseed(1)
		local function pick(n: number): number
			return math.random(1, n)
		end
		local racks = 400
		local solids: { [number]: number } = {}
		for _ = 1, racks do
			local balls = EightBall.rack(layout, pick)
			for spot, position in layout.rack do
				if spot ~= 5 and spot ~= 11 and spot ~= 15 then
					solids[spot] = (solids[spot] or 0) + (if (idAt(balls, position) :: number) < 8 then 1 else 0)
				end
			end
		end
		for spot, count in solids do
			check.near(count / racks, 0.5, 0.15, `share of solids on rack spot {spot}`)
		end
	end)

	test("the same picks give the same rack, and different picks a different one", function()
		local function order(pick: (number) -> number): string
			local ids = {}
			for _, spot in layout.rack do
				table.insert(ids, idAt(EightBall.rack(layout, pick), spot))
			end
			return table.concat(ids, ",")
		end
		check.equal(order(jumble()), order(jumble()))
		check.truthy(order(first) ~= order(last))
	end)

	test("ball in hand goes anywhere clear on the table, either side of the head line", function()
		local balls = EightBall.rack(layout, first)
		check.truthy(EightBall.canPlaceCue(balls, layout.headLineX - 2, 1, tableParams), "behind the head line")
		check.truthy(EightBall.canPlaceCue(balls, layout.headLineX + 2, 0, tableParams), "past it")
	end)

	test("the cue ball can't go on a ball, but can touch one, or go where a sunk ball was", function()
		local balls = EightBall.rack(layout, first)
		local apex = layout.rack[1]
		check.truthy(not EightBall.canPlaceCue(balls, apex.x - radius, apex.y, tableParams), "on it")
		check.truthy(EightBall.canPlaceCue(balls, apex.x - 2.01 * radius, apex.y, tableParams), "touching")
		for _, ball in balls do
			if idAt({ ball }, apex) then
				ball.pocket = 1
			end
		end
		check.truthy(EightBall.canPlaceCue(balls, apex.x, apex.y, tableParams), "where a sunk ball was")
	end)

	test("the cue ball stays on the felt, inside the cushions and out of the pockets' mouths", function()
		local edgeX, edgeY = tableParams.Length / 2 - radius, tableParams.Width / 2 - radius
		local function can(x: number, y: number): boolean
			return EightBall.canPlaceCue({}, x, y, tableParams)
		end
		check.truthy(can(-edgeX, 0), "against the head cushion")
		check.truthy(not can(-edgeX - 0.01, 0), "into the head cushion")
		check.truthy(not can(-4, edgeY + 0.01), "into a long cushion")
		check.truthy(not can(-edgeX, -edgeY), "in a corner pocket's mouth")
		check.truthy(not can(0, edgeY), "in a side pocket's mouth")
	end)

	test("a spot that isn't a real number is never allowed", function()
		for _, value in { 0 / 0, math.huge, -math.huge } do
			check.truthy(not EightBall.canPlaceCue({}, value, 0, tableParams))
			check.truthy(not EightBall.canPlaceCue({}, layout.headLineX, value, tableParams))
		end
	end)

	test("placing: a clear spot is its own nearest, and past the cushions it stops at the edge", function()
		local balls = EightBall.rack(layout, first)
		local x, y = EightBall.nearestCueSpot(balls, -6, 1, tableParams)
		check.equal(x, -6)
		check.equal(y, 1)
		x, y = EightBall.nearestCueSpot(balls, -20, 0, tableParams)
		check.equal(x, -(tableParams.Length / 2 - radius), "against the head cushion")
		check.equal(y, 0)
	end)

	test("placing: over a ball, the cue ball stops just touching it, on the pointer's side", function()
		local balls: { EightBall.Ball } = { { id = 1, x = -6, y = 0 } }
		local x, y = EightBall.nearestCueSpot(balls, -6 + radius / 2, 0, tableParams)
		check.near(x :: number, -6 + 2 * radius, radius / 100)
		check.equal(y, 0)
		check.truthy(EightBall.canPlaceCue(balls, x :: number, y :: number, tableParams))
	end)

	test("placing: whatever spot it finds is allowed, anywhere on or off the table, even by the rack", function()
		local balls = EightBall.rack(layout, first)
		for gx = -10, 10, 0.25 do
			for gy = -5, 5, 0.25 do
				local x, y = EightBall.nearestCueSpot(balls, gx, gy, tableParams)
				if x and y then
					check.truthy(EightBall.canPlaceCue(balls, x, y, tableParams), `from {gx}, {gy}`)
				end
			end
		end
	end)

	test("a sunk cue ball comes back at the first clear spot on the line, out from the middle", function()
		local x = layout.headLineX
		local balls: { EightBall.Ball } = { { id = 1, x = x, y = 0 } }
		local cueX, cueY = EightBall.freeSpot(balls, x, tableParams)
		check.equal(cueX, x)
		check.truthy(cueY ~= 0)
		check.truthy(EightBall.canPlaceCue(balls, cueX, cueY, tableParams))
	end)

	-- A shot's facts: the first ball hit and the ids that dropped, in order, each in pocket 1
	local function facts(firstHit: number?, dropped: { number }, isBreak: boolean?): EightBall.ShotFacts
		local drops = {}
		for _, id in dropped do
			table.insert(drops, { id = id, pocket = 1 })
		end
		return { isBreak = isBreak == true, firstHit = firstHit, dropped = drops }
	end
	local OPEN: EightBall.Groups = {}

	test("the table stays open after the break, even when balls go in", function()
		local outcome = EightBall.resolveShot(OPEN, "A", facts(1, { 3, 12 }, true))
		check.equal(outcome.groups.A, nil)
		check.equal(outcome.groups.B, nil)
	end)

	test(
		"the first legal pot on an open table gives the shooter's side that group, and the other side the other",
		function()
			local outcome = EightBall.resolveShot(OPEN, "B", facts(4, { 4 }))
			check.equal(outcome.groups.B, "solids")
			check.equal(outcome.groups.A, "stripes")
			outcome = EightBall.resolveShot(OPEN, "A", facts(2, { 11 }))
			check.equal(outcome.groups.A, "stripes", "any ball but the 8 first, and a stripe drops")
			check.equal(outcome.groups.B, "solids")
		end
	)

	test("when both kinds drop on the shot that opens the table, the first to drop decides", function()
		check.equal(EightBall.resolveShot(OPEN, "A", facts(9, { 13, 2 })).groups.A, "stripes")
		check.equal(EightBall.resolveShot(OPEN, "A", facts(9, { 2, 13 })).groups.A, "solids")
	end)

	test("a pot on a shot that isn't legal leaves the table open: scratch, the 8 first, or nothing hit", function()
		for name, shot in
			{
				scratch = facts(3, { 3, 0 }),
				["scratch first"] = facts(3, { 0, 3 }),
				["8 first"] = facts(8, { 5 }),
				["nothing hit"] = facts(nil, { 5 }),
			}
		do
			check.equal(EightBall.resolveShot(OPEN, "A", shot).groups.A, nil, name)
		end
	end)

	test("the 8 dropping on its own doesn't set a group, and a group ball after it does", function()
		check.equal(EightBall.resolveShot(OPEN, "A", facts(1, { 8 })).groups.A, nil)
		check.equal(EightBall.resolveShot(OPEN, "A", facts(1, { 8, 10 })).groups.A, "stripes")
	end)

	test("once groups are set, pots never change them, and the groups passed in are left as they were", function()
		local groups: EightBall.Groups = { A = "solids", B = "stripes" }
		local outcome = EightBall.resolveShot(groups, "A", facts(9, { 9 }))
		check.equal(outcome.groups.A, "solids")
		check.equal(outcome.groups.B, "stripes")
		local open: EightBall.Groups = {}
		EightBall.resolveShot(open, "A", facts(1, { 1 }))
		check.equal(open.A, nil, "an open table passed in stays open")
	end)

	local SET: EightBall.Groups = { A = "solids", B = "stripes" }

	test("the breaker keeps shooting when any ball goes in on the break, even the 8", function()
		check.truthy(EightBall.resolveShot(OPEN, "A", facts(1, { 3 }, true)).keepsTurn, "a solid")
		check.truthy(EightBall.resolveShot(OPEN, "A", facts(1, { 8 }, true)).keepsTurn, "the 8")
		check.truthy(not EightBall.resolveShot(OPEN, "A", facts(1, {}, true)).keepsTurn, "nothing in")
	end)

	test("sinking the cue ball on the break passes the turn, even with other balls down", function()
		check.truthy(not EightBall.resolveShot(OPEN, "A", facts(1, { 3, 0 }, true)).keepsTurn)
		check.truthy(not EightBall.resolveShot(OPEN, "A", facts(1, { 0, 3 }, true)).keepsTurn)
	end)

	test("on an open table a legal pot of either kind keeps the turn, and a miss passes it", function()
		check.truthy(EightBall.resolveShot(OPEN, "A", facts(2, { 2 })).keepsTurn, "a solid")
		check.truthy(EightBall.resolveShot(OPEN, "A", facts(2, { 12 })).keepsTurn, "a stripe off a solid")
		check.truthy(not EightBall.resolveShot(OPEN, "A", facts(2, {})).keepsTurn, "a miss")
	end)

	test("a pot on an illegal shot passes the turn: scratch, the 8 first, or nothing hit", function()
		for name, shot in
			{ scratch = facts(3, { 3, 0 }), ["8 first"] = facts(8, { 5 }), ["nothing hit"] = facts(nil, { 5 }) }
		do
			check.truthy(not EightBall.resolveShot(OPEN, "A", shot).keepsTurn, `open table, {name}`)
			check.truthy(not EightBall.resolveShot(SET, "A", shot).keepsTurn, `groups set, {name}`)
		end
	end)

	test("with groups set, sinking one of yours keeps the turn, even with one of theirs", function()
		check.truthy(EightBall.resolveShot(SET, "A", facts(2, { 2 })).keepsTurn, "A's solid")
		check.truthy(EightBall.resolveShot(SET, "B", facts(10, { 10 })).keepsTurn, "B's stripe")
		check.truthy(EightBall.resolveShot(SET, "A", facts(2, { 12, 2 })).keepsTurn, "theirs, then yours")
	end)

	test("with groups set, sinking only theirs passes the turn", function()
		check.truthy(not EightBall.resolveShot(SET, "A", facts(2, { 12 })).keepsTurn)
	end)

	test("with groups set, hitting one of theirs first passes the turn, even if yours goes in", function()
		check.truthy(not EightBall.resolveShot(SET, "A", facts(12, { 2 })).keepsTurn)
	end)

	test("the 8 going in after the break doesn't keep the turn", function()
		check.truthy(not EightBall.resolveShot(OPEN, "A", facts(2, { 8 })).keepsTurn, "open table")
		check.truthy(not EightBall.resolveShot(SET, "A", facts(2, { 8 })).keepsTurn, "groups set")
	end)

	test("solids are 1–7, stripes 9–15, and the cue ball and the 8 are in neither", function()
		for id, expected in { [1] = "solids", [7] = "solids", [9] = "stripes", [15] = "stripes" } do
			check.equal(EightBall.groupOf(id), expected, `ball {id}`)
		end
		check.equal(EightBall.groupOf(0), nil, "the cue ball")
		check.equal(EightBall.groupOf(8), nil, "the 8")
	end)
end
