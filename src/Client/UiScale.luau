--!strict
-- The "UI scale" setting: one number the HUD is drawn at, from Config.Settings' range. `apply` gives every element of a
-- screen a UIScale, so each grows or shrinks toward the edge it's anchored to. Screens that size themselves to the
-- screen's height (ItemSlots, LobbyButtons) multiply by `get()` and listen with `onChanged`, as does anything placed
-- under the top bar.

local UiScale = {}

local scale = 1
-- Every UIScale `apply` made, so a change reaches them all
local scales: { UIScale } = {}
local listeners: { (number) -> () } = {}

function UiScale.get(): number
	return scale
end

-- Calls `listener` with the new scale whenever it changes
function UiScale.onChanged(listener: (number) -> ())
	table.insert(listeners, listener)
end

function UiScale.set(value: number)
	if value == scale then
		return
	end
	scale = value
	for i = #scales, 1, -1 do
		local each = scales[i]
		if each.Parent then
			each.Scale = value
		else
			table.remove(scales, i)
		end
	end
	for _, listener in listeners do
		task.spawn(listener, value)
	end
end

local function give(item: Instance)
	if item:IsA("GuiObject") and not item:FindFirstChildOfClass("UIScale") then
		local each = Instance.new("UIScale")
		each.Scale = scale
		each.Parent = item
		table.insert(scales, each)
	end
end

-- Scales every element of `gui`, those added later included
function UiScale.apply(gui: ScreenGui)
	for _, child in gui:GetChildren() do
		give(child)
	end
	gui.ChildAdded:Connect(give)
end

return UiScale
