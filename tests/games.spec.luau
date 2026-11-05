--!strict
-- Whole games, played by seeded bots through the real rules, physics and table flow: 1v1 and 2v2, with players
-- pressing Leave now and then. Every game must end with a winner, the turn must never get stuck, and no ball may
-- leave the table or stop being a real number.
--     lune run tests/run games                    20 games
--     GAMES=1000 lune run tests/run games         1,000 games, a few minutes
--     SEED=37 lune run tests/run games            replays one game, as a failure names it
local process = require("@lune/process")

local Config = require("../src/Shared/Config")
local EightBall = require("../src/Shared/Rules/EightBall")
local Geometry = require("../src/Shared/Physics/Geometry")
local Simulate = require("../src/Shared/Physics/Simulate")
local TableFlow = require("../src/Shared/Rules/TableFlow")

local MAX_SHOTS = 500
-- Per shot, the chance that a random player still in presses Leave
local LEAVE_CHANCE = 0.003
-- Per shot, the chance the bot aims anywhere at all rather than at a ball it may hit
local WILD_CHANCE = 0.05
-- On the 8, the chance the bot calls the pocket nearest the 8 rather than any pocket
local NEAREST_CALL_CHANCE = 0.75

-- A seeded random source, since Lune has no Random
local function random(seed: number)
	local state = seed % 2147483648
	local function float(): number
		state = (state * 1103515245 + 12345) % 2147483648
		return state / 2147483648
	end
	local function int(low: number, high: number): number
		return low + math.floor(float() * (high - low + 1))
	end
	return float, int
end

local function isFinite(value: number): boolean
	return value == value and math.abs(value) ~= math.huge
end

