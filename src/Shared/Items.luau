--!strict
-- A game's items as plain tables (ARCHITECTURE.md, Items): each seat's item bar and slots, the points that fill the bar
-- and the items it gives, using them, and the effects they leave on the table until they end. Kept by seat, so a player
-- who takes over a seat gets its items. Match owns the state. Pure Luau, so Lune tests it; it never rolls dice itself:
-- the server passes in `roll`, a random number from 0 up to 1.

local Config = require("./Config")
local EightBall = require("./Rules/EightBall")
local Geometry = require("./Physics/Geometry")
local Simulate = require("./Physics/Simulate")
local TableFlow = require("./Rules/TableFlow")

local Items = {}

-- An item's name, one of Config.Items.List: "powerShot", "blastBall", "freeze", "oilSlick" or "pocketBlock"
export type Item = string
-- One seat's bar: its points, never past Config.Items.BarPoints, and its slots in order, each an item or false when
-- empty (false rather than nil, so the list survives a remote)
export type Bar = { points: number, slots: { Item | false } }
-- A spot on the felt, in table space
export type Spot = { x: number, y: number }
-- What an item is used on: a ball id for Freeze, a spot for Oil Slick, a pocket id for Pocket Block, nothing for the
-- others
export type Target = number | Spot
-- An effect that lasts until the end of the other side's next turn: the side that used it, and whether that turn has
-- started
export type Lasting = { side: EightBall.Side, started: boolean }
export type State = {
	-- Every seat's bar, in turn order
	bars: { Bar },
	-- An item was used on this shot
	used: boolean,
	-- The seat whose Power Shot is on, for the rest of its turn
	powerShot: number?,
	-- Blast Ball is on for this shot
	blast: boolean,
	-- Frozen balls by id, blocked pockets by id, and oil patches
	frozen: { [number]: Lasting },
	blocked: { [number]: Lasting },
	oil: { { side: EightBall.Side, started: boolean, x: number, y: number } },
	-- What each side froze or blocked, like "ball 3" or "pocket 2", on its turn now and its turn before, since a side
	-- can't pick the same target on two of its turns in a row
	targets: { [EightBall.Side]: { now: { [string]: boolean }, before: { [string]: boolean } } },
}
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

-- What each item does, in one short line for players, shown under its slot and under its big name as it's used
Items.LINES = {
	powerShot = "Hit harder: up to 150% power for the rest of your turn",
	blastBall = "The first ball you hit blasts the balls around it away",
	freeze = "Pick a ball: it can't move, and balls bounce off it, until after their next turn",
	oilSlick = "Pick a spot: balls roll farther across the oil",
	pocketBlock = "Pick a pocket: a lid blocks it until after their next turn",
} :: { [Item]: string }

-- What each item needs picked before it's used: a ball, a spot on the felt or a pocket. The others act at once.
Items.TARGETS = { freeze = "ball", oilSlick = "spot", pocketBlock = "pocket" } :: { [Item]: string }

function Items.new(seatCount: number): State
	local bars = {}
	for seat = 1, seatCount do
		local slots: { Item | false } = {}
		for slot = 1, Config.Items.Slots do
			slots[slot] = false
		end
		bars[seat] = { points = 0, slots = slots }
	end
	return {
		bars = bars,
		used = false,
		powerShot = nil,
		blast = false,
		frozen = {},
		blocked = {},
		oil = {},
		targets = { A = { now = {}, before = {} }, B = { now = {}, before = {} } },
	}
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

-- A whole number from `low` to `high`, or nil
local function wholeIn(value: unknown, low: number, high: number): number?
	if type(value) == "number" and value == math.floor(value) and value >= low and value <= high then
		return value
	end
	return nil
end

-- Whether ball `id` is still on the table, and whether it's the last of its group (solids or stripes) left there
local function onTable(balls: { EightBall.Ball }, id: number): (boolean, boolean)
	local group, here, left = EightBall.groupOf(id), false, 0
	for _, ball in balls do
		if not ball.pocket and EightBall.groupOf(ball.id) == group then
			left += 1
			here = here or ball.id == id
		end
	end
	return here, left == 1
end

