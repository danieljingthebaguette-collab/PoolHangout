--!strict
-- A game's items as plain tables (ARCHITECTURE.md, Items): each seat's item bar and slots, the points that fill the bar
-- and the items it gives. Kept by seat, so a player who takes over a seat gets its items. Match owns the state. Pure
-- Luau, so Lune tests it; it never rolls dice itself: the server passes in `roll`, a random number from 0 up to 1.

local Config = require("./Config")
local EightBall = require("./Rules/EightBall")

local Items = {}

export type Item = "powerShot" | "blastBall" | "freeze" | "oilSlick" | "pocketBlock"
-- One seat's bar: its points, never past Config.Items.BarPoints, and its slots in order, each an item or false when
-- empty (false rather than nil, so the list survives a remote)
export type Bar = { points: number, slots: { Item | false } }
-- Every seat's bar, in turn order
export type State = { bars: { Bar } }
-- A change to a bar, for its "+4" pop: whose, and the points it earned
export type Pop = { seat: number, points: number }

-- What each item is called on screen
Items.NAMES = {
	powerShot = "Power Shot",
	blastBall = "Blast Ball",
	freeze = "Freeze",
	oilSlick = "Oil Slick",
	pocketBlock = "Pocket Block",
} :: { [Item]: string }

function Items.new(seatCount: number): State
	local bars = {}
	for seat = 1, seatCount do
		local slots: { Item | false } = {}
		for slot = 1, Config.Items.Slots do
			slots[slot] = false
		end
		bars[seat] = { points = 0, slots = slots }
	end
	return { bars = bars }
end

local function emptySlot(bar: Bar): number?
	for i, item in bar.slots do
		if not item then
			return i
		end
	end
	return nil
end

-- Puts `item` in a seat's first empty slot. False if both are full.
function Items.give(state: State, seat: number, item: Item): boolean
	local bar = state.bars[seat]
	local slot = emptySlot(bar)
	if slot then
		bar.slots[slot] = item
	end
	return slot ~= nil
end

-- A full bar gives a random item for each BarPoints, into the first empty slot, keeping what's left over. With no empty
-- slot it stays full, and gives its item once a slot frees: call this again then.
function Items.award(state: State, seat: number, roll: () -> number)
	local bar = state.bars[seat]
	local list = Config.Items.List
	while bar.points >= Config.Items.BarPoints and emptySlot(bar) do
		bar.points -= Config.Items.BarPoints
		Items.give(state, seat, list[math.clamp(math.floor(roll() * #list) + 1, 1, #list)] :: Item)
	end
end

-- Adds points to a seat's bar and gives any items it fills. Points past a full bar are lost while both slots are full.
-- With `hold`, the items wait for the next Items.award. Returns the pop to show, or nil for no points.
-- ponytail: a held bar stops at full, so one turn's sinks hold at most one item; let them stack if
-- SinkItemsWaitForTurnEnd is ever turned on.
function Items.add(state: State, seat: number, points: number, roll: () -> number, hold: boolean?): Pop?
	if points <= 0 then
		return nil
	end
	local bar = state.bars[seat]
	bar.points += points
	if not hold then
		Items.award(state, seat, roll)
	end
	bar.points = math.min(bar.points, Config.Items.BarPoints)
	return { seat = seat, points = points }
end

-- How many balls on a shot earn its shooter OwnBallPoints: each ball of their side's group (as it was before the shot)
-- that dropped, or with no group yet, any ball but the cue ball and the 8. None on the break or a foul.
function Items.scoringPots(
	group: EightBall.Group?,
	isBreak: boolean,
	foul: boolean,
	dropped: { { id: number, pocket: number } }
): number
	if isBreak or foul then
		return 0
	end
	local count = 0
	for _, drop in dropped do
		local ballGroup = EightBall.groupOf(drop.id)
		if ballGroup and (group == nil or ballGroup == group) then
			count += 1
		end
	end
	return count
end

-- A shot from `seat` sank `pots` scoring balls: OwnBallPoints each for the shooter, and OpponentBallPoints each, all
-- of it, to the other side's player who shoots next, which in turn order is always the next seat. Returns the pops.
function Items.afterPots(state: State, seat: number, pots: number, roll: () -> number): { Pop }
	local pops = {}
	local items = Config.Items
	local mine = Items.add(state, seat, pots * items.OwnBallPoints, roll, items.SinkItemsWaitForTurnEnd)
	local theirs = Items.add(state, seat % #state.bars + 1, pots * items.OpponentBallPoints, roll)
	if mine then
		table.insert(pops, mine)
	end
	if theirs then
		table.insert(pops, theirs)
	end
	return pops
end

return Items
