--!strict
-- The top bar: a card for each side, left and right of the gap kept in the middle for the shot clock. Each shows its
-- players' avatars and names, whose turn it is, and with a game on, its group and that group's balls. Every screen draws
-- it from the server's TurnStarted message, so they all agree.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Seat = require(ReplicatedStorage.Shared.Seat)
local Theme = require(ReplicatedStorage.Shared.Theme)
local Card = require(script.Parent.Card)
local Ui = require(script.Parent.Ui)

local TopBar = {}

-- One side's card: the card and its glow, up to two players' avatars with their rings, the names, and the row with the
-- group and its balls
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
-- The left and right cards, once they're built
local sideCards: { SideCard } = {}
-- Avatar pictures by user id, so each is only asked for once, and the user each avatar shows
local thumbnails: { [number]: string } = {}
local shownUsers: { [ImageLabel]: number } = {}

-- A side's card. The two are mirrored, so the avatars sit by the gap. Hidden until it has players to show.
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
	Ui.roundCorners(halo, UDim.new(0, Theme.Ui.Corner + reach))
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
		Ui.roundCorners(avatar)
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
	local names = Ui.label("", text)
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
	local group = Ui.label("", row)
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
local function showAvatar(avatar: ImageLabel, userId: number?)
	if shownUsers[avatar] == userId then
		return
	elseif not userId then
		-- Coach, the bot, has no avatar picture
		shownUsers[avatar] = nil
		avatar.Image = ""
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
	players: { Seat.Seat },
	shooter: Seat.Seat?,
	group: string?,
	down: { [number]: boolean }?
)
	side.card.Visible = #players > 0
	local turn = shooter ~= nil and table.find(players, shooter) ~= nil
	side.halo.Visible = side.card.Visible and turn
	side.outline.Enabled = turn
	local names = {}
	for i, avatar in side.avatars do
		local player: Seat.Seat? = players[i]
		avatar.Visible = player ~= nil
		side.rings[i].Enabled = player ~= nil and shooter ~= nil and player == shooter
		if player then
			table.insert(names, Seat.name(player))
			showAvatar(avatar, Seat.userId(player))
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
		local icon = Ui.ballIcon(id)
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

-- Builds both cards in `gui`, hidden
function TopBar.build(gui: ScreenGui)
	sideCards = { sideCard(gui, true), sideCard(gui, false) }
end

-- Draws the bar from a TurnStarted message: this player's side on the left and the other side on the right, or side A
-- on the left for anyone watching. With no game on, only this player's own card shows.
function TopBar.show(
	shooter: Seat.Seat?,
	seats: { Seat.Seat }?,
	groups: { [string]: string }?,
	downIds: { number }?
)
	local me = Players.LocalPlayer
	if not seats then
		showSide(sideCards[1], { me }, nil, nil, nil)
		showSide(sideCards[2], {}, nil, nil, nil)
		return
	end
	-- Seats go A1, B1, A2, B2. A 2v2 player who left shows as the teammate playing for them, so only once.
	local sides: { [string]: { Seat.Seat } } = { A = {}, B = {} }
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

return TopBar
