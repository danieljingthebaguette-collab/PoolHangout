--!strict
-- The HUD around the top-down view: the top bar with your player card, and the tray on the right where sunk
-- balls collect. The settings button bottom-left, with the sound volume, shows in every view. The power meter
-- belongs to ShotController.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Theme = require(ReplicatedStorage.Shared.Theme)
local TableView = require(script.Parent.TableView)

local Hud = {}

-- Everything the HUD shows only in the top-down view
local guis: { ScreenGui } = {}

local function roundCorners(item: GuiObject, radius: UDim?)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = radius or UDim.new(0, Theme.Ui.Corner)
	corner.Parent = item
end

local function label(text: string, parent: Instance): TextLabel
	local item = Instance.new("TextLabel")
	item.BackgroundTransparency = 1
	item.Font = Theme.Font
	item.TextSize = Theme.TextSize
	item.TextColor3 = Theme.Colors.HudText
	item.Text = text
	item.Parent = parent
	return item
end

local function panel(parent: Instance): Frame
	local item = Instance.new("Frame")
	item.BackgroundColor3 = Theme.Colors.HudPanel
	item.BackgroundTransparency = Theme.Ui.HudTransparency
	item.BorderSizePixel = 0
	item.Parent = parent
	roundCorners(item)
	return item
end

-- Shows the HUD while you're in the top-down view. In the normal view it would sit where phones put the thumbstick.
function Hud.showTable(visible: boolean)
	for _, gui in guis do
		gui.Enabled = visible
	end
end

-- Your card, left of the top bar's center. The other player's card goes right of it in Phase 2.
local function playerCard(gui: ScreenGui)
	local player = Players.LocalPlayer
	local card = panel(gui)
	card.AnchorPoint = Vector2.new(1, 0)
	card.Position = UDim2.new(0.5, -Theme.Ui.Padding, 0, Theme.Ui.Padding)
	card.Size = UDim2.fromOffset(Theme.Ui.CardWidth, Theme.Ui.CardHeight)
	card.Active = true -- pressing it doesn't start a shot
	local avatarSize = Theme.Ui.CardHeight - 2 * Theme.Ui.Padding
	local avatar = Instance.new("ImageLabel")
	avatar.AnchorPoint = Vector2.new(1, 0.5)
	avatar.Position = UDim2.new(1, -Theme.Ui.Padding, 0.5, 0)
	avatar.Size = UDim2.fromOffset(avatarSize, avatarSize)
	avatar.BackgroundColor3 = Theme.Colors.Track
	avatar.Parent = card
	roundCorners(avatar)
	local name = label(player.DisplayName, card)
	name.AnchorPoint = Vector2.new(1, 0.5)
	name.Position = UDim2.new(1, -avatarSize - 2 * Theme.Ui.Padding, 0.5, 0)
	name.Size = UDim2.new(1, -avatarSize - 4 * Theme.Ui.Padding, 1, 0)
	name.TextXAlignment = Enum.TextXAlignment.Right
	name.TextTruncate = Enum.TextTruncate.AtEnd
	name.TextSize = Theme.Ui.PercentTextSize
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

-- A small ball for the tray: its color, or white with a band of color for a stripe
local function ballIcon(id: number): Frame
	local icon = Instance.new("Frame")
	icon.Size = UDim2.fromScale(0.8, 1 / 15)
	icon.BorderSizePixel = 0
	roundCorners(icon, UDim.new(0.5, 0))
	local fit = Instance.new("UIAspectRatioConstraint")
	fit.AspectRatio = 1
	fit.Parent = icon
	-- So the 8 shows against the black tray
	local outline = Instance.new("UIStroke")
	outline.Color = Theme.Colors.HudSubtle
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

