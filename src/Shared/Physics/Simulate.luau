--!strict
-- Ball physics in table space (see ARCHITECTURE.md). The server and every client must get exactly the
-- same shot from the same inputs, so keep it deterministic: fixed time step, balls in id order, and no
-- randomness, clock reads or trig.

local Config = require("../Config")
local Geometry = require("./Geometry")

export type Ball = { id: number, x: number, y: number, vx: number, vy: number, pocket: number? }

-- A unit direction rather than an angle, because math.sin and math.cos can round differently on
-- different devices. Power is 0–1.
export type Shot = { dirX: number, dirY: number, power: number }

-- The server sends the params it used with each shot, so every screen matches it even while they're
-- being tuned live.
export type Params = { Table: typeof(Config.Table), Physics: typeof(Config.Physics) }

export type Sim = { balls: { Ball }, params: Params, layout: Geometry.Layout, steps: number, done: boolean }

local Simulate = {}

-- Works on copies, so the caller's starting balls stay as they were to send to clients.
function Simulate.start(balls: { Ball }, shot: Shot, params: Params?): Sim
	local p: Params = params or Config
	local copies: { Ball } = {}
	for i, ball in balls do
		copies[i] = table.clone(ball)
	end
	table.sort(copies, function(a: Ball, b: Ball): boolean
		return a.id < b.id
	end)
	local speed = shot.power * p.Physics.FullPowerSpeed
	for _, ball in copies do
		if ball.id == 0 then
			ball.vx, ball.vy = shot.dirX * speed, shot.dirY * speed
		end
	end
	return { balls = copies, params = p, layout = Geometry.build(p.Table), steps = 0, done = false }
end

