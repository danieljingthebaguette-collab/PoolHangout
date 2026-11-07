--!strict
-- The end screen: once a game is decided, its players see who won and why, each player's stats, and Rematch and Back to
-- lobby, until the server's close time. When every player presses Rematch the server starts the same players again;
-- Back to lobby closes this screen. A new turn starting, or the table resetting, closes it too. Nobody is moved.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Theme = require(ReplicatedStorage.Shared.Theme)
local Card = require(script.Parent.Card)
local Ui = require(script.Parent.Ui)

-- A seat's line on the end screen, as GameOver sends it
type Row = { player: Player, side: string, shots: number, kept: number, sunk: number, bestRun: number, fouls: number }
type Answer = { player: Player, rematch: boolean }

local EndScreen = {}

local COLUMNS = { "Player", "Accuracy", "Sunk", "Best run", "Fouls" }

local gui: ScreenGui? = nil
-- The screen while it's up: its table, its card, the line saying who has answered, the Rematch button, and the
-- countdown's connection
local shown: {
	model: Model,
	card: Frame,
	status: TextLabel,
	rematch: TextButton,
	connection: RBXScriptConnection,
}? =
	nil

local function close()
	if shown then
		shown.connection:Disconnect()
		shown.card:Destroy()
		shown = nil
	end
end

-- One line of the stats table: the name takes the first share of the width, the numbers split the rest
local function statsRow(parent: Instance, cells: { string }, order: number, highlight: boolean): Frame
	local ui = Theme.Ui
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, ui.EndRowHeight)
	row.BackgroundColor3 = Theme.Colors.WinnerRow
	row.BackgroundTransparency = if highlight then ui.WinnerRowTransparency else 1
	row.BorderSizePixel = 0
	row.LayoutOrder = order
	Ui.roundCorners(row)
	row.Parent = parent
	local numberShare = (1 - ui.EndNameShare) / (#cells - 1)
	local x = 0
	for i, text in cells do
		local width = if i == 1 then ui.EndNameShare else numberShare
		local cell = Ui.label(text, row)
		cell.Position = UDim2.new(x, if i == 1 then ui.Padding else 0, 0, 0)
		cell.Size = UDim2.new(width, if i == 1 then -ui.Padding else 0, 1, 0)
		cell.TextXAlignment = if i == 1 then Enum.TextXAlignment.Left else Enum.TextXAlignment.Center
		cell.TextTruncate = Enum.TextTruncate.AtEnd
		x += width
	end
	return row
end

local function show(
	model: Model,
	headline: string,
	winner: string,
	rows: { Row },
	canRematch: boolean,
	closesAt: number
)
	close()
	local ui = Theme.Ui
	local card = Instance.new("Frame")
	card.Name = "EndScreen"
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.5)
	card.Size = UDim2.fromOffset(ui.EndScreenWidth, 0)
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.Active = true -- clicks on it don't reach the table
	Card.style(card)
	card.Parent = gui

	-- The layout lives in a child frame, since the card's own children are its brackets and dots
	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.fromScale(1, 0)
	content.AutomaticSize = Enum.AutomaticSize.Y
	content.BackgroundTransparency = 1
	content.ZIndex = 3
	content.Parent = card
	local padding = Instance.new("UIPadding")
	for _, side in { "PaddingTop", "PaddingBottom", "PaddingLeft", "PaddingRight" } do
		(padding :: any)[side] = UDim.new(0, 2 * ui.Padding)
	end
	padding.Parent = content
	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, ui.Padding)
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.Parent = content

	local title = Ui.label(headline, content)
	title.Size = UDim2.fromScale(1, 0)
	title.AutomaticSize = Enum.AutomaticSize.Y
	title.TextSize = ui.LargeTextSize
	title.TextWrapped = true
	title.LayoutOrder = 1

	statsRow(content, COLUMNS, 2, false)
	for i, row in rows do
		local accuracy = if row.shots > 0 then `{math.round(row.kept / row.shots * 100)}%` else "–"
		local cells =
			{ row.player.DisplayName, accuracy, tostring(row.sunk), tostring(row.bestRun), tostring(row.fouls) }
		statsRow(content, cells, 2 + i, row.side == winner)
	end

	local status = Ui.label("", content)
	status.Size = UDim2.new(1, 0, 0, ui.EndRowHeight)
	status.LayoutOrder = 10

	local buttons = Instance.new("Frame")
	buttons.Name = "Buttons"
	buttons.Size = UDim2.new(1, 0, 0, ui.ButtonHeight)
	buttons.BackgroundTransparency = 1
	buttons.LayoutOrder = 11
	buttons.Parent = content
	local buttonList = Instance.new("UIListLayout")
	buttonList.FillDirection = Enum.FillDirection.Horizontal
	buttonList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	buttonList.Padding = UDim.new(0, ui.Padding)
	buttonList.Parent = buttons
	local rematch = Ui.accentButton("Rematch", Theme.Colors.Button, buttons)
	rematch.Name = "Rematch"
	rematch.Size = UDim2.fromOffset(ui.EndButtonWidth, ui.ButtonHeight)
	rematch.Visible = canRematch
	local lobby = Ui.accentButton("Back to lobby", Theme.Colors.LobbyButton, buttons)
	lobby.Name = "Lobby"
	lobby.Size = UDim2.fromOffset(ui.EndButtonWidth, ui.ButtonHeight)

	local countdown = Ui.label("", content)
	countdown.Size = UDim2.new(1, 0, 0, ui.EndRowHeight)
	countdown.LayoutOrder = 12

	rematch.Activated:Connect(function()
		-- Pressed once: it dims, and the line above says who's still to answer
		rematch.Active, rematch.AutoButtonColor = false, false
		rematch.BackgroundColor3 = Theme.Colors.Track
		Remotes.Rematch:FireServer(true)
	end)
	lobby.Activated:Connect(function()
		Remotes.Rematch:FireServer(false)
		close()
	end)

	local function tick()
		local left = math.ceil(closesAt - workspace:GetServerTimeNow())
		countdown.Text = `Closes in {math.max(left, 0)}`
		-- The server closes it; this is in case its message never comes
		if left < -1 then
			close()
		end
	end
	shown = {
		model = model,
		card = card,
		status = status,
		rematch = rematch,
		connection = RunService.Heartbeat:Connect(tick),
	}
	tick()
