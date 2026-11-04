--!strict
-- The HUD around the top-down view, in the style of docs/STYLE.md: the top bar with each side's card, the banner
-- under it naming fouls and the winner, the Leave button top right while you're at a table, the power meter on the left, the tray on the right where sunk balls collect,
-- the control hints on the bottom right, the settings button bottom-left with the sound volume, and beside it
-- "TEST MODE" while the physics test mode has the table.

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Theme = require(ReplicatedStorage.Shared.Theme)
local Card = require(script.Parent.Card)
local Slider = require(script.Parent.Slider)
local TableView = require(script.Parent.TableView)

local Hud = {}

-- Everything the HUD shows only in the top-down view
local guis: { ScreenGui } = {}
local inView = false
-- The power meter, once it's built: its screen, its fill and its % readout
local meter: { gui: ScreenGui, fill: Frame, percent: TextLabel }? = nil
-- The control hints' column, once it's built, and the rows it shows
local hintColumn: Frame? = nil
local shownHints: { { string } }? = nil
-- The "TEST MODE" box, once it's built
local testLabel: TextLabel? = nil
-- The banner's card and text, once it's built, and how many messages it has shown, so an older message's timer
-- leaves a newer one up
local banner: { box: Frame, text: TextLabel }? = nil
local bannersShown = 0

-- One side's card in the top bar: the card and its glow, up to two players' avatars with their rings, the names, and
-- the row with the group and its balls
type SideCard = {
	left: boolean,
	halo: Frame,
	card: Frame,
	outline: UIStroke,
	avatars: { ImageLabel },
	rings: { UIStroke },
	text: Frame,
	names: TextLabel,
	row: Frame,
	group: TextLabel,
}
-- The top bar's left and right cards, once they're built
local sideCards: { SideCard } = {}
-- Avatar pictures by user id, so each is only asked for once, and the user each avatar shows
local thumbnails: { [number]: string } = {}
local shownUsers: { [ImageLabel]: number } = {}
-- The Leave button and the question it asks mid-game, once they're built, and from the latest TurnStarted, whether
-- this player is in a game still being played and has a teammate still in it
local leave: { button: TextButton, ask: Frame }? = nil
local playing = false

local function roundCorners(item: GuiObject, radius: UDim?)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = radius or UDim.new(0, Theme.Ui.Corner)
	corner.Parent = item
end

local function label(text: string, parent: Instance): TextLabel
	local item = Instance.new("TextLabel")
	item.BackgroundTransparency = 1
	item.FontFace = Theme.Font
	item.TextSize = Theme.TextSize
	item.TextColor3 = Theme.Colors.Text
	item.Text = text
	item.Parent = parent
	return item
end

-- Screen height, in pixels, kept clear along the bottom for the gear (left) and the control hints (right)
function Hud.bottomBand(): number
	local hints = Theme.Ui.HintRows * Theme.Ui.HintHeight + (Theme.Ui.HintRows - 1) * Theme.Ui.Padding / 2
	return math.max(Theme.Ui.ButtonHeight, hints) + 2 * Theme.Ui.Padding
end

-- Shows the HUD while you're in the top-down view. In the normal view it would sit where phones put the thumbstick.
function Hud.showTable(visible: boolean)
	inView = visible
	for _, gui in guis do
		gui.Enabled = visible
	end
	-- Prompts float over the table, so in the top-down view "Table in use" would sit on the felt
	ProximityPromptService.Enabled = not visible
end

-- Shows the pull on the power meter, 0 to 1, or hides the meter with nil while you can't shoot
function Hud.setPower(share: number?)
	if not meter then
		return
	end
	meter.gui.Enabled = share ~= nil
	if share then
		meter.fill.Size = UDim2.fromScale(1, share)
		meter.percent.Text = `{math.round(share * 100)}%`
	end
end

