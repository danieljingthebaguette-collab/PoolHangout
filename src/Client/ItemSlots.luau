--!strict
-- Your abilities, bottom center of the top-down view while you play: your item bar, filling toward your next one, and
-- under it a row for each slot, slot 1 on top, each like a control hint: its key, "1" or "2", in a dark key box, its
-- icon on a dark box, then a cream label with its name and what it does. An empty slot shows only its key and an empty
-- dark square. The row you're picking a target for gets a gold outline, the rows dim while you can't use one, and a
-- refused one's label turns coral and says why. Clicking a row does what its key does (onPress). ShotController
-- decides what the rows show, Hud the bar.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Items = require(ReplicatedStorage.Shared.Items)
local Theme = require(ReplicatedStorage.Shared.Theme)
local ItemIcons = require(script.Parent.ItemIcons)
local Ui = require(script.Parent.Ui)

local ItemSlots = {}

type Row = {
	frame: TextButton,
	glow: UIStroke,
	key: TextLabel,
	icon: Frame,
	veil: Frame,
	label: Frame,
	name: TextLabel,
	line: TextLabel,
}

-- The rows' column and each slot's row, once they're built, and what they show, so a call that changes nothing
-- touches nothing
local column: Frame? = nil
local rows: { Row } = {}
local shown: string? = nil
-- Your item bar above the rows: its track, its gold fill and the glow it gets when full
local bar: { track: Frame, fill: Frame, glow: UIStroke }? = nil
-- What a click on a row does, given its slot: the same as pressing its key
local pressed: ((slot: number) -> ())? = nil

-- Lays out `parent`'s children side by side, `gap` apart, centered up and down
local function sideBySide(parent: Instance, gap: number)
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, gap)
	layout.Parent = parent
end

-- Text as wide as it needs, as tall as its row
local function text(parent: Instance, order: number, size: number): TextLabel
	local label = Ui.label("", parent)
	label.LayoutOrder = order
	label.Size = UDim2.fromScale(0, 1)
	label.AutomaticSize = Enum.AutomaticSize.X
	label.TextSize = size
	return label
end

local function row(parent: Frame, i: number): Row
	local ui = Theme.Ui
	-- A button, so a click on the row does what its key does and never starts a shot
	local frame = Instance.new("TextButton")
	frame.Text = ""
	frame.AutoButtonColor = false
	frame.LayoutOrder = i
	frame.Size = UDim2.fromOffset(0, ui.HintHeight)
	frame.AutomaticSize = Enum.AutomaticSize.X
	frame.BackgroundTransparency = 1
	frame.Activated:Connect(function()
		if pressed then
			pressed(i)
		end
	end)
	frame.Visible = false
	Ui.roundCorners(frame)
	frame.Parent = parent
	sideBySide(frame, ui.Padding / 2)
	local glow = Instance.new("UIStroke")
	glow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	glow.Color = Theme.Colors.ItemPicking
	glow.Thickness = ui.TurnGlow
	glow.Enabled = false
	glow.Parent = frame
	-- The key, like a control hint's key box
	local key = Ui.label(tostring(i), frame)
	key.LayoutOrder = 1
	key.Size = UDim2.fromOffset(ui.HintHeight, ui.HintHeight)
	key.BackgroundTransparency = 0
	key.BackgroundColor3 = Theme.Colors.Dark
	key.TextColor3 = Theme.Colors.DarkText
	Ui.roundCorners(key)
	-- The icon on a dark box, since the icons are drawn for dark slots, with a dark veil to dim it
	local iconBox = Instance.new("Frame")
	iconBox.LayoutOrder = 2
	iconBox.Size = UDim2.fromOffset(ui.HintHeight, ui.HintHeight)
	iconBox.BackgroundColor3 = Theme.Colors.Dark
	iconBox.BorderSizePixel = 0
	Ui.roundCorners(iconBox)
	iconBox.Parent = frame
	local icon = Instance.new("Frame")
	icon.Position = UDim2.fromOffset(ui.ItemRowIconInset, ui.ItemRowIconInset)
	icon.Size = UDim2.new(1, -2 * ui.ItemRowIconInset, 1, -2 * ui.ItemRowIconInset)
	icon.BackgroundTransparency = 1
	icon.Parent = iconBox
	local veil = Instance.new("Frame")
	veil.Size = UDim2.fromScale(1, 1)
	veil.BackgroundColor3 = Theme.Colors.Dark
	veil.BackgroundTransparency = ui.ItemDimVeil
	veil.BorderSizePixel = 0
	veil.ZIndex = 2 -- over the icon
	veil.Visible = false
	Ui.roundCorners(veil)
	veil.Parent = iconBox
	-- The name and what it does, on a label box like a control hint's
	local label = Instance.new("Frame")
	label.LayoutOrder = 3
	label.Size = UDim2.fromOffset(0, ui.HintHeight)
	label.AutomaticSize = Enum.AutomaticSize.X
	label.BorderSizePixel = 0
	Ui.roundCorners(label)
	label.Parent = frame
	sideBySide(label, ui.Padding)
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, ui.Padding)
	padding.PaddingRight = padding.PaddingLeft
	padding.Parent = label
	return {
		frame = frame,
		glow = glow,
		key = key,
		icon = icon,
		veil = veil,
		label = label,
		name = text(label, 1, Theme.TextSize),
		line = text(label, 2, ui.ItemLineTextSize),
	}
end

