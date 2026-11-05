--!strict
-- The gear bottom-left of the top-down view, a bright accent button, and the card it opens with the sound volume.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(ReplicatedStorage.Shared.Theme)
local Card = require(script.Parent.Card)
local Slider = require(script.Parent.Slider)
local TableView = require(script.Parent.TableView)
local Ui = require(script.Parent.Ui)

local SettingsPanel = {}

function SettingsPanel.build(gui: ScreenGui)
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

	-- Opens beside the gear, clear of the power meter's readout above it
	local box = Instance.new("Frame")
	box.AnchorPoint = Vector2.new(0, 1)
	box.Position = UDim2.new(0, Theme.Ui.ButtonHeight + 2 * Theme.Ui.Padding, 1, -Theme.Ui.Padding)
	box.Size = UDim2.fromOffset(Theme.Ui.PanelWidth, Theme.Ui.ButtonHeight + 2 * Theme.Ui.Padding)
	box.Active = true
	box.Visible = false
	Card.style(box)
	box.Parent = gui
	local row = Slider.new({
		min = 0,
		max = 1,
		step = 0.01,
		value = 1,
		label = function(share: number): string
			return `Sound volume   {math.round(share * 100)}%`
		end,
		onChange = TableView.setVolume,
	})
	row.Position = UDim2.fromOffset(2 * Theme.Ui.Padding, Theme.Ui.Padding)
	row.Size = UDim2.new(1, -4 * Theme.Ui.Padding, 0, Theme.Ui.ButtonHeight)
	row.Parent = box

	gear.Activated:Connect(function()
		box.Visible = not box.Visible
	end)
end

return SettingsPanel