-- The tray on the right. Each object ball joins it when its part is hidden (it dropped) and leaves when it's shown
-- again (a rack). The first ball sunk sits at the bottom.
local function tray(gui: ScreenGui, tableModel: Model)
	local frame = Instance.new("Frame")
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.new(1, -Theme.Ui.TrayReserve / 2, 0.5, 0)
	frame.Size = UDim2.new(0, Theme.Ui.TrayWidth, Theme.Ui.TrayHeight, 0)
	frame.BackgroundColor3 = Theme.Colors.Tray
	frame.BorderSizePixel = 0
	frame.Active = true -- pressing it doesn't start a shot
	frame.Parent = gui
	roundCorners(frame)
	local list = Instance.new("UIListLayout")
	list.VerticalAlignment = Enum.VerticalAlignment.Bottom
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 2)
	list.Parent = frame
	local padding = Instance.new("UIPadding")
	padding.PaddingBottom = UDim.new(0, Theme.Ui.Padding / 2)
	padding.PaddingTop = padding.PaddingBottom
	padding.Parent = frame

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
				icon.Parent = frame
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

-- The gear bottom-left, and the panel it opens with the sound volume
local function settings(gui: ScreenGui)
	local gear = Instance.new("TextButton")
	gear.AnchorPoint = Vector2.new(0, 1)
	gear.Position = UDim2.new(0, Theme.Ui.Padding, 1, -Theme.Ui.Padding)
	gear.Size = UDim2.fromOffset(Theme.Ui.ButtonHeight, Theme.Ui.ButtonHeight)
	gear.BackgroundColor3 = Theme.Colors.HudPanel
	gear.BackgroundTransparency = Theme.Ui.HudTransparency
	gear.Font = Theme.Font
	gear.TextSize = Theme.Ui.PercentTextSize
	gear.TextColor3 = Theme.Colors.HudText
	gear.Text = "⚙"
	gear.Parent = gui
	roundCorners(gear, UDim.new(0.5, 0))

	-- Opens beside the gear, clear of the power meter's readout above it
	local box = panel(gui)
	box.AnchorPoint = Vector2.new(0, 1)
	box.Position = UDim2.new(0, Theme.Ui.ButtonHeight + 2 * Theme.Ui.Padding, 1, -Theme.Ui.Padding)
	box.Size = UDim2.fromOffset(Theme.Ui.PanelWidth, Theme.Ui.ButtonHeight + Theme.Ui.Padding)
	box.BackgroundTransparency = 0 -- solid, since it covers the Test button
	box.Active = true
	box.Visible = false
	local text = label("", box)
	text.Position = UDim2.fromOffset(Theme.Ui.Padding, 0)
	text.Size = UDim2.new(1, -2 * Theme.Ui.Padding, 0.5, 0)
	text.TextXAlignment = Enum.TextXAlignment.Left
	local bar = Instance.new("Frame")
	bar.AnchorPoint = Vector2.new(0, 0.5)
	bar.Position = UDim2.new(0, Theme.Ui.Padding, 0.72, 0)
	bar.Size = UDim2.new(1, -2 * Theme.Ui.Padding, 0, Theme.Ui.SliderBar)
	bar.BackgroundColor3 = Theme.Colors.Track
	bar.BorderSizePixel = 0
	bar.Parent = box
	local fill = Instance.new("Frame")
	fill.BackgroundColor3 = Theme.Colors.Fill
	fill.BorderSizePixel = 0
	fill.Parent = bar

	local function setVolume(share: number)
		TableView.setVolume(share)
		fill.Size = UDim2.fromScale(share, 1)
		text.Text = `Sound volume   {math.round(share * 100)}%`
	end
	setVolume(1)

	-- Drag anywhere on the panel to set the volume, by mouse or finger
	local dragging: InputObject? = nil
	local function moveTo(x: number)
		setVolume(math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1))
	end
	box.InputBegan:Connect(function(input: InputObject)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = input
			moveTo(input.Position.X)
		end
	end)
	UserInputService.InputChanged:Connect(function(input: InputObject)
		if
			dragging
			and (
				input == dragging
				or (
					input.UserInputType == Enum.UserInputType.MouseMovement
					and dragging.UserInputType == Enum.UserInputType.MouseButton1
				)
			)
		then
			moveTo(input.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(input: InputObject)
		if input == dragging then
			dragging = nil
		end
	end)

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

	-- Waits for the table's balls, so it goes last
	tray(gui, tableModel)
end

return Hud
