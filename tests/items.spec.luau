--!strict
local Config = require("../src/Shared/Config")
local Items = require("../src/Shared/Items")

return function(test, check)
	local BAR = Config.Items.BarPoints
	local function roll(): number
		return 0 -- always the first item in Config.Items.List
	end

	test("a game starts with every seat's bar empty and no items", function()
		local state = Items.new(4)
		check.equal(#state.bars, 4)
		for _, bar in state.bars do
			check.equal(bar.points, 0)
			check.equal(#bar.slots, Config.Items.Slots)
			for _, item in bar.slots do
				check.equal(item, false)
			end
		end
	end)

	test("a full bar gives an item into the first empty slot and keeps what's left over", function()
		local state = Items.new(2)
		Items.add(state, 1, BAR - 2, roll)
		check.equal(state.bars[1].slots[1], false, "not full yet")
		local pop = Items.add(state, 1, Config.Items.OwnBallPoints, roll)
		check.equal(state.bars[1].slots[1], Config.Items.List[1])
		check.equal(state.bars[1].slots[2], false)
		check.equal(state.bars[1].points, Config.Items.OwnBallPoints - 2, "leftover carries over")
		check.equal(pop and pop.points, Config.Items.OwnBallPoints, "the pop shows what was earned")
		check.equal(state.bars[2].points, 0, "the other seat's bar is untouched")
	end)

	test("enough points at once give an item for each full bar", function()
		local state = Items.new(2)
		Items.add(state, 1, 2 * BAR + 1, roll)
		check.truthy(state.bars[1].slots[1] and state.bars[1].slots[2], "both slots filled")
		check.equal(state.bars[1].points, 1)
	end)

	test(
		"with both slots full the bar stops at full, loses extra points, and gives its item once a slot frees",
		function()
			local state = Items.new(2)
			Items.add(state, 1, 2 * BAR, roll)
			Items.add(state, 1, BAR + 5, roll)
			check.equal(state.bars[1].points, BAR, "stops at full")
			state.bars[1].slots[1] = false -- an item was used
			Items.award(state, 1, roll)
			check.truthy(state.bars[1].slots[1], "the waiting item arrives")
			check.equal(state.bars[1].points, 0, "the points past full were lost")
		end
	)

	test("each item is picked from the roll, every one reachable", function()
		local list = Config.Items.List
		for i = 1, #list do
			local state = Items.new(2)
			Items.add(state, 1, BAR, function(): number
				return (i - 0.5) / #list
			end)
			check.equal(state.bars[1].slots[1], list[i])
		end
		local state = Items.new(2)
		Items.add(state, 1, BAR, function(): number
			return 0.9999999
		end)
		check.equal(state.bars[1].slots[1], list[#list], "a roll just under 1 is the last item")
	end)

	test("give puts an item in the first empty slot, and fails when both are full", function()
		local state = Items.new(2)
		check.truthy(Items.give(state, 2, "freeze"))
		check.truthy(Items.give(state, 2, "oilSlick"))
		check.equal(state.bars[2].slots[1], "freeze")
		check.equal(state.bars[2].slots[2], "oilSlick")
		check.truthy(not Items.give(state, 2, "blastBall"))
	end)

	test("held points wait for the next award", function()
		local state = Items.new(2)
		Items.add(state, 1, BAR + 4, roll, true)
		check.equal(state.bars[1].slots[1], false, "held")
		check.equal(state.bars[1].points, BAR, "stops at full while held")
		Items.award(state, 1, roll)
		check.truthy(state.bars[1].slots[1], "arrives at the award")
	end)

	test("only your own group's balls score; the other side's, the 8 and the cue ball don't", function()
		local dropped = { { id = 3, pocket = 1 }, { id = 11, pocket = 2 }, { id = 5, pocket = 4 } }
		check.equal(Items.scoringPots("solids", false, false, dropped), 2)
		check.equal(Items.scoringPots("stripes", false, false, dropped), 1)
		check.equal(Items.scoringPots("solids", false, false, { { id = 8, pocket = 1 }, { id = 0, pocket = 2 } }), 0)
	end)

	test("on an open table any legal pot but the 8 scores", function()
		local dropped = { { id = 3, pocket = 1 }, { id = 11, pocket = 2 }, { id = 8, pocket = 3 } }
		check.equal(Items.scoringPots(nil, false, false, dropped), 2)
	end)

	test("break pots and foul pots score nothing", function()
		local dropped = { { id = 3, pocket = 1 }, { id = 11, pocket = 2 } }
		check.equal(Items.scoringPots(nil, true, false, dropped), 0, "the break")
		check.equal(Items.scoringPots("solids", false, true, dropped), 0, "a foul")
	end)

	test("a pot gives the shooter OwnBallPoints and the opponent who shoots next OpponentBallPoints", function()
		local items = Config.Items
		local state = Items.new(2)
		local pops = Items.afterPots(state, 1, 2, roll)
		check.equal(state.bars[1].points, 2 * items.OwnBallPoints)
		check.equal(state.bars[2].points, 2 * items.OpponentBallPoints)
		check.equal(#pops, 2)
		check.equal(pops[1].seat, 1)
		check.equal(pops[2].seat, 2)
		check.equal(#Items.afterPots(state, 2, 0, roll), 0, "no pots, no pops")
	end)

	test("in 2v2 the opponent's points all go to the one who shoots next", function()
		local items = Config.Items
		-- Turn order A1, B1, A2, B2
		for seat, next in { [1] = 2, [2] = 3, [3] = 4, [4] = 1 } do
			local state = Items.new(4)
			Items.afterPots(state, seat, 1, roll)
			for other = 1, 4 do
				local expected = if other == seat
					then items.OwnBallPoints
					elseif other == next then items.OpponentBallPoints
					else 0
				check.equal(state.bars[other].points, expected, `seat {seat} pots, seat {other}`)
			end
		end
	end)

	-- A few balls: the cue ball, the 3 and the 8 on the table, and the 5 already down
	local BALLS = {
		{ id = 0, x = -4, y = 0, vx = 0, vy = 0 },
		{ id = 3, x = 2, y = 1, vx = 0, vy = 0 },
		{ id = 8, x = 4, y = 0, vx = 0, vy = 0 },
		{ id = 5, x = 0, y = 0, vx = 0, vy = 0, pocket = 2 },
	}
	local TABLE = Config.Table

	local function holding(...: string): Items.State
		local state = Items.new(4)
		for _, item in { ... } do
			Items.give(state, 1, item :: Items.Item)
		end
		return state
	end

	test("using an item spends it at once and frees its slot, so a full bar's waiting item arrives", function()
		local state = holding("blastBall", "powerShot")
		Items.add(state, 1, BAR, roll)
		check.equal(state.bars[1].points, BAR, "waiting for a slot")
		local item = Items.use(state, 1, 2, nil, BALLS, TABLE, roll)
		check.equal(item, "powerShot")
		check.equal(state.bars[1].slots[1], "blastBall")
		check.equal(state.bars[1].slots[2], Config.Items.List[1], "the waiting item took the freed slot")
		check.equal(state.bars[1].points, 0)
		check.equal(state.powerShot, 1)
	end)

	test("one item per shot, until the next shot", function()
		local state = holding("blastBall", "freeze")
		check.truthy(Items.use(state, 1, 1, nil, BALLS, TABLE, roll))
		check.equal(Items.use(state, 1, 2, 3, BALLS, TABLE, roll), nil, "a second item this shot")
		Items.newShot(state, 1, false)
		check.equal(Items.use(state, 1, 2, 3, BALLS, TABLE, roll), "freeze", "the next shot")
	end)

	test("a slot that's empty, missing or not a slot number is refused", function()
		local state = holding("blastBall")
		for _, slot in { 2, 0, 3, 1.5, "1", nil, math.huge, 0 / 0 } :: { any } do
			check.equal(Items.use(state, 1, slot, nil, BALLS, TABLE, roll), nil, tostring(slot))
		end
		check.equal(Items.use(state, 2, 1, nil, BALLS, TABLE, roll), nil, "another seat's slot")
		check.equal(state.bars[1].slots[1], "blastBall", "nothing spent")
	end)

	test("Power Shot lasts the turn, and a second can't be used while it's on", function()
		local state = holding("powerShot", "powerShot")
		check.truthy(Items.use(state, 1, 1, nil, BALLS, TABLE, roll))
		Items.newShot(state, 1, false)
		check.equal(state.powerShot, 1, "still on for the next shot of the turn")
		check.equal(Items.use(state, 1, 2, nil, BALLS, TABLE, roll), nil, "a second Power Shot")
		Items.turnEnded(state, 1)
		check.equal(state.powerShot, nil, "over when the turn passes")
	end)

	test("Blast Ball lasts one shot, even one the clock ran out on", function()
		local state = holding("blastBall")
		Items.use(state, 1, 1, nil, BALLS, TABLE, roll)
		check.truthy(state.blast)
		Items.newShot(state, 2, true)
		check.truthy(not state.blast)
	end)

	test("Freeze needs a ball on the table that isn't the cue ball, the 8 or frozen already", function()
		for _, target in { 0, 8, 5, 16, 3.5, "3", nil, { x = 0, y = 0 } } :: { any } do
			check.equal(Items.use(holding("freeze"), 1, 1, target, BALLS, TABLE, roll), nil, tostring(target))
		end
		local state = holding("freeze")
		local item, target = Items.use(state, 1, 1, 3, BALLS, TABLE, roll)
		check.equal(item, "freeze")
		check.equal(target, 3)
		check.truthy(state.frozen[3])
		Items.newShot(state, 1, false)
		Items.give(state, 1, "freeze")
		check.equal(Items.use(state, 1, 1, 3, BALLS, TABLE, roll), nil, "frozen already")
	end)

	test("Oil Slick needs a finite spot on the felt", function()
		local halfX, halfY = TABLE.Length / 2, TABLE.Width / 2
		for _, target in
			{ { x = halfX + 0.1, y = 0 }, { x = 0, y = -halfY - 0.1 }, { x = 0 / 0, y = 0 }, { x = math.huge, y = 0 }, { x = 1 }, 3, nil } :: { any }
		do
			check.equal(Items.use(holding("oilSlick"), 1, 1, target, BALLS, TABLE, roll), nil)
		end
		local state = holding("oilSlick")
		local item, spot = Items.use(state, 1, 1, { x = 1, y = -2, extra = "ignored" }, BALLS, TABLE, roll)
		check.equal(item, "oilSlick")
		check.equal((spot :: any).x, 1)
		check.equal((spot :: any).extra, nil, "only the checked numbers are kept")
		check.equal(#state.oil, 1)
	end)

	test("Pocket Block needs a pocket that isn't blocked already", function()
		for _, target in { 0, 7, 2.5, "1", nil } :: { any } do
			check.equal(Items.use(holding("pocketBlock"), 1, 1, target, BALLS, TABLE, roll), nil, tostring(target))
		end
		local state = holding("pocketBlock", "pocketBlock")
		check.equal(Items.use(state, 1, 1, 6, BALLS, TABLE, roll), "pocketBlock")
		check.truthy(state.blocked[6])
		Items.newShot(state, 1, false)
		check.equal(Items.use(state, 1, 2, 6, BALLS, TABLE, roll), nil, "blocked already")
	end)

	test("Freeze, Oil Slick and Pocket Block last until the end of the other side's next turn", function()
		local state = holding("freeze")
		Items.newShot(state, 1, true)
		Items.use(state, 1, 1, 3, BALLS, TABLE, roll)
		Items.newShot(state, 1, false)
		check.truthy(state.frozen[3], "for the rest of your own turn")
		Items.turnEnded(state, 1)
		Items.newShot(state, 2, true)
		check.truthy(state.frozen[3], "through the other side's next turn")
		Items.newShot(state, 2, false)
		check.truthy(state.frozen[3], "every shot of it")
		Items.turnEnded(state, 2)
		check.equal(state.frozen[3], nil, "gone once it ends")
	end)

	test("in 2v2 an effect ends after the other team's next turn, and the other side's effects keep going", function()
		local state = Items.new(4)
		Items.give(state, 1, "pocketBlock")
		Items.give(state, 2, "oilSlick")
		-- A1 blocks a pocket, then B1 lays oil
		Items.newShot(state, 1, true)
		Items.use(state, 1, 1, 2, BALLS, TABLE, roll)
		Items.turnEnded(state, 1)
		Items.newShot(state, 2, true)
		Items.use(state, 2, 1, { x = 0, y = 0 }, BALLS, TABLE, roll)
		Items.turnEnded(state, 2)
		check.equal(state.blocked[2], nil, "A1's lid ends after B1's turn")
		check.equal(#state.oil, 1, "B1's oil lasts through A2's turn...")
		Items.newShot(state, 3, true)
		Items.turnEnded(state, 3)
		check.equal(#state.oil, 0, "...and ends with it")
	end)

	test("the effects for the shot carry Blast Ball, and only a seat with Power Shot on may go past full power", function()
		local state = holding("blastBall", "powerShot")
		check.truthy(not Items.effects(state).blast)
		Items.use(state, 1, 1, nil, BALLS, TABLE, roll)
		check.truthy(Items.effects(state).blast, "on for this shot")
		check.equal(Items.maxPower(state, 1), 1)
		Items.newShot(state, 1, false)
		check.truthy(not Items.effects(state).blast, "spent after it")
		Items.use(state, 1, 2, nil, BALLS, TABLE, roll)
		check.equal(Items.maxPower(state, 1), Config.Items.PowerShotMax, "with Power Shot")
		check.equal(Items.maxPower(state, 2), 1, "nobody else")
		Items.turnEnded(state, 1)
		check.equal(Items.maxPower(state, 1), 1, "over with the turn")
	end)
end
