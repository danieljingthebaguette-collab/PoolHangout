--!strict
-- 8-ball rules in table space (see GAME_SPEC.md and ARCHITECTURE.md), in plain Luau so Lune can test them.
-- Randomness comes in as arguments: the server picks, and tests choose.

local Geometry = require("../Physics/Geometry")
local Simulate = require("../Physics/Simulate")

export type Ball = Simulate.Ball
export type Side = "A" | "B"
export type Group = "solids" | "stripes"
-- The group each side plays. Empty while the table is open; once one side has a group, so does the other.
export type Groups = { [Side]: Group }
-- What the rules need from a finished shot: whether it was the break, the first ball the cue ball touched (nil if
-- none), the balls it dropped in order, whether any ball touched a rail after the cue ball's first hit, the balls as
-- they stood before it, and the pocket called for the 8 (nil unless the shooter was on the 8)
export type ShotFacts = {
	isBreak: boolean,
	firstHit: number?,
	dropped: { { id: number, pocket: number } },
	railAfterHit: boolean,
	balls: { Ball },
	calledPocket: number?,
}
export type Foul = "scratch" | "nothingHit" | "wrongBall" | "noRail"
-- How a game ended: the 8 legally in the called pocket wins, and the rest lose
export type Reason = "eightPotted" | "eightEarly" | "eightWrongPocket" | "eightOnFoul"
-- What a shot decided: the groups after it, whether the shooter keeps the turn, any foul (the next shooter gets ball
-- in hand), the winning side and why once the game is over, and whether the 8 goes back on the foot spot
export type Outcome = {
	groups: Groups,
	keepsTurn: boolean,
	foul: Foul?,
	winner: Side?,
	reason: Reason?,
	respotEight: boolean,
}

-- Rack spots in Geometry's order, the apex first and then row by row toward the foot rail: the middle of the third
-- row, and the back row's two ends
local EIGHT_SPOT = 5
local BACK_CORNERS = { 11, 15 }
-- How many times nearestCueSpot pushes the cue ball off what it overlaps before giving up
local PUSHES = 4
-- Share of a ball radius left clear when a ball is placed beside another. Far more than the rounding in the
-- ball positions a screen sees, so the server, checking exact positions, agrees the spot is clear.
local CLEARANCE = 1e-3

local EightBall = {}

