--!strict
local Config = require("../src/Shared/Config")
local EightBall = require("../src/Shared/Rules/EightBall")
local Geometry = require("../src/Shared/Physics/Geometry")
local TableFlow = require("../src/Shared/Rules/TableFlow")

local function first(_: number): number
	return 1
end

return function(test, check)
	local layout = Geometry.build(Config.Table)
	local tableParams = Config.Table
	local cooldown = Config.Shot.RequestCooldown

	-- Seats and sides

	test("a table's Mode sets its seats: 2 for 1v1, 4 for 2v2, and 1v1 for anything else", function()
		check.equal(TableFlow.seatCount("1v1"), 2)
		check.equal(TableFlow.seatCount("2v2"), 4)
		check.equal(TableFlow.seatCount(nil), 2, "no Mode")
		check.equal(TableFlow.seatCount("3v3"), 2, "a Mode we don't know")
		check.equal(TableFlow.seatCount(4), 2, "a Mode that isn't text")
	end)

	test("seats in turn order are A1, B1, A2, B2, alternating sides", function()
		check.equal(table.concat(TableFlow.SEAT_NAMES, " "), "A1 B1 A2 B2")
		for seat, side in { "A", "B", "A", "B" } do
			check.equal(TableFlow.sideOf(seat), side, TableFlow.SEAT_NAMES[seat])
		end
		check.equal(TableFlow.otherSide("A"), "B")
		check.equal(TableFlow.otherSide("B"), "A")
	end)

	test("a game needs a player per seat, or just one in Studio solo", function()
		check.equal(TableFlow.needed(2, false), 2)
		check.equal(TableFlow.needed(4, false), 4)
		check.equal(TableFlow.needed(4, true), 1)
	end)

	-- Turns

	test("turns go A1 → B1 → A2 → B2 and round again in 2v2, and A → B in 1v1", function()
		local order = {}
		local seat = 1
		for _ = 1, 5 do
			seat = TableFlow.nextTurn(seat, 4, false, false)
			table.insert(order, TableFlow.SEAT_NAMES[seat])
		end
		check.equal(table.concat(order, " "), "B1 A2 B2 A1 B1")
		check.equal(TableFlow.nextTurn(1, 2, false, false), 2)
		check.equal(TableFlow.nextTurn(2, 2, false, false), 1)
	end)

	test("keeping the turn, or winning, stays on the same seat", function()
		check.equal(TableFlow.nextTurn(3, 4, true, false), 3, "kept")
		check.equal(TableFlow.nextTurn(3, 4, false, true), 3, "won")
	end)

	test("each seat shoots for itself, and once its player has left, their teammate shoots for it", function()
		for seat = 1, 4 do
			check.equal(TableFlow.shooterSeat(seat, {}, 4), seat)
		end
		check.equal(TableFlow.shooterSeat(1, { [1] = true }, 4), 3, "A2 for A1")
		check.equal(TableFlow.shooterSeat(3, { [3] = true }, 4), 1, "A1 for A2")
		check.equal(TableFlow.shooterSeat(2, { [2] = true }, 4), 4, "B2 for B1")
		check.equal(TableFlow.shooterSeat(4, { [4] = true }, 4), 2, "B1 for B2")
	end)

	test("after a foul the turn passes, and a seat whose player left is shot for by their teammate", function()
		-- A1 fouls with B1 gone: the turn passes to B1's seat, and B2 shoots it, with ball in hand from the foul
		local left = { [2] = true }
		local turn = TableFlow.nextTurn(1, 4, false, false)
		check.equal(turn, 2)
		check.equal(TableFlow.shooterSeat(turn, left, 4), 4)
	end)

	test("Leave in 2v2 leaves the teammate playing on; with nobody left on that side, the other side wins", function()
		check.equal(TableFlow.teammateIn(1, { [1] = true }, 4), 3, "A2 plays on for A1")
		check.equal(TableFlow.teammateIn(4, { [4] = true }, 4), 2, "B1 plays on for B2")
		check.equal(TableFlow.teammateIn(3, { [1] = true, [3] = true }, 4), nil, "both of A gone")
		check.equal(TableFlow.teammateIn(1, { [1] = true }, 2), nil, "1v1 has no teammate")
		check.equal(TableFlow.teammateIn(1, { [1] = true }, 1), nil, "nor Studio solo")
	end)

	-- After a shot

	local function outcome(fields: { [string]: any }): EightBall.Outcome
		local result: EightBall.Outcome = { groups = {}, keepsTurn = false, respotEight = false }
		for key, value in fields do
			(result :: any)[key] = value
		end
		return result
	end

	local function ballOf(balls: { EightBall.Ball }, id: number): EightBall.Ball
		for _, ball in balls do
			if ball.id == id then
				return ball
			end
		end
		error(`no ball {id}`)
	end

	test("after a foul the turn passes with ball in hand; after a fair shot, without", function()
		local balls = EightBall.rack(layout, first)
		local seat, inHand = TableFlow.afterShot(1, 2, outcome({ foul = "wrongBall" }), balls, layout, tableParams)
		check.equal(seat, 2)
		check.truthy(inHand, "foul")
		seat, inHand = TableFlow.afterShot(1, 2, outcome({ keepsTurn = true }), balls, layout, tableParams)
		check.equal(seat, 1)
		check.truthy(not inHand, "a pot that keeps the turn")
	end)

	test("running out of time passes the turn with ball in hand; on the break, the next player breaks", function()
		local seat, inHand = TableFlow.afterTimeout(1, 2, false)
		check.equal(seat, 2)
		check.truthy(inHand, "ball in hand after a timeout")
		seat, inHand = TableFlow.afterTimeout(4, 4, false)
		check.equal(seat, 1, "B2 passes to A1")
		seat, inHand = TableFlow.afterTimeout(1, 2, true)
		check.equal(seat, 2)
		check.truthy(not inHand, "no ball in hand on the break: the next player breaks")
		seat = TableFlow.afterTimeout(1, 1, false)
		check.equal(seat, 1, "Studio solo keeps the one seat")
	end)

	test("a sunk cue ball comes back on the head line, unless the game is won", function()
		local balls = EightBall.rack(layout, first)
		local cue = ballOf(balls, 0)
		cue.x, cue.y, cue.pocket = 7, 3, 3
		TableFlow.afterShot(1, 2, outcome({ foul = "scratch" }), balls, layout, tableParams)
		check.equal(cue.pocket, nil)
		check.equal(cue.x, layout.headLineX)
		cue.pocket = 3
		TableFlow.afterShot(1, 2, outcome({ winner = "B", reason = "eightOnFoul" }), balls, layout, tableParams)
		check.equal(cue.pocket, 3, "left down once the game is won")
	end)

	test("an 8 down on the break goes back on its spot, before a sunk cue ball comes back", function()
		local balls = EightBall.rack(layout, first)
		local eight, cue = ballOf(balls, 8), ballOf(balls, 0)
		eight.pocket, cue.pocket = 2, 5
		TableFlow.afterShot(1, 2, outcome({ respotEight = true, foul = "scratch" }), balls, layout, tableParams)
		check.equal(eight.pocket, nil)
		local spotX, spotY = EightBall.spotEight(balls, tableParams)
		check.equal(eight.x, spotX)
		check.equal(eight.y, spotY)
		check.equal(cue.pocket, nil)
		check.truthy(EightBall.canPlaceCue(balls, cue.x, cue.y, tableParams), "the cue ball keeps clear of the 8")
	end)

	-- Joining and the countdown

	test("players join in order, and the one who takes the last seat needed starts the countdown", function()
		local lobby = TableFlow.lobby()
		local joined, token = TableFlow.join(lobby, "P1", 2, 2, false, false)
		check.truthy(joined and token == nil, "the first joins and waits")
		joined, token = TableFlow.join(lobby, "P2", 2, 2, false, false)
		check.truthy(joined and token ~= nil, "the second starts it")
		check.equal(lobby.countdown, token)
		check.equal(table.concat(lobby.joined, " "), "P1 P2")
	end)

	test("in Studio solo one player starts the countdown", function()
		local lobby = TableFlow.lobby()
		local joined, token = TableFlow.join(lobby, "P1", 2, TableFlow.needed(2, true), false, false)
		check.truthy(joined and token ~= nil)
	end)

	test(
		"joining is refused with a game on, during the countdown, when busy elsewhere, or with every seat taken",
		function()
			local lobby = TableFlow.lobby()
			check.truthy(not (TableFlow.join(lobby, "P1", 2, 2, true, false)), "a game on")
			check.truthy(not (TableFlow.join(lobby, "P1", 2, 2, false, true)), "in a game or waiting at a table")
			check.equal(#lobby.joined, 0)
			TableFlow.join(lobby, "P1", 2, 3, false, false)
			TableFlow.join(lobby, "P2", 2, 3, false, false)
			check.truthy(not (TableFlow.join(lobby, "P3", 2, 3, false, false)), "every seat taken")
			local counting = TableFlow.lobby()
			TableFlow.join(counting, "P1", 4, 1, false, false)
			check.truthy(not (TableFlow.join(counting, "P2", 4, 1, false, false)), "counting down")
			check.equal(#counting.joined, 1)
		end
	)

	test("the countdown ending hands over the players in seat order and empties the lobby", function()
		local lobby = TableFlow.lobby()
		TableFlow.join(lobby, "P1", 2, 2, false, false)
		local _, token = TableFlow.join(lobby, "P2", 2, 2, false, false)
		local players = TableFlow.endCountdown(lobby, token :: {}, 2)
		check.equal(table.concat(players or {}, " "), "P1 P2")
		check.equal(#lobby.joined, 0)
		check.equal(lobby.countdown, nil)
	end)

	test(
		"leaving during the countdown calls it off, the others stay joined, and its timer then does nothing",
		function()
			local lobby = TableFlow.lobby()
			TableFlow.join(lobby, "P1", 2, 2, false, false)
			local _, token = TableFlow.join(lobby, "P2", 2, 2, false, false)
			local wasJoined, calledOff = TableFlow.unjoin(lobby, "P2")
			check.truthy(wasJoined and calledOff)
			check.equal(table.concat(lobby.joined, " "), "P1")
			check.equal(lobby.countdown, nil)
			check.equal(TableFlow.endCountdown(lobby, token :: {}, 2), nil)
			check.equal(table.concat(lobby.joined, " "), "P1", "still joined")
		end
	)

	test("a countdown called off and started again starts the game once, from the new countdown only", function()
		local lobby = TableFlow.lobby()
		TableFlow.join(lobby, "P1", 2, 2, false, false)
		local _, old = TableFlow.join(lobby, "P2", 2, 2, false, false)
		TableFlow.unjoin(lobby, "P2")
		local _, new = TableFlow.join(lobby, "P3", 2, 2, false, false)
		check.truthy(new ~= nil and new ~= old)
		check.equal(TableFlow.endCountdown(lobby, old :: {}, 2), nil, "the old timer")
		check.equal(table.concat(TableFlow.endCountdown(lobby, new :: {}, 2) or {}, " "), "P1 P3", "the new one")
	end)

	test(
		"leaving while waiting takes you off without calling anything off, and a stranger leaving changes nothing",
		function()
			local lobby = TableFlow.lobby()
			TableFlow.join(lobby, "P1", 2, 2, false, false)
			local wasJoined, calledOff = TableFlow.unjoin(lobby, "P1")
			check.truthy(wasJoined and not calledOff)
			wasJoined, calledOff = TableFlow.unjoin(lobby, "P9")
			check.truthy(not wasJoined and not calledOff)
		end
	)

	test("a countdown that ends with too few players still joined starts nothing, and keeps them joined", function()
		-- Studio solo started it, then a second player joined the server, so a game now needs both seats
		local lobby = TableFlow.lobby()
		local _, token = TableFlow.join(lobby, "P1", 2, 1, false, false)
		check.equal(TableFlow.endCountdown(lobby, token :: {}, 2), nil)
		check.equal(lobby.countdown, nil)
		check.equal(table.concat(lobby.joined, " "), "P1")
	end)

	-- Shot requests

	test("a shot request is looked at only from the shooter, with the game on and the balls still", function()
		check.truthy(TableFlow.mayRequest(false, true, false, nil, 10, cooldown), "first request")
		check.truthy(not TableFlow.mayRequest(true, true, false, nil, 10, cooldown), "game over")
		check.truthy(not TableFlow.mayRequest(false, false, false, nil, 10, cooldown), "not the shooter")
		check.truthy(not TableFlow.mayRequest(false, true, true, nil, 10, cooldown), "balls rolling")
	end)

	test("shot requests are rate limited per player, counting from the last one let in", function()
		check.truthy(not TableFlow.mayRequest(false, true, false, 10, 10 + cooldown / 2, cooldown), "too soon")
		check.truthy(TableFlow.mayRequest(false, true, false, 10, 10 + cooldown, cooldown), "just long enough")
	end)

	test("a shot needs number values, a real direction of some length, and power from 0 to 1", function()
		local function read(dirX: unknown, dirY: unknown, power: unknown): TableFlow.ShotRequest?
			return TableFlow.readShot(dirX, dirY, power, nil, false, layout)
		end
		check.truthy(read(1, 0, 0) and read(1, 0, 1) and read(-3, 4, 0.5), "fair values")
		check.equal(read("1", 0, 0.5), nil, "text")
		check.equal(read(1, nil, 0.5), nil, "missing")
		check.equal(read(1, 0, { 0.5 }), nil, "a table")
		check.equal(read(0, 0, 0.5), nil, "no length")
		check.equal(read(0 / 0, 0, 0.5), nil, "NaN direction")
		check.equal(read(math.huge, 0, 0.5), nil, "infinite direction")
		check.equal(read(1, 0, -0.01), nil, "below 0")
		check.equal(read(1, 0, 1.01), nil, "past 1")
		check.equal(read(1, 0, 0 / 0), nil, "NaN power")
	end)

	test("a fair shot comes back with its direction made unit length and its power as sent", function()
		local request = TableFlow.readShot(-3, 4, 0.25, nil, false, layout) :: TableFlow.ShotRequest
		check.near(request.dirX, -0.6, 1e-9)
		check.near(request.dirY, 0.8, 1e-9)
		check.equal(request.power, 0.25)
	end)

	test("on the 8 a shot must call a pocket that exists; off it any called pocket is ignored", function()
		local function called(pocket: unknown, onEight: boolean): number?
			local request = TableFlow.readShot(1, 0, 0.5, pocket, onEight, layout)
			return if request then request.calledPocket or -1 else nil
		end
		check.equal(called(3, true), 3)
		check.equal(called(#layout.pockets, true), #layout.pockets, "the last pocket")
		check.equal(called(nil, true), nil, "none called")
		check.equal(called("3", true), nil, "text")
		check.equal(called(1.5, true), nil, "not whole")
		check.equal(called(0, true), nil, "pocket 0")
		check.equal(called(#layout.pockets + 1, true), nil, "past the last")
		check.equal(called(0 / 0, true), nil, "NaN")
		check.equal(called(math.huge, true), nil, "infinite")
		check.equal(called("junk", false), -1, "off the 8 the shot goes, calling nothing")
	end)

	-- Live aim

	test("live aim needs a real angle, a pull from 0 to 1, and two true-or-false values", function()
		local function read(aim: unknown, pull: unknown, held: unknown, placing: unknown)
			return TableFlow.readAim(aim, pull, held, placing, nil, nil, nil, false, layout, tableParams)
		end
		local state = read(1, 0.5, true, false) :: TableFlow.AimState
		check.truthy(state, "a fair update")
		check.equal(state.aim, 1)
		check.equal(state.pull, 0.5)
		check.equal(read(0 / 0, 0.5, true, false), nil, "NaN angle")
		check.equal(read(math.huge, 0.5, true, false), nil, "infinite angle")
		check.equal(read(1, 1.5, true, false), nil, "pull past full")
		check.equal(read(1, -0.1, true, false), nil, "negative pull")
		check.equal(read(1, 0 / 0, true, false), nil, "NaN pull")
		check.equal(read("1", 0.5, true, false), nil, "angle as text")
		check.equal(read(1, 0.5, 1, false), nil, "held as a number")
		local turned = read(-math.pi / 2, 0, false, false) :: TableFlow.AimState
		check.near(turned.aim, 3 * math.pi / 2, 1e-9, "the angle comes back from 0 to 2π")
	end)

	test("live aim takes a cue ball spot on the felt only with ball in hand, and a pocket only if it exists", function()
		local function read(cueX: unknown, cueY: unknown, pocket: unknown, inHand: boolean)
			return TableFlow.readAim(0, 0, false, true, cueX, cueY, pocket, inHand, layout, tableParams)
		end
		local state = read(1, 2, 3, true) :: TableFlow.AimState
		check.equal(state.cueX, 1)
		check.equal(state.cueY, 2)
		check.equal(state.pocket, 3)
		check.truthy(state.placing, "placing with ball in hand")
		check.equal(read(1, 2, nil, false), nil, "a spot without ball in hand")
		check.equal(read(1, nil, nil, true), nil, "half a spot")
		check.equal(read(tableParams.Length, 0, nil, true), nil, "off the felt")
		check.equal(read(0 / 0, 0, nil, true), nil, "NaN spot")
		check.equal(read(nil, nil, 7, true), nil, "a pocket that doesn't exist")
		check.equal(read(nil, nil, 1.5, true), nil, "half a pocket")
		local noHand = TableFlow.readAim(0, 0, false, true, nil, nil, nil, false, layout, tableParams) :: TableFlow.AimState
		check.truthy(not noHand.placing, "no placing without ball in hand")
	end)

	test("with no spot the cue ball stays put, the only choice without ball in hand", function()
		local balls = EightBall.rack(layout, first)
		check.truthy(TableFlow.cueSpotAllowed(false, nil, nil, balls, tableParams), "no ball in hand")
		check.truthy(TableFlow.cueSpotAllowed(true, nil, nil, balls, tableParams), "ball in hand")
		check.truthy(not TableFlow.cueSpotAllowed(false, layout.headLineX, 1, balls, tableParams), "a spot")
	end)

	test("with ball in hand the cue ball goes on any spot the rules allow, given as two numbers", function()
		local balls = EightBall.rack(layout, first)
		local apex = layout.rack[1]
		check.truthy(TableFlow.cueSpotAllowed(true, layout.headLineX, 1, balls, tableParams), "a clear spot")
		check.truthy(not TableFlow.cueSpotAllowed(true, apex.x, apex.y, balls, tableParams), "on a ball")
		check.truthy(not TableFlow.cueSpotAllowed(true, layout.headLineX, nil, balls, tableParams), "one number")
		check.truthy(not TableFlow.cueSpotAllowed(true, "0", 1, balls, tableParams), "text")
		check.truthy(not TableFlow.cueSpotAllowed(true, 0 / 0, 1, balls, tableParams), "NaN")
	end)

	test("power past 1 is let in only up to the top the server allows, which is past 1 only with Power Shot on", function()
		local top = Config.Items.PowerShotMax
		check.equal(TableFlow.readShot(1, 0, 1.2, nil, false, layout), nil, "past 1 without Power Shot")
		local request = TableFlow.readShot(1, 0, 1.2, nil, false, layout, top)
		check.equal(request and request.power, 1.2, "past 1 with it")
		check.equal(TableFlow.readShot(1, 0, top + 0.01, nil, false, layout, top), nil, "past the top")
		local tableParams = Config.Table
		check.equal(TableFlow.readAim(0, 1.2, true, false, nil, nil, nil, false, layout, tableParams), nil, "live pull")
		check.truthy(TableFlow.readAim(0, 1.2, true, false, nil, nil, nil, false, layout, tableParams, top), "with it")
	end)
end