-- Checks an item's target, from a client so untrusted, with the lock-outs so nobody can be stopped from winning:
-- - a ball on the table that isn't the cue ball, the 8, the last ball left in its group or frozen already
-- - a finite spot on the felt
-- - a pocket that isn't blocked already, and not while the other side is shooting at the 8
-- and for a ball or a pocket, not one this side picked on its turn before. Returns it as checked, or nil and why, in
-- words for the player.
local function checkTarget(
	state: State,
	side: EightBall.Side,
	kind: string,
	target: unknown,
	balls: { EightBall.Ball },
	tableParams: Geometry.TableParams,
	groups: EightBall.Groups
): (Target?, string?)
	local before = state.targets[side].before
	if kind == "ball" then
		local id = wholeIn(target, 0, 15)
		if id == 0 then
			return nil, "Can't freeze the cue ball"
		elseif id == 8 then
			return nil, "Can't freeze the 8"
		elseif not id then
			return nil, "Pick a ball on the table"
		elseif state.frozen[id] then
			return nil, "That ball is frozen already"
		elseif before[`ball {id}`] then
			return nil, "You froze that ball last turn"
		end
		local here, last = onTable(balls, id)
		if not here then
			return nil, "Pick a ball on the table"
		elseif last then
			return nil, `Can't freeze the last {if id < 8 then "solid" else "stripe"}`
		end
		return id, nil
	elseif kind == "spot" then
		if type(target) ~= "table" then
			return nil, "Pick a spot on the felt"
		end
		local x, y = (target :: any).x, (target :: any).y
		if
			type(x) ~= "number"
			or type(y) ~= "number"
			or not (TableFlow.isFinite(x) and TableFlow.isFinite(y))
			or math.abs(x) > tableParams.Length / 2
			or math.abs(y) > tableParams.Width / 2
		then
			return nil, "Pick a spot on the felt"
		end
		return { x = x, y = y }, nil
	end
	local pocket = wholeIn(target, 1, #Geometry.build(tableParams).pockets)
	local other: EightBall.Side = TableFlow.otherSide(side)
	if not pocket then
		return nil, "Pick a pocket"
	elseif state.blocked[pocket] then
		return nil, "That pocket is blocked already"
	elseif before[`pocket {pocket}`] then
		return nil, "You blocked that pocket last turn"
	elseif groups[other] ~= nil and EightBall.groupCleared(groups, other, balls) then
		return nil, "Can't block a pocket while they're on the 8"
	end
	return pocket, nil
end

-- The seat's shooter uses the item in `slot`, with `target` for the items that need one (Items.TARGETS). From a client,
-- so every argument is checked: one item a shot, a slot holding an item, no second Power Shot while one is on, and an
-- allowed target, the lock-outs included (`groups` are each side's group now). It's spent at once and its slot frees,
-- so a full bar's waiting item arrives. Returns the item and its checked target, or nil when it's refused, with why in
-- words for the player when it's the target.
function Items.use(
	state: State,
	seat: number,
	slot: unknown,
	target: unknown,
	balls: { EightBall.Ball },
	tableParams: Geometry.TableParams,
	roll: () -> number,
	groups: EightBall.Groups?
): (Item?, Target?, string?)
	local index = wholeIn(slot, 1, Config.Items.Slots)
	local bar = state.bars[seat]
	local item = if index and bar and not state.used and bar.slots[index] then bar.slots[index] :: Item else nil
	if not (index and item) or (item == "powerShot" and state.powerShot) then
		return nil, nil, nil
	end
	local side: EightBall.Side = TableFlow.sideOf(seat)
	local kind = Items.TARGETS[item]
	local checked: Target?, why: string? = nil, nil
	if kind then
		checked, why = checkTarget(state, side, kind, target, balls, tableParams, groups or {})
		if not checked then
			return nil, nil, why
		end
	end
	local lasting: Lasting = { side = side, started = false }
	if item == "powerShot" then
		state.powerShot = seat
	elseif item == "blastBall" then
		state.blast = true
	elseif item == "freeze" then
		state.frozen[checked :: number] = lasting
		state.targets[side].now[`ball {checked}`] = true
	elseif item == "pocketBlock" then
		state.blocked[checked :: number] = lasting
		state.targets[side].now[`pocket {checked}`] = true
	else
		local spot = checked :: Spot
		table.insert(state.oil, { side = side, started = false, x = spot.x, y = spot.y })
	end
	bar.slots[index] = false
	state.used = true
	Items.award(state, seat, roll)
	return item, checked, nil
end

-- What the items on now change about the next shot, for the simulation on the server and every screen, and to draw
function Items.effects(state: State): Simulate.Effects
	local frozen, blocked, oil = {}, {}, {}
	for id in state.frozen do
		table.insert(frozen, id)
	end
	for index in state.blocked do
		table.insert(blocked, index)
	end
	for _, patch in state.oil do
		table.insert(oil, { x = patch.x, y = patch.y })
	end
	table.sort(frozen)
	table.sort(blocked)
	return { blast = state.blast, frozen = frozen, blocked = blocked, oil = oil }
end

-- Whether a pocket may be called for the 8: not while it's blocked
function Items.callable(state: State, pocket: number?): boolean
	return pocket == nil or not state.blocked[pocket]
end

-- The most power the seat's shooter may use: past 1 while their Power Shot is on
function Items.maxPower(state: State, seat: number): number
	return if state.powerShot == seat then Config.Items.PowerShotMax else 1
end

-- Every effect that lasts until the end of the other side's next turn
local function lastings(state: State): { Lasting }
	local all: { Lasting } = {}
	for _, lasting in state.frozen do
		table.insert(all, lasting)
	end
	for _, lasting in state.blocked do
		table.insert(all, lasting)
	end
	for _, patch in state.oil do
		table.insert(all, patch)
	end
	return all
end

-- A shot is up for `seat`: nothing used on it yet, and the last shot's Blast Ball is spent, even if that shot never
-- went. `fresh` when it starts a new turn: for effects the other side used, this is their next turn.
function Items.newShot(state: State, seat: number, fresh: boolean)
	state.used = false
	state.blast = false
	if fresh then
		local side: EightBall.Side = TableFlow.sideOf(seat)
		-- What this side picked on its last turn is off limits for this one
		local targets = state.targets[side]
		targets.before, targets.now = targets.now, {}
		for _, lasting in lastings(state) do
			if lasting.side ~= side then
				lasting.started = true
			end
		end
	end
end

-- The turn passes from `seat`: its Power Shot ends, and so does every effect the other side used whose next turn this
-- was
function Items.turnEnded(state: State, seat: number)
	state.powerShot = nil
	local side = TableFlow.sideOf(seat)
	local function over(lasting: Lasting): boolean
		return lasting.side ~= side and lasting.started
	end
	for id, lasting in state.frozen do
		if over(lasting) then
			state.frozen[id] = nil
		end
	end
	for id, lasting in state.blocked do
		if over(lasting) then
			state.blocked[id] = nil
		end
	end
	for i = #state.oil, 1, -1 do
		if over(state.oil[i]) then
			table.remove(state.oil, i)
		end
	end
end

return Items
