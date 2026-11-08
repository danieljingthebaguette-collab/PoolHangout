--!strict
-- Your own item slots, bottom center of the top-down view: dark slots with corner brackets, each with its item's icon,
-- or see-through with a dashed outline when empty, and its key, "1" or "2", in a small key box on its corner. The slot
-- you're picking a target for gets a gold outline, and both dim while you can't use an item. ShotController decides
-- what they show.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Theme = require(ReplicatedStorage.Shared.Theme)
local Card = require(script.Parent.Card)
local ItemIcons = require(script.Parent.ItemIcons)
local Ui = require(script.Parent.Ui)

local ItemSlots = {}

type Slot = {
	box: Frame,
	icon: Frame,
	dashes: Frame,
	brackets: { GuiObject },
	glow: UIStroke,
	veil: Frame,
	key: TextLabel,
	keyEdge: UIStroke,
}

-- Both slots, once they're built, and what they show, so a call that changes nothing touches nothing
local row: Frame? = nil
local slots: { Slot } = {}
local shown: string? = nil

-- The dashed outline of an empty slot, along the inside of each side
local function dashes(box: Frame): Frame
	local ui = Theme.Ui
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundTransparency = 1
	frame.Parent = box
	for k = 1, ui.ItemDashCount do
		local along = (k - 0.5) / ui.ItemDashCount
		for _, side in { Vector2.new(along, 0), Vector2.new(along, 1), Vector2.new(0, along), Vector2.new(1, along) } do
			local across = side.Y == 0 or side.Y == 1
			local dash = Instance.new("Frame")
			dash.AnchorPoint = Vector2.new(if across then 0.5 else side.X, if across then side.Y else 0.5)
			dash.Position = UDim2.fromScale(side.X, side.Y)
			dash.Size = if across
				then UDim2.fromOffset(ui.ItemDashLength, ui.BracketThickness)
				else UDim2.fromOffset(ui.BracketThickness, ui.ItemDashLength)
			dash.BackgroundColor3 = Theme.Colors.DarkText
			dash.BorderSizePixel = 0
			dash.Parent = frame
		end
	end
	return frame
end

local function slot(parent: Frame, i: number): Slot
	local ui = Theme.Ui
	local box = Instance.new("Frame")
	box.Position = UDim2.fromOffset((i - 1) * (ui.ItemSlotSize + ui.ItemSlotSpacing), 0)
	box.Size = UDim2.fromOffset(ui.ItemSlotSize, ui.ItemSlotSize)
	box.Active = true -- pressing it doesn't start a shot
	Card.style(box, true)
	box.Parent = parent
	local brackets = {}
	for _, child in box:GetChildren() do
		if child.Name == "Bracket" and child:IsA("GuiObject") then
			table.insert(brackets, child)
		end
	end
	local glow = Instance.new("UIStroke")
	glow.Color = Theme.Colors.ItemPicking
	glow.Thickness = ui.TurnGlow
	glow.Enabled = false
	glow.Parent = box
	local icon = Instance.new("Frame")
	icon.Position = UDim2.fromOffset(ui.ItemSlotIconInset, ui.ItemSlotIconInset)
	icon.Size = UDim2.fromOffset(ui.ItemSlotSize - 2 * ui.ItemSlotIconInset, ui.ItemSlotSize - 2 * ui.ItemSlotIconInset)
	icon.BackgroundTransparency = 1
	icon.Parent = box
	-- Dims a full slot: a dark veil over its icon and brackets, so the slot stays a solid dark box over the table. A
	-- CanvasGroup would fade it instead, but the HUD's screen orders by ZIndex across the whole screen, which
	-- CanvasGroups ignore.
	local veil = Instance.new("Frame")
	veil.Size = UDim2.fromScale(1, 1)
	veil.BackgroundColor3 = Theme.Colors.Dark
	veil.BackgroundTransparency = ui.ItemDimVeil
	veil.BorderSizePixel = 0
	veil.ZIndex = 3 -- over the brackets (2), under the key
	veil.Visible = false
	Ui.roundCorners(veil)
	veil.Parent = box
	-- The key, like the control hints' key boxes, over the top-left bracket
	local key = Ui.label(tostring(i), box)
	key.Position = UDim2.fromOffset(-ui.ItemKeyOverhang, -ui.ItemKeyOverhang)
	key.Size = UDim2.fromOffset(ui.ItemKeySize, ui.ItemKeySize)
	key.BackgroundTransparency = 0
	key.BackgroundColor3 = Theme.Colors.Dark
	key.TextColor3 = Theme.Colors.DarkText
	key.TextSize = ui.ItemKeyTextSize
	key.ZIndex = 4
	Ui.roundCorners(key)
	local keyEdge = Instance.new("UIStroke")
	keyEdge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	keyEdge.Color = Theme.Colors.DarkText
	keyEdge.Thickness = ui.ItemKeyEdge
	keyEdge.Parent = key
	return {
		box = box,
		icon = icon,
		dashes = dashes(box),
		brackets = brackets,
		glow = glow,
		veil = veil,
		key = key,
		keyEdge = keyEdge,
	}
end

-- Builds the slots bottom center of `gui`, hidden. `gui` ignores the top bar's inset. With the key boxes poking out
-- they reach ItemSlotSize + ItemKeyOverhang + Padding up the screen, inside Hints.bottomBand().
function ItemSlots.build(gui: ScreenGui)
	local ui = Theme.Ui
	local count = Config.Items.Slots
	local frame = Instance.new("Frame")
	frame.AnchorPoint = Vector2.new(0.5, 1)
	frame.Position = UDim2.new(0.5, 0, 1, -ui.Padding) -- level with the gear's and the hints' bottoms
	frame.Size = UDim2.fromOffset(count * ui.ItemSlotSize + (count - 1) * ui.ItemSlotSpacing, ui.ItemSlotSize)
	frame.BackgroundTransparency = 1
	frame.Visible = false
	frame.Parent = gui
	slots = {}
	for i = 1, count do
		slots[i] = slot(frame, i)
	end
	row = frame
	shown = nil
end

-- Shows your slots: each one's item, or false for an empty slot. `picking` is the slot whose target you're choosing,
-- and `usable` false dims both. Nil slots hide them. Called every frame, so it only changes what's different.
function ItemSlots.show(items: { string | false }?, picking: number?, usable: boolean)
	local state = if items then `{items[1]} {items[2]} {picking} {usable}` else nil
	if not row or state == shown then
		return
	end
	shown = state
	row.Visible = items ~= nil
	if not items then
		return
	end
	local keyFade = if usable then 0 else Theme.Ui.ItemDimKey
	for i, s in slots do
		local item = items[i]
		local full = item ~= nil and item ~= false
		ItemIcons.draw(if item then item :: string else "", s.icon)
		s.box.BackgroundTransparency = if full then 0 else Theme.Ui.ItemEmptyTransparency
		s.dashes.Visible = not full
		for _, arm in s.brackets do
			arm.Visible = full
		end
		s.glow.Enabled = picking == i
		s.veil.Visible = full and not usable
		s.key.TextTransparency = keyFade
		s.keyEdge.Transparency = keyFade
	end
end

return ItemSlots