-- One control hint: a label box and its key box, like "Lock aim [Space]"
local function hintRow(text: string, key: string, order: number): Frame
	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.Size = UDim2.fromOffset(0, Theme.Ui.HintHeight)
	row.AutomaticSize = Enum.AutomaticSize.X
	row.LayoutOrder = order
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, Theme.Ui.Padding / 2)
	layout.Parent = row
	for i, part in { { text = text, dark = false }, { text = key, dark = true } } do
		local box = label(part.text, row)
		box.LayoutOrder = i
		box.Size = UDim2.fromOffset(0, Theme.Ui.HintHeight)
		box.AutomaticSize = Enum.AutomaticSize.X
		box.BackgroundTransparency = if part.dark then 0 else Theme.Ui.HudTransparency
		box.BackgroundColor3 = if part.dark then Theme.Colors.Dark else Theme.Colors.Panel
		box.TextColor3 = if part.dark then Theme.Colors.DarkText else Theme.Colors.Text
		roundCorners(box)
		local padding = Instance.new("UIPadding")
		padding.PaddingLeft = UDim.new(0, Theme.Ui.Padding)
		padding.PaddingRight = padding.PaddingLeft
		padding.Parent = box
	end
	return row
end

-- Shows control hints down the bottom right, each a label and its key, or hides them with nil. `rows` is one of a
-- few fixed lists, so the rows are only rebuilt when a different list comes in.
function Hud.setHints(rows: { { string } }?)
	if not hintColumn or rows == shownHints then
		return
	end
	shownHints = rows
	for _, child in hintColumn:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	for i, row in (rows or {}) :: { { string } } do
		hintRow(row[1], row[2], i).Parent = hintColumn
	end
end

local function hints(gui: ScreenGui)
	local column = Instance.new("Frame")
	column.AnchorPoint = Vector2.new(1, 1)
	column.Position = UDim2.new(1, -Theme.Ui.Padding, 1, -Theme.Ui.Padding)
	column.AutomaticSize = Enum.AutomaticSize.XY
	column.BackgroundTransparency = 1
	column.Parent = gui
	local layout = Instance.new("UIListLayout")
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, Theme.Ui.Padding / 2)
	layout.Parent = column
	hintColumn = column
end

-- The power meter on the left with its % readout in a dark box. It only shows the pull; you don't drag it. Its own
-- screen, below Roblox's top bar, so the phones' Lock button (ShotController) lines up beside it.
local function powerMeter(playerGui: Instance)
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
	roundCorners(track)
	-- Fills up from the bottom as you pull
	local fill = Instance.new("Frame")
	fill.AnchorPoint = Vector2.new(0, 1)
	fill.Position = UDim2.fromScale(0, 1)
	fill.Size = UDim2.fromScale(1, 0)
	fill.BackgroundColor3 = Theme.Colors.Fill
	fill.BorderSizePixel = 0
	fill.Parent = track
	roundCorners(fill)
	local percent = label("0%", gui)
	percent.AnchorPoint = Vector2.new(0.5, 0)
	percent.Position = UDim2.new(0, Theme.Ui.MeterReserve / 2, 0.5 + Theme.Ui.MeterHeight / 2, Theme.Ui.Padding)
	percent.Size = UDim2.fromOffset(Theme.Ui.MeterReserve - Theme.Ui.Padding, Theme.Ui.LargeTextSize + Theme.Ui.Padding)
	percent.TextSize = Theme.Ui.LargeTextSize
	percent.BackgroundTransparency = 0
	percent.BackgroundColor3 = Theme.Colors.Dark
	percent.TextColor3 = Theme.Colors.DarkText
	roundCorners(percent)
	gui.Parent = playerGui
	meter = { gui = gui, fill = fill, percent = percent }
end

-- A cream card at the top center, under the top bar, for a message from the server. Hidden until one comes.
local function bannerCard(gui: ScreenGui)
	local box = Instance.new("Frame")
	box.AnchorPoint = Vector2.new(0.5, 0)
	box.Position = UDim2.new(0.5, 0, 0, Theme.Ui.CardHeight + 2 * Theme.Ui.Padding)
	box.Size = UDim2.fromOffset(Theme.Ui.BannerWidth, Theme.Ui.BannerHeight)
	box.Visible = false
	Card.style(box)
	box.Parent = gui
	local text = label("", box)
	text.Size = UDim2.new(1, -4 * Theme.Ui.Padding, 1, -Theme.Ui.Padding)
	text.AnchorPoint = Vector2.new(0.5, 0.5)
	text.Position = UDim2.fromScale(0.5, 0.5)
	-- Long names shrink the text to fit rather than spill out
	text.TextScaled = true
	local fit = Instance.new("UITextSizeConstraint")
	fit.MaxTextSize = Theme.Ui.LargeTextSize
	fit.Parent = text
	banner = { box = box, text = text }
