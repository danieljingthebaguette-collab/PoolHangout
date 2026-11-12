--!strict
-- The settings page: the gear bottom-left of the top-down view opens it, and so does the lobby's Settings button (V).
-- Music and sound volume, camera glide, screen shake, control hints, UI scale and show stats, each applied at once and
-- saved (Settings). A note says so when this session's changes can't be saved.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Theme = require(ReplicatedStorage.Shared.Theme)
local Panel = require(script.Parent.Panel)
local Settings = require(script.Parent.Settings)
local Slider = require(script.Parent.Slider)
local Ui = require(script.Parent.Ui)

local SettingsPanel = {}

-- The page, once it's built
local page: Panel.Panel? = nil

-- A section's name, small, over its rows
local function section(text: string, parent: Instance, order: number)
	local label = Ui.label(text, parent)
	label.LayoutOrder = order
	label.Size = UDim2.new(1, 0, 0, Theme.Ui.SettingsSectionTextSize + Theme.Ui.Padding / 2)
	label.TextSize = Theme.Ui.SettingsSectionTextSize
	label.TextColor3 = Theme.Colors.ItemLine
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Bottom
end

-- A row with the setting's name and an On/Off button at its right; returns a function that shows its value
local function toggleRow(text: string, field: string, parent: Instance, order: number): () -> ()
	local row = Instance.new("Frame")
	row.LayoutOrder = order
	row.Size = UDim2.new(1, 0, 0, Theme.Ui.ButtonHeight)
	row.BackgroundTransparency = 1
	row.Parent = parent
	local name = Ui.label(text, row)
	name.Size = UDim2.fromScale(1, 1)
	name.TextXAlignment = Enum.TextXAlignment.Left
	local button = Ui.accentButton("", Theme.Colors.Button, row)
	button.AnchorPoint = Vector2.new(1, 0.5)
	button.Position = UDim2.fromScale(1, 0.5)
	button.Size = UDim2.new(0, Theme.Ui.ToggleWidth, 1, -Theme.Ui.Padding / 2)
	local function show()
		local on = (Settings.get() :: any)[field] == true
		button.Text = if on then "On" else "Off"
		button.BackgroundColor3 = if on then Theme.Colors.Button else Theme.Colors.Dark
		button.TextColor3 = if on then Theme.Colors.Text else Theme.Colors.DarkText
	end
	button.Activated:Connect(function()
		Settings.set(field, not (Settings.get() :: any)[field])
	end)
	show()
	return show
end

-- A slider row; returns a function that shows its value
local function sliderRow(
	field: string,
	parent: Instance,
	order: number,
	range: { min: number, max: number, step: number },
	label: (number) -> string
): () -> ()
	local row, show = Slider.new({
		min = range.min,
		max = range.max,
		step = range.step,
		value = (Settings.get() :: any)[field],
		label = label,
		onChange = function(value: number)
			Settings.set(field, value)
		end,
	})
	row.LayoutOrder = order
	row.Size = UDim2.new(1, 0, 0, Theme.Ui.ButtonHeight)
	row.Parent = parent
	return function()
		show((Settings.get() :: any)[field])
	end
end

local function percent(name: string): (number) -> string
	return function(value: number): string
		return `{name}   {math.round(value * 100)}%`
	end
end

-- Opens the page, or closes it if it's open
function SettingsPanel.toggle()
	if page then
		page.toggle()
	end
end

-- Builds the gear on `gui`, the top-down view's own screen, and the page on its own screen
function SettingsPanel.build(gui: ScreenGui, playerGui: Instance)
	local gear = Instance.new("TextButton")
	gear.AnchorPoint = Vector2.new(0, 1)
	gear.Position = UDim2.new(0, Theme.Ui.Padding, 1, -Theme.Ui.Padding)
	gear.Size = UDim2.fromOffset(Theme.Ui.ButtonHeight, Theme.Ui.ButtonHeight)
	gear.BackgroundColor3 = Theme.Colors.Button
	gear.FontFace = Theme.Font
	gear.TextSize = Theme.Ui.LargeTextSize
	gear.TextColor3 = Theme.Colors.Text
	gear.Text = "⚙"
	gear.Parent = gui
	Ui.roundCorners(gear)
	gear.Activated:Connect(SettingsPanel.toggle)

	local made = Panel.new(playerGui, "SettingsPage", "Settings", Theme.Ui.SettingsWidth)
	local list = made.content
	local volume = { min = 0, max = 1, step = 0.01 }
	local s = Config.Settings
	section("Sound", list, 1)
	section("Camera", list, 4)
	section("Screen", list, 6)
	local shows = {
		sliderRow("music", list, 2, volume, percent("Music")),
		sliderRow("sound", list, 3, volume, percent("Sound")),
		toggleRow("Camera glide", "cameraGlide", list, 5),
		toggleRow("Screen shake", "screenShake", list, 7),
		toggleRow("Control hints", "controlHints", list, 8),
		sliderRow(
			"uiScale",
			list,
			9,
			{ min = s.UiScaleMin, max = s.UiScaleMax, step = s.UiScaleStep },
			percent("UI scale")
		),
		toggleRow("Show stats", "showStats", list, 10),
	}
	-- Only while changes can't be saved
	local note = Ui.label("Your saved settings couldn't load, so changes last this session only.", list)
	note.LayoutOrder = 11
	note.Size = UDim2.fromScale(1, 0)
	note.AutomaticSize = Enum.AutomaticSize.Y
	note.TextWrapped = true
	note.TextSize = Theme.Ui.SettingsSectionTextSize
	note.TextColor3 = Theme.Colors.ItemLine
	note.TextXAlignment = Enum.TextXAlignment.Left
	note.Visible = false
	Settings.onChanged(function()
		for _, show in shows do
			show()
		end
		note.Visible = Settings.answered() and not Settings.saving()
	end)
	page = made
end

return SettingsPanel