-- Builds the rows bottom center of `gui`, hidden. `gui` ignores the top bar's inset. Both rows together are as tall as
-- two control hints, inside Hints.bottomBand().
function ItemSlots.build(gui: ScreenGui)
	local ui = Theme.Ui
	local frame = Instance.new("Frame")
	frame.AnchorPoint = Vector2.new(0.5, 1)
	frame.Position = UDim2.new(0.5, 0, 1, -ui.Padding) -- level with the hints' bottoms
	frame.AutomaticSize = Enum.AutomaticSize.XY
	frame.BackgroundTransparency = 1
	frame.Visible = false
	frame.Parent = gui
	local layout = Instance.new("UIListLayout")
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Left -- so the key boxes line up
	layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, ui.Padding / 2)
	layout.Parent = frame
	-- Your item bar, above the rows, as wide as an ability's name and line need to be noticed
	local track = Instance.new("Frame")
	track.LayoutOrder = 0
	track.Size = UDim2.fromOffset(ui.ItemBottomBarWidth, ui.ItemBarHeight)
	track.BackgroundColor3 = Theme.Colors.Dark
	track.BorderSizePixel = 0
	track.Parent = frame
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = Theme.Colors.Fill
	fill.BorderSizePixel = 0
	fill.Parent = track
	-- Full with both slots full: it glows until a slot frees and its ability arrives
	local glow = Instance.new("UIStroke")
	glow.Color = Theme.Colors.TurnGlow
	glow.Thickness = ui.TurnGlow
	glow.Enabled = false
	glow.Parent = track
	bar = { track = track, fill = fill, glow = glow }
	rows = {}
	for i = 1, Config.Items.Slots do
		rows[i] = row(frame, i)
	end
	column = frame
	shown = nil
end

-- A "+4" that rises from your bar and fades, so you learn what fills it
local function pop(track: Frame, points: number)
	local ui = Theme.Ui
	local label = Ui.label(`+{points}`, track)
	label.AnchorPoint = Vector2.new(0.5, 1)
	label.Position = UDim2.fromScale(0.5, 0)
	label.Size = UDim2.new(1, 0, 0, ui.ItemPopTextSize)
	label.TextSize = ui.ItemPopTextSize
	label.TextColor3 = Theme.Colors.Fill
	label.ZIndex = 2
	local edge = Instance.new("UIStroke")
	edge.Color = Theme.Colors.Text
	edge.Parent = label
	local info = TweenInfo.new(ui.ItemPopSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(label, info, { Position = UDim2.new(0.5, 0, 0, -ui.ItemPopRise), TextTransparency = 1 }):Play()
	TweenService:Create(edge, info, { Transparency = 1 }):Play()
	task.delay(ui.ItemPopSeconds, label.Destroy, label)
end

-- Shows your item bar's points, with a pop for each fill just earned, or hides it with nil while you're not playing
function ItemSlots.showBar(points: number?, pops: { number }?)
	if not bar then
		return
	end
	bar.track.Visible = points ~= nil
	if points then
		local share = math.clamp(points / Config.Items.BarPoints, 0, 1)
		bar.fill.Size = UDim2.fromScale(share, 1)
		bar.glow.Enabled = share >= 1
		for _, earned in (pops or {}) :: { number } do
			pop(bar.track, earned)
		end
	end
end

-- What clicking a row does, given its slot, or nothing with nil. ShotController sets it to the same as the keys.
function ItemSlots.onPress(action: ((slot: number) -> ())?)
	pressed = action
end

-- Shows your items: each slot's item, or false for an empty slot. `picking` is the slot whose target you're choosing,
-- `usable` false dims the rows, and `refusal` says why a slot's item can't be used, in place of what it does. Nil slots
-- hide them. Called every frame, so it only changes what's different.
function ItemSlots.show(
	items: { string | false }?,
	picking: number?,
	usable: boolean,
	refusal: { slot: number, text: string }?
)
	local state = if items
		then `{items[1]} {items[2]} {picking} {usable} {refusal and refusal.slot} {refusal and refusal.text}`
		else nil
	if not column or state == shown then
		return
	end
	shown = state
	column.Visible = items ~= nil
	if not items then
		return
	end
	local ui = Theme.Ui
	for i, r in rows do
		local item = if items[i] then items[i] :: string else nil
		-- Every slot has its row: an empty one shows only its key and an empty dark square
		r.frame.Visible = true
		r.label.Visible = item ~= nil
		ItemIcons.draw(item or "", r.icon)
		if not item then
			r.glow.Enabled = false
			r.veil.Visible = false
			r.key.TextTransparency = if usable then 0 else ui.ItemDimText
		else
			local refused = refusal ~= nil and refusal.slot == i
			-- A refusal is a warning, so it stays readable while the rest dim
			local dim = not usable and not refused
			local fade = if dim then ui.ItemDimText else 0
			r.name.Text = Items.NAMES[item] or item
			r.line.Text = if refusal and refused then refusal.text else Items.LINES[item] or ""
			r.line.TextColor3 = if refused then Theme.Colors.Text else Theme.Colors.ItemLine
			r.label.BackgroundColor3 = if refused then Theme.Colors.ItemRefusal else Theme.Colors.Panel
			r.label.BackgroundTransparency = if refused then 0 elseif dim then ui.ItemDimBox else ui.HudTransparency
			r.glow.Enabled = picking == i
			r.veil.Visible = dim
			r.key.TextTransparency = fade
			r.name.TextTransparency = fade
			r.line.TextTransparency = fade
		end
	end
end

return ItemSlots
