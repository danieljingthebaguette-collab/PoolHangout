--!strict
-- The card look from docs/STYLE.md: a cream panel, or a dark box, with thin corner brackets and, on cream, a faint
-- dot texture. The HUD and the test panel use it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(ReplicatedStorage.Shared.Theme)

local Card = {}

-- Square pixels of card each dot of the texture is given. Generous, so the dots always reach the card's bottom.
local DOT_AREA = 50

local function brackets(frame: GuiObject, color: Color3)
	local length, thickness, inset = Theme.Ui.BracketLength, Theme.Ui.BracketThickness, Theme.Ui.BracketInset
	for _, corner in { Vector2.new(0, 0), Vector2.new(1, 0), Vector2.new(0, 1), Vector2.new(1, 1) } do
		-- Each corner's two arms: one along the top or bottom edge, one down the side
		for _, size in { Vector2.new(length, thickness), Vector2.new(thickness, length) } do
			local arm = Instance.new("Frame")
			arm.Name = "Bracket"
			arm.AnchorPoint = corner
			arm.Position = UDim2.new(corner.X, inset * (1 - 2 * corner.X), corner.Y, inset * (1 - 2 * corner.Y))
			arm.Size = UDim2.fromOffset(size.X, size.Y)
			arm.BackgroundColor3 = color
			arm.BorderSizePixel = 0
			arm.ZIndex = 2
			arm.Parent = frame
		end
	end
end

-- A faint grid of dots, drawn as text so it needs no image: a line of ". " in a monospaced font wraps into even
-- columns. A period, because RobotoMono has no "·" and the narrow fallback packs the dots together. The text runs
-- past the card's bottom, and the card cuts it off.
local function dots(frame: GuiObject)
	local texture = Instance.new("TextLabel")
	texture.Name = "Dots"
	texture.Size = UDim2.fromScale(1, 1)
	texture.BackgroundTransparency = 1
	texture.Font = Enum.Font.RobotoMono
	texture.TextSize = Theme.Ui.DotSize
	texture.TextColor3 = Theme.Colors.Text
	texture.TextTransparency = Theme.Ui.DotTransparency
	texture.TextWrapped = true
	texture.TextXAlignment = Enum.TextXAlignment.Left
	texture.TextYAlignment = Enum.TextYAlignment.Top
	-- Default ZIndex, and made before the card's contents, so it draws above the card but under everything on it
	-- (in a ScreenGui that orders by ZIndex across the whole screen, a lower one would hide it behind the card)
	texture.Parent = frame
	local function fill()
		local size = frame.AbsoluteSize
		texture.Text = string.rep(". ", math.ceil(size.X * size.Y / DOT_AREA))
	end
	frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(fill)
	fill()
	frame.ClipsDescendants = true
end

-- Dresses `frame` as a card: cream with dark brackets and dots, or with `dark`, a dark box with cream brackets.
-- The brackets and dots are its children, so put any layout in a child frame instead.
function Card.style(frame: GuiObject, dark: boolean?)
	frame.BackgroundColor3 = if dark then Theme.Colors.Dark else Theme.Colors.Panel
	frame.BorderSizePixel = 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, Theme.Ui.Corner)
	corner.Parent = frame
	brackets(frame, if dark then Theme.Colors.DarkText else Theme.Colors.Text)
	if not dark then
		dots(frame)
	end
end

return Card
