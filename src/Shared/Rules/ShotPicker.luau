--!strict
-- Picks shots for bots: Coach, who plays sensible shots, and the whole-game tests' random players. Pure Luau, so Lune
-- tests it. Randomness comes in as `float`, a function returning a number from 0 up to 1.
-- Coach looks at every ball it may hit first and every pocket, and plays the easiest pot with a clear path: the
-- smallest cut over the shortest distance, using the ghost ball (where the cue ball must touch the object ball to send
-- it at the pocket). Power is worked out from the distances and the physics' steady slowdown. A small random aim error
-- keeps it beatable. With ball in hand it places the cue ball straight behind its best pot.
-- ponytail: no banks, combos, safeties or position play, and power ignores Physics.SpeedDrag (0 today).

local EightBall = require("./EightBall")
local Geometry = require("../Physics/Geometry")
local Simulate = require("../Physics/Simulate")

local ShotPicker = {}

-- A shot as RequestShot asks for it: a direction, power 0–1, with ball in hand where the cue ball goes, and on the 8
-- the pocket called
export type Shot = { dirX: number, dirY: number, power: number, cueX: number?, cueY: number?, calledPocket: number? }

-- How Coach plays: Config.Coach
export type Skill = {
	MaxCut: number, -- degrees: the thinnest cut it tries
	AimError: number, -- degrees: its aim is off by up to this much either way
	PowerMargin: number, -- times the speed a pot needs, so the ball reaches the pocket with some to spare
	PlaceDistances: { number }, -- studs behind the ghost ball it tries to place the cue ball with ball in hand
}

-- A pot Coach could play: from where the cue ball is, at a ball, into a pocket
type Option = { dirX: number, dirY: number, power: number, pocket: number, ease: number }

local function ballOf(balls: { EightBall.Ball }, id: number): EightBall.Ball?
	for _, ball in balls do
		if ball.id == id and not ball.pocket then
			return ball
		end
	end
	return nil
end

-- The cue ball, which is always on the table between shots
function ShotPicker.cueBall(balls: { EightBall.Ball }): EightBall.Ball
	return ballOf(balls, 0) :: EightBall.Ball
end

