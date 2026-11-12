--!strict
-- The turn, timeout and ability flow: the pure calls Server/Match makes, in its order, through whole sequences of
-- turns. `startTurn`, `shot` and `timeOut` below mirror Match's startTurn, shoot (after the rules' outcome) and timeOut;
-- change them together.
local Config = require("../src/Shared/Config")
local Items = require("../src/Shared/Items")
local TableFlow = require("../src/Shared/Rules/TableFlow")

type Game = { turnSeat: number, isBreak: boolean, ballInHand: boolean, items: Items.State }

local function roll(): number
	return 0 -- always the first item, though these tests give items by name
end

-- Every ball on the table, spread out, for picking targets
local BALLS = {}
for id = 0, 15 do
	table.insert(BALLS, { id = id, x = -6 + id * 0.7, y = (id % 3 - 1) * 2, vx = 0, vy = 0 })
end

-- Match.startTurn: a new player's visit earns TurnPoints and moves on the items' lifetimes; every shot resets "used"
local function startTurn(game: Game, fresh: boolean)
	if fresh then
		Items.add(game.items, game.turnSeat, Config.Items.TurnPoints, roll)
	end
	Items.newShot(game.items, game.turnSeat, fresh)
end

local function newGame(seats: number): Game
	local game = { turnSeat = 1, isBreak = true, ballInHand = false, items = Items.new(seats) }
	startTurn(game, true)
	return game
end

-- Match.shoot after the outcome: points for `pots` scoring pots, then the turn stays or passes
local function shot(game: Game, keepsTurn: boolean, foul: boolean, pots: number)
	Items.afterPots(game.items, game.turnSeat, pots, roll)
	local shotSeat = game.turnSeat
	game.turnSeat = TableFlow.nextTurn(game.turnSeat, #game.items.bars, keepsTurn, false)
	game.ballInHand = foul
	game.isBreak = false
	local fresh = game.turnSeat ~= shotSeat
	if fresh then
		Items.turnEnded(game.items, shotSeat)
	end
	startTurn(game, fresh)
end

-- Match.timeOut: a foul that passes the turn; on the break the next player breaks, with no ball in hand
local function timeOut(game: Game)
	Items.turnEnded(game.items, game.turnSeat)
	game.turnSeat, game.ballInHand = TableFlow.afterTimeout(game.turnSeat, #game.items.bars, game.isBreak)
	startTurn(game, true)
end

local function use(game: Game, slot: number, target: any): (string?, string?)
	local item, _, why = Items.use(game.items, game.turnSeat, slot, target, BALLS :: any, Config.Table, roll, nil)
	return item, why
end

return function(test, check)
	test("2v2 turns go A1, B1, A2, B2 and back, and a legal pot keeps the same seat", function()
		local game = newGame(4)
		local seen = { game.turnSeat }
		for _, keeps in { false, false, true, false, false } do
			shot(game, keeps, false, if keeps then 1 else 0)
			table.insert(seen, game.turnSeat)
		end
		check.equal(table.concat(seen, ","), "1,2,3,3,4,1")
	end)

	test("a foul passes the turn with ball in hand", function()
		local game = newGame(2)
		shot(game, false, true, 0)
		check.equal(game.turnSeat, 2)
		check.equal(game.ballInHand, true)
		shot(game, false, false, 0)
		check.equal(game.ballInHand, false, "a plain miss gives none")
	end)

	test("a timeout on the break hands the break on without ball in hand; later one gives ball in hand", function()
		local game = newGame(2)
		timeOut(game)
		check.equal(game.turnSeat, 2)
		check.equal(game.ballInHand, false, "no ball in hand on the break")
		check.equal(game.isBreak, true, "the next player breaks")
		shot(game, true, false, 0) -- the break keeps the turn
		timeOut(game)
		check.equal(game.turnSeat, 1)
		check.equal(game.ballInHand, true)
	end)

	test("the bar earns 3 for each new turn only, 4 for each own pot and 2 for the opponent who shoots next", function()
		local items = Config.Items
		local game = newGame(4)
		local bars = game.items.bars
		check.equal(bars[1].points, items.TurnPoints, "the break is the breaker's first turn")
		shot(game, true, false, 1)
		check.equal(bars[1].points, items.TurnPoints + items.OwnBallPoints, "a kept turn earns no turn points")
		check.equal(bars[2].points, items.OpponentBallPoints, "to B1, who shoots next")
		check.equal(bars[4].points, 0, "not to B2")
		shot(game, false, false, 0)
		check.equal(bars[2].points, items.OpponentBallPoints + items.TurnPoints)
		timeOut(game)
		check.equal(bars[3].points, items.TurnPoints, "a timeout still starts the next player's turn")
	end)

	test("Power Shot lasts the turn, Blast Ball one shot, and only one item goes per shot", function()
		local game = newGame(2)
		Items.give(game.items, 1, "powerShot")
		Items.give(game.items, 1, "blastBall")
		check.equal(use(game, 1), "powerShot")
		check.equal(Items.maxPower(game.items, 1), Config.Items.PowerShotMax)
		check.equal(use(game, 2), nil, "a second item on the same shot is refused")
		shot(game, true, false, 1)
		check.equal(Items.maxPower(game.items, 1), Config.Items.PowerShotMax, "still on for the kept turn")
		check.equal(use(game, 2), "blastBall", "a new shot takes another item")
		check.equal(Items.effects(game.items).blast, true)
		shot(game, true, false, 1)
		check.equal(Items.effects(game.items).blast, false, "Blast Ball is gone after its shot")
		shot(game, false, false, 0)
		check.equal(Items.maxPower(game.items, 1), 1, "Power Shot ends as the turn passes")
	end)

	test("Freeze lasts until the end of the other side's next turn, and a timeout ends that turn too", function()
		local game = newGame(2)
		Items.give(game.items, 1, "freeze")
		check.equal(use(game, 1, 3), "freeze")
		check.equal(Items.effects(game.items).frozen[1], 3)
		shot(game, false, false, 0)
		check.equal(Items.effects(game.items).frozen[1], 3, "still frozen through B's turn")
		timeOut(game)
		check.equal(#Items.effects(game.items).frozen, 0, "melts as B's turn ends")
	end)

	test("A's freeze holds through A's own shots this turn, then ends after B's next turn", function()
		local game = newGame(2)
		Items.give(game.items, 1, "freeze")
		use(game, 1, 5)
		shot(game, true, false, 1)
		check.equal(Items.effects(game.items).frozen[1], 5, "A's own next shot this turn")
		shot(game, false, false, 0)
		shot(game, false, false, 0)
		check.equal(#Items.effects(game.items).frozen, 0, "gone once B's turn is over")
	end)
end
