--!strict
-- The shot clock: a dark box in the top bar's gap showing the seconds left on the shooter's clock, coral and bigger for
-- the last few, with a coral border pulsing once a second for the very last ones, and whose turn it is under it ("Your
-- turn", "Opponent's turn"). It counts to the server's clock end time, so every screen agrees, and hides once the shot
-- goes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Theme = require(ReplicatedStorage.Shared.Theme)
local Card = require(script.Parent.Card)
local Ui = require(script.Parent.Ui)

local ShotClock = {}

-- The box, its seconds, its pulsing border and whose turn it is, once they're built, and the countdown's connection
-- while one runs
local box: Frame? = nil
local seconds: TextLabel? = nil
local pulse: UIStroke? = nil
local turnLabel: TextLabel? = nil
local connection: RBXScriptConnection? = nil

-- Builds the box in the top bar's gap, hidden
function ShotClock.build(gui: ScreenGui)
	local frame = Instance.new("Frame")
	frame.Name = "ShotClock"
	frame.AnchorPoint = Vector2.new(0.5, 0)
	frame.Position = UDim2.new(0.5, 0, 0, Theme.Ui.Padding)
	frame.Size = UDim2.fromOffset(Theme.Ui.ClockWidth, Theme.Ui.CardHeight)
	frame.Visible = false
	Card.style(frame, true)
	frame.Parent = gui
	local label = Ui.label("", frame)
	label.Size = UDim2.fromScale(1, 1)
	label.ZIndex = 3
	-- A border of its own, on a frame just as big, so it never fights the card's look
	local edge = Instance.new("Frame")
	edge.Size = UDim2.fromScale(1, 1)
	edge.BackgroundTransparency = 1
	edge.ZIndex = 4
	edge.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.Colors.ClockWarning
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Enabled = false
	stroke.Parent = edge
	-- Whose turn it is, on a small dark box under the clock, so it reads over the world
	local whose = Ui.label("", frame)
	whose.AnchorPoint = Vector2.new(0.5, 0)
	whose.Position = UDim2.new(0.5, 0, 1, Theme.Ui.Padding / 2)
	whose.Size = UDim2.fromOffset(0, Theme.Ui.ClockTurnHeight)
	whose.AutomaticSize = Enum.AutomaticSize.X
	whose.TextSize = Theme.Ui.ClockTurnTextSize
	whose.TextColor3 = Theme.Colors.DarkText
	whose.BackgroundTransparency = 0
	whose.BackgroundColor3 = Theme.Colors.Dark
	whose.BorderSizePixel = 0
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, Theme.Ui.Padding)
	padding.PaddingRight = padding.PaddingLeft
	padding.Parent = whose
	box, seconds, pulse, turnLabel = frame, label, stroke, whose
end

-- Counts down to `endsAt`, in the server's time, with whose turn it is under it, or hides with nil
function ShotClock.show(endsAt: number?, whose: string?)
	if connection then
		connection:Disconnect()
		connection = nil
	end
	local frame, label, stroke = box :: Frame, seconds :: TextLabel, pulse :: UIStroke
	frame.Visible = endsAt ~= nil
	stroke.Enabled = false
	local turnText = turnLabel :: TextLabel
	turnText.Text = whose or ""
	turnText.Visible = whose ~= nil
	if not endsAt then
		return
	end
	local function update()
		local remaining = endsAt - workspace:GetServerTimeNow()
		local left = math.max(math.ceil(remaining), 0)
		local warning = left <= Config.Shot.ClockWarningSeconds
		label.Text = tostring(left)
		label.TextColor3 = if warning then Theme.Colors.ClockWarning else Theme.Colors.DarkText
		label.TextSize = if warning then Theme.Ui.ClockWarningTextSize else Theme.Ui.LargeTextSize
		-- The last few seconds: a coral border that starts each second thick and solid, then thins and fades
		local pulsing = remaining > 0 and remaining <= Theme.Ui.ClockPulseSeconds
		stroke.Enabled = pulsing
		if pulsing then
			local through = remaining % 1
			stroke.Thickness = Theme.Ui.ClockPulseThickness * through
			stroke.Transparency = 1 - through
		end
	end
	update()
	connection = RunService.Heartbeat:Connect(update)
end

return ShotClock
