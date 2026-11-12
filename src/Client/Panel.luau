--!strict
-- A panel in the middle of the screen, on its own screen over the rest of the HUD: a cream card with its title and a
-- Close button at the top, and a list under them that the caller fills. Close, Esc (Roblox's menu opening) and the
-- caller's own key close it. The settings page and the shop use it.

local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Theme = require(ReplicatedStorage.Shared.Theme)
local Card = require(script.Parent.Card)
local Ui = require(script.Parent.Ui)
local UiScale = require(script.Parent.UiScale)

local Panel = {}

export type Panel = {
	gui: ScreenGui,
	card: Frame,
	-- The list under the title, laid out top to bottom by LayoutOrder; the card grows to fit it
	content: Frame,
	toggle: () -> (),
	close: () -> (),
	isOpen: () -> boolean,
}

function Panel.new(playerGui: Instance, name: string, title: string, width: number): Panel
	local ui = Theme.Ui
	local gui = Instance.new("ScreenGui")
	gui.Name = name
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 5 -- an open panel covers the rest of the HUD
	-- Active, so a click on it never reaches the table
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
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, ui.Padding)
	layout.Parent = inside

	local header = Instance.new("Frame")
	header.LayoutOrder = -1
	header.Size = UDim2.new(1, 0, 0, ui.ButtonHeight)
	header.BackgroundTransparency = 1
	header.Parent = inside
	local heading = Ui.label(title, header)
	heading.Size = UDim2.fromScale(1, 1)
	heading.TextSize = ui.LargeTextSize
	heading.TextXAlignment = Enum.TextXAlignment.Left
	local shut = Ui.accentButton("Close", Theme.Colors.LobbyButton, header)
	shut.AnchorPoint = Vector2.new(1, 0)
	shut.Position = UDim2.fromScale(1, 0)
	shut.Size = UDim2.new(0, ui.AbilitiesCloseWidth, 1, 0)
	shut.TextColor3 = Theme.Colors.DarkText

	local content = Instance.new("Frame")
	content.Size = UDim2.fromScale(1, 0)
	content.AutomaticSize = Enum.AutomaticSize.Y
	content.BackgroundTransparency = 1
	content.Parent = inside
	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, ui.Padding)
	list.Parent = content

	-- At the UI scale setting, but never taller than the screen
	local scale = Instance.new("UIScale")
	scale.Parent = card
	local function fit()
		local s = UiScale.get()
		-- The list's size is measured after this card's own scale, so take it back out
		local height = layout.AbsoluteContentSize.Y / scale.Scale + 4 * ui.Padding
		card.Size = UDim2.fromOffset(width, height)
		scale.Scale = math.min(s, gui.AbsoluteSize.Y * ui.PanelScreenShare / height)
	end
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(fit)
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	UiScale.onChanged(fit)
	fit()
	gui.Parent = playerGui
	fit()

	local function close()
		card.Visible = false
	end
	shut.Activated:Connect(close)
	-- Esc opens Roblox's menu, which the game can't bind, so close as it opens; and on an Escape press if one arrives
	GuiService.MenuOpened:Connect(close)
	UserInputService.InputBegan:Connect(function(input: InputObject)
		if input.KeyCode == Enum.KeyCode.Escape then
			close()
		end
	end)
	return {
		gui = gui,
		card = card,
		content = content,
		toggle = function()
			card.Visible = not card.Visible
		end,
		close = close,
		isOpen = function(): boolean
			return card.Visible
		end,
	}
end

return Panel
