--!strict
-- One game of 8-ball on one table: who's seated, whose turn it is, ball in hand, and the shots they ask for. The
-- server is the referee: a shot only goes once every check in `shoot` passes. Once the 8 decides the game, or a
-- player presses Leave with no teammate left to play on, everyone sees who won and why, and then the game tells
-- TableService it's over.
-- ponytail: no shot clock or leaving yet; they come with later Phase 2 and Phase 3 tasks.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local EightBall = require(ReplicatedStorage.Shared.Rules.EightBall)
local Geometry = require(ReplicatedStorage.Shared.Physics.Geometry)
local PhysicsTestAccess = require(ReplicatedStorage.Shared.PhysicsTestAccess)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Simulate = require(ReplicatedStorage.Shared.Physics.Simulate)
local TableFlow = require(ReplicatedStorage.Shared.Rules.TableFlow)
local Balls = require(script.Parent.Balls)

export type Match = {
	tableModel: Model,
	-- In turn order: A1, B1, then A2 and B2 on a 2v2 table
	seats: { Player },
	-- The seat whose turn it is, and who shoots for it: its own player, or their teammate once they've left
	turnSeat: number,
	shooter: Player,
	-- The seats of 2v2 players who pressed Leave while a teammate played on. They keep their seat, so the sides stay
	-- put.
	left: { [number]: boolean },
	-- Whether the shooter may place the cue ball anywhere before their next shot, after a foul
	ballInHand: boolean,
	isBreak: boolean,
	groups: EightBall.Groups,
	-- When each player last asked for a shot, for the rate limit
	lastRequest: { [Player]: number },
	-- No more shots: the game is over, or was ended
	ended: boolean,
	connection: RBXScriptConnection?,
	-- Called once the result has shown, for TableService to end the game and re-rack
	onEnd: () -> (),
}

local Match = {}

-- The banner's words for each foul, and for how a game ended
local FOUL_TEXT: { [EightBall.Foul]: string } = {
	scratch = "cue ball in",
	nothingHit = "no ball hit",
	wrongBall = "wrong ball first",
	noRail = "no rail after contact",
}
local REASON_TEXT: { [EightBall.Reason]: string } = {
	eightPotted = "8 in the called pocket",
	eightEarly = "8 in too early",
	eightWrongPocket = "8 in the wrong pocket",
	eightOnFoul = "8 in on a foul",
}

local function log(match: Match, message: string)
	if Config.Debug.LogShots and RunService:IsStudio() then
		print(`[{match.tableModel.Name}] {message}`)
	end
end

-- A1 and A2 are side A, B1 and B2 side B. In Studio solo you're A.
local function sideOf(match: Match, player: Player): EightBall.Side
	return TableFlow.sideOf(table.find(match.seats, player) :: number)
end

