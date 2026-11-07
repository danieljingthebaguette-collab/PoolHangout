--!strict
-- Physics test mode (see Config.Debug.PhysicsTest and PhysicsTestLive): racks Table1 when a player asks,
-- shoots the cue ball the way they aimed, and keeps the sliders' values. Any player PhysicsTestAccess allows
-- may rack or shoot while the balls are still and no game is on the table, and move a slider any time, except the
-- pocket sizes, which rebuild the table and so wait for those same times. It plays like a game without turns: an
-- 8-ball rack, the break, and ball in hand after a scratch.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local EightBall = require(ReplicatedStorage.Shared.Rules.EightBall)
local Geometry = require(ReplicatedStorage.Shared.Physics.Geometry)
local PhysicsTestAccess = require(ReplicatedStorage.Shared.PhysicsTestAccess)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Simulate = require(ReplicatedStorage.Shared.Physics.Simulate)
local Balls = require(script.Parent.Balls)
local TableBuilder = require(script.Parent.TableBuilder)
local TableService = require(script.Parent.TableService)

local PhysicsTest = {}

-- Sliders that change the table's shape, so Table1 is rebuilt to match
local REBUILDS = { CornerPocketMouth = true, SidePocketMouth = true }

local function isFinite(value: number): boolean
	return value == value and math.abs(value) ~= math.huge
end

function PhysicsTest.start()
	local tableModel = workspace:WaitForChild("Tables"):WaitForChild("Table1") :: Model

	for _, slider in Config.Debug.TestSliders do
		Remotes.TestTune:SetAttribute(slider.name, (Config :: any)[slider.group][slider.name])
	end

	-- Test racks and shots wait for the balls to stop, and stay off while a game is on the table
	local function free(): boolean
		return not Balls.isRolling(tableModel) and not TableService.hasGame(tableModel)
	end

	-- The first shot after a rack is the break, with BreakPower times the power, and a scratch gives ball in hand. Each
	-- only holds while the balls resting are the ones this test mode placed, so a game in between leaves nothing stale.
	-- The table's BreakNext attribute tells the shooter's screen, which starts the shot before the server's copy
	-- arrives.
	local racked: { Simulate.Ball }? = nil
	local scratched: { Simulate.Ball }? = nil
	local function ballInHand(): boolean
		return scratched ~= nil and Balls.get(tableModel) == scratched
	end

	-- Tells screens where the cue ball may be placed now. With no shooter, TurnStarted is the test mode's.
	local function announce(player: Player?)
		if TableService.hasGame(tableModel) then
			return
		elseif player then
			Remotes.TurnStarted:FireClient(player, tableModel, nil, ballInHand())
		else
			Remotes.TurnStarted:FireAllClients(tableModel, nil, ballInHand())
		end
	end
	Remotes.ClientReady.OnServerEvent:Connect(announce)

	local random = Random.new()
	local function rack()
		local balls = EightBall.rack(Geometry.build(PhysicsTestAccess.params().Table), function(n: number): number
			return random:NextInteger(1, n)
		end)
		Balls.place(tableModel, balls)
		racked = balls
		tableModel:SetAttribute("BreakNext", true)
		if Config.Debug.LogShots and RunService:IsStudio() then
			print(`[{tableModel.Name}] racked for the physics test mode`)
		end
		announce()
	end
	rack()

	Remotes.TestRack.OnServerEvent:Connect(function(player: Player)
		if PhysicsTestAccess.canTest(player) and free() then
			rack()
		end
	end)

	-- Rebuilds Table1 from the sliders' pocket sizes, in the running game only, never the saved place. A change during
	-- a rebuild, which yields, rebuilds once more after it.
	local rebuilding, rebuildAgain = false, false
	local function rebuild()
		if rebuilding then
			rebuildAgain = true
			return
		end
		rebuilding = true
		repeat
			rebuildAgain = false
			-- A failed rebuild mustn't leave `rebuilding` stuck on
			local ok, problem = pcall(TableBuilder.build, tableModel, PhysicsTestAccess.params().Table)
			if not ok then
				warn(`[{tableModel.Name}] rebuild failed: {problem}`)
			end
		until not rebuildAgain
		rebuilding = false
	end

	Remotes.TestTune.OnServerEvent:Connect(function(player: Player, name: unknown, value: unknown)
		if typeof(value) ~= "number" or not PhysicsTestAccess.canTest(player) then
			return
		end
		for _, slider in Config.Debug.TestSliders do
			-- NaN fails both comparisons
			if slider.name ~= name or not (value >= slider.min and value <= slider.max) then
				continue
			end
			if REBUILDS[slider.name] and not free() then
				-- Puts that player's slider back to the value kept here
				Remotes.TestTune:FireClient(player)
			else
				Remotes.TestTune:SetAttribute(slider.name, value)
				if REBUILDS[slider.name] then
					rebuild()
				end
			end
		end
	end)

	Remotes.TestPrint.OnServerEvent:Connect(function(player: Player)
		if not PhysicsTestAccess.canTest(player) then
			return
		end
		local lines = { `Physics test values, printed for {player.Name}:` }
		for _, slider in Config.Debug.TestSliders do
			local value = string.format("%g", Remotes.TestTune:GetAttribute(slider.name) :: number)
			table.insert(lines, `  {slider.group}.{slider.name} = {value},`)
		end
		print(table.concat(lines, "\n"))
	end)

	Remotes.TestShoot.OnServerEvent:Connect(
		function(player: Player, dirX: unknown, dirY: unknown, power: unknown, cueX: unknown, cueY: unknown)
			if typeof(dirX) ~= "number" or typeof(dirY) ~= "number" or typeof(power) ~= "number" then
				return
			end
			if not (PhysicsTestAccess.canTest(player) and free()) then
				return
			end
			local length = math.sqrt(dirX * dirX + dirY * dirY)
			if not (isFinite(length) and length > 0 and power >= 0 and power <= 1) then
				return
			end

			local params = PhysicsTestAccess.params()
			-- Both read before placing the cue ball, which makes a new list of resting balls
			local isBreak = Balls.get(tableModel) == racked
			if not Balls.placeCue(tableModel, ballInHand(), cueX, cueY, params.Table) then
				return
			end
			scratched = nil
			local shot: Simulate.Shot = { dirX = dirX / length, dirY = dirY / length, power = power, isBreak = isBreak }
			tableModel:SetAttribute("BreakNext", false)
			local balls = Balls.shoot(tableModel, shot, params).balls
			-- A sunk cue ball comes back on the head line with ball in hand, like after a foul in a game. The cue ball
			-- sorts first.
			local cue = balls[1]
			if cue.pocket then
				cue.pocket = nil
				cue.x, cue.y = EightBall.freeSpot(balls, Geometry.build(params.Table).headLineX, params.Table)
				scratched = balls
			end
			Balls.place(tableModel, balls)
			Remotes.ShotResolved:FireAllClients(tableModel, balls)
			announce()
		end
	)
end

return PhysicsTest
