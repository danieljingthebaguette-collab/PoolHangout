--!strict
-- The shot clock: a dark box in the top bar's gap showing the seconds left on the shooter's clock, coral and bigger for
-- the last few. It counts to the server's clock end time, so every screen agrees, and hides once the shot goes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Theme = require(ReplicatedStorage.Shared.Theme)
local Card = require(script.Parent.Card)
local Ui = require(script.Parent.Ui)

local ShotClock = {}

-- The box and its seconds, once they're built, and the countdown's connection while one runs
local box: Frame? = nil
local seconds: TextLabel? = nil
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
	box, seconds = frame, label
end

-- Counts down to `endsAt`, in the server's time, or hides with nil
function ShotClock.show(endsAt: number?)
	if connection then
		connection:Disconnect()
		connection = nil
	end
	local frame, label = box :: Frame, seconds :: TextLabel
	frame.Visible = endsAt ~= nil
	if not endsAt then
		return
	end
	local function update()
		local left = math.max(math.ceil(endsAt - workspace:GetServerTimeNow()), 0)
		local warning = left <= Config.Shot.ClockWarningSeconds
		label.Text = tostring(left)
		label.TextColor3 = if warning then Theme.Colors.ClockWarning else Theme.Colors.DarkText
		label.TextSize = if warning then Theme.Ui.ClockWarningTextSize else Theme.Ui.LargeTextSize
	end
	update()
	connection = RunService.Heartbeat:Connect(update)
end

return ShotClock
