--!strict
-- One game of 8-ball on one table: who's seated, whose turn it is, ball in hand, and the shots they ask for. The
-- server is the referee: a shot only goes once every check in `shoot` passes.
-- ponytail: the rack, the break, groups and turns so far. Fouls and the 8 come with the next Phase 2 tasks.

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
	-- Whether the shooter may place the cue ball anywhere before their next shot, after a scratch
	ballInHand: boolean,
	isBreak: boolean,
	groups: EightBall.Groups,
	-- When each player last asked for a shot, for the rate limit
	lastRequest: { [Player]: number },
	ended: boolean,
	connection: RBXScriptConnection?,
}

local Match = {}

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
	Remotes.TurnStarted:FireAllClients(match.tableModel, match.shooter, match.ballInHand, match.seats)
end

local function shoot(
	match: Match,
	player: Player,
	dirX: unknown,
	dirY: unknown,
	power: unknown,
	cueX: unknown,
	cueY: unknown
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
	if not Balls.placeCue(tableModel, match.ballInHand, cueX, cueY, params.Table) then
		return
	end

	match.ballInHand = false
	local shot: Simulate.Shot = { dirX = dirX / length, dirY = dirY / length, power = power, isBreak = match.isBreak }
	match.isBreak = false
	local sim = Balls.shoot(tableModel, shot, params)
	local side = sideOf(match, player)
	local outcome = EightBall.resolveShot(
		match.groups,
		side,
		{ isBreak = shot.isBreak == true, firstHit = sim.firstHit, dropped = Simulate.dropped(sim) }
	)
	if outcome.groups[side] and not match.groups[side] then
		log(match, `{player.Name} ({side}) takes {outcome.groups[side]}`)
	end
	match.groups = outcome.groups
	if outcome.keepsTurn then
		log(match, `{player.Name} keeps the turn`)
	else
		-- Round the seats in order: A1, B1, then A2 and B2 on a 2v2 table
		match.shooter = match.seats[(table.find(match.seats, player) :: number) % #match.seats + 1]
		log(match, `turn passes to {match.shooter.Name}`)
	end
	local balls = sim.balls
	-- ponytail: until the fouls task, a sunk cue ball comes back on the head line and the next shooter gets ball in
	-- hand. The cue ball sorts first.
	local cue = balls[1]
	if cue.pocket then
		cue.pocket = nil
		cue.x, cue.y = EightBall.freeSpot(balls, Geometry.build(params.Table).headLineX, params.Table)
		match.ballInHand = true
	end
	Balls.place(tableModel, balls)
	Remotes.ShotResolved:FireAllClients(tableModel, balls)
	if not match.ended then
		startTurn(match)
	end
end

-- Racks the table and starts a game, with a random player breaking. `pick(n)` returns a random whole number from 1
-- to n.
function Match.new(tableModel: Model, seats: { Player }, pick: (number) -> number): Match
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
