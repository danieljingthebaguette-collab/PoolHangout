--!strict
-- The pull's power: how far the pointer has moved from where it pressed, straight back from the shot. Every
-- distance comes from Config.
local Config = require("../src/Shared/Config")
local Pull = require("../src/Shared/Pull")

local CANCEL = Config.Shot.CancelRadius * Config.Table.BallRadius
local FULL = Config.Shot.FullPullDistance * Config.Table.Length
-- A shot along a diagonal, so nothing leans on one axis
local DIR_X, DIR_Y = math.sqrt(0.5), math.sqrt(0.5)

-- A pull pressed at the table's center
local function newPull(): Pull.Pull
	return Pull.new(0, 0, CANCEL, FULL)
end

-- Puts the pointer `along` the shot from where it pressed (negative is back, toward the stick) and `across` it
local function pointAt(pull: Pull.Pull, along: number, across: number?)
	local side = across or 0
	Pull.moveTo(pull, DIR_X * along - DIR_Y * side, DIR_Y * along + DIR_X * side, DIR_X, DIR_Y)
end

return function(test, check)
	test("pulling straight back builds power from the cancel zone's edge to full", function()
		local pull = newPull()
		pointAt(pull, -CANCEL)
		check.near(Pull.power(pull), 0, 1e-9, "still in the cancel zone")
		pointAt(pull, -(CANCEL + FULL / 2))
		check.near(Pull.power(pull), 0.5, 1e-9, "halfway")
		pointAt(pull, -(CANCEL + FULL))
		check.equal(Pull.power(pull), 1, "full")
		pointAt(pull, -(CANCEL + 2 * FULL))
		check.equal(Pull.power(pull), 1, "and no more")
	end)

	test("pushing forward well past the start drops power to 0, and it stays there", function()
		local pull = newPull()
		pointAt(pull, -(CANCEL + 0.8 * FULL))
		check.near(Pull.power(pull), 0.8, 1e-9, "pulled back")
		pointAt(pull, 0)
		check.equal(Pull.power(pull), 0, "back at the start")
		-- On well past the start, in small moves, checking all the way
		for i = 1, 20 do
			pointAt(pull, i * FULL / 4)
			check.equal(Pull.power(pull), 0, `pushed on, move {i}`)
		end
		check.truthy(pull.left, "letting go now cancels")
	end)

	test("power counts from where the pull pressed, so after pushing past it, power comes back behind it", function()
		local pull = newPull()
		pointAt(pull, 3 * FULL)
		pointAt(pull, FULL)
		check.equal(Pull.power(pull), 0, "still in front of where it pressed")
		pointAt(pull, -(CANCEL + FULL / 2))
		check.near(Pull.power(pull), 0.5, 1e-9, "behind it again")
	end)

	test("sideways movement neither adds nor removes power", function()
		local pull = newPull()
		pointAt(pull, -(CANCEL + FULL / 2))
		local before = Pull.power(pull)
		pointAt(pull, -(CANCEL + FULL / 2), 3 * FULL)
		check.near(Pull.power(pull), before, 1e-9, "far to one side")
		pointAt(pull, -(CANCEL + FULL / 2), -5 * FULL)
		check.near(Pull.power(pull), before, 1e-9, "far to the other")
	end)

	test("past full power, it stays full until the pointer comes back within the full pull", function()
		local pull = newPull()
		pointAt(pull, -(CANCEL + 3 * FULL))
		pointAt(pull, -(CANCEL + 2 * FULL))
		check.equal(Pull.power(pull), 1, "still past full")
		pointAt(pull, -(CANCEL + 0.75 * FULL))
		check.near(Pull.power(pull), 0.75, 1e-9, "back within it")
	end)
end