end

-- Who has answered so far, from the server: someone going back to the lobby means no rematch
local function showAnswers(model: Model, answers: { Answer })
	if not (shown and shown.model == model) then
		return
	end
	local me = Players.LocalPlayer
	local mine: boolean? = nil
	local wanting, leaving = {}, {}
	for _, answer in answers do
		if answer.player == me then
			mine = answer.rematch
		elseif answer.rematch then
			table.insert(wanting, answer.player.DisplayName)
		else
			table.insert(leaving, answer.player.DisplayName)
		end
	end
	if #leaving > 0 then
		shown.status.Text = `{table.concat(leaving, " and ")} went back to the lobby`
		shown.rematch.Visible = false
	elseif mine then
		shown.status.Text = "Waiting for the others…"
	elseif #wanting > 0 then
		shown.status.Text = `{table.concat(wanting, " and ")} {if #wanting == 1 then "wants" else "want"} a rematch`
	end
end

function EndScreen.start(playerGui: Instance)
	local screen = Instance.new("ScreenGui")
	screen.Name = "EndScreen"
	screen.ResetOnSpawn = false
	screen.DisplayOrder = 5 -- over the HUD and the banner
	screen.Parent = playerGui
	gui = screen

	Remotes.GameOver.OnClientEvent:Connect(show)
	Remotes.Rematch.OnClientEvent:Connect(showAnswers)
	-- A new turn (a rematch) or no game on the table any more closes it
	Remotes.TurnStarted.OnClientEvent:Connect(function(model: Model?, shooter: Player?, _: boolean?, seats: { Player }?)
		if shown and model == shown.model and (shooter ~= nil or seats == nil) then
			close()
		end
	end)
end

return EndScreen
