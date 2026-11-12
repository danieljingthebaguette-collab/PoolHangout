--!strict
-- An item's name shown big at the top center as it's used, just under the banner so the two never overlap: the name in
-- the display font with what the item does under it and its icon beside them, on a dark box. It pops in, holds, and
-- fades out, all within Theme.Ui.ItemNameSeconds, and a newer one replaces it. Its own screen, shown in either view.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Items = require(ReplicatedStorage.Shared.Items)
local Theme = require(ReplicatedStorage.Shared.Theme)
local Card = require(script.Parent.Card)
local ItemIcons = require(script.Parent.ItemIcons)
local TopBar = require(script.Parent.TopBar)
local Ui = require(script.Parent.Ui)
local UiScale = require(script.Parent.UiScale)

local ItemName = {}

-- The box, faded as a whole, its pop, its icon, name and line, once they're built; how many names it has shown, so an
-- older name's timer leaves a newer one up; and the fade playing
local shown: { group: CanvasGroup, pop: UIScale, icon: Frame, text: TextLabel, line: TextLabel }? = nil
local namesShown = 0
local fading: Tween? = nil

-- Builds the screen, with the box hidden
function ItemName.build(playerGui: Instance)
	local ui = Theme.Ui
	local gui = Instance.new("ScreenGui")
	gui.Name = "ItemName"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true -- so it lines up under the banner
	gui.DisplayOrder = 1 -- over the HUD, under the Leave question and the end screen
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling -- the CanvasGroup only fades what's in it with Sibling ordering
	local group = Instance.new("CanvasGroup")
	group.AnchorPoint = Vector2.new(0.5, 0.5) -- so it pops from its middle
	-- Under the banner, which sits under the top bar
	local function place()
		local s = UiScale.get()
		group.Position =
			UDim2.new(0.5, 0, 0, (TopBar.height() + ui.BannerHeight + ui.ItemNameHeight / 2) * s + 2 * ui.Padding)
	end
	place()
	UiScale.onChanged(place)
	group.Size = UDim2.fromOffset(0, ui.ItemNameHeight)
	group.AutomaticSize = Enum.AutomaticSize.X
	group.BackgroundTransparency = 1
	group.Visible = false
	group.Parent = gui
	local pop = Instance.new("UIScale")
	pop.Parent = group
	local box = Instance.new("Frame")
	box.Size = UDim2.fromScale(0, 1)
	box.AutomaticSize = Enum.AutomaticSize.X
	Card.style(box, true)
	box.Parent = group
	-- The icon beside the name and its line, in a frame of their own, clear of the box's brackets
	local row = Instance.new("Frame")
	row.Size = UDim2.fromScale(0, 1)
	row.AutomaticSize = Enum.AutomaticSize.X
	row.BackgroundTransparency = 1
	row.Parent = box
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, ui.Padding)
	layout.Parent = row
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 2 * ui.Padding)
	padding.PaddingRight = UDim.new(0, 3 * ui.Padding)
	padding.Parent = row
	local icon = Instance.new("Frame")
	icon.Size = UDim2.fromOffset(ui.ItemNameIconSize, ui.ItemNameIconSize)
	icon.BackgroundTransparency = 1
	icon.Parent = row
	local words = Instance.new("Frame")
	words.LayoutOrder = 1
	words.Size = UDim2.fromScale(0, 1)
	words.AutomaticSize = Enum.AutomaticSize.X
	words.BackgroundTransparency = 1
	words.Parent = row
	local stack = Instance.new("UIListLayout")
	stack.VerticalAlignment = Enum.VerticalAlignment.Center
	stack.SortOrder = Enum.SortOrder.LayoutOrder
	stack.Parent = words
	local function text(order: number, size: number): TextLabel
		local label = Ui.label("", words)
		label.LayoutOrder = order
		label.Size = UDim2.fromOffset(0, size)
		label.AutomaticSize = Enum.AutomaticSize.X
		label.TextSize = size
		label.TextColor3 = Theme.Colors.DarkText
		label.TextXAlignment = Enum.TextXAlignment.Left
		return label
	end
	local name = text(1, ui.ItemNameTextSize)
	name.FontFace = Theme.DisplayFont
	local line = text(2, ui.ItemNameLineTextSize)
	gui.Parent = playerGui
	shown = { group = group, pop = pop, icon = icon, text = name, line = line }
end

-- Shows `item`'s name, what it does and its icon, replacing any name still up
function ItemName.show(item: string)
	if not shown then
		return
	end
	local ui = Theme.Ui
	namesShown += 1
	local mine = namesShown
	if fading then
		fading:Cancel()
	end
	-- In capitals: Luckiest Guy draws lowercase letters as small caps with an odd "e"
	shown.text.Text = string.upper(Items.NAMES[item] or item)
	shown.line.Text = Items.LINES[item] or ""
	ItemIcons.draw(item, shown.icon)
	shown.group.GroupTransparency = 0
	shown.group.Visible = true
	shown.pop.Scale = ui.ItemNamePopScale
	TweenService:Create(
		shown.pop,
		TweenInfo.new(ui.ItemNamePopSeconds, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Scale = 1 }
	):Play()
	local group = shown.group
	task.delay(ui.ItemNameSeconds - ui.ItemNameFadeSeconds, function()
		if namesShown ~= mine then
			return
		end
		local fade = TweenService:Create(group, TweenInfo.new(ui.ItemNameFadeSeconds), { GroupTransparency = 1 })
		fade.Completed:Once(function(state: Enum.PlaybackState)
			if state == Enum.PlaybackState.Completed then
				group.Visible = false
			end
		end)
		fading = fade
		fade:Play()
	end)
end

return ItemName