-- The balls the shooter may hit first: on the break the whole rack, then their group's, the 8 once it's cleared, or on
-- an open table any but the 8
function ShotPicker.targets(
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

-- Whether a ball rolling from (ax, ay) to (bx, by) gets there without touching any ball still on the table, besides
-- the ones in `skip`
local function clear(
	balls: { EightBall.Ball },
	ax: number,
	ay: number,
	bx: number,
	by: number,
	skip: { [number]: boolean },
	radius: number
): boolean
	local dx, dy = bx - ax, by - ay
	local lengthSq = dx * dx + dy * dy
	for _, ball in balls do
		if not ball.pocket and not skip[ball.id] then
			local t = if lengthSq > 0 then math.clamp(((ball.x - ax) * dx + (ball.y - ay) * dy) / lengthSq, 0, 1) else 0
			local px, py = ax + dx * t - ball.x, ay + dy * t - ball.y
			if px * px + py * py < (2 * radius) ^ 2 then
				return false
			end
		end
	end
	return true
end

-- The power for a pot: enough that the object ball, taking (1 + BallBounce) / 2 of the speed along the line of
-- centers, still has PowerMargin times the speed it needs to roll into the pocket
local function potPower(
	cueDistance: number,
	ballDistance: number,
	cosCut: number,
	skill: Skill,
	params: Simulate.Params
): number
	local physics = params.Physics
	local slowdown, full = physics.RollingSlowdown, physics.FullPowerSpeed
	local ballSpeed = math.sqrt(2 * slowdown * ballDistance) * skill.PowerMargin
	local atContact = ballSpeed / ((1 + physics.BallBounce) / 2 * cosCut)
	local share = math.sqrt(atContact * atContact + 2 * slowdown * cueDistance) / full
	local soft = physics.SoftestShot
	return math.clamp((math.max(share - soft, 0) / (1 - soft)) ^ (1 / physics.PowerCurve), 0, 1)
end

-- Where to send a ball into a pocket: a side pocket's middle, or the middle of a corner pocket's mouth, between its
-- jaws. Aimed at the corner itself, a ball coming in at much more or less than 45° clips a jaw and rattles out.
local function mouth(pocket: Geometry.Pocket, tableParams: Geometry.TableParams): (number, number)
	if pocket.x == 0 then
		return pocket.x, pocket.y
	end
	local inset = tableParams.CornerPocketMouth / math.sqrt(2) / 2
	return pocket.x - math.sign(pocket.x) * inset, pocket.y - math.sign(pocket.y) * inset
end

-- Every clear pot from (cueX, cueY), easiest first
local function options(
	balls: { EightBall.Ball },
	targets: { EightBall.Ball },
	cueX: number,
	cueY: number,
	skill: Skill,
	params: Simulate.Params,
	layout: Geometry.Layout
): { Option }
	local radius = params.Table.BallRadius
	local minCos = math.cos(math.rad(skill.MaxCut))
	local list: { Option } = {}
	for _, target in targets do
		for index, pocket in layout.pockets do
			local mouthX, mouthY = mouth(pocket, params.Table)
			local toX, toY = mouthX - target.x, mouthY - target.y
			local ballDistance = math.sqrt(toX * toX + toY * toY)
			local ux, uy = toX / ballDistance, toY / ballDistance
			-- A side pocket only takes balls coming in fairly square to its rail
			local square = pocket.x ~= 0 or math.abs(uy) > 0.6
			local ghostX, ghostY = target.x - ux * 2 * radius, target.y - uy * 2 * radius
			local aimX, aimY = ghostX - cueX, ghostY - cueY
			local cueDistance = math.sqrt(aimX * aimX + aimY * aimY)
			local cosCut = if cueDistance > 0 then (aimX * ux + aimY * uy) / cueDistance else -1
			if
				square
				and cosCut >= minCos
				and clear(balls, cueX, cueY, ghostX, ghostY, { [0] = true, [target.id] = true }, radius)
				and clear(balls, target.x, target.y, mouthX, mouthY, { [0] = true, [target.id] = true }, radius)
			then
				table.insert(list, {
					dirX = aimX / cueDistance,
					dirY = aimY / cueDistance,
					power = potPower(cueDistance, ballDistance, cosCut, skill, params),
					pocket = index,
					-- Straighter and shorter is easier
					ease = cosCut * cosCut / (1 + (cueDistance + ballDistance) / params.Table.Length),
				})
			end
		end
	end
	table.sort(list, function(a: Option, b: Option): boolean
		return a.ease > b.ease
	end)
	return list
end

-- With ball in hand: the spot straight behind the easiest pot, or nil with none to be found
local function placeForPot(
	balls: { EightBall.Ball },
	targets: { EightBall.Ball },
	skill: Skill,
	params: Simulate.Params,
	layout: Geometry.Layout
): (number?, number?)
	local radius = params.Table.BallRadius
	local bestX, bestY, bestEase = nil, nil, -math.huge
	for _, target in targets do
		for _, pocket in layout.pockets do
			local mouthX, mouthY = mouth(pocket, params.Table)
			local toX, toY = mouthX - target.x, mouthY - target.y
			local length = math.sqrt(toX * toX + toY * toY)
			local ux, uy = toX / length, toY / length
			for _, back in skill.PlaceDistances do
				local x, y = target.x - ux * (2 * radius + back), target.y - uy * (2 * radius + back)
				if EightBall.canPlaceCue(balls, x, y, params.Table) then
					local best = options(balls, { target }, x, y, skill, params, layout)[1]
					if best and best.ease > bestEase then
						bestX, bestY, bestEase = x, y, best.ease
					end
				end
			end
		end
	end
	return bestX, bestY
end

-- The pocket nearest the 8, called when no pot on it is clear
local function nearestPocket(balls: { EightBall.Ball }, layout: Geometry.Layout): number
	local eight = ballOf(balls, 8)
	local best, bestSq = 1, math.huge
	for index, pocket in layout.pockets do
		local distSq = if eight then (pocket.x - eight.x) ^ 2 + (pocket.y - eight.y) ^ 2 else 0
		if distSq < bestSq then
			best, bestSq = index, distSq
		end
	end
	return best
end

-- Coach's shot. On the break it hits the rack at full power. Otherwise it plays the easiest clear pot, or with none,
-- hits a ball it may hit fairly at medium power, so it doesn't foul.
function ShotPicker.coach(
	balls: { EightBall.Ball },
	groups: EightBall.Groups,
	side: EightBall.Side,
	isBreak: boolean,
	ballInHand: boolean,
	skill: Skill,
	params: Simulate.Params,
	float: () -> number
): Shot
	local layout = Geometry.build(params.Table)
	local cue = ballOf(balls, 0) :: EightBall.Ball
	local cueX, cueY = cue.x, cue.y
	if isBreak then
		local apex = layout.rack[1]
		local dx, dy = apex.x - cueX, apex.y - cueY
		local length = math.sqrt(dx * dx + dy * dy)
		return { dirX = dx / length, dirY = dy / length, power = 1 }
	end
	local targets = ShotPicker.targets(balls, groups, side)
	local placedX, placedY = nil, nil
	if ballInHand then
		placedX, placedY = placeForPot(balls, targets, skill, params, layout)
		if placedX and placedY then
			cueX, cueY = placedX, placedY
		end
	end
	local onEight = EightBall.groupCleared(groups, side, balls)
	local best = options(balls, targets, cueX, cueY, skill, params, layout)[1]
	local dirX, dirY, power, called
	if best then
		dirX, dirY, power, called = best.dirX, best.dirY, best.power, best.pocket
	else
		-- Nothing to pot: hit the nearest ball it may hit, full on, best one with nothing in the way
		local radius = params.Table.BallRadius
		local nearest, nearestScore = nil, math.huge
		for _, target in targets do
			local score = (target.x - cueX) ^ 2 + (target.y - cueY) ^ 2
			if not clear(balls, cueX, cueY, target.x, target.y, { [0] = true, [target.id] = true }, radius) then
				score += params.Table.Length ^ 2
			end
			if score < nearestScore then
				nearest, nearestScore = target, score
			end
		end
		local toX, toY = if nearest then nearest.x - cueX else 1, if nearest then nearest.y - cueY else 0
		local length = math.sqrt(toX * toX + toY * toY)
		dirX, dirY, power, called = toX / length, toY / length, 0.5, nearestPocket(balls, layout)
	end
	-- Off by a little, either way
	local miss = math.rad(skill.AimError) * (2 * float() - 1)
	local cos, sin = math.cos(miss), math.sin(miss)
	return {
		dirX = dirX * cos - dirY * sin,
		dirY = dirX * sin + dirY * cos,
		power = power,
		cueX = placedX,
		cueY = placedY,
		calledPocket = if onEight then called else nil,
	}
end

return ShotPicker
