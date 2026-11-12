--!strict
-- Your 2 ability squares, bottom center of the screen whenever you're at a table, in either view: side by side, each
-- with its key, 1 or 2, on a tab on its bottom edge, just an outline when empty and the ability's icon on a dark tile
-- when held. Your ability bar sits under them in segments, filling toward your next ability, with a "+4" for each
-- fill. While you pick a target that square is outlined in gold, the squares dim while you can't use one, and a coral
-- note above them says why a target was refused. Clicking a square does what its key does (onPress). Sized for a
-- 1080-pixel-high screen and scaled to the real one. Hud fills the squares and bar from ItemsChanged; ShotController
-- sets picking, usable and the refusal.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Theme = require(ReplicatedStorage.Shared.Theme)
local ItemIcons = require(script.Parent.ItemIcons)
local Ui = require(script.Parent.Ui)
local UiScale = require(script.Parent.UiScale)

local ItemSlots = {}

type Square = { button: TextButton, outline: UIStroke, icon: Frame, veil: Frame }

-- Everything, once it's built
local gui: ScreenGui? = nil
local squares: { Square } = {}
local segments: { Frame } = {}
local barGlow: UIStroke? = nil
local barFrame: Frame? = nil
local refusalLabel: TextLabel? = nil
-- What a click on a square does, given its slot: the same as pressing its key
local pressed: ((slot: number) -> ())? = nil
-- What each square holds, and the state ShotController last set, so nothing is redrawn when nothing changed
local held: { string | false } = {}
local shownState: string? = nil

local look = Theme.Abilities

-- How tall the squares and bar stand above the screen's bottom edge, in real pixels, for the top-down view to keep
-- clear
function ItemSlots.reserve(screenHeight: number): number
	local scale = screenHeight / look.DesignHeight * UiScale.get()
	return (look.BottomMargin + look.SlotSize + look.BarGap + look.BarHeight) * scale + Theme.Ui.Padding
end

local function square(parent: Frame, slot: number, x: number): Square
	local button = Instance.new("TextButton")
	button.Text = ""
	button.AutoButtonColor = false
	button.Position = UDim2.fromOffset(x, 0)
	button.Size = UDim2.fromOffset(look.SlotSize, look.SlotSize)
	button.BackgroundColor3 = Theme.Colors.Dark
	button.BackgroundTransparency = 1
	button.Parent = parent
	Ui.roundCorners(button, UDim.new(0, look.SlotCorner))
	button.Activated:Connect(function()
		if pressed then
			pressed(slot)
		end
	end)
	local outline = Instance.new("UIStroke")
	outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	outline.Color = Theme.Colors.Panel
	outline.Thickness = look.SlotOutline
	outline.Transparency = look.SlotOutlineTransparency
	outline.Parent = button
	local icon = Instance.new("Frame")
	icon.Position = UDim2.fromOffset(look.IconInset, look.IconInset)
	icon.Size = UDim2.new(1, -2 * look.IconInset, 1, -2 * look.IconInset)
	icon.BackgroundTransparency = 1
	icon.Parent = button
	local veil = Instance.new("Frame")
	veil.Size = UDim2.fromScale(1, 1)
	veil.BackgroundColor3 = Theme.Colors.Dark
	veil.BackgroundTransparency = look.DimTransparency
	veil.BorderSizePixel = 0
	veil.ZIndex = 2
	veil.Visible = false
	Ui.roundCorners(veil, UDim.new(0, look.SlotCorner))
	veil.Parent = button
	-- The key on a cream tab, half over the square's bottom edge
	local tab = Ui.label(tostring(slot), button)
	tab.AnchorPoint = Vector2.new(0.5, 0.5)
	tab.Position = UDim2.fromScale(0.5, 1)
	tab.Size = UDim2.fromOffset(look.TabWidth, look.TabHeight)
	tab.TextSize = look.TabTextSize
	tab.BackgroundTransparency = 0
	tab.BackgroundColor3 = Theme.Colors.Panel
	tab.ZIndex = 3
	Ui.roundCorners(tab)
	return { button = button, outline = outline, icon = icon, veil = veil }
end

