--!strict
-- Times the server's physics: a full-power break from the middle of the head line, stepped in slices of
-- Config.Shot.ServerStepsPerFrame steps, as Server/Balls.luau does once a frame. Prints each run's total and worst
-- slice, their medians, what 6 tables breaking in the same frame would cost, and whether the result matches stepping
-- the whole break at once (it must: slicing only spreads the same work over frames). Run it from the project root,
-- optionally with another slice size or number of runs: lune run tools/BenchPhysics Steps=120 Runs=7
local process = require("@lune/process")
local Config = require("../src/Shared/Config")
local Geometry = require("../src/Shared/Physics/Geometry")
local Simulate = require("../src/Shared/Physics/Simulate")

local FRAME_MS = 1000 / 60
local TABLES = 6

local args: { [string]: number } = {}
for _, arg in process.args do
	local name, value = string.match(arg, "^(%a+)=(%d+)$")
	if name and value then
		args[name] = tonumber(value) :: number
	end
end
local steps = args.Steps or Config.Shot.ServerStepsPerFrame
local runs = args.Runs or 5

local params = { Table = Config.Table, Physics = Config.Physics }
local layout = Geometry.build(Config.Table)

local function rack(): { Simulate.Ball }
	local balls = { { id = 0, x = layout.headLineX, y = 0, vx = 0, vy = 0 } }
	for id, spot in layout.rack do
		table.insert(balls, { id = id, x = spot.x, y = spot.y, vx = 0, vy = 0 })
	end
	return balls
end

local apex = layout.rack[1]
local toApex = math.sqrt((apex.x - layout.headLineX) ^ 2 + apex.y ^ 2)
local BREAK = { dirX = (apex.x - layout.headLineX) / toApex, dirY = apex.y / toApex, power = 1, isBreak = true }

-- Where every ball ended up and after how many steps, exactly, to compare two runs
local function result(sim: Simulate.Sim): string
	local parts = { tostring(sim.steps) }
	for _, ball in sim.balls do
		table.insert(parts, string.format("%d:%.17g,%.17g,%s", ball.id, ball.x, ball.y, tostring(ball.pocket)))
	end
	return table.concat(parts, " ")
end

local function median(values: { number }): number
	local sorted = table.clone(values)
	table.sort(sorted)
	return sorted[(#sorted + 1) // 2]
end

print(string.format("Full-power break, %d steps a slice, %d runs", steps, runs))
local totals, worsts = {}, {}
local slicedResult = ""
for run = 1, runs do
	local sim = Simulate.start(rack(), BREAK, params)
	local total, worst, slices = 0, 0, 0
	local done = false
	while not done do
		local t0 = os.clock()
		done = Simulate.step(sim, steps)
		local ms = (os.clock() - t0) * 1000
		total += ms
		worst = math.max(worst, ms)
		slices += 1
	end
	table.insert(totals, total)
	table.insert(worsts, worst)
	slicedResult = result(sim)
	print(string.format("  run %d: %d slices, %.1f ms in all, worst slice %.2f ms", run, slices, total, worst))
end

local worst = median(worsts)
print(string.format("Median: %.1f ms in all, worst slice %.2f ms", median(totals), worst))
print(
	string.format(
		"%d tables breaking in the same frame: %.1f ms of the %.1f ms frame (%.0f%%)",
		TABLES,
		TABLES * worst,
		FRAME_MS,
		TABLES * worst / FRAME_MS * 100
	)
)
local whole = Simulate.run(rack(), BREAK, params)
print("Same result as stepping the whole break at once: " .. (if result(whole) == slicedResult then "yes" else "NO"))
