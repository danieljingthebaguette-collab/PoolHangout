--!strict
-- Where the shooter stands to shoot, in table space (see ARCHITECTURE.md): a fixed distance straight behind the cue
-- ball along the aim, so they always face the ball, on top of the table when that spot is over it. Also where they step
-- off to afterwards, and one frame of gliding between spots. Pure Luau, so Lune tests it.

local ShotStance = {}

export type Point = { x: number, y: number }

-- The spot `back` studs behind the cue ball at (cueX, cueY), for an aim at angle `aim` (radians, 0 along +x)
function ShotStance.spot(cueX: number, cueY: number, aim: number, back: number): Point
	return { x = cueX - math.cos(aim) * back, y = cueY - math.sin(aim) * back }
end

-- Whether a spot is over the table, which reaches `halfX` by `halfY` from its centre: there, the shooter stands on top
function ShotStance.overTable(x: number, y: number, halfX: number, halfY: number): boolean
	return math.abs(x) < halfX and math.abs(y) < halfY
end

-- The nearest spot `clear` studs off the table from (x, y), straight out past its nearest edge. A spot already off the
-- table stays where it is.
function ShotStance.offTable(x: number, y: number, halfX: number, halfY: number, clear: number): Point
	if not ShotStance.overTable(x, y, halfX, halfY) then
		return { x = x, y = y }
	end
	if halfX - math.abs(x) < halfY - math.abs(y) then
		return { x = (if x < 0 then -1 else 1) * (halfX + clear), y = y }
	end
	return { x = x, y = (if y < 0 then -1 else 1) * (halfY + clear) }
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
