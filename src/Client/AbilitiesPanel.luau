--!strict
-- The Abilities panel, a cream card in the middle of the screen that the lobby's Abilities button (LobbyButtons) opens:
-- how you earn and use abilities, in plain words, then every ability in Config.Items.List order with its icon, name and
-- line. Players see "Abilities"; the code says items. Its close button, Esc (Roblox's menu opening) and joining a table
-- close it.

local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local Items = require(ReplicatedStorage.Shared.Items)
local Theme = require(ReplicatedStorage.Shared.Theme)
local Card = require(script.Parent.Card)
local ItemIcons = require(script.Parent.ItemIcons)
local Ui = require(script.Parent.Ui)

local AbilitiesPanel = {}

local EARN = "At a table, the bar under your two ability squares fills as you play: each turn, and when balls drop. "
	.. "When it's full you get an ability, and you can hold 2."
local USE = "On your turn, press 1 or 2, or click its square, before you shoot."

-- The panel, once it's built
local panel: Frame? = nil

-- Text that wraps to the width it's given and grows down to fit
local function paragraph(text: string, parent: Instance, order: number, size: number, color: Color3): TextLabel
	local label = Ui.label(text, parent)
	label.LayoutOrder = order
	label.Size = UDim2.fromScale(1, 0)
	label.AutomaticSize = Enum.AutomaticSize.Y
	label.TextSize = size
	label.TextColor3 = color
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	return label
end

-- A vertical list of `parent`'s children, `gap` apart
local function stack(parent: Instance, gap: number): UIListLayout
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, gap)
	layout.Parent = parent
	return layout
end

-- One ability's row: its icon on a dark box, then its name with its line under it
local function abilityRow(item: Items.Item, parent: Instance, order: number)
	local ui = Theme.Ui
	local row = Instance.new("Frame")
	row.LayoutOrder = order
	row.Size = UDim2.fromScale(1, 0)
	row.AutomaticSize = Enum.AutomaticSize.Y
	row.BackgroundTransparency = 1
	row.Parent = parent
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, ui.Padding * 1.5)
	layout.Parent = row
	local box = Instance.new("Frame")
	box.Size = UDim2.fromOffset(ui.AbilitiesIconSize, ui.AbilitiesIconSize)
	box.BackgroundColor3 = Theme.Colors.Dark
	box.BorderSizePixel = 0
	Ui.roundCorners(box)
	box.Parent = row
	local icon = Instance.new("Frame")
	icon.Position = UDim2.fromOffset(ui.AbilitiesIconInset, ui.AbilitiesIconInset)
	icon.Size = UDim2.new(1, -2 * ui.AbilitiesIconInset, 1, -2 * ui.AbilitiesIconInset)
	icon.BackgroundTransparency = 1
	icon.Parent = box
	ItemIcons.draw(item, icon)
	local words = Instance.new("Frame")
	words.LayoutOrder = 1
	words.Size = UDim2.new(1, -ui.AbilitiesIconSize - ui.Padding * 1.5, 0, 0)
	words.AutomaticSize = Enum.AutomaticSize.Y
	words.BackgroundTransparency = 1
	words.Parent = row
	stack(words, 0)
	paragraph(Items.NAMES[item] or item, words, 1, Theme.TextSize, Theme.Colors.Text)
	paragraph(Items.LINES[item] or "", words, 2, ui.AbilitiesLineTextSize, Theme.Colors.ItemLine)
end

local function close()
	if panel then
		panel.Visible = false
	end
end

-- Opens the panel, or closes it if it's open
function AbilitiesPanel.toggle()
	if panel then
		panel.Visible = not panel.Visible
	end
end

-- Joining a table closes the panel. Hud calls it whenever that changes, from LeaveButton.
function AbilitiesPanel.setAtTable(atTable: boolean)
	if atTable then
		close()
	end
end

function AbilitiesPanel.build(playerGui: Instance)
	local ui = Theme.Ui
	local gui = Instance.new("ScreenGui")
	gui.Name = "Abilities"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 5 -- the open panel covers the rest of the HUD

	-- The card, as tall as what's in it. Active, so a click on it never reaches the table.
	local card = Instance.new("Frame")
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.5)
	card.Active = true
	card.Visible = false
	Card.style(card)
	card.Parent = gui
	local inside = Instance.new("Frame")
	inside.Size = UDim2.fromScale(1, 1)
	inside.BackgroundTransparency = 1
	inside.Parent = card
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 2 * ui.Padding)
	padding.PaddingRight = padding.PaddingLeft
	padding.PaddingTop = padding.PaddingLeft
	padding.PaddingBottom = padding.PaddingLeft
	padding.Parent = inside
	local layout = stack(inside, ui.Padding)

	-- The title, with the close button at its right
	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, ui.ButtonHeight)
	header.BackgroundTransparency = 1
	header.Parent = inside
	local title = Ui.label("Abilities", header)
	title.Size = UDim2.fromScale(1, 1)
	title.TextSize = ui.LargeTextSize
	title.TextXAlignment = Enum.TextXAlignment.Left
	local shut = Ui.accentButton("Close", Theme.Colors.LobbyButton, header)
	shut.AnchorPoint = Vector2.new(1, 0)
	shut.Position = UDim2.fromScale(1, 0)
	shut.Size = UDim2.new(0, ui.AbilitiesCloseWidth, 1, 0)
	shut.TextColor3 = Theme.Colors.DarkText

	paragraph(EARN, inside, 1, Theme.TextSize, Theme.Colors.Text)
	paragraph(USE, inside, 2, Theme.TextSize, Theme.Colors.Text)
	for i, item in Config.Items.List do
		abilityRow(item, inside, 2 + i)
	end
	local function fit()
		card.Size = UDim2.fromOffset(ui.AbilitiesPanelWidth, layout.AbsoluteContentSize.Y + 4 * ui.Padding)
	end
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(fit)
	fit()
	gui.Parent = playerGui
	panel = card

	shut.Activated:Connect(close)
	-- Esc opens Roblox's menu, which the game can't bind, so close as it opens; and on an Escape press if one arrives
	GuiService.MenuOpened:Connect(close)
	UserInputService.InputBegan:Connect(function(input: InputObject)
		if input.KeyCode == Enum.KeyCode.Escape then
			close()
		end
	end)
end

return AbilitiesPanel
