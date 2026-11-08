--!strict
-- The Leave button, top right in the top bar's row in both views while this player is at a table, and the question it
-- asks mid-game. Off a game it leaves at once; in one it asks first, since leaving loses unless a teammate plays on.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Theme = require(ReplicatedStorage.Shared.Theme)
local Card = require(script.Parent.Card)
local Ui = require(script.Parent.Ui)

local LeaveButton = {}

-- The button and the question, once they're built, and from the latest TurnStarted, whether this player is in a game
-- still being played and has a teammate still in it
local leave: { button: TextButton, ask: Frame }? = nil
local playing = false
local hasTeammate = false
-- Told whether this player is at a table each time that changes, and what it was last told
local onChange: ((atTable: boolean) -> ())? = nil
local wasAtTable: boolean? = nil

-- Shows the button while this player is at a table: joined and waiting, starting, or playing
local function showLeave()
	if not leave then
		return
	end
	local atTable = playing or Players.LocalPlayer:GetAttribute("JoinedTable") ~= nil
	leave.button.Visible = atTable
	leave.ask.Visible = leave.ask.Visible and playing
	if onChange and atTable ~= wasAtTable then
		wasAtTable = atTable
		onChange(atTable)
	end
end

-- Builds the button and its question. `onAtTable`, if given, hears whether this player is at a table (when the button
-- shows), once now and again each time it changes.
function LeaveButton.build(playerGui: Instance, onAtTable: ((atTable: boolean) -> ())?)
	onChange = onAtTable
	local gui = Instance.new("ScreenGui")
	gui.Name = "Leave"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true -- in the top bar's row, clear of the tray under it
	gui.DisplayOrder = 4 -- the question covers the rest of the HUD
	local button = Ui.accentButton("Leave", Theme.Colors.LeaveButton, gui)
	button.AnchorPoint = Vector2.new(1, 0)
	button.Position = UDim2.new(1, -Theme.Ui.Padding, 0, Theme.Ui.Padding)
	button.Size = UDim2.fromOffset(Theme.Ui.LeaveButtonWidth, Theme.Ui.ButtonHeight)
	button.Visible = false

	-- A card in the middle of the screen. Active, so a click on it never starts a shot.
	local ask = Instance.new("Frame")
	ask.AnchorPoint = Vector2.new(0.5, 0.5)
	ask.Position = UDim2.fromScale(0.5, 0.5)
	ask.Size = UDim2.fromOffset(Theme.Ui.AskWidth, 2 * Theme.Ui.ButtonHeight + 3 * Theme.Ui.Padding)
	ask.Active = true
	ask.Visible = false
	Card.style(ask)
	ask.Parent = gui
	local question = Ui.label("", ask)
	question.Position = UDim2.fromOffset(0, Theme.Ui.Padding)
	question.Size = UDim2.new(1, 0, 0, Theme.Ui.ButtonHeight)
	question.TextSize = Theme.Ui.LargeTextSize
	local yes = Ui.accentButton("Yes", Theme.Colors.LeaveButton, ask)
	yes.AnchorPoint = Vector2.new(1, 1)
	yes.Position = UDim2.new(0.5, -Theme.Ui.Padding / 2, 1, -Theme.Ui.Padding)
	yes.Size = UDim2.fromOffset(Theme.Ui.LeaveButtonWidth, Theme.Ui.ButtonHeight)
	local no = Ui.accentButton("No", Theme.Colors.Button, ask)
	no.AnchorPoint = Vector2.new(0, 1)
	no.Position = UDim2.new(0.5, Theme.Ui.Padding / 2, 1, -Theme.Ui.Padding)
	no.Size = yes.Size
	gui.Parent = playerGui
	leave = { button = button, ask = ask }

	button.Activated:Connect(function()
		if playing then
			question.Text = if hasTeammate then "Leave? Your teammate plays on alone." else "Leave and lose this game?"
			ask.Visible = true
		else
			Remotes.LeaveTable:FireServer()
		end
	end)
	yes.Activated:Connect(function()
		ask.Visible = false
		Remotes.LeaveTable:FireServer()
	end)
	no.Activated:Connect(function()
		ask.Visible = false
	end)
	Players.LocalPlayer:GetAttributeChangedSignal("JoinedTable"):Connect(showLeave)
	showLeave()
end

-- From a TurnStarted message: whether this player is in a game still being played, and has a teammate still in it
function LeaveButton.update(inGame: boolean, teammate: boolean)
	playing = inGame
	hasTeammate = teammate
	showLeave()
end

return LeaveButton
