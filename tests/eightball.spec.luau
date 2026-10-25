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

	-- Every ball on the table but `down`, which are in pocket 1. Where they stand doesn't matter to resolveShot.
	local function tableWith(down: { number }): { EightBall.Ball }
		local balls: { EightBall.Ball } = {}
		for id = 0, 15 do
			table.insert(balls, { id = id, x = 0, y = 0, pocket = if table.find(down, id) then 1 else nil })
		end
		return balls
	end
	local SOLIDS = { 1, 2, 3, 4, 5, 6, 7 }

	-- A shot's facts: the first ball hit and the ids that dropped, in order, each in pocket 1. Every ball was up
	-- before it, and a ball touched a rail after the first hit.
	local function facts(firstHit: number?, dropped: { number }, isBreak: boolean?): EightBall.ShotFacts
		local drops = {}
		for _, id in dropped do
			table.insert(drops, { id = id, pocket = 1 })
		end
		return {
			isBreak = isBreak == true,
			firstHit = firstHit,
			dropped = drops,
			railAfterHit = true,
			balls = tableWith({}),
			calledPocket = nil,
		}
	end
	-- The same for a shot by side A on solids with every solid down, so A is on the 8, calling pocket 1 or `called`
	local function onEight(firstHit: number?, dropped: { number }, called: number?): EightBall.ShotFacts
		local shot = facts(firstHit, dropped)
		shot.balls = tableWith(SOLIDS)
		shot.calledPocket = called or 1
		return shot
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

	-- Fouls

	test("sinking the cue ball is a foul, even with one of yours down, and it names the foul over any other", function()
		for name, shot in
			{ alone = facts(2, { 0 }), ["with yours"] = facts(2, { 2, 0 }), ["after theirs first"] = facts(12, { 0 }) }
		do
			local outcome = EightBall.resolveShot(SET, "A", shot)
			check.equal(outcome.foul, "scratch", name)
			check.truthy(not outcome.keepsTurn, name)
		end
	end)

	test("the cue ball hitting nothing is a foul, on an open table or with groups set", function()
		check.equal(EightBall.resolveShot(OPEN, "A", facts(nil, {})).foul, "nothingHit")
		check.equal(EightBall.resolveShot(SET, "A", facts(nil, {})).foul, "nothingHit")
	end)

	test("on an open table, hitting the 8 first is a foul, and any other ball first isn't", function()
		check.equal(EightBall.resolveShot(OPEN, "A", facts(8, {})).foul, "wrongBall")
		check.equal(EightBall.resolveShot(OPEN, "A", facts(3, {})).foul, nil, "a solid")
		check.equal(EightBall.resolveShot(OPEN, "A", facts(12, {})).foul, nil, "a stripe")
	end)

	test("with groups set, hitting one of theirs or the 8 first is a foul, and one of yours isn't", function()
		check.equal(EightBall.resolveShot(SET, "A", facts(12, {})).foul, "wrongBall", "theirs")
		check.equal(EightBall.resolveShot(SET, "A", facts(8, {})).foul, "wrongBall", "the 8")
		check.equal(EightBall.resolveShot(SET, "B", facts(3, {})).foul, "wrongBall", "B hits a solid")
		check.equal(EightBall.resolveShot(SET, "A", facts(3, {})).foul, nil, "yours")
	end)

	test("on the 8, hitting anything but the 8 first is a foul", function()
		check.equal(EightBall.resolveShot(SET, "A", onEight(12, {})).foul, "wrongBall")
		check.equal(EightBall.resolveShot(SET, "A", onEight(8, {})).foul, nil)
	end)

	test("when nothing drops and no ball touches a rail after the first hit, it's a foul", function()
		local quiet = facts(2, {})
		quiet.railAfterHit = false
		check.equal(EightBall.resolveShot(SET, "A", quiet).foul, "noRail", "no rail, nothing in")
		check.equal(EightBall.resolveShot(SET, "A", facts(2, {})).foul, nil, "a rail")
		local potted = facts(2, { 2 })
		potted.railAfterHit = false
		local outcome = EightBall.resolveShot(SET, "A", potted)
		check.equal(outcome.foul, nil, "no rail, but yours in")
		check.truthy(outcome.keepsTurn, "no rail, but yours in")
	end)

	test("a foul passes the turn, and a pot on it neither keeps the turn nor sets a group", function()
		local quiet = facts(2, {})
		quiet.railAfterHit = false
		for name, shot in { scratch = facts(2, { 2, 0 }), ["wrong ball"] = facts(8, { 2 }), ["no rail"] = quiet } do
			local outcome = EightBall.resolveShot(OPEN, "A", shot)
			check.truthy(outcome.foul ~= nil, name)
			check.truthy(not outcome.keepsTurn, name)
			check.equal(outcome.groups.A, nil, name)
			check.equal(outcome.winner, nil, name)
		end
	end)

	test("a fair shot that misses passes the turn with no foul", function()
		local outcome = EightBall.resolveShot(SET, "A", facts(2, {}))
		check.equal(outcome.foul, nil)
		check.truthy(not outcome.keepsTurn)
	end)

	-- The break

	test("any break counts: only a scratch fouls it, not nothing in, the 8 first, or no rail", function()
		local quiet = facts(8, {}, true)
		quiet.railAfterHit = false
		check.equal(EightBall.resolveShot(OPEN, "A", quiet).foul, nil, "the 8 first, no rail")
		check.equal(EightBall.resolveShot(OPEN, "A", facts(nil, {}, true)).foul, nil, "nothing hit")
		check.equal(EightBall.resolveShot(OPEN, "A", facts(1, { 3, 0 }, true)).foul, "scratch", "scratch")
	end)

	test("the 8 on the break comes back on the foot spot and play goes on, with no win or loss", function()
		local outcome = EightBall.resolveShot(OPEN, "A", facts(1, { 8 }, true))
		check.truthy(outcome.respotEight)
		check.equal(outcome.winner, nil)
		check.equal(outcome.foul, nil)
		check.truthy(outcome.keepsTurn)
		outcome = EightBall.resolveShot(OPEN, "A", facts(1, { 8, 0 }, true))
		check.truthy(outcome.respotEight, "with a scratch")
		check.equal(outcome.winner, nil, "with a scratch")
		check.equal(outcome.foul, "scratch", "with a scratch")
		check.truthy(not outcome.keepsTurn, "with a scratch")
		check.truthy(not EightBall.resolveShot(OPEN, "A", facts(1, { 3 }, true)).respotEight, "the 8 stays up")
	end)

	-- Where the 8 is respotted: clear of every ball still up, other than itself
	local function clear(balls: { EightBall.Ball }, x: number, y: number): boolean
		for _, ball in balls do
			if ball.id ~= 8 and not ball.pocket and (ball.x - x) ^ 2 + (ball.y - y) ^ 2 < (2 * radius) ^ 2 then
				return false
			end
		end
		return true
	end
	local footX = tableParams.Length / 4

	test("the 8 comes back on the foot spot when it's clear", function()
		local x, y = EightBall.spotEight({ { id = 0, x = layout.headLineX, y = 0 } }, tableParams)
		check.equal(x, footX)
		check.equal(y, 0)
	end)

	test("with a ball on the foot spot, the 8 goes just behind it, toward the foot rail", function()
		local balls: { EightBall.Ball } = { { id = 3, x = footX, y = 0 } }
		local x, y = EightBall.spotEight(balls, tableParams)
		check.near(x, footX + 2 * radius, radius / 100)
		check.equal(y, 0)
		check.truthy(clear(balls, x, y))
		-- Even behind a whole rack
		local racked = EightBall.rack(layout, first)
		racked[9].pocket = 1
		x, y = EightBall.spotEight(racked, tableParams)
		check.truthy(x > footX and x <= tableParams.Length / 2 - radius, `behind the rack at {x}`)
		check.truthy(clear(racked, x, y), "behind the rack")
	end)

	test("with no room behind the foot spot, the 8 goes in front of it", function()
		local balls: { EightBall.Ball } = {}
		for x = footX, tableParams.Length / 2 - radius, 2 * radius do
			-- Any ids but the 8's
			table.insert(balls, { id = if #balls < 7 then #balls + 1 else #balls + 2, x = x, y = 0 })
		end
		local x, y = EightBall.spotEight(balls, tableParams)
		check.near(x, footX - 2 * radius, radius / 100)
		check.truthy(clear(balls, x, y))
	end)

	-- The 8

	test("a side is on the 8 once every ball of its group is down, and never on an open table", function()
		check.truthy(EightBall.groupCleared(SET, "A", tableWith(SOLIDS)), "every solid down")
		check.truthy(not EightBall.groupCleared(SET, "B", tableWith(SOLIDS)), "stripes still up")
		check.truthy(not EightBall.groupCleared(SET, "A", tableWith({ 1, 2, 3, 4, 5, 6 })), "one solid left")
		check.truthy(not EightBall.groupCleared(OPEN, "A", tableWith(SOLIDS)), "open table")
	end)

	test("sinking the 8 in the called pocket on a legal shot wins", function()
		local outcome = EightBall.resolveShot(SET, "A", onEight(8, { 8 }))
		check.equal(outcome.winner, "A")
		check.equal(outcome.reason, "eightPotted")
		local stripes = facts(8, { 8 })
		stripes.balls, stripes.calledPocket = tableWith({ 9, 10, 11, 12, 13, 14, 15 }), 1
		check.equal(EightBall.resolveShot(SET, "B", stripes).winner, "B", "B on stripes")
	end)

	test("sinking the 8 before your group is cleared loses, on an open table or with groups set", function()
		for name, case in
			{ open = { groups = OPEN, shot = facts(3, { 8 }) }, set = { groups = SET, shot = facts(2, { 8 }) } }
		do
			local outcome = EightBall.resolveShot(case.groups, "A", case.shot)
			check.equal(outcome.winner, "B", name)
			check.equal(outcome.reason, "eightEarly", name)
		end
	end)

	test("sinking the 8 on the same shot as your last ball loses, whichever drops first", function()
		for _, order in { { 7, 8 }, { 8, 7 } } do
			local shot = facts(7, order)
			shot.balls = tableWith({ 1, 2, 3, 4, 5, 6 })
			local outcome = EightBall.resolveShot(SET, "A", shot)
			check.equal(outcome.winner, "B", `{order[1]} then {order[2]}`)
			check.equal(outcome.reason, "eightEarly", `{order[1]} then {order[2]}`)
		end
	end)

	test("the 8 in a pocket you didn't call loses", function()
		local outcome = EightBall.resolveShot(SET, "A", onEight(8, { 8 }, 3))
		check.equal(outcome.winner, "B")
		check.equal(outcome.reason, "eightWrongPocket")
	end)

	test("the 8 going in on a foul loses: with the cue ball, or after another ball first", function()
		for name, shot in
			{
				["scratch after"] = onEight(8, { 8, 0 }),
				["scratch first"] = onEight(8, { 0, 8 }),
				["wrong ball"] = onEight(12, { 8 }),
			}
		do
			local outcome = EightBall.resolveShot(SET, "A", shot)
			check.equal(outcome.winner, "B", name)
			check.equal(outcome.reason, "eightOnFoul", name)
		end
	end)

	test("a foul on the 8 that leaves the 8 up is just a foul", function()
		for name, case in
			{
				scratch = { shot = onEight(8, { 0 }), foul = "scratch" },
				["nothing hit"] = { shot = onEight(nil, {}), foul = "nothingHit" },
				["theirs first"] = { shot = onEight(12, { 12 }), foul = "wrongBall" },
			}
		do
			local outcome = EightBall.resolveShot(SET, "A", case.shot)
			check.equal(outcome.foul, case.foul, name)
			check.equal(outcome.winner, nil, name)
			check.truthy(not outcome.keepsTurn, name)
		end
	end)

	test("on the 8, a fair miss or sinking one of theirs passes the turn with no foul", function()
		for name, shot in { miss = onEight(8, {}), theirs = onEight(8, { 12 }) } do
			local outcome = EightBall.resolveShot(SET, "A", shot)
			check.equal(outcome.foul, nil, name)
			check.equal(outcome.winner, nil, name)
			check.truthy(not outcome.keepsTurn, name)
		end
	end)

	test("solids are 1–7, stripes 9–15, and the cue ball and the 8 are in neither", function()
		for id, expected in { [1] = "solids", [7] = "solids", [9] = "stripes", [15] = "stripes" } do
			check.equal(EightBall.groupOf(id), expected, `ball {id}`)
		end
		check.equal(EightBall.groupOf(0), nil, "the cue ball")
		check.equal(EightBall.groupOf(8), nil, "the 8")
	end)
end