end

-- Shows a message on the banner for `seconds`, replacing any message still up
local function showBanner(message: string, seconds: number)
	if not banner then
		return
	end
	bannersShown += 1
	local shown = bannersShown
	banner.text.Text = message
	banner.box.Visible = true
	task.delay(seconds, function()
		if banner and bannersShown == shown then
			banner.box.Visible = false
		end
	end)
end

-- A small ball for the tray: its color, or white with a band of color for a stripe
local function ballIcon(id: number): Frame
	local icon = Instance.new("Frame")
	icon.Size = UDim2.fromScale(0.8, 1 / 15)
	icon.BorderSizePixel = 0
	roundCorners(icon, UDim.new(0.5, 0))
	local fit = Instance.new("UIAspectRatioConstraint")
	fit.AspectRatio = 1
	fit.Parent = icon
	-- So the 8 shows against the dark tray
	local outline = Instance.new("UIStroke")
	outline.Color = Theme.Colors.DarkText
	outline.Thickness = 1
	outline.Parent = icon
	if id >= 9 then
		icon.BackgroundColor3 = Color3.new(1, 1, 1)
		-- Sharp steps in a gradient draw the band, and the rounded corners clip it to the circle
		local white, color = Theme.Colors.BallMark, Theme.BallColors[id]
		local band = Instance.new("UIGradient")
		band.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, white),
			ColorSequenceKeypoint.new(0.25, white),
			ColorSequenceKeypoint.new(0.251, color),
			ColorSequenceKeypoint.new(0.749, color),
			ColorSequenceKeypoint.new(0.75, white),
			ColorSequenceKeypoint.new(1, white),
		})
		band.Rotation = 90
		band.Parent = icon
	else
		icon.BackgroundColor3 = Theme.BallColors[id]
	end
	return icon
end

