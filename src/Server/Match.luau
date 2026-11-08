--!strict
-- One game of 8-ball on one table: who's seated, whose turn it is, ball in hand, and the shots they ask for. The
-- server is the referee: a shot only goes once every check in `shoot` passes. Once the 8 decides the game, or a
-- player presses Leave with no teammate left to play on, its players see the end screen, with who won and why and each
-- player's stats, and anyone else near the table sees the result as a banner. When every player still in presses
-- Rematch, or the end screen's time is up, the game tells TableService, which starts the rematch or ends the game.
-- Each turn has a shot clock: running out is a foul. A seat can hold Coach, the bot (Seat.luau), which plays its turns
-- here with ShotPicker's shots, through the same checks as a player's.
-- ponytail: no takeovers, or removal after 2 timeouts in a row, until Phase 4's leaving rules.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local EightBall = require(ReplicatedStorage.Shared.Rules.EightBall)
local Geometry = require(ReplicatedStorage.Shared.Physics.Geometry)
local PhysicsTestAccess = require(ReplicatedStorage.Shared.PhysicsTestAccess)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Seat = require(ReplicatedStorage.Shared.Seat)
local ShotPicker = require(ReplicatedStorage.Shared.Rules.ShotPicker)
local ShotStance = require(ReplicatedStorage.Shared.ShotStance)
local Simulate = require(ReplicatedStorage.Shared.Physics.Simulate)
local TableFlow = require(ReplicatedStorage.Shared.Rules.TableFlow)
local TableSpace = require(ReplicatedStorage.Shared.TableSpace)
local Balls = require(script.Parent.Balls)

export type Match = {
	tableModel: Model,
	-- In turn order: A1, B1, then A2 and B2 on a 2v2 table
	seats: { Seat.Seat },
	-- The seat whose turn it is, and who shoots for it: its own player, or their teammate once they've left
	turnSeat: number,
	shooter: Seat.Seat,
	-- The seats of 2v2 players who pressed Leave while a teammate played on. They keep their seat, so the sides stay
	-- put.
	left: { [number]: boolean },
	-- Whether the shooter may place the cue ball anywhere before their next shot, after a foul
	ballInHand: boolean,
	-- When the turn's shot clock runs out, in the server's time, and a token for it while it runs: a timer that finds
	-- another token, or none because the shot went, does nothing
	clockEndsAt: number,
	clock: {}?,
	isBreak: boolean,
	groups: EightBall.Groups,
	-- When each player last asked for a shot, for the rate limit
	lastRequest: { [Seat.Seat]: number },
	-- No more shots: the game is over, or was ended
	ended: boolean,
	-- The game's RequestShot and AimUpdate connections, and when the shooter's last live aim was passed on
	connection: RBXScriptConnection?,
	aimConnection: RBXScriptConnection?,
	lastAim: number,
	-- Each player's stats for the end screen
	stats: { [Seat.Seat]: EightBall.Stats },
	-- Once the game is over, each player's answer on the end screen: true for Rematch, false for Back to lobby. Closed
	-- once the end screen is done with, after which nothing more happens.
	votes: { [Seat.Seat]: boolean },
	closed: boolean,
	-- Called once the end screen closes, for TableService to start the rematch or end the game and re-rack
	onEnd: (rematch: boolean) -> (),
}

local Match = {}

-- Coach's aim error
local random = Random.new()

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

-- Whether a player is in this game and hasn't pressed Leave
local function playing(match: Match, player: Seat.Seat): boolean
	local seat = table.find(match.seats, player)
	return seat ~= nil and not match.left[seat]
end

-- A1 and A2 are side A, B1 and B2 side B. In Studio solo you're A.
local function sideOf(match: Match, player: Seat.Seat): EightBall.Side
	return TableFlow.sideOf(table.find(match.seats, player) :: number)
end

