--!strict
local Config = require("../src/Shared/Config")

return function(test, check)
	test("every Config value is a number, string or boolean", function()
		for section, values in Config :: any do
			for name, value in values do
				local kind = type(value)
				check.truthy(kind == "number" or kind == "string" or kind == "boolean", section .. "." .. name)
			end
		end
	end)

	test("the fastest ball moves under a third of its radius per step", function()
		local perStep = Config.Physics.FullPowerSpeed * Config.Physics.TimeStep
		check.truthy(perStep < Config.Table.BallRadius / 3, "moves " .. perStep .. " per step")
	end)

	test("full power rolls about 4 table lengths", function()
		local speed = Config.Physics.FullPowerSpeed
		local distance = speed * speed / (2 * Config.Physics.RollingSlowdown)
		check.near(distance / Config.Table.Length, 4, 0.5)
	end)
end
