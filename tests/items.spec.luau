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
end
