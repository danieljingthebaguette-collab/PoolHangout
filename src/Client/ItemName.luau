--!strict
-- An item's name shown big in the middle of the screen as it's used, with its icon, on a dark box: it pops in, holds,
-- and fades out, all within Theme.Ui.ItemNameSeconds, and a newer one replaces it. Its own screen, shown in either view.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Items = require(ReplicatedStorage.Shared.Items)
local Theme = require(ReplicatedStorage.Shared.Theme)
local Card = require(script.Parent.Card)
local ItemIcons = require(script.Parent.ItemIcons)
local Ui = require(script.Parent.Ui)

local ItemName = {}

-- The box, faded as a whole, its pop, its icon and its text, once they're built; how many names it has shown, so an
-- older name's timer leaves a newer one up; and the fade playing
local shown: { group: CanvasGroup, pop: UIScale, icon: Frame, text: TextLabel }? = nil
local namesShown = 0
local fading: Tween? = nil

-- Builds the screen, with the box hidden
function ItemName.build(playerGui: Instance)
	local ui = Theme.Ui
	local gui = Instance.new("ScreenGui")
	gui.Name = "ItemName"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true -- the screen's true middle
	gui.DisplayOrder = 1 -- over the HUD, under the Leave question and the end screen
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling -- the CanvasGroup only fades what's in it with Sibling ordering
	local group = Instance.new("CanvasGroup")
	group.AnchorPoint = Vector2.new(0.5, 0.5)
	group.Position = UDim2.fromScale(0.5, 0.5)
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
	-- The icon and the name side by side, in a frame of their own, clear of the box's brackets
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
	local text = Ui.label("", row)
	text.LayoutOrder = 1
	text.Size = UDim2.fromScale(0, 1)
	text.AutomaticSize = Enum.AutomaticSize.X
	text.TextSize = ui.ItemNameTextSize
	text.TextColor3 = Theme.Colors.DarkText
	gui.Parent = playerGui
	shown = { group = group, pop = pop, icon = icon, text = text }
end

-- Shows `item`'s name and icon, replacing any name still up
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
	shown.text.Text = (Items.NAMES :: { [string]: string })[item] or item
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