-- Builds the squares, the bar and the refusal note on their own screen, hidden until you're at a table
function ItemSlots.build(playerGui: Instance)
	local screen = Instance.new("ScreenGui")
	screen.Name = "AbilitySlots"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true -- measured from the screen's real bottom, like the top-down view's reserves
	screen.Enabled = false
	local box = Instance.new("Frame")
	box.AnchorPoint = Vector2.new(0.5, 1)
	box.Position = UDim2.new(0.5, 0, 1, -look.BottomMargin)
	box.Size = UDim2.fromOffset(look.BarWidth, look.SlotSize + look.BarGap + look.BarHeight)
	box.BackgroundTransparency = 1
	box.Parent = screen
	local scale = Instance.new("UIScale")
	scale.Parent = box
	local function fit()
		scale.Scale = screen.AbsoluteSize.Y / look.DesignHeight * UiScale.get()
	end
	screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	UiScale.onChanged(fit)

	local across = 2 * look.SlotSize + look.SlotGap
	local left = (look.BarWidth - across) / 2
	squares = {}
	for slot = 1, Config.Items.Slots do
		squares[slot] = square(box, slot, left + (slot - 1) * (look.SlotSize + look.SlotGap))
	end

	-- The bar, in segments of Config.Items.BarPoints / BarSegments points each
	local bar = Instance.new("Frame")
	bar.Position = UDim2.fromOffset(0, look.SlotSize + look.BarGap)
	bar.Size = UDim2.fromOffset(look.BarWidth, look.BarHeight)
	bar.BackgroundTransparency = 1
	bar.Parent = box
	local count = look.BarSegments
	local width = (look.BarWidth - (count - 1) * look.BarSegmentGap) / count
	segments = {}
	for k = 1, count do
		local track = Instance.new("Frame")
		track.Position = UDim2.fromOffset((k - 1) * (width + look.BarSegmentGap), 0)
		track.Size = UDim2.fromOffset(width, look.BarHeight)
		track.BackgroundColor3 = Theme.Colors.Dark
		track.BorderSizePixel = 0
		track.ClipsDescendants = true
		Ui.roundCorners(track)
		track.Parent = bar
		local fill = Instance.new("Frame")
		fill.Size = UDim2.fromScale(0, 1)
		fill.BackgroundColor3 = Theme.Colors.Fill
		fill.BorderSizePixel = 0
		fill.Parent = track
		segments[k] = fill
	end
	-- Full with both slots full: it glows until a slot frees and its ability arrives
	local glow = Instance.new("UIStroke")
	glow.Color = Theme.Colors.TurnGlow
	glow.Thickness = Theme.Ui.TurnGlow
	glow.Enabled = false
	glow.Parent = bar
	barGlow, barFrame = glow, bar

	-- Why a target was refused, just above the squares
	local note = Ui.label("", box)
	note.AnchorPoint = Vector2.new(0.5, 1)
	note.Position = UDim2.new(0.5, 0, 0, -look.RefusalGap)
	note.Size = UDim2.fromOffset(0, look.RefusalHeight)
	note.AutomaticSize = Enum.AutomaticSize.X
	note.TextSize = look.RefusalTextSize
	note.BackgroundTransparency = 0
	note.BackgroundColor3 = Theme.Colors.ItemRefusal
	note.Visible = false
	Ui.roundCorners(note)
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, Theme.Ui.Padding)
	padding.PaddingRight = padding.PaddingLeft
	padding.Parent = note
	refusalLabel = note

	screen.Parent = playerGui
	fit()
	gui = screen
	held, shownState = {}, nil
end

-- Shows the squares and bar while this player is at a table, joined or playing, in either view
function ItemSlots.setAtTable(atTable: boolean)
	if gui then
		gui.Enabled = atTable
	end
end

-- A "+4" that rises from the bar's end and fades, so you learn what fills it
local function pop(points: number)
	local bar = barFrame
	if not bar then
		return
	end
	local label = Ui.label(`+{points}`, bar)
	label.AnchorPoint = Vector2.new(0, 0.5)
	label.Position = UDim2.new(1, Theme.Ui.Padding / 2, 0.5, 0)
	label.Size = UDim2.fromOffset(0, Theme.Ui.ItemPopTextSize)
	label.AutomaticSize = Enum.AutomaticSize.X
	label.TextSize = Theme.Ui.ItemPopTextSize
	label.TextColor3 = Theme.Colors.Fill
	local edge = Instance.new("UIStroke")
	edge.Color = Theme.Colors.Text
	edge.Parent = label
	local info = TweenInfo.new(Theme.Ui.ItemPopSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local rise = UDim2.new(1, Theme.Ui.Padding / 2, 0.5, -Theme.Ui.ItemPopRise)
	TweenService:Create(label, info, { Position = rise, TextTransparency = 1 }):Play()
	TweenService:Create(edge, info, { Transparency = 1 }):Play()
	task.delay(Theme.Ui.ItemPopSeconds, label.Destroy, label)
end

-- Fills the squares and the bar from ItemsChanged: your slots (each an ability's name, or false when empty), your
-- bar's points and the pops just earned. Nil empties them, as before a game.
function ItemSlots.showItems(slots: { string | false }?, points: number?, pops: { number }?)
	for slot, sq in squares do
		local item = if slots and slots[slot] then slots[slot] :: string else nil
		held[slot] = item or false
		ItemIcons.draw(item or "", sq.icon)
		-- Held, a dark tile with its icon; empty, just the outline
		sq.button.BackgroundTransparency = if item then 0 else 1
	end
	local perSegment = Config.Items.BarPoints / #segments
	for k, fill in segments do
		fill.Size = UDim2.fromScale(math.clamp(((points or 0) - (k - 1) * perSegment) / perSegment, 0, 1), 1)
	end
	if barGlow then
		barGlow.Enabled = (points or 0) >= Config.Items.BarPoints
	end
	for _, earned in (pops or {}) :: { number } do
		pop(earned)
	end
	shownState = nil
end

-- From ShotController every frame in the top-down view: `picking` (1 or 2) outlines that square in gold, `usable`
-- false dims the squares, and `refusal` shows why a slot's target was refused above them. Only touches what changed.
function ItemSlots.setState(picking: number?, usable: boolean, refusal: { slot: number, text: string }?)
	local state = `{picking} {usable} {refusal and refusal.text}`
	if state == shownState then
		return
	end
	shownState = state
	for slot, sq in squares do
		local isPicking = picking == slot
		sq.outline.Color = if isPicking then Theme.Colors.ItemPicking else Theme.Colors.Panel
		sq.outline.Thickness = if isPicking then look.PickingOutline else look.SlotOutline
		sq.outline.Transparency = if isPicking then 0 else look.SlotOutlineTransparency
		sq.veil.Visible = not usable and held[slot] ~= false
	end
	if refusalLabel then
		refusalLabel.Visible = refusal ~= nil
		refusalLabel.Text = if refusal then refusal.text else ""
	end
end

-- What clicking a square does, given its slot, or nothing with nil. ShotController sets it to the same as the keys.
function ItemSlots.onPress(action: ((slot: number) -> ())?)
	pressed = action
end

return ItemSlots
