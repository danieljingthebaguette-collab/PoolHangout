--!strict
local Config = require("../src/Shared/Config")

return function(test, check)
	test("every Config value is a number, string or boolean, or a list of them", function()
		local function checkPlain(value: any, path: string)
			local kind = type(value)
			if kind == "table" then
				for key, inner in value do
					checkPlain(inner, `{path}.{key}`)
				end
			else
				check.truthy(kind == "number" or kind == "string" or kind == "boolean", path)
			end
		end
		checkPlain(Config, "Config")
	end)

	test("every physics test slider sets a Config value that starts inside its range", function()
		for _, slider in Config.Debug.TestSliders do
			local value = (Config :: any)[slider.group][slider.name]
			check.truthy(type(value) == "number" and value >= slider.min and value <= slider.max, slider.name)
		end
	end)

	-- Faster balls split a step into sub-steps, which costs time, so only the break should need them. The step
	-- measures speed as |vx| + |vy|, up to √2 times the speed on a diagonal.
	test("a normal full-power shot fits in one step, even at the speed slider's top", function()
		local fastest = Config.Physics.FullPowerSpeed
		for _, slider in Config.Debug.TestSliders do
			if slider.name == "FullPowerSpeed" then
				fastest = math.max(fastest, slider.max)
			end
		end
		local perStep = fastest * math.sqrt(2) * Config.Physics.TimeStep
		local limit = Config.Physics.MaxStepTravel * Config.Table.BallRadius
		check.truthy(perStep <= limit, `moves {perStep} per step, over {limit}`)
	end)

	test("full power rolls about 11 table lengths", function()
		local speed = Config.Physics.FullPowerSpeed
		local distance = speed * speed / (2 * Config.Physics.RollingSlowdown)
		check.near(distance / Config.Table.Length, 11, 1)
	end)
end
