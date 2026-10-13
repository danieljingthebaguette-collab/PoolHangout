--!strict
-- Physics test mode (see Config.Debug.PhysicsTest and PhysicsTestLive): R or the Rack button racks Table1, and the
-- sliders tune the physics live for everyone. Shots use the real controls (ShotController).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Theme = require(ReplicatedStorage.Shared.Theme)

local PhysicsTestPanel = {}

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

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0, 0.5)
	panel.Position = UDim2.new(0, Theme.Ui.Padding, 0.5, 0)
	panel.Size = UDim2.fromOffset(Theme.Ui.PanelWidth, 0)
	panel.AutomaticSize = Enum.AutomaticSize.Y
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

	local printButton = button("Print values", #Config.Debug.TestSliders + 1, function()
		local lines = { "Physics test values, as the server has them:" }
		for _, range in Config.Debug.TestSliders do
			local value = string.format("%g", Remotes.TestTune:GetAttribute(range.name))
			table.insert(lines, `  {range.group}.{range.name} = {value},`)
		end
		print(table.concat(lines, "\n"))
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
