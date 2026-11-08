--!strict
-- The tray on the right of the top-down view, a dark box from below the top bar down to the control hints. Each object
-- ball joins it when its part is hidden (it dropped) and leaves when it's shown again (a rack). The first ball sunk sits
-- at the bottom.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(ReplicatedStorage.Shared.Theme)
local Card = require(script.Parent.Card)
local Hints = require(script.Parent.Hints)
local Ui = require(script.Parent.Ui)

local Tray = {}

-- Builds the tray in `gui` for a table's balls, waiting for them. Returns a function that takes it down again.
function Tray.build(gui: ScreenGui, tableModel: Model): () -> ()
	local top = Theme.Ui.CardHeight + 2 * Theme.Ui.Padding
	local box = Instance.new("Frame")
	box.AnchorPoint = Vector2.new(0.5, 0)
	box.Position = UDim2.new(1, -Theme.Ui.TrayReserve / 2, 0, top)
	box.Size = UDim2.new(0, Theme.Ui.TrayWidth, 1, -top - Hints.bottomBand())
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
	local connections: { RBXScriptConnection } = {}
	local balls = tableModel:WaitForChild("Balls")
	for id = 1, 15 do
		local part = balls:WaitForChild(`Ball{id}`) :: BasePart
		local function update()
			local down = part.Transparency == 1
			if down and not icons[id] then
				sunk += 1
				local icon = Ui.ballIcon(id)
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
		table.insert(connections, part:GetPropertyChangedSignal("Transparency"):Connect(update))
	end
	return function()
		for _, connection in connections do
			connection:Disconnect()
		end
		box:Destroy()
	end
end

return Tray
