--!strict
-- The HUD around the top-down view, in the style of docs/STYLE.md, built from its parts: TopBar (each side's card),
-- ShotClock (between the cards), Banner (fouls and the winner, under the top bar), LeaveButton (top right while you're at a table), PowerMeter (left),
-- Tray (right, where sunk balls collect), Hints (the control hints, bottom right) and SettingsPanel (the gear
-- bottom-left, with the sound volume), and beside the gear "TEST MODE" while the physics test mode has the table.
-- It also starts TurnArrow, the "Turn" card over each shooter's head in the normal view. The top bar, clock and tray
-- follow one table at a time (ActiveTable); setTable switches them.

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Items = require(ReplicatedStorage.Shared.Items)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Theme = require(ReplicatedStorage.Shared.Theme)
local Banner = require(script.Parent.Banner)
local Effects = require(script.Parent.Effects)
local EndScreen = require(script.Parent.EndScreen)
local Hints = require(script.Parent.Hints)
local LeaveButton = require(script.Parent.LeaveButton)
local PowerMeter = require(script.Parent.PowerMeter)
local SettingsPanel = require(script.Parent.SettingsPanel)
local ShotClock = require(script.Parent.ShotClock)
local TopBar = require(script.Parent.TopBar)
local TurnArrow = require(script.Parent.TurnArrow)
local Tray = require(script.Parent.Tray)
local Ui = require(script.Parent.Ui)

local Hud = {}

-- Everything the HUD shows only in the top-down view
local guis: { ScreenGui } = {}
local inView = false
-- The "TEST MODE" box, once it's built
local testLabel: TextLabel? = nil
-- The table the top bar, clock and tray follow, the HUD's main screen, and taking down the tray built for that table
local current: Model? = nil
local hudGui: ScreenGui? = nil
local removeTray: (() -> ())? = nil
-- Who was shooting at that table, so your balls pulse only as your turn starts, not on every shot you keep
local lastShooter: Instance? = nil

-- The ball parts that are yours on this table: your group's, or the 8 once your group is cleared. None on an open
-- table, where nothing is yours yet. Only the ones still on the table.
local function yourBalls(tableModel: Model, group: string?, onEight: boolean): { BasePart }
	local folder = tableModel:FindFirstChild("Balls")
	local parts: { BasePart } = {}
	for id = 1, 15 do
		local yours = if onEight
			then id == 8
			elseif group == "solids" then id < 8
			elseif group == "stripes" then id > 8
			else false
		local part = if yours and folder then folder:FindFirstChild(`Ball{id}`) else nil
		if part and part:IsA("BasePart") and part.Transparency ~= 1 then
			table.insert(parts, part)
		end
	end
	return parts
end

-- Shows the HUD while you're in the top-down view. In the normal view it would sit where phones put the thumbstick.
function Hud.showTable(visible: boolean)
	inView = visible
	for _, gui in guis do
		gui.Enabled = visible
	end
	-- Prompts float over the table, so in the top-down view "2/2 joined" would sit on the felt
	ProximityPromptService.Enabled = not visible
	TurnArrow.setHidden(visible)
end

-- Shows the pull on the power meter, 0 to 1, or hides the meter with nil while you can't shoot
function Hud.setPower(share: number?)
	PowerMeter.set(share)
end

-- Shows control hints down the bottom right, or hides them with nil
function Hud.setHints(rows: { { string } }?)
	Hints.set(rows)
end

-- Shows "TEST MODE" while no game is on the table and the physics test mode has it, so it can't pass for a game
function Hud.setTestMode(shown: boolean)
	if testLabel then
		testLabel.Visible = shown
	end
end

-- A small dark box bottom-left, beside the gear and the test panel's Test button
local function testModeLabel(gui: ScreenGui)
	local box = Ui.label("TEST MODE", gui)
	box.AnchorPoint = Vector2.new(0, 1)
	box.Position = UDim2.new(
		0,
		Theme.Ui.ButtonHeight + Theme.Ui.TestButtonWidth + 3 * Theme.Ui.Padding,
		1,
		-Theme.Ui.Padding - (Theme.Ui.ButtonHeight - Theme.Ui.HintHeight) / 2
	)
	box.Size = UDim2.fromOffset(0, Theme.Ui.HintHeight)
	box.AutomaticSize = Enum.AutomaticSize.X
	box.BackgroundTransparency = 0
	box.BackgroundColor3 = Theme.Colors.Dark
	box.TextColor3 = Theme.Colors.DarkText
	box.Visible = false
	Ui.roundCorners(box)
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, Theme.Ui.Padding)
	padding.PaddingRight = padding.PaddingLeft
	padding.Parent = box
	testLabel = box
end

-- Follows another table: its top bar and clock come with its next turn message, and its tray at once
function Hud.setTable(tableModel: Model)
	current = tableModel
	lastShooter = nil
	TopBar.show(nil, nil, nil, nil)
	TopBar.showItems(nil, nil)
	ShotClock.show(nil)
	if removeTray then
		removeTray()
		removeTray = nil
	end
	local gui = hudGui :: ScreenGui
	task.spawn(function()
		local remove = Tray.build(gui, tableModel)
		-- Another switch while this one waited for the balls
		if current == tableModel then
			removeTray = remove
		else
			remove()
		end
	end)
end

function Hud.start(tableModel: Model)
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	current = tableModel

	local gui = Instance.new("ScreenGui")
	gui.Name = "Hud"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true -- the top-down view's reserves are measured from the screen's top
	gui.Enabled = false
	TopBar.build(gui)
	TopBar.show(nil, nil, nil, nil)
	ShotClock.build(gui)
	Hints.build(gui)
	testModeLabel(gui)
	gui.Parent = playerGui
	table.insert(guis, gui)
	hudGui = gui

	local settingsGui = Instance.new("ScreenGui")
	settingsGui.Name = "Settings"
	settingsGui.ResetOnSpawn = false
	settingsGui.Enabled = false
	settingsGui.DisplayOrder = 3 -- the open panel covers the test panel's button beside the gear
	SettingsPanel.build(settingsGui)
	settingsGui.Parent = playerGui
	table.insert(guis, settingsGui)

	PowerMeter.build(playerGui)
	LeaveButton.build(playerGui)
	TurnArrow.start()
	EndScreen.start(playerGui)
	Banner.start(playerGui, function(model: Model): boolean
		return inView and model == current
	end)

	-- A player who has joined sees "Waiting for players" on that table's prompt, since there's no leaving until the
	-- game ends. Only on this screen, and the server's own words come back each time it changes them, so check again
	-- then.
	local player = Players.LocalPlayer
	for _, model in workspace:WaitForChild("Tables"):GetChildren() do
		task.spawn(function()
			local felt = model:WaitForChild("Felt")
			local prompt = felt:WaitForChild("JoinPrompt"):WaitForChild("ProximityPrompt") :: ProximityPrompt
			local function relabel()
				local mine = player:GetAttribute("JoinedTable") == model.Name
				if mine and prompt.ActionText == "Join table" then
					prompt.ActionText = "Waiting for players"
				elseif not mine and prompt.ActionText == "Waiting for players" then
					prompt.ActionText = "Join table"
				end
			end
			prompt:GetPropertyChangedSignal("ActionText"):Connect(relabel)
			player:GetAttributeChangedSignal("JoinedTable"):Connect(relabel)
			relabel()
		end)
	end
	Remotes.TurnStarted.OnClientEvent:Connect(
		function(
			model: Model?,
			shooter: Player?,
			_: boolean?,
			seats: { Player }?,
			onEight: boolean?,
			groups: { [string]: string }?,
			down: { number }?,
			clockEndsAt: number?
		)
			if model ~= current then
				return
			end
			TopBar.show(shooter, seats, groups, down)
			ShotClock.show(if shooter then clockEndsAt else nil)
			-- Your turn starting: your balls pulse once, so you can see which they are
			local seat = seats and table.find(seats, player)
			if shooter == player and lastShooter ~= player and seat then
				local side = if seat % 2 == 1 then "A" else "B"
				Effects.pulse(yourBalls(model :: Model, (groups or {})[side], onEight == true))
			end
			lastShooter = shooter
			-- In a game still being played, and in 2v2 with a teammate still in: seats alternate sides, and a teammate
			-- who left shows as this player
			local teammate = false
			for i, other in (seats or {}) :: { Player } do
				teammate = teammate or (seat ~= nil and other ~= player and i % 2 == seat % 2)
			end
			LeaveButton.update(seat ~= nil and shooter ~= nil, teammate)
		end
	)

	Remotes.ItemsChanged.OnClientEvent:Connect(function(model: Model?, bars: { Items.Bar }?, pops: { Items.Pop }?)
		if model == current then
			TopBar.showItems(bars, pops)
		end
	end)

	-- The clock stops when the shot goes
	Remotes.ShotStarted.OnClientEvent:Connect(function(model: Model?)
		if model == current then
			ShotClock.show(nil)
		end
	end)

	Hud.setTable(tableModel)
end

return Hud
