--!strict
-- Small builders the HUD and the shot controls share, in the look docs/STYLE.md describes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(ReplicatedStorage.Shared.Theme)

local Ui = {}

-- Rounds an item's corners, by Theme's corner size unless given another
function Ui.roundCorners(item: GuiObject, radius: UDim?)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = radius or UDim.new(0, Theme.Ui.Corner)
	corner.Parent = item
end

-- See-through text in Theme's font, size and ink
function Ui.label(text: string, parent: Instance): TextLabel
	local item = Instance.new("TextLabel")
	item.BackgroundTransparency = 1
	item.FontFace = Theme.Font
	item.TextSize = Theme.TextSize
	item.TextColor3 = Theme.Colors.Text
	item.Text = text
	item.Parent = parent
	return item
end

-- A bright button with ink text
function Ui.accentButton(text: string, color: Color3, parent: Instance): TextButton
	local button = Instance.new("TextButton")
	button.BackgroundColor3 = color
	button.FontFace = Theme.Font
	button.TextSize = Theme.TextSize
	button.TextColor3 = Theme.Colors.Text
	button.Text = text
	button.Parent = parent
	Ui.roundCorners(button)
	return button
end

-- A small ball for the tray and the cards: its color, or white with a band of color for a stripe
function Ui.ballIcon(id: number): Frame
	local icon = Instance.new("Frame")
	icon.Size = UDim2.fromScale(0.8, 1 / 15)
	icon.BorderSizePixel = 0
	Ui.roundCorners(icon, UDim.new(0.5, 0))
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

return Ui
