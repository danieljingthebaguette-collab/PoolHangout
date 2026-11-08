--!strict
local ShotStance = require("../src/Shared/ShotStance")

return function(test, check)
	local HALF_X, HALF_Y = 9.1, 5.1

	test("the shooter stands straight behind the cue ball along the aim, so they face it", function()
		local spot = ShotStance.spot(0, 0, 0, 3)
		check.near(spot.x, -3, 1e-9, "aiming along +x: 3 studs back along -x")
		check.near(spot.y, 0, 1e-9)
		spot = ShotStance.spot(2, 1, math.pi / 2, 3)
		check.near(spot.x, 2, 1e-9, "aiming along +y")
		check.near(spot.y, -2, 1e-9)
		for i = 0, 7 do
			local aim = i * math.pi / 4
			local at = ShotStance.spot(1, -1, aim, 3)
			-- From the spot, the cue ball lies along the aim
			check.near(math.atan2(-1 - at.y, 1 - at.x) % (2 * math.pi), aim % (2 * math.pi), 1e-9, `aim {aim}`)
		end
	end)

	test("a spot over the table is on top of it; off it, on the floor", function()
		check.truthy(ShotStance.overTable(0, 0, HALF_X, HALF_Y), "the middle")
		check.truthy(ShotStance.overTable(-9, 5, HALF_X, HALF_Y), "a corner of the rails")
		check.truthy(not ShotStance.overTable(-9.5, 0, HALF_X, HALF_Y), "past the end")
		check.truthy(not ShotStance.overTable(0, 6, HALF_X, HALF_Y), "past the side")
	end)

	test("stepping off the table goes straight out past the nearest edge", function()
		local off = ShotStance.offTable(2, 4, HALF_X, HALF_Y, 1)
		check.near(off.x, 2, 1e-9, "near a side: straight across")
		check.near(off.y, HALF_Y + 1, 1e-9)
		off = ShotStance.offTable(-8.5, 0, HALF_X, HALF_Y, 1)
		check.near(off.x, -HALF_X - 1, 1e-9, "near an end: straight out the end")
		off = ShotStance.offTable(-12, 3, HALF_X, HALF_Y, 1)
		check.near(off.x, -12, 1e-9, "already off: stays put")
		check.near(off.y, 3, 1e-9)
	end)

	test("one frame's glide moves at most speed × dt across and climb × dt up, and stops when it's there", function()
		local x, y, h = ShotStance.step(0, 0, 0, 10, 0, 5, 16, 12, 0.1)
		check.near(x, 1.6, 1e-9)
		check.near(y, 0, 1e-9)
		check.near(h, 1.2, 1e-9)
		x, y, h = ShotStance.step(9.9, 0, 4.9, 10, 0, 5, 16, 12, 0.1)
		check.near(x, 10, 1e-9, "doesn't overshoot")
		check.near(h, 5, 1e-9)
		x, y, h = ShotStance.step(3, 4, 2, 3, 4, 2, 16, 12, 0.1)
		check.near(x, 3, 1e-9, "already there")
		check.near(h, 2, 1e-9)
	end)
end
