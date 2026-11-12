--!strict
-- A mock shop, from Illegal Soccer's structure with our own items: the lobby's Shop button (C) opens it. Three tabs:
-- Daily Shop (a row of today's items, which leave at midnight UTC, and a bigger featured one), Bundles, and Passes.
-- Prices are in coins, and every buy button just says "Coming soon": nothing is for sale (GAME_SPEC).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(ReplicatedStorage.Shared.Theme)
local Panel = require(script.Parent.Panel)
local Ui = require(script.Parent.Ui)

local ShopPanel = {}

type Offer = { name: string, kind: string, price: number, was: number?, color: Color3 }

-- Example items, made up for the mock
local TODAY: { Offer } = {
	{ name = "Maple Classic", kind = "Cue", price = 250, color = Color3.fromRGB(196, 140, 84) },
	{ name = "Ember", kind = "Cue", price = 400, color = Color3.fromRGB(230, 96, 40) },
	{ name = "Pastel Set", kind = "Balls", price = 600, color = Color3.fromRGB(214, 175, 222) },
	{ name = "Royal Felt", kind = "Felt", price = 500, color = Color3.fromRGB(40, 80, 170) },
	{ name = "Gold Drop", kind = "Pocket effect", price = 900, color = Color3.fromRGB(248, 215, 52) },
}
local FEATURED: Offer = { name = "Glacier", kind = "Cue", price = 1200, color = Color3.fromRGB(150, 215, 255) }
local BUNDLES: { Offer } = {
	{
		name = "Lodge Starter: cue, ball set and felt",
		kind = "Bundle",
		price = 900,
		was = 1350,
		color = Color3.fromRGB(122, 70, 40),
	},
	{
		name = "Sunset Kit: cue, felt and pocket effect",
		kind = "Bundle",
		price = 1500,
		was = 2200,
		color = Color3.fromRGB(237, 120, 60),
	},
}
local PASSES: { Offer } = {
	{
		name = "Club Pass: a cue and a felt each month",
		kind = "Pass",
		price = 2000,
		color = Color3.fromRGB(56, 160, 120),
	},
	{ name = "Effects Pass: every pocket effect", kind = "Pass", price = 1800, color = Color3.fromRGB(51, 132, 250) },
}

local page: Panel.Panel? = nil

-- A coin price button that says "Coming soon" when pressed
local function buyButton(offer: Offer, parent: Instance): TextButton
	local text = if offer.was then `{offer.price} coins (was {offer.was})` else `{offer.price} coins`
	local button = Ui.accentButton(text, Theme.Colors.Button, parent)
	button.TextSize = Theme.Ui.ShopPriceTextSize
	button.Activated:Connect(function()
		button.Text = "Coming soon"
		task.delay(Theme.Ui.ShopSoonSeconds, function()
			button.Text = text
		end)
	end)
	return button
end

-- An item's card: a swatch of its color (an icon until real item art), its name and kind, and its price
local function card(offer: Offer, parent: Instance, order: number, width: number, height: number)
	local box = Instance.new("Frame")
	box.LayoutOrder = order
	box.Size = UDim2.fromOffset(width, height)
	box.BackgroundColor3 = Theme.Colors.Dark
	box.BorderSizePixel = 0
	box.Parent = parent
	local pad = Theme.Ui.Padding / 2
	local swatch = Instance.new("Frame")
	swatch.Position = UDim2.fromOffset(pad, pad)
	swatch.Size = UDim2.new(1, -2 * pad, 1, -(2 * pad + 2 * Theme.Ui.ShopLineHeight + Theme.Ui.ButtonHeight))
	swatch.BackgroundColor3 = offer.color
	swatch.BorderSizePixel = 0
	swatch.Parent = box
	for i, line in { offer.name, offer.kind } do
		local label = Ui.label(line, box)
		label.AnchorPoint = Vector2.new(0, 1)
		label.Position = UDim2.new(0, pad, 1, -(pad + Theme.Ui.ButtonHeight + (2 - i) * Theme.Ui.ShopLineHeight))
		label.Size = UDim2.new(1, -2 * pad, 0, Theme.Ui.ShopLineHeight)
		label.TextSize = if i == 1 then Theme.TextSize else Theme.Ui.ShopPriceTextSize
		label.TextColor3 = if i == 1 then Theme.Colors.DarkText else Theme.Colors.Track
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextTruncate = Enum.TextTruncate.AtEnd
	end
	local buy = buyButton(offer, box)
	buy.AnchorPoint = Vector2.new(0, 1)
	buy.Position = UDim2.new(0, pad, 1, -pad)
	buy.Size = UDim2.new(1, -2 * pad, 0, Theme.Ui.ButtonHeight - pad)
end

-- A row laid out left to right
local function row(parent: Instance, order: number, height: number): Frame
	local frame = Instance.new("Frame")
	frame.LayoutOrder = order
	frame.Size = UDim2.new(1, 0, 0, height)
	frame.BackgroundTransparency = 1
	frame.Parent = parent
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, Theme.Ui.Padding / 2)
	layout.Parent = frame
	return frame
