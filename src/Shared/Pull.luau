--!strict
-- The slingshot pull's power, in plain Luau so Lune can test it. Like 8 Ball Duels: power is how far the pointer
-- has moved from where it pressed, measured only along the line straight back from the shot, toward the stick.
-- Moving toward the ball lowers it, down to 0, and it stays at 0 however far the pointer goes on that way.
-- Sideways movement does nothing. The first `cancel` studs back are the cancel zone, where letting go fires
-- nothing, and power counts from its edge, reaching full `full` studs past it.

export type Pull = { pressX: number, pressY: number, back: number, left: boolean, cancel: number, full: number }

local Pull = {}

-- A pull that started with the pointer at (x, y) on the table
function Pull.new(x: number, y: number, cancel: number, full: number): Pull
	return { pressX = x, pressY = y, back = 0, left = false, cancel = cancel, full = full }
end

-- The pointer is now at (x, y) on the table, for a shot along the unit direction (dirX, dirY)
function Pull.moveTo(pull: Pull, x: number, y: number, dirX: number, dirY: number)
	pull.back = -((x - pull.pressX) * dirX + (y - pull.pressY) * dirY)
	-- Once past the cancel zone, coming back into it is a cancel rather than a pull that never started
	if pull.back > pull.cancel then
		pull.left = true
	end
end

-- The shot's power, 0 to 1. Exactly 1 from full power on, rather than a rounding error short of it.
function Pull.power(pull: Pull): number
	if pull.back >= pull.cancel + pull.full then
		return 1
	end
	return math.clamp((pull.back - pull.cancel) / pull.full, 0, 1)
end

return Pull