-- A side's card in the top bar, left or right of the gap kept in the middle for the shot clock. The two are mirrored,
-- so the avatars sit by the gap. Hidden until it has players to show.
local function sideCard(gui: ScreenGui, left: boolean): SideCard
	local anchorX = if left then 1 else 0
	local inward = if left then -1 else 1
	local x = inward * Theme.Ui.TopBarGap / 2
	-- The soft glow round the card while it's this side's turn. Behind it rather than in it, since the card clips what's
	-- inside it.
	local reach = Theme.Ui.TurnHalo
	local halo = Instance.new("Frame")
	halo.AnchorPoint = Vector2.new(anchorX, 0)
	halo.Position = UDim2.new(0.5, x - inward * reach, 0, Theme.Ui.Padding - reach)
	halo.Size = UDim2.fromOffset(Theme.Ui.CardWidth + 2 * reach, Theme.Ui.CardHeight + 2 * reach)
	halo.BackgroundColor3 = Theme.Colors.TurnGlow
	halo.BackgroundTransparency = Theme.Ui.TurnHaloTransparency
	halo.BorderSizePixel = 0
	halo.ZIndex = 0
	halo.Visible = false
	roundCorners(halo, UDim.new(0, Theme.Ui.Corner + reach))
	halo.Parent = gui

	local card = Instance.new("Frame")
	card.AnchorPoint = Vector2.new(anchorX, 0)
	card.Position = UDim2.new(0.5, x, 0, Theme.Ui.Padding)
	card.Size = UDim2.fromOffset(Theme.Ui.CardWidth, Theme.Ui.CardHeight)
	card.Active = true -- pressing it doesn't start a shot
	card.Visible = false
	Card.style(card)
	card.Parent = gui
	local outline = Instance.new("UIStroke")
	outline.Color = Theme.Colors.TurnGlow
	outline.Thickness = Theme.Ui.TurnGlow
	outline.Enabled = false
	outline.Parent = card

	-- Two avatars side by side from the edge by the gap, for 2v2. The shooter's gets a gold ring.
	local avatarSize = Theme.Ui.CardHeight - 2 * Theme.Ui.Padding
	local avatars, rings = {}, {}
	for i = 1, 2 do
		local avatar = Instance.new("ImageLabel")
		avatar.AnchorPoint = Vector2.new(anchorX, 0.5)
		avatar.Position =
			UDim2.new(anchorX, inward * (Theme.Ui.Padding + (i - 1) * (avatarSize + Theme.Ui.Padding / 2)), 0.5, 0)
		avatar.Size = UDim2.fromOffset(avatarSize, avatarSize)
		avatar.BackgroundColor3 = Theme.Colors.Dark
		avatar.Visible = false
		avatar.Parent = card
		roundCorners(avatar)
		local ring = Instance.new("UIStroke")
		ring.Color = Theme.Colors.TurnGlow
		ring.Thickness = Theme.Ui.TurnGlow
		ring.Enabled = false
		ring.Parent = avatar
		avatars[i], rings[i] = avatar, ring
	end

	-- The names, with the group and its balls under them, beside the avatars
	local align = if left then Enum.TextXAlignment.Right else Enum.TextXAlignment.Left
	local text = Instance.new("Frame")
	text.AnchorPoint = Vector2.new(anchorX, 0.5)
	text.BackgroundTransparency = 1
	text.Parent = card
	local stack = Instance.new("UIListLayout")
	stack.VerticalAlignment = Enum.VerticalAlignment.Center
	stack.SortOrder = Enum.SortOrder.LayoutOrder
	stack.Parent = text
	local names = label("", text)
	names.Size = UDim2.new(1, 0, 0, Theme.Ui.LargeTextSize)
	names.TextXAlignment = align
	names.TextTruncate = Enum.TextTruncate.AtEnd
	names.TextSize = Theme.Ui.LargeTextSize
	local row = Instance.new("Frame")
	row.LayoutOrder = 1
	row.Size = UDim2.new(1, 0, 0, Theme.TextSize)
	row.BackgroundTransparency = 1
	row.Parent = text
	local line = Instance.new("UIListLayout")
	line.FillDirection = Enum.FillDirection.Horizontal
	line.HorizontalAlignment = if left then Enum.HorizontalAlignment.Right else Enum.HorizontalAlignment.Left
	line.VerticalAlignment = Enum.VerticalAlignment.Center
	line.SortOrder = Enum.SortOrder.LayoutOrder
	line.Padding = UDim.new(0, 2)
	line.Parent = row
	local group = label("", row)
	group.Size = UDim2.fromScale(0, 1)
	group.AutomaticSize = Enum.AutomaticSize.X
	local gap = Instance.new("UIPadding")
	gap.PaddingRight = UDim.new(0, Theme.Ui.Padding / 2)
	gap.Parent = group

	return {
		left = left,
		halo = halo,
		card = card,
		outline = outline,
		avatars = avatars,
		rings = rings,
		text = text,
		names = names,
		row = row,
		group = group,
	}
end

-- Puts a player's picture on an avatar. Asking Roblox for it can wait or fail; the card works without it.
local function showAvatar(avatar: ImageLabel, userId: number)
	if shownUsers[avatar] == userId then
		return
	end
	shownUsers[avatar] = userId
	avatar.Image = thumbnails[userId] or ""
	if thumbnails[userId] then
		return
	end
	task.spawn(function()
		local ok, image = pcall(
			Players.GetUserThumbnailAsync,
			Players,
			userId,
			Enum.ThumbnailType.HeadShot,
			Enum.ThumbnailSize.Size150x150
		)
		if ok then
			thumbnails[userId] = image
			if shownUsers[avatar] == userId then
				avatar.Image = image
			end
		end
	end)
end

