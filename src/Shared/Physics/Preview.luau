--!strict
-- Where a shot's cue ball first touches something, for the aim indicator. It follows the cue ball's straight
-- path with the same contacts Simulate uses (balls, rails with their ends as jaws, pockets, and the felt's
-- edge), worked out exactly instead of step by step. For a ball, it also works out where each ball goes after the
-- hit with Simulate's own rule, so the indicator shows the cue ball's slight drift forward too.

local Geometry = require("./Geometry")

export type Ball = { id: number, x: number, y: number, pocket: number? }
-- What a hit sends each ball. `cueX, cueY` is the unit direction the cue ball leaves in, and `cueShare` and
-- `ballShare` the shares of the cue ball's speed at the contact that the cue ball keeps and the hit ball gets.
export type Hit = { cueX: number, cueY: number, cueShare: number, ballShare: number }
-- `x, y` is the cue ball's center at the contact. For a ball, `ball` is its id, `pushX, pushY` the unit
-- direction it gets sent (along the line between the centers, as in Simulate's equal-mass hit), and `hit` what
-- each ball gets.
export type Contact = {
	kind: "ball" | "rail" | "pocket",
	x: number,
	y: number,
	ball: number?,
	pushX: number?,
	pushY: number?,
	hit: Hit?,
}
-- The physics settings a hit depends on: Config.Physics, or the params a shot will use
export type HitParams = { BallBounce: number, Follow: number }

local Preview = {}

-- How far along the unit direction (dx, dy) from (x, y) until the point comes within `reach` of (cx, cy).
-- Starting already within counts only while heading closer, the way Simulate needs two balls to be closing.
local function reachPoint(x: number, y: number, dx: number, dy: number, cx: number, cy: number, reach: number): number?
	local fx, fy = x - cx, y - cy
	local along = fx * dx + fy * dy
	local gap = fx * fx + fy * fy - reach * reach
	if gap <= 0 then
		return if along < 0 then 0 else nil
	end
	local disc = along * along - gap
	if along >= 0 or disc < 0 then
		return nil
	end
	return -along - math.sqrt(disc)
end

-- How far until the point comes within `reach` of the rail. Simulate clamps the closest point to the rail's
-- ends, so near an end the rail is round.
local function reachRail(x: number, y: number, dx: number, dy: number, rail: Geometry.Rail, reach: number): number?
	local ex, ey = rail.bx - rail.ax, rail.by - rail.ay
	local length = math.sqrt(ex * ex + ey * ey)
	local ux, uy = ex / length, ey / length
	-- The rail's normal on the point's side
	local nx, ny = -uy, ux
	local side = (x - rail.ax) * nx + (y - rail.ay) * ny
	if side < 0 then
		nx, ny, side = -nx, -ny, -side
	end
	local best: number? = nil
	local toward = -(dx * nx + dy * ny)
	if toward > 0 and side > reach then
		local t = (side - reach) / toward
		local along = (x + dx * t - rail.ax) * ux + (y + dy * t - rail.ay) * uy
		if along >= 0 and along <= length then
			best = t
		end
	end
	for _, corner in { { rail.ax, rail.ay }, { rail.bx, rail.by } } do
		local t = reachPoint(x, y, dx, dy, corner[1], corner[2], reach)
		if t and (not best or t < best) then
			best = t
		end
	end
	return best
end

-- What a cue ball heading along the unit direction (dirX, dirY) sends each ball when it hits a still ball, which
-- leaves along the unit direction (pushX, pushY). Simulate's rule for a ball rolling into a still one: the hit
-- ball takes (1 + BallBounce) / 2 of the speed along the line between the centers, and the cue ball keeps the
-- rest, plus Follow of what the hit takes away. Shares don't depend on speed, so neither does this.
function Preview.hit(dirX: number, dirY: number, pushX: number, pushY: number, physics: HitParams): Hit
	local push = (1 + physics.BallBounce) / 2 * (dirX * pushX + dirY * pushY)
	local taken = push * (1 - physics.Follow)
	local cueVX, cueVY = dirX - taken * pushX, dirY - taken * pushY
	local cueShare = math.sqrt(cueVX * cueVX + cueVY * cueVY)
	-- A cue ball stopped dead has no direction; point its line straight on
	local cueX, cueY = if cueShare > 0 then cueVX / cueShare else dirX, if cueShare > 0 then cueVY / cueShare else dirY
	return { cueX = cueX, cueY = cueY, cueShare = cueShare, ballShare = push }
end

-- The pocket a ball at (x, y) heading along the unit direction (dirX, dirY) points at most directly, by the angle
-- between its path and the line to each pocket. For calling the 8 from its yellow line.
function Preview.aimedPocket(layout: Geometry.Layout, x: number, y: number, dirX: number, dirY: number): number
	local best, bestCos = 1, -math.huge
	for index, pocket in layout.pockets do
		local px, py = pocket.x - x, pocket.y - y
		local cos = (px * dirX + py * dirY) / math.sqrt(px * px + py * py)
		if cos > bestCos then
			best, bestCos = index, cos
		end
	end
	return best
end

-- `dirX, dirY` must be a unit direction. `layout` is Geometry.build(tableParams), built once by the caller.
-- `physics` decides what a hit sends each ball.
function Preview.firstContact(
	balls: { Ball },
	dirX: number,
	dirY: number,
	tableParams: Geometry.TableParams,
	layout: Geometry.Layout,
	physics: HitParams
): Contact
	local radius = tableParams.BallRadius
	local cue: Ball = balls[1]
	for _, ball in balls do
		if ball.id == 0 then
			cue = ball
		end
	end
	local x, y = cue.x, cue.y

	-- The felt's edge comes last: only a pocket's opening lets the cue ball's center past it
	local halfLength, halfWidth = tableParams.Length / 2, tableParams.Width / 2
	local best = math.min(
		if dirX > 0 then (halfLength - x) / dirX elseif dirX < 0 then (-halfLength - x) / dirX else math.huge,
		if dirY > 0 then (halfWidth - y) / dirY elseif dirY < 0 then (-halfWidth - y) / dirY else math.huge
	)
	local kind: "ball" | "rail" | "pocket" = "pocket"
	local hit: Ball? = nil

	for _, pocket in layout.pockets do
		local t = reachPoint(x, y, dirX, dirY, pocket.x, pocket.y, pocket.radius)
		if t and t < best then
			best, kind, hit = t, "pocket", nil
		end
	end
	for _, rail in layout.rails do
		local t = reachRail(x, y, dirX, dirY, rail, radius)
		if t and t < best then
			best, kind, hit = t, "rail", nil
		end
	end
	for _, ball in balls do
		if ball.id ~= 0 and not ball.pocket then
			local t = reachPoint(x, y, dirX, dirY, ball.x, ball.y, 2 * radius)
			if t and t < best then
				best, kind, hit = t, "ball", ball
			end
		end
	end

	local contactX, contactY = x + dirX * best, y + dirY * best
	if hit then
		local nx, ny = hit.x - contactX, hit.y - contactY
		local dist = math.sqrt(nx * nx + ny * ny)
		local pushX, pushY = nx / dist, ny / dist
		return {
			kind = "ball",
			x = contactX,
			y = contactY,
			ball = hit.id,
			pushX = pushX,
			pushY = pushY,
			hit = Preview.hit(dirX, dirY, pushX, pushY, physics),
		}
	end
	return { kind = kind, x = contactX, y = contactY }
end

return Preview