-- Who shoots for a seat: its own player, or once they've left, their teammate
local function shooterFor(match: Match, seat: number): Seat.Seat
	return match.seats[TableFlow.shooterSeat(seat, match.left, #match.seats)]
end

-- The seats as every screen sees them: a player who left shows as the teammate playing for them
local function seatsShown(match: Match): { Seat.Seat }
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

-- TurnStarted's values for the game as it stands. Once it's over, nobody shoots while its result shows.
local function turnMessage(match: Match): ...any
	local shooter = if match.ended then nil else match.shooter
	local callPocket = shooter ~= nil
		and EightBall.groupCleared(match.groups, sideOf(match, shooter), Balls.get(match.tableModel))
	return match.tableModel,
		shooter,
		shooter ~= nil and match.ballInHand,
		seatsShown(match),
		callPocket,
		match.groups,
		ballsDown(match),
		if shooter then match.clockEndsAt else nil
end

local startTurn: (Match) -> ()

-- The shot clock ran out: a foul, so the turn passes with ball in hand, or on the break the next player breaks
local function timeOut(match: Match)
	if match.ended then
		return
	end
	log(match, `{match.shooter.Name} ran out of time`)
	EightBall.countTimeout(match.stats[match.shooter])
	local wasBreak = match.isBreak
	match.turnSeat, match.ballInHand = TableFlow.afterTimeout(match.turnSeat, #match.seats, match.isBreak)
	match.shooter = shooterFor(match, match.turnSeat)
	local name = Seat.name(match.shooter)
	local text = if wasBreak then `Time's up. {name} breaks.` else `Time's up. {name} has ball in hand.`
	Remotes.Banner:FireAllClients(match.tableModel, text, Config.Timers.FoulBannerSeconds)
	startTurn(match)
end

local shoot: (Match, Seat.Seat, ...unknown) -> ()

-- Sends the shooter's live aim to every screen but their own, for anyone in the top-down view to draw
function Match.sendAim(match: Match, state: TableFlow.AimState)
	for _, other: Seat.Seat in Players:GetPlayers() do
		if other ~= match.shooter and other:IsA("Player") then
			Remotes.AimRelay:FireClient(other, match.tableModel, state)
		end
	end
end

-- Each Coach figure's current glide, so a newer one takes over
local glides: { [Model]: {} } = {}

-- Glides a Coach figure to (toX, toY) in table space, standing on top of the table when that's over it, facing
-- (faceX, faceY), at Config.Stance's speeds. Its figure is anchored, so it glides; every screen poses it once it stands
-- still.
local function glideCoach(match: Match, bot: Model, toX: number, toY: number, faceX: number, faceY: number)
	local token = {}
	glides[bot] = token
	local felt = match.tableModel:FindFirstChild("Felt") :: BasePart
	local seats = match.tableModel:FindFirstChild("Seats")
	local marker = seats and seats:FindFirstChild("A1")
	local root = bot:FindFirstChild("HumanoidRootPart") :: BasePart
	local stance = Config.Stance
	local halfX, halfY = Config.Table.Length / 2 + stance.TableEdge, Config.Table.Width / 2 + stance.TableEdge
	-- Its root's height standing there: on the table, or on the floor where the seat markers lie, on 2-stud R6 legs
	local toHeight = if ShotStance.overTable(toX, toY, halfX, halfY) or not (marker and marker:IsA("BasePart"))
		then felt.Position.Y + felt.Size.Y / 2 + stance.TableStandHeight
		else marker.Position.Y + marker.Size.Y / 2
	toHeight += 2 + root.Size.Y / 2
	local ball = TableSpace.toWorld(felt, faceX, faceY, 0).Position
	task.spawn(function()
		while glides[bot] == token and bot.Parent do
			local dt = task.wait()
			local at = bot:GetPivot().Position
			local x, y = TableSpace.toTable(felt, at)
			local newX, newY, height =
				ShotStance.step(x, y, at.Y, toX, toY, toHeight, stance.Speed, stance.Climb, dt)
			local spot = TableSpace.toWorld(felt, newX, newY, 0).Position
			local position = Vector3.new(spot.X, height, spot.Z)
			bot:PivotTo(CFrame.lookAt(position, Vector3.new(ball.X, height, ball.Z)))
			if newX == toX and newY == toY and height == toHeight then
				break
			end
		end
		if glides[bot] == token then
			glides[bot] = nil
		end
	end)
end

-- Every Coach that isn't shooting goes back to its seat's spot, facing the table, out of the shooter's way; once the
-- game is over, every Coach does
local function seatCoaches(match: Match)
	local felt = match.tableModel:FindFirstChild("Felt") :: BasePart
	local seats = match.tableModel:FindFirstChild("Seats")
	for seat, occupant in match.seats do
		local marker = seats and seats:FindFirstChild(TableFlow.SEAT_NAMES[seat])
		local shooting = occupant == match.shooter and not match.ended
		if not shooting and occupant:IsA("Model") and marker and marker:IsA("BasePart") then
			local x, y = TableSpace.toTable(felt, marker.Position)
			glideCoach(match, occupant, x, y, 0, 0)
		end
	end
end

-- Coach's turn, slow enough to follow, with its aim showing live: it waits ReadySeconds (with ball in hand, holding the
-- cue ball where it'll go), swings its aim onto its shot over AimSeconds, draws the cue back over PullSeconds, then
-- shoots through the same checks as a player's shot. A turn that's over by then (the game ended) stops it.
local function botTurn(match: Match, clock: {})
	local bot = match.shooter
	local float = function(): number
		return random:NextNumber()
	end
	local shot = ShotPicker.coach(
		Balls.get(match.tableModel),
		match.groups,
		sideOf(match, bot),
		match.isBreak,
		match.ballInHand,
		Config.Coach,
		PhysicsTestAccess.params(),
		float
	)
	local coach = Config.Coach
	local aim = math.atan2(shot.dirY, shot.dirX)
	if bot:IsA("Model") then
		-- It goes to stand behind the cue ball, where it'll place it with ball in hand
		local cue = ShotPicker.cueBall(Balls.get(match.tableModel))
		local cueX, cueY = shot.cueX or cue.x, shot.cueY or cue.y
		local spot = ShotStance.spot(cueX, cueY, aim, Config.Stance.Distance)
		glideCoach(match, bot, spot.x, spot.y, cueX, cueY)
	end
	local fromAim = aim + math.rad(coach.AimSwing) * (if random:NextNumber() < 0.5 then -1 else 1)
	task.spawn(function()
		local started = os.clock()
		while match.clock == clock do
			local t = os.clock() - started
			local aiming = math.clamp((t - coach.ReadySeconds) / coach.AimSeconds, 0, 1)
			local drawing = math.clamp((t - coach.ReadySeconds - coach.AimSeconds) / coach.PullSeconds, 0, 1)
			-- Easing in, so it settles onto the shot
			local settled = 1 - (1 - aiming) ^ 2
			Match.sendAim(match, {
				aim = (fromAim + (aim - fromAim) * settled) % (2 * math.pi),
				pull = drawing * shot.power,
				held = drawing > 0,
				placing = shot.cueX ~= nil and t < coach.ReadySeconds,
				cueX = shot.cueX,
				cueY = shot.cueY,
				pocket = shot.calledPocket,
			})
			if t >= coach.ReadySeconds + coach.AimSeconds + coach.PullSeconds then
				break
			end
			task.wait(1 / Config.Aim.RelayRate)
		end
		if match.clock == clock then
			shoot(match, bot, shot.dirX, shot.dirY, shot.power, shot.cueX, shot.cueY, shot.calledPocket)
		end
	end)
end

function startTurn(match: Match)
	-- Tells the shooter's screen to start the shot at break power before the server's copy arrives. Display only.
	match.tableModel:SetAttribute("BreakNext", match.isBreak)
	local clock = {}
	match.clock = clock
	match.clockEndsAt = workspace:GetServerTimeNow() + Config.Shot.ClockSeconds
	task.delay(Config.Shot.ClockSeconds, function()
		if match.clock == clock then
			timeOut(match)
		end
	end)
	Remotes.TurnStarted:FireAllClients(turnMessage(match))
	seatCoaches(match)
	if Seat.isBot(match.shooter) then
		botTurn(match, clock)
	end
end

-- The shooter's screen sent where they're aiming. Display only, so a bad or late one is simply dropped.
local function relayAim(match: Match, player: Seat.Seat, ...: unknown)
	local now = os.clock()
	if
		match.ended
		or player ~= match.shooter
		or Balls.isRolling(match.tableModel)
		or now - match.lastAim < Config.Aim.RelayMinGap
	then
		return
	end
	match.lastAim = now
	local tableParams = PhysicsTestAccess.params().Table
	local aim, pull, held, placing, cueX, cueY, pocket = ...
	local state = TableFlow.readAim(
		aim,
		pull,
		held,
		placing,
		cueX,
		cueY,
		pocket,
		match.ballInHand,
		Geometry.build(tableParams),
		tableParams
	)
	if state then
		Match.sendAim(match, state)
	end
end

-- The end screen closes, once: with a rematch, or with the game ending
local function close(match: Match, rematch: boolean)
	if match.closed then
		return
	end
	match.closed = true
	match.onEnd(rematch)
end

-- The game is decided, and nobody's turn is on. Its players see the end screen; anyone else gets a banner.
local function finish(match: Match, winner: EightBall.Side, why: string)
	match.ended = true
	local names = {}
	for _, player in match.seats do
		if sideOf(match, player) == winner then
			table.insert(names, Seat.name(player))
		end
	end
	-- In Studio solo the one player is side A, so side B can win with nobody on it
	local text = if #names == 0
		then `{Seat.name(match.seats[1])} loses: {why}`
		else `{table.concat(names, " and ")} {if #names == 1 then "wins" else "win"}: {why}`
	log(match, text)
	Remotes.TurnStarted:FireAllClients(turnMessage(match))
	seatCoaches(match)
	local rows = {}
	for seat, player in match.seats do
		local stats = match.stats[player]
		table.insert(rows, {
			player = player,
			side = TableFlow.sideOf(seat),
			shots = stats.shots,
			kept = stats.kept,
			sunk = stats.sunk,
			bestRun = stats.bestRun,
			fouls = stats.fouls,
		})
	end
	-- A rematch needs every player, so not after someone pressed Leave
	local canRematch = next(match.left) == nil
	local closesAt = workspace:GetServerTimeNow() + Config.Timers.EndScreenSeconds
	for _, player in Players:GetPlayers() do
		if playing(match, player) then
			Remotes.GameOver:FireClient(player, match.tableModel, text, winner, rows, canRematch, closesAt)
		else
			Remotes.Banner:FireClient(player, match.tableModel, text, Config.Timers.ResultSeconds)
		end
	end
	task.delay(Config.Timers.EndScreenSeconds, close, match, false)
	-- Coach always wants a rematch
	for _, seat in match.seats do
		if Seat.isBot(seat) then
			Match.vote(match, seat, true)
		end
	end
end

function shoot(
	match: Match,
	player: Seat.Seat,
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

	-- The shot goes, so the clock stops
	match.clock = nil
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
	EightBall.countShot(match.stats[player], side, outcome, Simulate.dropped(sim))
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
		local text = `Foul: {FOUL_TEXT[outcome.foul]}. {Seat.name(match.shooter)} has ball in hand.`
		Remotes.Banner:FireAllClients(tableModel, text, Config.Timers.FoulBannerSeconds)
	end
	startTurn(match)
end

-- Racks the table and starts a game, with a random player breaking. `pick(n)` returns a random whole number from 1
-- to n. `onEnd` is called once a finished game's end screen closes, with whether every player pressed Rematch; it isn't
-- called for Match.destroy.
function Match.new(
	tableModel: Model,
	seats: { Seat.Seat },
	pick: (number) -> number,
	onEnd: (rematch: boolean) -> ()
): Match
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
		clockEndsAt = 0,
		clock = nil,
		isBreak = true,
		groups = {},
		lastRequest = {},
		ended = false,
		connection = nil,
		aimConnection = nil,
		lastAim = -math.huge,
		stats = {},
		votes = {},
		closed = false,
		onEnd = onEnd,
	}
	for _, player in seats do
		match.stats[player] = EightBall.newStats()
	end
	match.connection = Remotes.RequestShot.OnServerEvent:Connect(function(player: Player, ...: unknown)
		shoot(match, player, ...)
	end)
	match.aimConnection = Remotes.AimUpdate.OnServerEvent:Connect(function(player: Player, ...: unknown)
		relayAim(match, player, ...)
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
	finish(match, TableFlow.otherSide(TableFlow.sideOf(seat)), `{Seat.name(player)} left`)
end

-- An answer on the end screen, from a player still in the game: Rematch (true) or Back to lobby (false), once each.
-- Every player still in hears who has answered, and once they've all pressed Rematch, it starts.
function Match.vote(match: Match, player: Seat.Seat, rematch: unknown)
	if
		not match.ended
		or match.closed
		or type(rematch) ~= "boolean"
		or not playing(match, player)
		or match.votes[player] ~= nil
	then
		return
	end
	match.votes[player] = rematch
	local answers = {}
	for who, answer in match.votes do
		table.insert(answers, { player = who, rematch = answer })
	end
	local everyone = next(match.left) == nil
	for _, other in match.seats do
		everyone = everyone and match.votes[other] == true
		if playing(match, other) and other:IsA("Player") then
			Remotes.Rematch:FireClient(other, match.tableModel, answers)
		end
	end
	if everyone then
		close(match, true)
	end
end

-- Tells one screen about the game as it stands, for a player who joined the server after it started
function Match.showTo(match: Match, player: Player)
	Remotes.TurnStarted:FireClient(player, turnMessage(match))
end

-- Ends the game at once. A shot still rolling finishes and is shown, but no turn follows it.
function Match.destroy(match: Match)
	match.ended = true
	match.closed = true
	match.tableModel:SetAttribute("BreakNext", false)
	if match.connection then
		match.connection:Disconnect()
	end
	if match.aimConnection then
		match.aimConnection:Disconnect()
	end
	Remotes.TurnStarted:FireAllClients(match.tableModel, nil, false)
end

return Match
