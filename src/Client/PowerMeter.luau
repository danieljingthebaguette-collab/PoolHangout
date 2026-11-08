--!strict
-- The power meter on the left of the top-down view, with its % readout in a dark box. It only shows the pull; you
-- don't drag it. Its own screen, below Roblox's top bar, so the phones' Lock button (ShotController) lines up beside
-- it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Theme = require(ReplicatedStorage.Shared.Theme)
local Ui = require(script.Parent.Ui)

local PowerMeter = {}

-- The meter, once it's built: its screen, its track, its fill and its % readout
local meter: { gui: ScreenGui, track: Frame, fill: Frame, percent: TextLabel }? = nil

function PowerMeter.build(playerGui: Instance)
	local gui = Instance.new("ScreenGui")
	gui.Name = "PowerMeter"
	gui.ResetOnSpawn = false
	gui.Enabled = false
	-- Centered in the space the view keeps clear on the left. Active, so pressing it doesn't start a pull.
	local track = Instance.new("Frame")
	track.AnchorPoint = Vector2.new(0.5, 0.5)
	track.Position = UDim2.new(0, Theme.Ui.MeterReserve / 2, 0.5, 0)
	track.Size = UDim2.new(0, Theme.Ui.MeterTrack, Theme.Ui.MeterHeight, 0)
	track.BackgroundColor3 = Theme.Colors.Dark
	track.BorderSizePixel = 0
	track.Active = true
	track.Parent = gui
	Ui.roundCorners(track)
	-- Fills up from the bottom as you pull
	local fill = Instance.new("Frame")
	fill.AnchorPoint = Vector2.new(0, 1)
	fill.Position = UDim2.fromScale(0, 1)
	fill.Size = UDim2.fromScale(1, 0)
	fill.BackgroundColor3 = Theme.Colors.Fill
	fill.BorderSizePixel = 0
	fill.Parent = track
	Ui.roundCorners(fill)
	local percent = Ui.label("0%", gui)
	percent.AnchorPoint = Vector2.new(0.5, 0)
	percent.Position = UDim2.new(0, Theme.Ui.MeterReserve / 2, 0.5 + Theme.Ui.MeterHeight / 2, Theme.Ui.Padding)
	percent.Size = UDim2.fromOffset(Theme.Ui.MeterReserve - Theme.Ui.Padding, Theme.Ui.LargeTextSize + Theme.Ui.Padding)
	percent.TextSize = Theme.Ui.LargeTextSize
	percent.BackgroundTransparency = 0
	percent.BackgroundColor3 = Theme.Colors.Dark
	percent.TextColor3 = Theme.Colors.DarkText
	Ui.roundCorners(percent)
	gui.Parent = playerGui
	meter = { gui = gui, track = track, fill = fill, percent = percent }
end

-- Shows the pull, 0 to 1, or hides the meter with nil while you can't shoot. With Power Shot it goes past 1: the meter
-- stays full and an orange fill rises again from the bottom, up to Config.Items.PowerShotMax. A placeholder look until
-- the GUI pass.
function PowerMeter.set(share: number?)
	if not meter then
		return
	end
	meter.gui.Enabled = share ~= nil
	if share then
		local over = share > 1
		meter.track.BackgroundColor3 = if over then Theme.Colors.Fill else Theme.Colors.Dark
		meter.fill.BackgroundColor3 = if over then Theme.Colors.PowerOver else Theme.Colors.Fill
		local height = if over then (share - 1) / (Config.Items.PowerShotMax - 1) else share
		meter.fill.Size = UDim2.fromScale(1, math.clamp(height, 0, 1))
		meter.percent.Text = `{math.round(share * 100)}%`
	end
end

return PowerMeter