-- Who shoots for a seat: its own player, or once they've left, their teammate
local function shooterFor(match: Match, seat: number): Player
	return match.seats[TableFlow.shooterSeat(seat, match.left, #match.seats)]
end

-- The seats as every screen sees them: a player who left shows as the teammate playing for them
local function seatsShown(match: Match): { Player }
	local shown = {}
	for seat in match.seats do
		shown[seat] = shooterFor(match, seat)
	end
	return shown
end

-- The ids of the balls down, for every screen's top bar
local function ballsDown(match: Match): { number }
	local down = {}
	for _, ball in Balls.get(match.tableModel) do
		if ball.pocket then
			table.insert(down, ball.id)
		end
	end
	return down
end

local function startTurn(match: Match)
	-- Tells the shooter's screen to start the shot at break power before the server's copy arrives. Display only.
	match.tableModel:SetAttribute("BreakNext", match.isBreak)
	local callPocket = EightBall.groupCleared(match.groups, sideOf(match, match.shooter), Balls.get(match.tableModel))
	Remotes.TurnStarted:FireAllClients(
		match.tableModel,
		match.shooter,
		match.ballInHand,
		seatsShown(match),
		callPocket,
		match.groups,
		ballsDown(match)
	)
end

-- The game is decided: everyone at the table sees who won and why, with nobody's turn, and then the game ends
local function finish(match: Match, winner: EightBall.Side, why: string)
	match.ended = true
	local names = {}
	for _, player in match.seats do
		if sideOf(match, player) == winner then
			table.insert(names, player.DisplayName)
		end
	end
	-- In Studio solo the one player is side A, so side B can win with nobody on it
	local text = if #names == 0
		then `{match.seats[1].DisplayName} loses: {why}`
		else `{table.concat(names, " and ")} {if #names == 1 then "wins" else "win"}: {why}`
	log(match, text)
	Remotes.Banner:FireAllClients(match.tableModel, text, Config.Timers.ResultSeconds)
	Remotes.TurnStarted:FireAllClients(
		match.tableModel,
		nil,
		false,
		seatsShown(match),
		false,
		match.groups,
		ballsDown(match)
	)
	task.delay(Config.Timers.ResultSeconds, match.onEnd)
end

local function shoot(
	match: Match,
	player: Player,
	dirX: unknown,
	dirY: unknown,
	power: unknown,
	cueX: unknown,
	cueY: unknown,
	calledPocket: unknown
)
	local tableModel = match.tableModel
	local now = os.clock()
	local isShooter = player == match.shooter
	local rolling = Balls.isRolling(tableModel)
	if
		not TableFlow.mayRequest(
			match.ended,
			isShooter,
			rolling,
			match.lastRequest[player],
			now,
			Config.Shot.RequestCooldown
		)
	then
		return
	end
	match.lastRequest[player] = now
	local params = PhysicsTestAccess.params()
	local layout = Geometry.build(params.Table)
	local side: EightBall.Side = sideOf(match, player)
	local onEight = EightBall.groupCleared(match.groups, side, Balls.get(tableModel))
	local request = TableFlow.readShot(dirX, dirY, power, calledPocket, onEight, layout)
	if not request or not Balls.placeCue(tableModel, match.ballInHand, cueX, cueY, params.Table) then
		return
	end

	match.ballInHand = false
	local called = request.calledPocket
	local shot: Simulate.Shot =
		{ dirX = request.dirX, dirY = request.dirY, power = request.power, isBreak = match.isBreak }
	match.isBreak = false
	local before = Balls.get(tableModel)
	local sim = Balls.shoot(tableModel, shot, params)
	local outcome = EightBall.resolveShot(match.groups, side, {
		isBreak = shot.isBreak == true,
		firstHit = sim.firstHit,
		dropped = Simulate.dropped(sim),
		railAfterHit = Simulate.railAfterFirstHit(sim),
		balls = before,
		calledPocket = called,
	})
	if outcome.groups[side] and not match.groups[side] then
		log(match, `{player.Name} ({side}) takes {outcome.groups[side]}`)
	end
	match.groups = outcome.groups
	if outcome.foul then
		log(match, `{player.Name} fouls: {FOUL_TEXT[outcome.foul]}`)
	end
	if outcome.keepsTurn then
		log(match, `{player.Name} keeps the turn`)
	end
	-- The same seat or the next, with ball in hand after a foul: where the cue ball stopped, or back on the head line
	-- if it went in. A shooter who left mid-shot hands it to their teammate.
	local balls = sim.balls
	match.turnSeat, match.ballInHand =
		TableFlow.afterShot(match.turnSeat, #match.seats, outcome, balls, layout, params.Table)
	match.shooter = shooterFor(match, match.turnSeat)
	if not outcome.keepsTurn and not outcome.winner then
		log(match, `turn passes to {match.shooter.Name}`)
	end
	if outcome.respotEight then
		log(match, "the 8 goes back on the foot spot")
	end
	Balls.place(tableModel, balls)
	Remotes.ShotResolved:FireAllClients(tableModel, balls)
	if match.ended then
		return
	elseif outcome.winner and outcome.reason then
		finish(match, outcome.winner, REASON_TEXT[outcome.reason])
		return
	elseif outcome.foul then
		local text = `Foul: {FOUL_TEXT[outcome.foul]}. {match.shooter.DisplayName} has ball in hand.`
		Remotes.Banner:FireAllClients(tableModel, text, Config.Timers.FoulBannerSeconds)
	end
	startTurn(match)
end

-- Racks the table and starts a game, with a random player breaking. `pick(n)` returns a random whole number from 1
-- to n. `onEnd` is called once a finished game's result has shown; it isn't called for Match.destroy.
function Match.new(tableModel: Model, seats: { Player }, pick: (number) -> number, onEnd: () -> ()): Match
	local params = PhysicsTestAccess.params()
	Balls.place(tableModel, EightBall.rack(Geometry.build(params.Table), pick))
	local breaker = pick(#seats)
	local match: Match = {
		tableModel = tableModel,
		seats = seats,
		turnSeat = breaker,
		shooter = seats[breaker],
		left = {},
		-- The break is from the middle of the head line, where the rack put the cue ball
		ballInHand = false,
		isBreak = true,
		groups = {},
		lastRequest = {},
		ended = false,
		connection = nil,
		onEnd = onEnd,
	}
	match.connection = Remotes.RequestShot.OnServerEvent:Connect(function(player: Player, ...: unknown)
		shoot(match, player, ...)
	end)
	local names = {}
	for _, player in seats do
		table.insert(names, player.Name)
	end
	log(match, `game started: {table.concat(names, ", ")}. {match.shooter.Name} breaks.`)
	startTurn(match)
	return match
end

-- A player pressed Leave mid-game. A teammate still playing carries on alone and takes their turns; with nobody left
-- on their side, the other side wins.
function Match.leave(match: Match, player: Player)
	local seat = table.find(match.seats, player) :: number
	if match.ended or match.left[seat] then
		return
	end
	match.left[seat] = true
	local teammate = TableFlow.teammateIn(seat, match.left, #match.seats)
	if teammate then
		log(match, `{player.Name} left; {match.seats[teammate].Name} plays on alone`)
		if match.shooter == player and not Balls.isRolling(match.tableModel) then
			-- Their turn, with the balls still: the teammate shoots now, and every screen drops the leaver
			match.shooter = shooterFor(match, match.turnSeat)
			startTurn(match)
		else
			-- Every other screen drops them at the next turn. A shot of theirs still rolling hands the turn on
			-- when it's done.
			Remotes.TurnStarted:FireClient(player, match.tableModel, nil, false)
		end
		return
	end
	finish(match, TableFlow.otherSide(TableFlow.sideOf(seat)), `{player.DisplayName} left`)
end

-- Ends the game at once. A shot still rolling finishes and is shown, but no turn follows it.
function Match.destroy(match: Match)
	match.ended = true
	match.tableModel:SetAttribute("BreakNext", false)
	if match.connection then
		match.connection:Disconnect()
	end
	Remotes.TurnStarted:FireAllClients(match.tableModel, nil, false)
end

return Match
