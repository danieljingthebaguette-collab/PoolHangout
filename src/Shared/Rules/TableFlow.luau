--!strict
-- How a table runs, by seat number: its seats and sides, whose turn comes next, who shoots for a seat whose player
-- left, joining and the countdown before a game, and the checks every shot request must pass. Pure Luau, so Lune can
-- test it. TableService and Match keep the players, remotes, timers, prompts and ball parts.

local EightBall = require("./EightBall")
local Geometry = require("../Physics/Geometry")

-- The players who have joined a table and wait for its game, in the order they joined, and its countdown while one
-- is on: a token, so a countdown called off and started again doesn't start the game twice
export type Lobby<T> = { joined: { T }, countdown: {}? }

-- A shot request's values once they've passed every check, with the direction made unit length
export type ShotRequest = { dirX: number, dirY: number, power: number, calledPocket: number? }

local TableFlow = {}

-- Seats in turn order, by the names of their markers. A 1v1 table has the first two.
TableFlow.SEAT_NAMES = { "A1", "B1", "A2", "B2" }
local SEATS: { [string]: number } = { ["1v1"] = 2, ["2v2"] = 4 }

local function isFinite(value: number): boolean
	return value == value and math.abs(value) ~= math.huge
end

-- How many seats a table has, from its Mode. A table with no Mode, or one we don't know, is 1v1.
function TableFlow.seatCount(mode: unknown): number
	return if type(mode) == "string" and SEATS[mode] then SEATS[mode] else SEATS["1v1"]
end

-- How many players a game needs: one per seat, or one in Studio solo
function TableFlow.needed(seats: number, solo: boolean): number
	return if solo then 1 else seats
end

-- A1 and A2 are side A, B1 and B2 side B: seats alternate sides in turn order
function TableFlow.sideOf(seat: number): EightBall.Side
	return if seat % 2 == 1 then "A" else "B"
end

function TableFlow.otherSide(side: EightBall.Side): EightBall.Side
	return if side == "A" then "B" else "A"
end

-- Who shoots for a seat: its own player, or once they've left, their teammate, two seats on
function TableFlow.shooterSeat(seat: number, left: { [number]: boolean }, count: number): number
	return if left[seat] then (seat + 1) % count + 1 else seat
end

-- The seat whose turn it is after a shot: the same one if the shooter keeps the turn or the game is won, otherwise
-- the next in turn order, A1 → B1 → A2 → B2
function TableFlow.nextTurn(seat: number, count: number, keepsTurn: boolean, won: boolean): number
	return if keepsTurn or won then seat else seat % count + 1
end

-- After a shot: the seat whose turn is next, and whether its shooter has ball in hand, which is after any foul. It
-- also sets the balls for the next shot: an 8 down on the break goes back on its spot first, so the cue ball keeps
-- clear of it, then a sunk cue ball goes back on the head line, unless the game is won.
function TableFlow.afterShot(
	seat: number,
	count: number,
	outcome: EightBall.Outcome,
	balls: { EightBall.Ball },
	layout: Geometry.Layout,
	tableParams: Geometry.TableParams
): (number, boolean)
	for _, ball in balls do
		if ball.id == 8 and outcome.respotEight then
			ball.pocket = nil
			ball.x, ball.y = EightBall.spotEight(balls, tableParams)
		end
	end
	for _, ball in balls do
		if ball.id == 0 and ball.pocket and not outcome.winner then
			ball.pocket = nil
			ball.x, ball.y = EightBall.freeSpot(balls, layout.headLineX, tableParams)
		end
	end
	return TableFlow.nextTurn(seat, count, outcome.keepsTurn, outcome.winner ~= nil), outcome.foul ~= nil
end

-- The shot clock ran out: a foul, so the turn passes and the next shooter has ball in hand. On the break there's no
-- ball in hand, so the next player breaks instead.
function TableFlow.afterTimeout(seat: number, count: number, isBreak: boolean): (number, boolean)
	return TableFlow.nextTurn(seat, count, false, false), not isBreak
end

-- A seat on the same side as this one whose player is still in, to play on alone after this one presses Leave. Nil
-- with none, and then the other side wins.
function TableFlow.teammateIn(seat: number, left: { [number]: boolean }, count: number): number?
	for other = 1, count do
		if other ~= seat and not left[other] and other % 2 == seat % 2 then
			return other
		end
	end
	return nil
