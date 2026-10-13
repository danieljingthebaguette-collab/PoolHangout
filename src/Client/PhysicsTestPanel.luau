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
	item.Font = Theme.Font
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

	-- Closed until you open it with the Test button, beside the settings gear, so it doesn't cover the HUD. It
	-- scrolls when it's taller than the screen, as on a phone held sideways.
	local panel = Instance.new("ScrollingFrame")
	panel.AnchorPoint = Vector2.new(0, 1)
	panel.Position = UDim2.new(0, Theme.Ui.Padding, 1, -Theme.Ui.ButtonHeight - 2 * Theme.Ui.Padding)
	panel.Visible = false
	panel.AutomaticCanvasSize = Enum.AutomaticSize.Y
	panel.CanvasSize = UDim2.new()
	panel.ScrollBarThickness = Theme.Ui.Padding
	panel.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
	panel.BorderSizePixel = 0
	panel.BackgroundColor3 = Theme.Colors.Panel
	panel.Active = true
	panel.Parent = gui
	addCorner(panel)
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
		panel.Size = UDim2.fromOffset(Theme.Ui.PanelWidth, math.min(height, room))
	end
	list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(fit)
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	fit()

	local toggle = button("Test", 0, function()
		panel.Visible = not panel.Visible
	end)
	toggle.AnchorPoint = Vector2.new(0, 1)
	toggle.Position = UDim2.new(0, Theme.Ui.ButtonHeight + 2 * Theme.Ui.Padding, 1, -Theme.Ui.Padding)
	toggle.Size = UDim2.fromOffset(Theme.Ui.LockButtonWidth, Theme.Ui.ButtonHeight)
	toggle.Parent = gui

	button("Rack (R)", 0, function()
		Remotes.TestRack:FireServer()
	end).Parent = panel

	-- The slider being dragged, if any: where to move it, and what to do when it's let go
	local dragging: { moveTo: (number) -> (), release: () -> () }? = nil

	-- Returns a function that shows a new value on the slider
	local function slider(
		label: string,
		range: { min: number, max: number, step: number },
		value: number,
		order: number,
		onRelease: (number) -> ()
	): (number) -> ()
		local row = Instance.new("TextButton")
		style(row, "")
		row.AutoButtonColor = false
		row.LayoutOrder = order
		local text = Instance.new("TextLabel")
		style(text, "")
		text.Size = UDim2.fromScale(1, 0.5)
		text.TextXAlignment = Enum.TextXAlignment.Left
		text.Parent = row
		local bar = Instance.new("Frame")
		bar.AnchorPoint = Vector2.new(0, 0.5)
		bar.Position = UDim2.fromScale(0, 0.75)
		bar.Size = UDim2.new(1, 0, 0, Theme.Ui.SliderBar)
		bar.BackgroundColor3 = Theme.Colors.Track
		bar.BorderSizePixel = 0
		bar.Parent = row
		local fill = Instance.new("Frame")
		fill.BackgroundColor3 = Theme.Colors.Fill
		fill.BorderSizePixel = 0
		fill.Parent = bar

		local function show(newValue: number)
			value = newValue
			fill.Size = UDim2.fromScale((value - range.min) / (range.max - range.min), 1)
			text.Text = `{label}   {string.format("%g", value)}`
		end
		show(value)

		local function moveTo(x: number)
			local share = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
			local raw = range.min + share * (range.max - range.min)
			show(math.clamp(math.round(raw / range.step) * range.step, range.min, range.max))
		end
		row.InputBegan:Connect(function(input: InputObject)
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				dragging = {
					moveTo = moveTo,
					release = function()
						onRelease(value)
					end,
				}
				moveTo(input.Position.X)
			end
		end)
		row.Parent = panel
		return show
	end

	for i, range in Config.Debug.TestSliders do
		local show = slider(
			range.name,
			range,
			Remotes.TestTune:GetAttribute(range.name) or (Config :: any)[range.group][range.name],
			i,
			function(value: number)
				Remotes.TestTune:FireServer(range.name, value)
			end
		)
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
	UserInputService.InputChanged:Connect(function(input: InputObject)
		if
			dragging
			and (
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			dragging.moveTo(input.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(input: InputObject)
		if
			dragging
			and (
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			dragging.release()
			dragging = nil
		end
	end)

	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

return PhysicsTestPanel