-- Shows a side on its card: its players, whether it's their turn (the card glows and the shooter's avatar gets a
-- ring), and with a game on, its group with that group's balls, sunk ones greyed out, and the 8 once all seven are
-- down. No players hides the card.
local function showSide(
	side: SideCard,
	players: { Player },
	shooter: Player?,
	group: string?,
	down: { [number]: boolean }?
)
	side.card.Visible = #players > 0
	local turn = shooter ~= nil and table.find(players, shooter) ~= nil
	side.halo.Visible = side.card.Visible and turn
	side.outline.Enabled = turn
	local names = {}
	for i, avatar in side.avatars do
		local player: Player? = players[i]
		avatar.Visible = player ~= nil
		side.rings[i].Enabled = player ~= nil and player == shooter
		if player then
			table.insert(names, player.DisplayName)
			showAvatar(avatar, player.UserId)
		end
	end
	side.names.Text = table.concat(names, " · ")
	-- The text starts beside the last avatar shown
	local avatarSize = Theme.Ui.CardHeight - 2 * Theme.Ui.Padding
	local used = Theme.Ui.Padding * 3 / 2 + math.max(#players, 1) * (avatarSize + Theme.Ui.Padding / 2)
	side.text.Position = UDim2.new(if side.left then 1 else 0, (if side.left then -1 else 1) * used, 0.5, 0)
	side.text.Size = UDim2.new(1, -used - Theme.Ui.Padding * 2, 1, 0)

	side.row.Visible = down ~= nil
	side.group.Text = if group == "solids" then "Solids" elseif group == "stripes" then "Stripes" else "Open table"
	for _, child in side.row:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	if not (down and (group == "solids" or group == "stripes")) then
		return
	end
	local first = if group == "solids" then 1 else 9
	local ids = {}
	for id = first, first + 6 do
		table.insert(ids, id)
	end
	local cleared = true
	for _, id in ids do
		cleared = cleared and down[id] == true
	end
	if cleared then
		table.insert(ids, 8)
	end
	for i, id in ids do
		local icon = ballIcon(id)
		icon.Size = UDim2.fromOffset(Theme.Ui.CardBallSize, Theme.Ui.CardBallSize)
		icon.LayoutOrder = i;
		(icon:FindFirstChildOfClass("UIStroke") :: UIStroke).Color = Theme.Colors.Text
		if down[id] then
			icon.BackgroundColor3 = Theme.Colors.SunkBall
			local band = icon:FindFirstChildOfClass("UIGradient")
			if band then
				band.Enabled = false
			end
		end
		icon.Parent = side.row
	end
end

-- The top bar from a TurnStarted message: this player's side on the left and the other side on the right, or side A
-- on the left for anyone watching. Every screen draws it from the same message, so they all agree. With no game on,
-- only this player's own card shows.
local function showTopBar(shooter: Player?, seats: { Player }?, groups: { [string]: string }?, downIds: { number }?)
	local me = Players.LocalPlayer
	if not seats then
		showSide(sideCards[1], { me }, nil, nil, nil)
		showSide(sideCards[2], {}, nil, nil, nil)
		return
	end
	-- Seats go A1, B1, A2, B2. A 2v2 player who left shows as the teammate playing for them, so only once.
	local sides: { [string]: { Player } } = { A = {}, B = {} }
	for i, player in seats do
		local side = sides[if i % 2 == 1 then "A" else "B"]
		if not table.find(side, player) then
			table.insert(side, player)
		end
	end
	local seat = table.find(seats, me)
	local mine = if seat and seat % 2 == 0 then "B" else "A"
	local theirs = if mine == "A" then "B" else "A"
	local down: { [number]: boolean } = {}
	for _, id in (downIds or {}) :: { number } do
		down[id] = true
	end
	showSide(sideCards[1], sides[mine], shooter, (groups or {})[mine], down)
	showSide(sideCards[2], sides[theirs], shooter, (groups or {})[theirs], down)
end

-- A bright button with ink text
local function accentButton(text: string, color: Color3, parent: Instance): TextButton
	local button = Instance.new("TextButton")
	button.BackgroundColor3 = color
	button.FontFace = Theme.Font
	button.TextSize = Theme.TextSize
	button.TextColor3 = Theme.Colors.Text
	button.Text = text
	button.Parent = parent
	roundCorners(button)
	return button
end

-- Shows the Leave button while this player is at a table: joined and waiting, starting, or playing
local function showLeave()
	if not leave then
		return
	end
	leave.button.Visible = playing or Players.LocalPlayer:GetAttribute("JoinedTable") ~= nil
	leave.ask.Visible = leave.ask.Visible and playing
end

-- The Leave button, top right in the top bar's row in both views, and the question it asks mid-game. Off a game it
-- leaves at once; in one it asks first, since leaving loses unless a teammate plays on.
local function leaveControls(playerGui: Instance): (boolean) -> ()
	local gui = Instance.new("ScreenGui")
	gui.Name = "Leave"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true -- in the top bar's row, clear of the tray under it
	gui.DisplayOrder = 4 -- the question covers the rest of the HUD
	local button = accentButton("Leave", Theme.Colors.LeaveButton, gui)
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
	local question = label("", ask)
	question.Position = UDim2.fromOffset(0, Theme.Ui.Padding)
	question.Size = UDim2.new(1, 0, 0, Theme.Ui.ButtonHeight)
	question.TextSize = Theme.Ui.LargeTextSize
	local yes = accentButton("Yes", Theme.Colors.LeaveButton, ask)
	yes.AnchorPoint = Vector2.new(1, 1)
	yes.Position = UDim2.new(0.5, -Theme.Ui.Padding / 2, 1, -Theme.Ui.Padding)
	yes.Size = UDim2.fromOffset(Theme.Ui.LeaveButtonWidth, Theme.Ui.ButtonHeight)
	local no = accentButton("No", Theme.Colors.Button, ask)
	no.AnchorPoint = Vector2.new(0, 1)
	no.Position = UDim2.new(0.5, Theme.Ui.Padding / 2, 1, -Theme.Ui.Padding)
	no.Size = yes.Size
	gui.Parent = playerGui
	leave = { button = button, ask = ask }

	local hasTeammate = false
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
	-- TurnStarted says whether this player's teammate is still in
	return function(teammate: boolean)
		hasTeammate = teammate
	end
end

-- The tray on the right, a dark box from below the top bar down to the control hints. Each object ball joins it
-- when its part is hidden (it dropped) and leaves when it's shown again (a rack). The first ball sunk sits at the
-- bottom.
local function tray(gui: ScreenGui, tableModel: Model)
	local top = Theme.Ui.CardHeight + 2 * Theme.Ui.Padding
	local box = Instance.new("Frame")
	box.AnchorPoint = Vector2.new(0.5, 0)
	box.Position = UDim2.new(1, -Theme.Ui.TrayReserve / 2, 0, top)
	box.Size = UDim2.new(0, Theme.Ui.TrayWidth, 1, -top - Hud.bottomBand())
	box.Active = true -- pressing it doesn't start a shot
	Card.style(box, true)
	box.Parent = gui
	-- The stack sits in its own frame, so its layout leaves the brackets alone
	local stack = Instance.new("Frame")
	stack.Size = UDim2.fromScale(1, 1)
	stack.BackgroundTransparency = 1
	stack.Parent = box
	local list = Instance.new("UIListLayout")
	list.VerticalAlignment = Enum.VerticalAlignment.Bottom
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 2)
	list.Parent = stack
	local padding = Instance.new("UIPadding")
	padding.PaddingBottom = UDim.new(0, Theme.Ui.Padding)
	padding.PaddingTop = padding.PaddingBottom
	padding.Parent = stack

	local icons: { [number]: Frame } = {}
	local sunk = 0
	local balls = tableModel:WaitForChild("Balls")
	for id = 1, 15 do
		local part = balls:WaitForChild(`Ball{id}`) :: BasePart
		local function update()
			local down = part.Transparency == 1
			if down and not icons[id] then
				sunk += 1
				local icon = ballIcon(id)
				-- Later balls sort above earlier ones, so the stack grows up from the bottom
				icon.LayoutOrder = -sunk
				icon.Parent = stack
				icons[id] = icon
			elseif not down and icons[id] then
				icons[id]:Destroy()
				icons[id] = nil
			end
		end
		update()
		part:GetPropertyChangedSignal("Transparency"):Connect(update)
	end