-- Advances the shot by up to `count` time steps. Returns true once it's over: every ball has stopped
-- or dropped, or the time cap was reached.
function Simulate.step(sim: Sim, count: number): boolean
	local balls, rails, pockets = sim.balls, sim.layout.rails, sim.layout.pockets
	local tableParams, physics = sim.params.Table, sim.params.Physics
	local radius, dt = tableParams.BallRadius, physics.TimeStep
	local diameterSq = 4 * radius * radius
	local halfLength, halfWidth = tableParams.Length / 2, tableParams.Width / 2
	local hitShare = (1 + physics.BallBounce) / 2
	local slowdown = physics.RollingSlowdown * dt
	local lastStep = physics.TimeCap / dt
	-- No rail or pocket reaches farther than this onto the felt
	local edgeReach = radius
	for _, pocket in pockets do
		edgeReach = math.max(edgeReach, pocket.radius)
	end

	for _ = 1, count do
		if sim.done then
			break
		end

		for _, ball in balls do
			ball.x += ball.vx * dt
			ball.y += ball.vy * dt
		end

		for i, a in balls do
			if a.pocket then
				continue
			end
			for j = i + 1, #balls do
				local b = balls[j]
				if b.pocket or (a.vx == 0 and a.vy == 0 and b.vx == 0 and b.vy == 0) then
					continue
				end
				local dx, dy = b.x - a.x, b.y - a.y
				local distSq = dx * dx + dy * dy
				local wx, wy = a.vx - b.vx, a.vy - b.vy
				local closing = dx * wx + dy * wy
				if distSq >= diameterSq or closing <= 0 then
					continue
				end

				-- Wind both balls back to the moment they touched. Resolving the hit where they already
				-- overlap would send the object ball several degrees off line on fast cut shots.
				local wSq = wx * wx + wy * wy
				local back = math.min((math.sqrt(closing * closing + wSq * (diameterSq - distSq)) - closing) / wSq, dt)
				a.x -= a.vx * back
				a.y -= a.vy * back
				b.x -= b.vx * back
				b.y -= b.vy * back

				dx, dy = b.x - a.x, b.y - a.y
				local dist = math.sqrt(dx * dx + dy * dy)
				local nx, ny = dx / dist, dy / dist
				local aInto, bInto = a.vx * nx + a.vy * ny, -(b.vx * nx + b.vy * ny)
				local push = hitShare * (aInto + bInto)
				-- A ball rolling into the hit keeps Follow of the speed the hit takes away, like natural roll.
				-- Every moving ball counts as rolling, even one that was only just hit.
				local pushA = if aInto > 0 then push * (1 - physics.Follow) else push
				local pushB = if bInto > 0 then push * (1 - physics.Follow) else push
				a.vx -= pushA * nx
				a.vy -= pushA * ny
				b.vx += pushB * nx
				b.vy += pushB * ny

				a.x += a.vx * back
				a.y += a.vy * back
				b.x += b.vx * back
				b.y += b.vy * back
			end
		end

		for _, ball in balls do
			if
				(ball.vx == 0 and ball.vy == 0)
				or (math.abs(ball.x) < halfLength - edgeReach and math.abs(ball.y) < halfWidth - edgeReach)
			then
				continue
			end

			local nearest, nearestSq = 1, math.huge
			for index, pocket in pockets do
				local px, py = ball.x - pocket.x, ball.y - pocket.y
				if px * px + py * py < nearestSq then
					nearest, nearestSq = index, px * px + py * py
				end
			end
			-- Only a pocket's opening lets a ball's center past the edge of the felt, so that drops it too
			local pocketRadius = pockets[nearest].radius
			if
				nearestSq < pocketRadius * pocketRadius
				or math.abs(ball.x) > halfLength
				or math.abs(ball.y) > halfWidth
			then
				ball.pocket = nearest
				ball.vx, ball.vy = 0, 0
				continue
			end

			for _, rail in rails do
				-- The closest point is clamped to the rail's ends, so the ends work as the pockets' jaws
				local ex, ey = rail.bx - rail.ax, rail.by - rail.ay
				local along =
					math.clamp(((ball.x - rail.ax) * ex + (ball.y - rail.ay) * ey) / (ex * ex + ey * ey), 0, 1)
				local dx, dy = ball.x - (rail.ax + ex * along), ball.y - (rail.ay + ey * along)
				local distSq = dx * dx + dy * dy
				if distSq >= radius * radius or distSq == 0 then
					continue
				end
				local dist = math.sqrt(distSq)
				local nx, ny = dx / dist, dy / dist
				local into = -(ball.vx * nx + ball.vy * ny)
				if into <= 0 then
					continue
				end
				-- Bounce from the point where it touched the rail, so bank shots come off true
				local back = math.min((radius - dist) / into, dt)
				ball.x -= ball.vx * back
				ball.y -= ball.vy * back
				ball.vx = (ball.vx + 2 * into * nx) * physics.RailBounce
				ball.vy = (ball.vy + 2 * into * ny) * physics.RailBounce
				ball.x += ball.vx * back
				ball.y += ball.vy * back
			end
		end

		local moving = false
		for _, ball in balls do
			if ball.vx == 0 and ball.vy == 0 then
				continue
			end
			local speed = math.sqrt(ball.vx * ball.vx + ball.vy * ball.vy)
			if speed - slowdown <= physics.StopSpeed then
				ball.vx, ball.vy = 0, 0
			else
				local scale = (speed - slowdown) / speed
				ball.vx *= scale
				ball.vy *= scale
				moving = true
			end
		end

		sim.steps += 1
		if not moving or sim.steps >= lastStep then
			for _, ball in balls do
				ball.vx, ball.vy = 0, 0
			end
			sim.done = true
		end
	end
	return sim.done
end

-- Plays a whole shot at once, for tests. The game steps a shot a slice at a time instead.
function Simulate.run(balls: { Ball }, shot: Shot, params: Params?): Sim
	local sim = Simulate.start(balls, shot, params)
	Simulate.step(sim, math.huge)
	return sim
end

return Simulate
