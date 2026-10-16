--!strict
-- A labelled slider row for mouse and touch: press anywhere on the row and drag to set it. The physics test panel
-- and the settings use it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Theme = require(ReplicatedStorage.Shared.Theme)

local Slider = {}

export type Options = {
	min: number,
	max: number,
	step: number,
	value: number,
	label: (number) -> string, -- the row's text for a value
	onChange: ((number) -> ())?, -- as it's dragged
	onRelease: ((number) -> ())?, -- when it's let go
}

-- Returns the row, for the caller to place, and a function that shows a new value without calling back
function Slider.new(options: Options): (TextButton, (number) -> ())
	local row = Instance.new("TextButton")
	row.Size = UDim2.new(1, 0, 0, Theme.Ui.ButtonHeight)
	row.BackgroundTransparency = 1
	row.AutoButtonColor = false
	row.Text = ""
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 0.5)
	text.BackgroundTransparency = 1
	text.FontFace = Theme.Font
	text.TextSize = Theme.TextSize
	text.TextColor3 = Theme.Colors.Text
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

	local value = options.value
	local function show(newValue: number)
		value = newValue
		fill.Size = UDim2.fromScale((value - options.min) / (options.max - options.min), 1)
		text.Text = options.label(value)
	end
	show(value)

	local function moveTo(x: number)
		local share = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
		local raw = options.min + share * (options.max - options.min)
		show(math.clamp(math.round(raw / options.step) * options.step, options.min, options.max))
		if options.onChange then
			options.onChange(value)
		end
	end

	-- The mouse button or finger dragging it. A mouse drag arrives as plain mouse movement.
	local dragging: InputObject? = nil
	local function isDragging(input: InputObject): boolean
		return dragging ~= nil
			and (
				input == dragging
				or (
					dragging.UserInputType == Enum.UserInputType.MouseButton1
					and (
						input.UserInputType == Enum.UserInputType.MouseMovement
						or input.UserInputType == Enum.UserInputType.MouseButton1
					)
				)
			)
	end
	row.InputBegan:Connect(function(input: InputObject)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = input
			moveTo(input.Position.X)
		end
	end)
	UserInputService.InputChanged:Connect(function(input: InputObject)
		if isDragging(input) then
			moveTo(input.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(input: InputObject)
		if isDragging(input) then
			dragging = nil
			if options.onRelease then
				options.onRelease(value)
			end
		end
	end)

	return row, show
end

return Slider