return function(test, check)
	local tableParams = Config.Table
	local layout = Geometry.build(tableParams)
	local radius = tableParams.BallRadius

	-- On the felt inside the cushions, or in a pocket's mouth
	local function onTable(x: number, y: number): boolean
		if
			math.abs(x) <= tableParams.Length / 2 - radius + 1e-6
			and math.abs(y) <= tableParams.Width / 2 - radius + 1e-6
		then
			return true
		end
		for _, pocket in layout.pockets do
			if (x - pocket.x) ^ 2 + (y - pocket.y) ^ 2 <= (pocket.radius + 2 * radius) ^ 2 then
				return true
			end
		end
		return false
	end

	local function ballOf(balls: { EightBall.Ball }, id: number): EightBall.Ball
		for _, ball in balls do
			if ball.id == id then
				return ball
			end
		end
		error(`no ball {id}`)
	end

	-- The balls the shooter may hit first: their group's, the 8 once it's cleared, or on an open table any but the 8
	local function targets(
		balls: { EightBall.Ball },
		groups: EightBall.Groups,
		side: EightBall.Side
	): { EightBall.Ball }
		local onEight = EightBall.groupCleared(groups, side, balls)
		local list = {}
		for _, ball in balls do
			local group = EightBall.groupOf(ball.id)
			local legal = if onEight then ball.id == 8 elseif groups[side] then group == groups[side] else group ~= nil
			if legal and not ball.pocket then
				table.insert(list, ball)
			end
		end
		return list
	end

	-- Plays one game and returns the winning side and how many shots it took
	local function play(seed: number, count: number): (EightBall.Side, number)
		local float, int = random(seed)
		local balls: { EightBall.Ball } = EightBall.rack(layout, function(n: number): number
			return int(1, n)
		end)
		local turnSeat = int(1, count)
		local left: { [number]: boolean } = {}
		local groups: EightBall.Groups = {}
		local ballInHand, isBreak = false, true

		for shots = 1, MAX_SHOTS do
			-- Now and then someone presses Leave: their teammate plays on, or with nobody left on their side, the
			-- other side wins
			if float() < LEAVE_CHANCE then
				local still = {}
				for seat = 1, count do
					if not left[seat] then
						table.insert(still, seat)
					end
				end
				local seat = still[int(1, #still)]
				left[seat] = true
				if not TableFlow.teammateIn(seat, left, count) then
					return TableFlow.otherSide(TableFlow.sideOf(seat)), shots
				end
			end

			-- Exactly one player shoots, and it's someone still in
			local shooter = TableFlow.shooterSeat(turnSeat, left, count)
			check.truthy(
				shooter >= 1 and shooter <= count and not left[shooter],
				`shot {shots}: shooter seat {shooter}`
			)
			local side = TableFlow.sideOf(shooter)
			local onEight = EightBall.groupCleared(groups, side, balls)

			-- Ball in hand: a random spot the rules allow
			local cueX, cueY = nil, nil
			if ballInHand then
				for _ = 1, 20 do
					local x, y = EightBall.nearestCueSpot(
						balls,
						(float() - 0.5) * tableParams.Length,
						(float() - 0.5) * tableParams.Width,
						tableParams
					)
					if x and y then
						cueX, cueY = x, y
						break
					end
				end
			end
			check.truthy(
				TableFlow.cueSpotAllowed(ballInHand, cueX, cueY, balls, tableParams),
				`shot {shots}: cue spot {cueX}, {cueY}`
			)
			if cueX and cueY then
				local cue = ballOf(balls, 0)
				cue.x, cue.y = cueX, cueY
			end

			-- Aim at a ball it may hit, cut a random amount, with random power, and call a pocket. Now and
			-- then it aims anywhere, for misses and scratches.
			local cue = ballOf(balls, 0)
			local aimX, aimY
			local list = if isBreak then { ballOf(balls, 1) } else targets(balls, groups, side)
			if #list > 0 and float() >= WILD_CHANCE then
				local target = list[int(1, #list)]
				local toX, toY = target.x - cue.x, target.y - cue.y
				local length = math.sqrt(toX * toX + toY * toY)
				local cut = (float() * 2 - 1) * 1.8 * radius
				aimX, aimY = toX - toY / length * cut, toY + toX / length * cut
			else
				local angle = float() * 2 * math.pi
				aimX, aimY = math.cos(angle), math.sin(angle)
			end
			local power = if isBreak then 0.3 + 0.7 * float() else 0.05 + 0.95 * float()
			local called = int(1, #layout.pockets)
			if float() < NEAREST_CALL_CHANCE then
				local eight, best = ballOf(balls, 8), math.huge
				for index, pocket in layout.pockets do
					local distSq = (pocket.x - eight.x) ^ 2 + (pocket.y - eight.y) ^ 2
					if distSq < best then
						called, best = index, distSq
					end
				end
			end
			local request = TableFlow.readShot(aimX, aimY, power, called, onEight, layout)
			check.truthy(request, `shot {shots}: the request is refused`)
			local shot = request :: TableFlow.ShotRequest

			local sim =
				Simulate.run(balls, { dirX = shot.dirX, dirY = shot.dirY, power = shot.power, isBreak = isBreak }, nil)
			local outcome = EightBall.resolveShot(groups, side, {
				isBreak = isBreak,
				firstHit = sim.firstHit,
				dropped = Simulate.dropped(sim),
				railAfterHit = Simulate.railAfterFirstHit(sim),
				balls = balls,
				calledPocket = shot.calledPocket,
			})
			isBreak = false
			groups = outcome.groups
			balls = sim.balls
			turnSeat, ballInHand = TableFlow.afterShot(turnSeat, count, outcome, balls, layout, tableParams)

			check.equal(ballInHand, outcome.foul ~= nil, `shot {shots}: ball in hand only after a foul`)
			for _, ball in balls do
				check.truthy(
					isFinite(ball.x) and isFinite(ball.y),
					`shot {shots}: ball {ball.id} at {ball.x}, {ball.y}`
				)
				if not ball.pocket then
					check.truthy(
						onTable(ball.x, ball.y),
						`shot {shots}: ball {ball.id} off the table at {ball.x}, {ball.y}`
					)
				end
			end
			if outcome.winner then
				return outcome.winner, shots
			end
			check.truthy(not ballOf(balls, 0).pocket, `shot {shots}: the cue ball is still down`)
			check.truthy(not ballOf(balls, 8).pocket, `shot {shots}: the 8 is down with the game still on`)
		end
		error(`no winner after {MAX_SHOTS} shots`)
	end

	local seeds = {}
	if process.env.SEED then
		table.insert(seeds, tonumber(process.env.SEED) :: number)
	else
		for seed = 1, tonumber(process.env.GAMES) or 20 do
			table.insert(seeds, seed)
		end
	end
	for _, seed in seeds do
		-- Odd seeds play 1v1 and even ones 2v2
		local count = if seed % 2 == 1 then 2 else 4
		test(`a random {count / 2}v{count / 2} game ends with a winner (replay with SEED={seed})`, function()
			local winner = play(seed, count)
			check.truthy(winner == "A" or winner == "B")
		end)
	end
end