end

-- Shows "TEST MODE" while no game is on the table and the physics test mode has it, so it can't pass for a game
function Hud.setTestMode(shown: boolean)
	if testLabel then
		testLabel.Visible = shown
	end
end

-- A small dark box bottom-left, beside the gear and the test panel's Test button
local function testModeLabel(gui: ScreenGui)
	local box = label("TEST MODE", gui)
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
	roundCorners(box)
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, Theme.Ui.Padding)
	padding.PaddingRight = padding.PaddingLeft
	padding.Parent = box
	testLabel = box
end

-- The gear bottom-left, a bright accent button, and the card it opens with the sound volume
local function settings(gui: ScreenGui)
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
	roundCorners(gear)

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

function Hud.start(tableModel: Model)
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local gui = Instance.new("ScreenGui")
	gui.Name = "Hud"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true -- the top-down view's reserves are measured from the screen's top
	gui.Enabled = false
	sideCards = { sideCard(gui, true), sideCard(gui, false) }
	showTopBar(nil, nil, nil, nil)
	hints(gui)
	testModeLabel(gui)
	gui.Parent = playerGui
	table.insert(guis, gui)

	local settingsGui = Instance.new("ScreenGui")
	settingsGui.Name = "Settings"
	settingsGui.ResetOnSpawn = false
	settingsGui.Enabled = false
	settingsGui.DisplayOrder = 3 -- the open panel covers the test panel's button beside the gear
	settings(settingsGui)
	settingsGui.Parent = playerGui
	table.insert(guis, settingsGui)

	powerMeter(playerGui)
	local setTeammate = leaveControls(playerGui)

	-- The banner has its own screen, shown in either view, since "Starting..." comes before anyone's in the top-down
	-- view. It's for everyone at the table: watching from above, waiting to play, or standing near it.
	local bannerGui = Instance.new("ScreenGui")
	bannerGui.Name = "Banner"
	bannerGui.ResetOnSpawn = false
	bannerGui.IgnoreGuiInset = true -- so it lines up under the top bar's cards
	bannerCard(bannerGui)
	bannerGui.Parent = playerGui
	local felt = tableModel:WaitForChild("Felt") :: BasePart
	local player = Players.LocalPlayer
	local function atTable(): boolean
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		return inView
			or player:GetAttribute("JoinedTable") == tableModel.Name
			or (
				root ~= nil
				and root:IsA("BasePart")
				and (root.Position - felt.Position).Magnitude <= Config.Join.BannerDistance
			)
	end
	Remotes.Banner.OnClientEvent:Connect(function(model: Model?, message: string, seconds: number)
		if model == tableModel and atTable() then
			showBanner(message, seconds)
		end
	end)

	-- A player who has joined sees "Waiting for players" on the prompt, since there's no leaving until the game ends.
	-- Only on this screen, and the server's own words come back each time it changes them, so check again then.
	task.spawn(function()
		local prompt = felt:WaitForChild("JoinPrompt"):WaitForChild("ProximityPrompt") :: ProximityPrompt
		local function relabel()
			local mine = player:GetAttribute("JoinedTable") == tableModel.Name
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
	Remotes.TurnStarted.OnClientEvent:Connect(
		function(
			model: Model?,
			shooter: Player?,
			_: boolean?,
			seats: { Player }?,
			_: boolean?,
			groups: { [string]: string }?,
			down: { number }?
		)
			if model ~= tableModel then
				return
			end
			showTopBar(shooter, seats, groups, down)
			-- In a game still being played, and in 2v2 with a teammate still in: seats alternate sides, and a teammate
			-- who left shows as this player
			local seat = seats and table.find(seats, player)
			playing = seat ~= nil and shooter ~= nil
			local teammate = false
			for i, other in (seats or {}) :: { Player } do
				teammate = teammate or (seat ~= nil and other ~= player and i % 2 == seat % 2)
			end
			setTeammate(teammate)
			showLeave()
		end
	)

	-- Waits for the table's balls, so it goes last
	tray(gui, tableModel)
end

return Hud
