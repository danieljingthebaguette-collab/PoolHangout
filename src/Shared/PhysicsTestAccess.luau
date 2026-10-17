--!strict
-- Who may use the physics test mode: everyone in Studio, and in a published server only the place's owner,
-- while Config.Debug.PhysicsTestLive is on. The server checks it on every test request, so another player's
-- client can't use the test remotes even if it fires them. Also builds the physics params the sliders set.

local RunService = game:GetService("RunService")

local Config = require(script.Parent.Config)
local Remotes = require(script.Parent.Remotes)
local Simulate = require(script.Parent.Physics.Simulate)

local PhysicsTestAccess = {}

-- May yield on a group-owned place, which asks Roblox for the player's rank the first time
function PhysicsTestAccess.canTest(player: Player): boolean
	if not Config.Debug.PhysicsTest then
		return false
	end
	if RunService:IsStudio() then
		return true
	end
	if not Config.Debug.PhysicsTestLive then
		return false
	end
	if game.CreatorType == Enum.CreatorType.User then
		return player.UserId == game.CreatorId
	end
	-- 255 is a group's owner
	local ok, rank = pcall(player.GetRankInGroup, player, game.CreatorId)
	return ok and rank == 255
end

-- A fresh copy of one of Config's groups with the sliders' values in it. A slider whose value hasn't reached this
-- screen yet keeps Config's.
local function withSliders(group: string): any
	local values = table.clone((Config :: any)[group])
	for _, slider in Config.Debug.TestSliders do
		if slider.group == group then
			values[slider.name] = Remotes.TestTune:GetAttribute(slider.name) or values[slider.name]
		end
	end
	return values
end

-- A fresh copy of Config with the sliders' values, so moving a slider mid-shot can't change that shot. The server
-- shoots with it, and the shooter's screen starts the same shot with it before the server's copy arrives.
function PhysicsTestAccess.params(): Simulate.Params
	return { Table = withSliders("Table"), Physics = withSliders("Physics") }
end

-- Config.Shot with the sliders' values: the feel of the shot controls, like how far a full pull is
function PhysicsTestAccess.shot(): typeof(Config.Shot)
	return withSliders("Shot")
end

return PhysicsTestAccess