end

function TableFlow.lobby<T>(): Lobby<T>
	return { joined = {}, countdown = nil }
end

-- Pressing the "Join table" prompt. Refused while the table has a game on (`inUse`) or counts down, while the player
-- is in a game or waiting at a table (`busy`), or once every seat is taken. Returns whether they joined, and the
-- token of the countdown it starts once enough have joined.
function TableFlow.join<T>(
	lobby: Lobby<T>,
	who: T,
	seats: number,
	needed: number,
	inUse: boolean,
	busy: boolean
): (boolean, {}?)
	if inUse or lobby.countdown or busy or #lobby.joined >= seats then
		return false, nil
	end
	table.insert(lobby.joined, who)
	if #lobby.joined >= needed then
		local token = {}
		lobby.countdown = token
		return true, token
	end
	return true, nil
end

-- Takes a player off the lobby. Returns whether they were in it, and whether that called off its countdown; the
-- others stay joined.
function TableFlow.unjoin<T>(lobby: Lobby<T>, who: T): (boolean, boolean)
	local index = table.find(lobby.joined, who)
	if not index then
		return false, false
	end
	table.remove(lobby.joined, index)
	local calledOff = lobby.countdown ~= nil
	lobby.countdown = nil
	return true, calledOff
end

-- The countdown ran out. If it's still the table's current one it ends, and with enough players still joined they
-- leave the lobby as the game's players, in seat order. Nil if it was called off, or too few are left.
function TableFlow.endCountdown<T>(lobby: Lobby<T>, token: {}, needed: number): { T }?
	if lobby.countdown ~= token then
		return nil
	end
	lobby.countdown = nil
	local players = lobby.joined
	if #players == 0 or #players < needed then
		return nil
	end
	lobby.joined = {}
	return players
end

-- Whether a shot request gets looked at: the game is on, it's from the shooter, the balls are still, and the
-- shooter's last request was at least `cooldown` seconds ago. A request let in counts for the rate limit, whether or
-- not its values then pass.
function TableFlow.mayRequest(
	ended: boolean,
	isShooter: boolean,
	rolling: boolean,
	last: number?,
	now: number,
	cooldown: number
): boolean
	return not ended and isShooter and not rolling and now - (last or -math.huge) >= cooldown
end

-- A shot request's values, as a client sent them: an aim direction of nonzero length, power from 0 to 1, and on the
-- 8 (`onEight`) the number of a pocket that exists. Off the 8 any called pocket is ignored. Nil if anything is wrong.
-- The cue ball's spot is checked last, with `cueSpotAllowed`, as it's placed.
function TableFlow.readShot(
	dirX: unknown,
	dirY: unknown,
	power: unknown,
	calledPocket: unknown,
	onEight: boolean,
	layout: Geometry.Layout
): ShotRequest?
	if type(dirX) ~= "number" or type(dirY) ~= "number" or type(power) ~= "number" then
		return nil
	end
	local length = math.sqrt(dirX * dirX + dirY * dirY)
	if not (isFinite(length) and length > 0 and power >= 0 and power <= 1) then
		return nil
	end
	-- NaN and infinity fail the whole-number check
	local called: number? = nil
	if onEight then
		if type(calledPocket) ~= "number" or calledPocket % 1 ~= 0 or not layout.pockets[calledPocket] then
			return nil
		end
		called = calledPocket
	end
	return { dirX = dirX / length, dirY = dirY / length, power = power, calledPocket = called }
end

-- Whether a shot may put the cue ball here: no spot (nil, nil) leaves it where it rests, the only choice without
-- ball in hand, like on the break; with ball in hand, any pair of numbers the rules allow
function TableFlow.cueSpotAllowed(
	ballInHand: boolean,
	cueX: unknown,
	cueY: unknown,
	balls: { EightBall.Ball },
	tableParams: Geometry.TableParams
): boolean
	if cueX == nil and cueY == nil then
		return true
	end
	return ballInHand
		and type(cueX) == "number"
		and type(cueY) == "number"
		and EightBall.canPlaceCue(balls, cueX, cueY, tableParams)
end

return TableFlow