-- Every ball racked for a new game, sorted by id: the 8 in the middle, a solid and a stripe in the back corners
-- (which corner each gets is random too), the rest in random order, and the cue ball in the middle of the head
-- line. `pick(n)` returns a random whole number from 1 to n.
function EightBall.rack(layout: Geometry.Layout, pick: (number) -> number): { Simulate.Ball }
	local solids, stripes = { 1, 2, 3, 4, 5, 6, 7 }, { 9, 10, 11, 12, 13, 14, 15 }
	local corners = { table.remove(solids, pick(#solids)) :: number, table.remove(stripes, pick(#stripes)) :: number }
	if pick(2) == 2 then
		corners[1], corners[2] = corners[2], corners[1]
	end
	local rest = table.move(stripes, 1, #stripes, #solids + 1, solids)
	for i = #rest, 2, -1 do
		local j = pick(i)
		rest[i], rest[j] = rest[j], rest[i]
	end

	local ids: { [number]: number } =
		{ [EIGHT_SPOT] = 8, [BACK_CORNERS[1]] = corners[1], [BACK_CORNERS[2]] = corners[2] }
	local balls: { Simulate.Ball } = { { id = 0, x = layout.headLineX, y = 0, vx = 0, vy = 0 } }
	for spot, position in layout.rack do
		local id = ids[spot] or table.remove(rest) :: number
		table.insert(balls, { id = id, x = position.x, y = position.y, vx = 0, vy = 0 })
	end
	table.sort(balls, function(a: Simulate.Ball, b: Simulate.Ball): boolean
		return a.id < b.id
	end)
	return balls
end

-- Whether the cue ball may be placed with its center at (x, y) with ball in hand, which is anywhere on the felt
-- inside the cushions, out of every pocket's mouth and clear of every other ball still on the table. Written so a NaN
-- or infinite spot never passes.
function EightBall.canPlaceCue(balls: { Ball }, x: number, y: number, tableParams: Geometry.TableParams): boolean
	local radius = tableParams.BallRadius
	if not (math.abs(x) <= tableParams.Length / 2 - radius and math.abs(y) <= tableParams.Width / 2 - radius) then
		return false
	end
	for _, pocket in Geometry.build(tableParams).pockets do
		if (x - pocket.x) ^ 2 + (y - pocket.y) ^ 2 < pocket.radius * pocket.radius then
			return false
		end
	end
	local diameter = 2 * radius
	for _, ball in balls do
		if ball.id ~= 0 and not ball.pocket and (ball.x - x) ^ 2 + (ball.y - y) ^ 2 < diameter * diameter then
			return false
		end
	end
	return true
end

-- The allowed spot for the cue ball nearest to (x, y), for ball in hand: kept inside the cushions, and pushed
-- straight off any ball or pocket mouth it would overlap. Nil if none turns up, like deep in a cluster.
function EightBall.nearestCueSpot(
	balls: { Ball },
	x: number,
	y: number,
	tableParams: Geometry.TableParams
): (number?, number?)
	local radius = tableParams.BallRadius
	local layout = Geometry.build(tableParams)
	local edgeX, edgeY = tableParams.Length / 2 - radius, tableParams.Width / 2 - radius
	-- Circles the cue ball's center has to stay out of: around every ball still on the table, and each pocket's mouth
	local circles: { { x: number, y: number, reach: number } } = {}
	for _, ball in balls do
		if ball.id ~= 0 and not ball.pocket then
			table.insert(circles, { x = ball.x, y = ball.y, reach = 2 * radius })
		end
	end
	for _, pocket in layout.pockets do
		table.insert(circles, { x = pocket.x, y = pocket.y, reach = pocket.radius })
	end
	for _ = 1, PUSHES do
		x, y = math.clamp(x, -edgeX, edgeX), math.clamp(y, -edgeY, edgeY)
		if EightBall.canPlaceCue(balls, x, y, tableParams) then
			return x, y
		end
		for _, circle in circles do
			local dx, dy = x - circle.x, y - circle.y
			local distSq = dx * dx + dy * dy
			if distSq < circle.reach * circle.reach then
				local dist = math.sqrt(distSq)
				-- From the very middle, any way out will do: toward the head rail
				if dist == 0 then
					dx, dist = -1, 1
				end
				local out = circle.reach + CLEARANCE * radius
				x, y = circle.x + dx / dist * out, circle.y + dy / dist * out
			end
		end
	end
	return nil, nil
end

-- The first spot on the line across the table at `x` where the cue ball overlaps no other ball: the middle, then
-- out to either side a ball's width at a time. Where a sunk cue ball comes back.
function EightBall.freeSpot(balls: { Ball }, x: number, tableParams: Geometry.TableParams): (number, number)
	local diameter = 2 * tableParams.BallRadius
	local steps = math.floor((tableParams.Width / 2 - tableParams.BallRadius) / diameter)
	for i = 0, 2 * steps do
		local y = (if i % 2 == 0 then 1 else -1) * math.ceil(i / 2) * diameter
		local clear = true
		for _, ball in balls do
			if ball.id ~= 0 and not ball.pocket and (ball.x - x) ^ 2 + (ball.y - y) ^ 2 < diameter * diameter then
				clear = false
				break
			end
		end
		if clear then
			return x, y
		end
	end
	return x, 0
end

-- Solids are 1–7 and stripes 9–15. The cue ball and the 8 are in neither.
function EightBall.groupOf(id: number): Group?
	if id >= 1 and id <= 7 then
		return "solids"
	elseif id >= 9 and id <= 15 then
		return "stripes"
	end
	return nil
end

-- Whether `side` has a group and none of its balls is left on the table, so it shoots at the 8
function EightBall.groupCleared(groups: Groups, side: Side, balls: { Ball }): boolean
	local group = groups[side]
	if not group then
		return false
	end
	for _, ball in balls do
		if not ball.pocket and EightBall.groupOf(ball.id) == group then
			return false
		end
	end
	return true
end

-- Where the 8 comes back after dropping on the break: the foot spot, or with a ball in the way, the nearest clear
-- spot behind it on the line down the table's middle, toward the foot rail. With no room there, the nearest in front.
function EightBall.spotEight(balls: { Ball }, tableParams: Geometry.TableParams): (number, number)
	local radius = tableParams.BallRadius
	local diameter = 2 * radius
	local footX = tableParams.Length / 4
	local edge = tableParams.Length / 2 - radius
	for _, direction in { 1, -1 } do
		local x = footX
		-- Each move only goes one way, past the ball in the way, so every ball moves it at most once
		local moved = true
		while moved and math.abs(x) <= edge do
			moved = false
			for _, ball in balls do
				local reachSq = diameter * diameter - ball.y * ball.y
				if ball.id ~= 8 and not ball.pocket and reachSq > 0 then
					local reach = math.sqrt(reachSq)
					if math.abs(ball.x - x) < reach then
						x = ball.x + direction * (reach + CLEARANCE * radius)
						moved = true
					end
				end
			end
		end
		if math.abs(x) <= edge then
			return x, 0
		end
	end
	return footX, 0
end

-- What a finished shot by `side` decided. Leaves `groups` as it was.
function EightBall.resolveShot(groups: Groups, side: Side, facts: ShotFacts): Outcome
	local outcome: Outcome = { groups = table.clone(groups), keepsTurn = false, respotEight = false }
	local scratched, eightPocket = false, nil
	for _, drop in facts.dropped do
		if drop.id == 0 then
			scratched = true
		elseif drop.id == 8 then
			eightPocket = drop.pocket
		end
	end
	-- Any break counts, so only a scratch fouls it, and a dropped 8 comes back. Any ball down keeps the turn, unless
	-- the cue ball went in too. The table stays open either way.
	if facts.isBreak then
		outcome.foul = if scratched then "scratch" else nil
		outcome.respotEight = eightPocket ~= nil
		outcome.keepsTurn = #facts.dropped > 0 and not scratched
		return outcome
	end

	-- The cue ball must first hit one of the shooter's group, the 8 once that's cleared, or on an open table any ball
	-- but the 8. Then a ball must drop or touch a rail.
	local group = groups[side]
	local onEight = EightBall.groupCleared(groups, side, facts.balls)
	local first = facts.firstHit
	local firstGroup = if first then EightBall.groupOf(first) else nil
	local legalFirst = if onEight then first == 8 elseif group then firstGroup == group else firstGroup ~= nil
	local foul: Foul? = if scratched
		then "scratch"
		elseif first == nil then "nothingHit"
		elseif not legalFirst then "wrongBall"
		elseif #facts.dropped == 0 and not facts.railAfterHit then "noRail"
		else nil
	outcome.foul = foul

	-- The 8 going in ends the game: a win only on a legal shot, once the group is cleared, into the called pocket.
	-- Clearing the group on the same shot is too early.
	if eightPocket then
		local reason: Reason = if not onEight
			then "eightEarly"
			elseif foul then "eightOnFoul"
			elseif eightPocket ~= facts.calledPocket then "eightWrongPocket"
			else "eightPotted"
		outcome.reason = reason
		outcome.winner = if reason == "eightPotted" then side elseif side == "A" then "B" else "A"
		return outcome
	end
	-- Balls that drop on a foul stay down, but never set a group or keep the turn
	if foul then
		return outcome
	end
	for _, drop in facts.dropped do
		local dropGroup: Group? = EightBall.groupOf(drop.id)
		-- On an open table the first ball to drop decides the groups, even if both kinds went in
		if not group and dropGroup then
			group = dropGroup
			outcome.groups[side] = dropGroup
			local otherSide: Side = if side == "A" then "B" else "A"
			outcome.groups[otherSide] = if dropGroup == "solids" then "stripes" else "solids"
		end
		-- A legal pot of your own group keeps the turn, including the one that just set it
		outcome.keepsTurn = outcome.keepsTurn or (dropGroup ~= nil and dropGroup == group)
	end
	return outcome
end

return EightBall
