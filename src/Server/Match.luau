--!strict
-- One game of 8-ball on one table: who's seated, whose turn it is, ball in hand, and the shots they ask for. The
-- server is the referee: a shot only goes once every check in `shoot` passes. Once the 8 decides the game, everyone
-- sees who won and why, and then the game tells TableService it's over.
-- ponytail: no shot clock or leaving yet; they come with later Phase 2 and Phase 3 tasks.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local EightBall = require(ReplicatedStorage.Shared.Rules.EightBall)
local Geometry = require(ReplicatedStorage.Shared.Physics.Geometry)
local PhysicsTestAccess = require(ReplicatedStorage.Shared.PhysicsTestAccess)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Simulate = require(ReplicatedStorage.Shared.Physics.Simulate)
local Balls = require(script.Parent.Balls)

export type Match = {
	tableModel: Model,
	-- In turn order: A1, B1, then A2 and B2 on a 2v2 table
	seats: { Player },
	shooter: Player,
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

local function isFinite(value: number): boolean
	return value == value and math.abs(value) ~= math.huge
end

local function log(match: Match, message: string)
	if Config.Debug.LogShots and RunService:IsStudio() then
		print(`[{match.tableModel.Name}] {message}`)
	end
end

-- A1 and A2 are side A, B1 and B2 side B. In Studio solo you're A.
local function sideOf(match: Match, player: Player): EightBall.Side
	return if (table.find(match.seats, player) :: number) % 2 == 1 then "A" else "B"
end

local function startTurn(match: Match)
	-- ponytail: each player's group and whether it's their turn as attributes, for the card's temporary label. Display
	-- only. The top bar task sends them to everyone's screen instead.
	for _, player in match.seats do
		player:SetAttribute("Group", match.groups[sideOf(match, player)] or "open")
		player:SetAttribute("MyTurn", player == match.shooter)
	end
	-- Tells the shooter's screen to start the shot at break power before the server's copy arrives. Display only.
	match.tableModel:SetAttribute("BreakNext", match.isBreak)
	local callPocket = EightBall.groupCleared(match.groups, sideOf(match, match.shooter), Balls.get(match.tableModel))
	Remotes.TurnStarted:FireAllClients(match.tableModel, match.shooter, match.ballInHand, match.seats, callPocket)
end

-- The 8 decided the game: everyone at the table sees who won and why, with nobody's turn, and then the game ends
local function finish(match: Match, winner: EightBall.Side, reason: EightBall.Reason)
	match.ended = true
	local names = {}
	for _, player in match.seats do
		player:SetAttribute("MyTurn", false)
		if sideOf(match, player) == winner then
			table.insert(names, player.DisplayName)
		end
	end
	-- In Studio solo the one player is side A, so side B can win with nobody on it
	local text = if #names == 0
		then `{match.seats[1].DisplayName} loses: {REASON_TEXT[reason]}`
		else `{table.concat(names, " and ")} {if #names == 1 then "wins" else "win"}: {REASON_TEXT[reason]}`
	log(match, text)
	Remotes.Banner:FireAllClients(match.tableModel, text, Config.Timers.ResultSeconds)
	Remotes.TurnStarted:FireAllClients(match.tableModel, nil, false, match.seats, false)
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
	if match.ended or player ~= match.shooter or Balls.isRolling(tableModel) then
		return
	end
	local now = os.clock()
	if now - (match.lastRequest[player] or -math.huge) < Config.Shot.RequestCooldown then
		return
	end
	match.lastRequest[player] = now
	if typeof(dirX) ~= "number" or typeof(dirY) ~= "number" or typeof(power) ~= "number" then
		return
	end
	local length = math.sqrt(dirX * dirX + dirY * dirY)
	if not (isFinite(length) and length > 0 and power >= 0 and power <= 1) then
		return
	end

	local params = PhysicsTestAccess.params()
	local layout = Geometry.build(params.Table)
	local side = sideOf(match, player)
	-- On the 8, the shot must call a pocket that exists. NaN and infinity fail the whole-number check.
	local onEight = EightBall.groupCleared(match.groups, side, Balls.get(tableModel))
	local called: number? = nil
	if onEight then
		if typeof(calledPocket) ~= "number" or calledPocket % 1 ~= 0 or not layout.pockets[calledPocket] then
			return
		end
		called = calledPocket
	end
	if not Balls.placeCue(tableModel, match.ballInHand, cueX, cueY, params.Table) then
		return
	end

	match.ballInHand = false
	local shot: Simulate.Shot = { dirX = dirX / length, dirY = dirY / length, power = power, isBreak = match.isBreak }
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
	elseif not outcome.winner then
		-- Round the seats in order: A1, B1, then A2 and B2 on a 2v2 table
		match.shooter = match.seats[(table.find(match.seats, player) :: number) % #match.seats + 1]
		log(match, `turn passes to {match.shooter.Name}`)
	end
	-- After a foul the next shooter places the cue ball anywhere: where it stopped, or back on the head line if it
	-- went in. An 8 down on the break goes back first, so the cue ball keeps clear of it.
	match.ballInHand = outcome.foul ~= nil
	local balls = sim.balls
	for _, ball in balls do
		if ball.id == 8 and outcome.respotEight then
			ball.pocket = nil
			ball.x, ball.y = EightBall.spotEight(balls, params.Table)
			log(match, "the 8 goes back on the foot spot")
		end
	end
	for _, ball in balls do
		if ball.id == 0 and ball.pocket and not outcome.winner then
			ball.pocket = nil
			ball.x, ball.y = EightBall.freeSpot(balls, layout.headLineX, params.Table)
		end
	end
	Balls.place(tableModel, balls)
	Remotes.ShotResolved:FireAllClients(tableModel, balls)
	if match.ended then
		return
	elseif outcome.winner and outcome.reason then
		finish(match, outcome.winner, outcome.reason)
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
	local match: Match = {
		tableModel = tableModel,
		seats = seats,
		shooter = seats[pick(#seats)],
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

-- Ends the game at once. A shot still rolling finishes and is shown, but no turn follows it.
function Match.destroy(match: Match)
	match.ended = true
	match.tableModel:SetAttribute("BreakNext", false)
	if match.connection then
		match.connection:Disconnect()
	end
	for _, player in match.seats do
		player:SetAttribute("Group", nil)
		player:SetAttribute("MyTurn", nil)
	end
	Remotes.TurnStarted:FireAllClients(match.tableModel, nil, false)
end

return Match
