--!strict
-- A fingerprint of every ball's final place over a fixed set of 40 breaks, 40 shots and 40 item shots, and how long the
-- physics took.
-- Simulate.luau runs native on servers and Android but as bytecode everywhere else, so results must match exactly:
-- after changing the physics, run this in Lune (lune run tools/NativeCheck), then the same body on a Studio server
-- with a Server execute_luau (requiring the modules from ReplicatedStorage.Shared), and compare the fingerprints.
-- 2026-11-17, with the item shots: 1579840315 over 435,701 steps in both; 1,824 ms in Lune and 1,233 ms native on a
-- Studio server. (2026-11-12, breaks and shots only: 1716332278 over 295,933 steps.)
local Config = require("../src/Shared/Config")
local Geometry = require("../src/Shared/Physics/Geometry")
local Simulate = require("../src/Shared/Physics/Simulate")
local params = { Table = Config.Table, Physics = Config.Physics }
local layout = Geometry.build(Config.Table)
local seed = 12345
local function rnd()
	seed = (seed * 1103515245 + 12345) % 2147483648
	return seed / 2147483648
end
local function rack()
	local balls = { { id = 0, x = layout.headLineX, y = 0, vx = 0, vy = 0 } }
	for id, spot in layout.rack do
		table.insert(balls, { id = id, x = spot.x, y = spot.y, vx = 0, vy = 0 })
	end
	return balls
end
local function scattered()
	local balls = {}
	for id = 0, 15 do
		table.insert(balls, {
			id = id,
			x = (rnd() - 0.5) * (Config.Table.Length - 2),
			y = (rnd() - 0.5) * (Config.Table.Width - 2),
			vx = 0,
			vy = 0,
		})
	end
	return balls
end
local parts, sum, steps, simMs = {}, 0, 0, 0
local function record(sim)
	steps += sim.steps
	for _, b in sim.balls do
		local s = string.format("%d:%.17g,%.17g,%s;", b.id, b.x, b.y, tostring(b.pocket))
		for i = 1, #s do
			sum = (sum * 31 + string.byte(s, i)) % 2147483647
		end
	end
end
local apex = layout.rack[1]
local t0 = os.clock()
for k = 1, 40 do
	local dy = (rnd() - 0.5) * 0.2
	local dx, dyy = apex.x - layout.headLineX, apex.y + dy
	local len = math.sqrt(dx * dx + dyy * dyy)
	local t = os.clock()
	local sim = Simulate.run(rack(), { dirX = dx / len, dirY = dyy / len, power = 1, isBreak = true }, params)
	simMs += (os.clock() - t) * 1000
	record(sim)
end
for k = 1, 40 do
	local angle = rnd() * 2 * math.pi
	local balls = scattered()
	local t = os.clock()
	local sim =
		Simulate.run(balls, { dirX = math.cos(angle), dirY = math.sin(angle), power = 0.2 + rnd() * 0.8 }, params)
	simMs += (os.clock() - t) * 1000
	record(sim)
end
-- Item shots, 8 of each, aimed so the item comes into play: Power Shot at 150%, Blast Ball at a ball, the cue ball at a
-- frozen ball, an oil patch under the cue ball, and the cue ball at a blocked pocket
for k = 0, 39 do
	local balls = scattered()
	local cue, target = balls[1], balls[2 + k % 15]
	local kind = k % 5
	local x, y, power, effects = target.x, target.y, 0.2 + rnd() * 0.8, {}
	if kind == 0 then
		power = Config.Items.PowerShotMax
	elseif kind == 1 then
		effects = { blast = true }
	elseif kind == 2 then
		effects = { frozen = { target.id } }
	elseif kind == 3 then
		effects = { oil = { { x = cue.x, y = cue.y } } }
	else
		local pocket = 1 + k % 6
		x, y = layout.pockets[pocket].x, layout.pockets[pocket].y
		effects = { blocked = { pocket } }
	end
	local dx, dyy = x - cue.x, y - cue.y
	local len = math.sqrt(dx * dx + dyy * dyy)
	local t = os.clock()
	local sim = Simulate.run(balls, { dirX = dx / len, dirY = dyy / len, power = power }, params, effects)
	simMs += (os.clock() - t) * 1000
	record(sim)
end
local ms = simMs
print(string.format("lune: fingerprint %d, %d steps, %.0f ms", sum, steps, ms))
