--!strict
local ShotStance = require("../src/Shared/ShotStance")

return function(test, check)
	local HALF_X, HALF_Y = 9.1, 5.1

	test("the shooter stands straight behind the cue ball along the aim, so they face it", function()
		local spot = ShotStance.spot(0, 0, 0, 3, 0)
		check.near(spot.x, -3, 1e-9, "aiming along +x: 3 studs back along -x")
		check.near(spot.y, 0, 1e-9)
		spot = ShotStance.spot(2, 1, math.pi / 2, 3, 0)
		check.near(spot.x, 2, 1e-9, "aiming along +y")
		check.near(spot.y, -2, 1e-9)
		for i = 0, 7 do
			local aim = i * math.pi / 4
			local at = ShotStance.spot(1, -1, aim, 3, 0)
			-- From the spot, the cue ball lies along the aim
			check.near(math.atan2(-1 - at.y, 1 - at.x) % (2 * math.pi), aim % (2 * math.pi), 1e-9, `aim {aim}`)
		end
	end)

	test(
		"the shooter stands to the left of the shot's line, so the cue passes their back hand, the right one",
		function()
			-- Table y is the felt's Z, so a character facing along +x has +y on its right and -y on its left
			local spot = ShotStance.spot(0, 0, 0, 3, 1)
			check.near(spot.x, -3, 1e-9, "still 3 studs back")
			check.near(spot.y, -1, 1e-9, "1 stud to the left")
			for i = 0, 7 do
				local aim = i * math.pi / 4
				local at = ShotStance.spot(1, -1, aim, 3, 1)
				-- From the spot, the cue ball is 3 studs ahead along the aim and 1 stud to the right
				local toX, toY = 1 - at.x, -1 - at.y
				check.near(toX * math.cos(aim) + toY * math.sin(aim), 3, 1e-9, `ahead, aim {aim}`)
				check.near(-toX * math.sin(aim) + toY * math.cos(aim), 1, 1e-9, `to the right, aim {aim}`)
			end
		end
	)

	test(
		"the shooter faces along the shot: the point beside the cue ball, straight ahead of where they stand",
		function()
			local spot, face = ShotStance.spot(0, 0, 0, 3, 1)
			check.near(face.x, 0, 1e-9, "level with the cue ball")
			check.near(face.y, -1, 1e-9, "1 stud to its left")
			spot, face = ShotStance.spot(1, -1, math.pi / 3, 3, 1)
			check.near(math.atan2(face.y - spot.y, face.x - spot.x), math.pi / 3, 1e-9, "straight ahead is the aim")
		end
	)

	test("a shooter standing off the table keeps clear of its edge; one over it stays on top", function()
		local at = ShotStance.clear(2, 4, HALF_X, HALF_Y, 2)
		check.near(at.x, 2, 1e-9, "over the table: stays")
		check.near(at.y, 4, 1e-9)
		at = ShotStance.clear(2, HALF_Y + 0.5, HALF_X, HALF_Y, 2)
		check.near(at.x, 2, 1e-9, "too close to a side: straight out")
		check.near(at.y, HALF_Y + 2, 1e-9)
		at = ShotStance.clear(-HALF_X - 0.6, HALF_Y + 0.8, HALF_X, HALF_Y, 2)
		check.near(at.x, -HALF_X - 1.2, 1e-9, "too close to a corner: straight out from the corner")
		check.near(at.y, HALF_Y + 1.6, 1e-9)
		at = ShotStance.clear(HALF_X, 0, HALF_X, HALF_Y, 2)
		check.near(at.x, HALF_X + 2, 1e-9, "on the edge itself: out past it")
		check.near(at.y, 0, 1e-9)
		at = ShotStance.clear(-12, 3, HALF_X, HALF_Y, 2)
		check.near(at.x, -12, 1e-9, "already clear: stays put")
		check.near(at.y, 3, 1e-9)
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
		off = ShotStance.offTable(2, HALF_Y + 0.4, HALF_X, HALF_Y, 1)
		check.near(off.x, 2, 1e-9, "beside the table but too close: straight out to the same distance")
		check.near(off.y, HALF_Y + 1, 1e-9)
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
