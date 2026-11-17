--!strict
-- Where the shooter stands to shoot, in table space (see ARCHITECTURE.md): a fixed distance behind the cue ball and a
-- little to the left of the shot's line, so the cue passes their back hand; on top of the table when that spot is over
-- it, and clear of its edge when it isn't. Also where they step off to afterwards, and one frame of gliding between
-- spots. Pure Luau, so Lune tests it.

local ShotStance = {}

export type Point = { x: number, y: number }

-- The spot `back` studs behind the cue ball at (cueX, cueY) and `side` studs to the left of the shot's line, for an
-- aim at angle `aim` (radians, 0 along +x), and the point the shooter faces from there: beside the cue ball, straight
-- ahead along the aim. Table y is the felt's Z, so facing along the aim, left is (sin, -cos).
function ShotStance.spot(cueX: number, cueY: number, aim: number, back: number, side: number): (Point, Point)
	local cos, sin = math.cos(aim), math.sin(aim)
	local faceX, faceY = cueX + sin * side, cueY - cos * side
	return { x = faceX - cos * back, y = faceY - sin * back }, { x = faceX, y = faceY }
end

-- Whether a spot is over the table, which reaches `halfX` by `halfY` from its centre: there, the shooter stands on top
function ShotStance.overTable(x: number, y: number, halfX: number, halfY: number): boolean
	return math.abs(x) < halfX and math.abs(y) < halfY
end

-- The nearest spot at least `clear` studs off the table from (x, y): from on the table, straight out past its nearest
-- edge; from beside it, straight out from the table's nearest point. A spot already that far off stays where it is.
function ShotStance.offTable(x: number, y: number, halfX: number, halfY: number, clear: number): Point
	local nearX, nearY = math.clamp(x, -halfX, halfX), math.clamp(y, -halfY, halfY)
	local dx, dy = x - nearX, y - nearY
	local distance = math.sqrt(dx * dx + dy * dy)
	if distance >= clear then
		return { x = x, y = y }
	elseif distance > 0 then
		return { x = nearX + dx / distance * clear, y = nearY + dy / distance * clear }
	elseif halfX - math.abs(x) < halfY - math.abs(y) then
		return { x = (if x < 0 then -1 else 1) * (halfX + clear), y = y }
	end
	return { x = x, y = (if y < 0 then -1 else 1) * (halfY + clear) }
end

-- Where a shooter headed for (x, y) stands: over the table, right there, on top of it; off it, at least `clear` studs
-- from its edge, so no body hangs over the rails
function ShotStance.clear(x: number, y: number, halfX: number, halfY: number, clear: number): Point
	if ShotStance.overTable(x, y, halfX, halfY) then
		return { x = x, y = y }
	end
	return ShotStance.offTable(x, y, halfX, halfY, clear)
end

-- One frame's glide from (x, y) at `height` towards (toX, toY) at `toHeight`: across at `speed` studs/s and up or down
-- at `climb` studs/s, each stopping once it's there
function ShotStance.step(
	x: number,
	y: number,
	height: number,
	toX: number,
	toY: number,
	toHeight: number,
	speed: number,
	climb: number,
	dt: number
): (number, number, number)
	local dx, dy = toX - x, toY - y
	local distance = math.sqrt(dx * dx + dy * dy)
	-- Landing exactly on the spot, so "there" is exact
	if distance <= speed * dt then
		x, y = toX, toY
	else
		x, y = x + dx / distance * speed * dt, y + dy / distance * speed * dt
	end
	local rise = toHeight - height
	height += math.sign(rise) * math.min(math.abs(rise), climb * dt)
	return x, y, height
end

return ShotStance
