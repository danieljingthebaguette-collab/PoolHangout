--!strict
-- Physics test mode (see Config.Debug.PhysicsTest and PhysicsTestLive): R or the Rack button racks Table1, and the
-- sliders tune the physics live for everyone. Shots use the real controls (ShotController). The panel stays closed
-- until you open it with the Test button.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Theme = require(ReplicatedStorage.Shared.Theme)
local Card = require(script.Parent.Card)
local Slider = require(script.Parent.Slider)

local PhysicsTestPanel = {}

local panelGui: ScreenGui? = nil

-- The Test button and panel show only in the top-down view, clear of the phones' thumbstick in the normal view.
-- R racks in any view.
function PhysicsTestPanel.show(visible: boolean)
	if panelGui then
		panelGui.Enabled = visible
	end
end

local function style(item: TextLabel | TextButton, text: string)
	item.Size = UDim2.new(1, 0, 0, Theme.Ui.ButtonHeight)
	item.BackgroundTransparency = 1
	item.FontFace = Theme.Font
	item.TextSize = Theme.TextSize
	item.TextColor3 = Theme.Colors.Text
	item.Text = text
end

local function addCorner(item: GuiObject)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, Theme.Ui.Corner)
	corner.Parent = item
end

local function button(text: string, order: number, onPress: () -> ()): TextButton
	local item = Instance.new("TextButton")
	style(item, text)
	item.BackgroundTransparency = 0
	item.BackgroundColor3 = Theme.Colors.Button
	item.LayoutOrder = order
	addCorner(item)
	item.Activated:Connect(onPress)
	return item
end

function PhysicsTestPanel.start()
	local gui = Instance.new("ScreenGui")
	gui.Name = "PhysicsTest"
	gui.ResetOnSpawn = false
	gui.Enabled = false
	gui.DisplayOrder = 2 -- the open panel covers the power meter
	panelGui = gui

	-- A cream card, closed until you open it with the Test button, beside the settings gear, so it doesn't cover the
	-- HUD. Its contents scroll when it's taller than the screen, as on a phone held sideways.
	local card = Instance.new("Frame")
	card.AnchorPoint = Vector2.new(0, 1)
	card.Position = UDim2.new(0, Theme.Ui.Padding, 1, -Theme.Ui.ButtonHeight - 2 * Theme.Ui.Padding)
	card.Visible = false
	card.Active = true
	Card.style(card)
	card.Parent = gui
	-- The list scrolls in its own frame, so its layout leaves the card's brackets alone
	local panel = Instance.new("ScrollingFrame")
	panel.Size = UDim2.fromScale(1, 1)
	panel.BackgroundTransparency = 1
	panel.AutomaticCanvasSize = Enum.AutomaticSize.Y
	panel.CanvasSize = UDim2.new()
	panel.ScrollBarThickness = Theme.Ui.Padding
	panel.ScrollBarImageColor3 = Theme.Colors.Text
	panel.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
	panel.BorderSizePixel = 0
	panel.Parent = card
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, Theme.Ui.Padding)
	padding.PaddingBottom = padding.PaddingTop
	padding.PaddingLeft = padding.PaddingTop
	padding.PaddingRight = padding.PaddingTop
	padding.Parent = panel
	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, Theme.Ui.Padding / 2)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = panel
	-- As tall as its contents, up to the room above the Test button
	local function fit()
		local room = gui.AbsoluteSize.Y - Theme.Ui.ButtonHeight - 3 * Theme.Ui.Padding
		local height = list.AbsoluteContentSize.Y + 2 * Theme.Ui.Padding
		card.Size = UDim2.fromOffset(Theme.Ui.PanelWidth, math.min(height, room))
	end
	list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(fit)
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	fit()

	local toggle = button("Test", 0, function()
		card.Visible = not card.Visible
	end)
	toggle.AnchorPoint = Vector2.new(0, 1)
	toggle.Position = UDim2.new(0, Theme.Ui.ButtonHeight + 2 * Theme.Ui.Padding, 1, -Theme.Ui.Padding)
	toggle.Size = UDim2.fromOffset(Theme.Ui.TestButtonWidth, Theme.Ui.ButtonHeight)
	toggle.Parent = gui

	button("Rack (R)", 0, function()
		Remotes.TestRack:FireServer()
	end).Parent = panel

	for i, range in Config.Debug.TestSliders do
		local row, show = Slider.new({
			min = range.min,
			max = range.max,
			step = range.step,
			value = Remotes.TestTune:GetAttribute(range.name) or (Config :: any)[range.group][range.name],
			label = function(value: number): string
				return `{range.name}   {string.format("%g", value)}`
			end,
			-- Sent once on letting go, so dragging doesn't flood the server
			onRelease = function(value: number)
				Remotes.TestTune:FireServer(range.name, value)
			end,
		})
		row.LayoutOrder = i
		row.Parent = panel
		Remotes.TestTune:GetAttributeChangedSignal(range.name):Connect(function()
			show(Remotes.TestTune:GetAttribute(range.name))
		end)
	end

	-- The server prints them, so they show in Studio's Output however the game is running
	local printButton = button("Print values", #Config.Debug.TestSliders + 1, function()
		Remotes.TestPrint:FireServer()
	end)
	printButton.Parent = panel

	UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
		if gameProcessed then
			return
		elseif input.KeyCode == Enum.KeyCode.R then
			Remotes.TestRack:FireServer()
		end
	end)
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

return PhysicsTestPanel