end

local function heading(text: string, parent: Instance, order: number)
	local label = Ui.label(text, parent)
	label.LayoutOrder = order
	label.Size = UDim2.new(1, 0, 0, Theme.Ui.ShopLineHeight)
	label.TextXAlignment = Enum.TextXAlignment.Left
end

-- Time left until the daily items change, at midnight UTC
local function leavesIn(): string
	local left = 86400 - os.time() % 86400
	return `Leaves in {left // 3600}h {left % 3600 // 60}m`
end

-- Opens the shop, or closes it if it's open
function ShopPanel.toggle()
	if page then
		page.toggle()
	end
end

function ShopPanel.build(playerGui: Instance)
	local ui = Theme.Ui
	local made = Panel.new(playerGui, "Shop", "Shop", ui.ShopWidth)
	local inner = ui.ShopWidth - 4 * ui.Padding
	local tabs = row(made.content, 1, ui.ButtonHeight)
	local bodies: { Frame } = {}
	local buttons: { TextButton } = {}
	local function body(order: number): Frame
		local frame = Instance.new("Frame")
		frame.LayoutOrder = 2
		frame.Size = UDim2.fromScale(1, 0)
		frame.AutomaticSize = Enum.AutomaticSize.Y
		frame.BackgroundTransparency = 1
		frame.Visible = order == 1
		frame.Parent = made.content
		local layout = Instance.new("UIListLayout")
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Padding = UDim.new(0, ui.Padding / 2)
		layout.Parent = frame
		bodies[order] = frame
		return frame
	end
	local function showTab(order: number)
		for i, frame in bodies do
			frame.Visible = i == order
			buttons[i].BackgroundColor3 = if i == order then Theme.Colors.Button else Theme.Colors.Dark
			buttons[i].TextColor3 = if i == order then Theme.Colors.Text else Theme.Colors.DarkText
		end
	end
	for i, name in { "Daily Shop", "Bundles", "Passes" } do
		local tab = Ui.accentButton(name, Theme.Colors.Dark, tabs)
		tab.LayoutOrder = i
		tab.Size = UDim2.fromOffset(ui.ShopTabWidth, ui.ButtonHeight)
		tab.Activated:Connect(function()
			showTab(i)
		end)
		buttons[i] = tab
	end

	-- Daily Shop: today's row, then the featured item
	local daily = body(1)
	local today = Ui.label(`Today · {leavesIn()}`, daily)
	today.LayoutOrder = 1
	today.Size = UDim2.new(1, 0, 0, ui.ShopLineHeight)
	today.TextXAlignment = Enum.TextXAlignment.Left
	local cardWidth = (inner - 4 * ui.Padding / 2) / #TODAY
	local todayRow = row(daily, 2, ui.ShopCardHeight)
	for i, offer in TODAY do
		card(offer, todayRow, i, cardWidth, ui.ShopCardHeight)
	end
	heading("Featured", daily, 3)
	local featuredRow = row(daily, 4, ui.ShopFeaturedHeight)
	card(FEATURED, featuredRow, 1, inner, ui.ShopFeaturedHeight)

	-- Bundles and Passes: wider cards, two to a row
	for order, offers in { [2] = BUNDLES, [3] = PASSES } do
		local frame = body(order)
		local cards = row(frame, 1, ui.ShopCardHeight)
		for i, offer in offers do
			card(offer, cards, i, (inner - ui.Padding / 2) / 2, ui.ShopCardHeight)
		end
	end
	showTab(1)
	-- Fresh times each time it opens
	made.card:GetPropertyChangedSignal("Visible"):Connect(function()
		today.Text = `Today · {leavesIn()}`
	end)
	page = made
end

return ShopPanel
