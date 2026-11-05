--!strict
-- The control hints down the bottom right of the top-down view, each a label and its key, like "Lock aim [Space]".
-- ShotController picks which hints show.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(ReplicatedStorage.Shared.Theme)
local Ui = require(script.Parent.Ui)

local Hints = {}

-- The hints' column, once it's built, and the rows it shows
local column: Frame? = nil
local shown: { { string } }? = nil

-- Screen height, in pixels, kept clear along the bottom for the gear (left) and the control hints (right)
function Hints.bottomBand(): number
	local hints = Theme.Ui.HintRows * Theme.Ui.HintHeight + (Theme.Ui.HintRows - 1) * Theme.Ui.Padding / 2
	return math.max(Theme.Ui.ButtonHeight, hints) + 2 * Theme.Ui.Padding
end

-- One control hint: a label box and its key box
local function hintRow(text: string, key: string, order: number): Frame
	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.Size = UDim2.fromOffset(0, Theme.Ui.HintHeight)
	row.AutomaticSize = Enum.AutomaticSize.X
	row.LayoutOrder = order
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, Theme.Ui.Padding / 2)
	layout.Parent = row
	for i, part in { { text = text, dark = false }, { text = key, dark = true } } do
		local box = Ui.label(part.text, row)
		box.LayoutOrder = i
		box.Size = UDim2.fromOffset(0, Theme.Ui.HintHeight)
		box.AutomaticSize = Enum.AutomaticSize.X
		box.BackgroundTransparency = if part.dark then 0 else Theme.Ui.HudTransparency
		box.BackgroundColor3 = if part.dark then Theme.Colors.Dark else Theme.Colors.Panel
		box.TextColor3 = if part.dark then Theme.Colors.DarkText else Theme.Colors.Text
		Ui.roundCorners(box)
		local padding = Instance.new("UIPadding")
		padding.PaddingLeft = UDim.new(0, Theme.Ui.Padding)
		padding.PaddingRight = padding.PaddingLeft
		padding.Parent = box
	end
	return row
end

-- Shows control hints, or hides them with nil. `rows` is one of a few fixed lists, so the rows are only rebuilt when a
-- different list comes in.
function Hints.set(rows: { { string } }?)
	if not column or rows == shown then
		return
	end
	shown = rows
	for _, child in column:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	for i, row in (rows or {}) :: { { string } } do
		hintRow(row[1], row[2], i).Parent = column
	end
end

-- Builds the empty column, bottom right of `gui`
function Hints.build(gui: ScreenGui)
	local list = Instance.new("Frame")
	list.AnchorPoint = Vector2.new(1, 1)
	list.Position = UDim2.new(1, -Theme.Ui.Padding, 1, -Theme.Ui.Padding)
	list.AutomaticSize = Enum.AutomaticSize.XY
	list.BackgroundTransparency = 1
	list.Parent = gui
	local layout = Instance.new("UIListLayout")
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, Theme.Ui.Padding / 2)
	layout.Parent = list
	column = list
end

return Hints
