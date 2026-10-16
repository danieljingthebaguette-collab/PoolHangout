--!strict
-- 20 breaks, summarized, for comparing our break with 8 Ball Duels while tuning. Run it with Lune from the
-- project root, with any physics or table setting to try: lune run tools/BreakStats.luau RackGap=0.02 Verbose=1
local process = require("@lune/process")
local Config = require("../src/Shared/Config")
local Geometry = require("../src/Shared/Physics/Geometry")
local Simulate = require("../src/Shared/Physics/Simulate")

local overrides = {}
for _, arg in process.args do
	local name, value = string.match(arg, "^(%w+)=([%d%.]+)$")
	if name then
		overrides[name] = tonumber(value)
	end
end
local params = { Table = table.clone(Config.Table), Physics = table.clone(Config.Physics) } :: any
for name, value in overrides do
	if params.Table[name] ~= nil then
		params.Table[name] = value
	else
		params.Physics[name] = value
	end
end
local T = params.Table
local layout = Geometry.build(T)
local r = T.BallRadius

-- The rack's middle, and "bunched" = within NEAR studs of it (the rack itself reaches about 1.2 from its middle)
local cx, cy = 0, 0
for _, spot in layout.rack do
	cx += spot.x / 15
	cy += spot.y / 15
end
local NEAR = tonumber(overrides.Near) or 2

local totals = { sunk = 0, scratch = 0, bunched = 0, pastMiddle = 0, spread = 0, time = 0, cueX = 0 }
local rows = {}
for i = 0, 19 do
	local cueY = (i / 19 - 0.5) * 2 -- across ±1 stud of the head line's middle
	local balls = { { id = 0, x = layout.headLineX, y = cueY, vx = 0, vy = 0 } }
	for id, spot in layout.rack do
		table.insert(balls, { id = id, x = spot.x, y = spot.y, vx = 0, vy = 0 })
	end
	local apex = layout.rack[1]
	local dx, dy = apex.x - layout.headLineX, apex.y - cueY
	local length = math.sqrt(dx * dx + dy * dy)
	local sim = Simulate.run(balls, { dirX = dx / length, dirY = dy / length, power = 1, isBreak = true }, params)
	local sunk, bunched, past, spread = 0, 0, 0, 0
	local cue = sim.balls[1]
	for _, b in sim.balls do
		if b.id == 0 then
			continue
		end
		if b.pocket then
			sunk += 1
		elseif math.sqrt((b.x - cx) ^ 2 + (b.y - cy) ^ 2) <= NEAR then
			bunched += 1
		else
			spread += 1
			if b.x < 0 then
				past += 1
			end
		end
	end
	local time = sim.steps * params.Physics.TimeStep
	totals.sunk += sunk
	totals.scratch += if cue.pocket then 1 else 0
	totals.bunched += bunched
	totals.pastMiddle += past
	totals.spread += spread
	totals.time += time
	totals.cueX += if cue.pocket then 0 else cue.x
	table.insert(
		rows,
		string.format(
			"%2d  sunk %d%s  bunched %2d  spread %2d (past middle %d)  cue x %5.2f  %.2f s",
			i + 1,
			sunk,
			if cue.pocket then " +scratch" else "",
			bunched,
			spread,
			past,
			cue.x,
			time
		)
	)
end
if overrides.Verbose then
	print(table.concat(rows, "\n"))
end
print(
	string.format(
		"RackGap %.3f BreakPower %.2f BallBounce %.2f SpeedDrag %.3f | per break: sunk %.2f, scratches %d/20, bunched %.1f, spread %.1f (past middle %.1f), cue ball stops at x %.2f, stops after %.2f s",
		T.RackGap,
		params.Physics.BreakPower,
		params.Physics.BallBounce,
		params.Physics.SpeedDrag or 0,
		totals.sunk / 20,
		totals.scratch,
		totals.bunched / 20,
		totals.spread / 20,
		totals.pastMiddle / 20,
		totals.cueX / 20,
		totals.time / 20
	)
)
