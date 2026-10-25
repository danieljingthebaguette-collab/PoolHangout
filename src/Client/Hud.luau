--!strict
-- The HUD around the top-down view, in the style of docs/STYLE.md: the top bar with your player card, the banner
-- under it naming fouls and the winner, the power meter on the left, the tray on the right where sunk balls collect,
-- the control hints on the bottom right, the settings button bottom-left with the sound volume, and beside it
-- "TEST MODE" while the physics test mode has the table.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Theme = require(ReplicatedStorage.Shared.Theme)
local Card = require(script.Parent.Card)
local Slider = require(script.Parent.Slider)
local TableView = require(script.Parent.TableView)

local Hud = {}

-- Everything the HUD shows only in the top-down view
local guis: { ScreenGui } = {}
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
	for _, gui in guis do
		gui.Enabled = visible
	end
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
	for i, row in rows or {} do
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

-- Your card, left of the top bar's center. The other player's card goes right of it in Phase 2.
local function playerCard(gui: ScreenGui)
	local player = Players.LocalPlayer
	local card = Instance.new("Frame")
	card.AnchorPoint = Vector2.new(1, 0)
	card.Position = UDim2.new(0.5, -Theme.Ui.Padding, 0, Theme.Ui.Padding)
	card.Size = UDim2.fromOffset(Theme.Ui.CardWidth, Theme.Ui.CardHeight)
	card.Active = true -- pressing it doesn't start a shot
	Card.style(card)
	card.Parent = gui
	local avatarSize = Theme.Ui.CardHeight - 2 * Theme.Ui.Padding
	local avatar = Instance.new("ImageLabel")
	avatar.AnchorPoint = Vector2.new(1, 0.5)
	avatar.Position = UDim2.new(1, -Theme.Ui.Padding, 0.5, 0)
	avatar.Size = UDim2.fromOffset(avatarSize, avatarSize)
	avatar.BackgroundColor3 = Theme.Colors.Dark
	avatar.Parent = card
	roundCorners(avatar)
	-- The name, with your group under it while you're in a game
	local text = Instance.new("Frame")
	text.AnchorPoint = Vector2.new(1, 0.5)
	text.Position = UDim2.new(1, -avatarSize - 2 * Theme.Ui.Padding, 0.5, 0)
	text.Size = UDim2.new(1, -avatarSize - 4 * Theme.Ui.Padding, 1, 0)
	text.BackgroundTransparency = 1
	text.Parent = card
	local stack = Instance.new("UIListLayout")
	stack.VerticalAlignment = Enum.VerticalAlignment.Center
	stack.SortOrder = Enum.SortOrder.LayoutOrder
	stack.Parent = text
	local name = label(player.DisplayName, text)
	name.Size = UDim2.new(1, 0, 0, Theme.Ui.LargeTextSize)
	name.TextXAlignment = Enum.TextXAlignment.Right
	name.TextTruncate = Enum.TextTruncate.AtEnd
	name.TextSize = Theme.Ui.LargeTextSize
	-- ponytail: a temporary label from the server's display-only "Group" and "MyTurn" attributes. The top bar task
	-- replaces it.
	local group = label("", text)
	group.LayoutOrder = 1
	group.Size = UDim2.new(1, 0, 0, Theme.TextSize)
	group.TextXAlignment = Enum.TextXAlignment.Right
	local function showGroup()
		local value = player:GetAttribute("Group")
		local groupName = if value == "solids" then "Solids" elseif value == "stripes" then "Stripes" else "Open table"
		group.Text = `{groupName} · {if player:GetAttribute("MyTurn") then "Your turn" else "Their turn"}`
		group.Visible = value ~= nil
	end
	player:GetAttributeChangedSignal("Group"):Connect(showGroup)
	player:GetAttributeChangedSignal("MyTurn"):Connect(showGroup)
	showGroup()
	-- Asking Roblox for the picture can wait or fail; the card works without it
	task.spawn(function()
		local ok, image = pcall(
			Players.GetUserThumbnailAsync,
			Players,
			player.UserId,
			Enum.ThumbnailType.HeadShot,
			Enum.ThumbnailSize.Size150x150
		)
		if ok then
			avatar.Image = image
		end
	end)
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
	playerCard(gui)
	bannerCard(gui)
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

	Remotes.Banner.OnClientEvent:Connect(function(model: Model?, message: string, seconds: number)
		if model == tableModel then
			showBanner(message, seconds)
		end
	end)

	-- Waits for the table's balls, so it goes last
	tray(gui, tableModel)
end

return Hud
