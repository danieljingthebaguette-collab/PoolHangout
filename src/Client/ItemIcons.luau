--!strict
-- Each item's icon, drawn in code from rounded and turned frames, so it needs no image. Every size is a share of the
-- square it fills, so one drawing works from the top bar's small slots up to the big item name. Drawn for the dark
-- slots; colors in Theme.ItemIcons.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(ReplicatedStorage.Shared.Theme)

local ItemIcons = {}

local NAME = "ItemIcon"

-- One shape, centered at (x, y) and `w` by `h`, all shares of the icon's square, turned `rotation` degrees clockwise.
-- `round` makes a circle or a pill. Shapes draw in the order they're made, so an edge goes first and its fill over it.
local function shape(
	root: Frame,
	color: Color3,
	x: number,
	y: number,
	w: number,
	h: number,
	rotation: number,
	round: boolean
)
	local part = Instance.new("Frame")
	part.AnchorPoint = Vector2.new(0.5, 0.5)
	part.Position = UDim2.fromScale(x, y)
	part.Size = UDim2.fromScale(w, h)
	part.Rotation = rotation
	part.BackgroundColor3 = color
	part.BorderSizePixel = 0
	part.ZIndex = root.ZIndex
	if round then
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.5, 0)
		corner.Parent = part
	end
	part.Parent = root
end

-- A drop with its point `tilt` degrees clockwise from straight up: a circle `d` across centered at (x, y), and a diamond
-- whose bottom corner sits at the circle's center, so its sides leave the circle as tangents. `grow` widens it all
-- round, for an edge drawn under it.
local function drop(root: Frame, color: Color3, x: number, y: number, d: number, tilt: number, grow: number)
	shape(root, color, x, y, d + 2 * grow, d + 2 * grow, 0, true)
	local turn, reach, side = math.rad(tilt), d * math.sqrt(2) / 4, d / 2 + 2 * grow
	shape(root, color, x + reach * math.sin(turn), y - reach * math.cos(turn), side, side, 45 + tilt, false)
end

local DRAWINGS: { [string]: (Frame) -> () } = {
	-- An orange flame with a gold heart and a cream core, and a lick of flame each side
	powerShot = function(root: Frame)
		local c = Theme.ItemIcons
		drop(root, c.Flame, 0.3, 0.66, 0.26, -30, 0)
		drop(root, c.Flame, 0.7, 0.66, 0.26, 30, 0)
		drop(root, c.Flame, 0.5, 0.56, 0.6, 0, 0)
		drop(root, c.FlameHeart, 0.5, 0.67, 0.34, 0, 0)
		shape(root, c.FlameCore, 0.5, 0.73, 0.14, 0.14, 0, true)
	end,
	-- An eight-point gold burst, an orange one turned inside it, and a cream core: two squares turned 45° make each
	blastBall = function(root: Frame)
		local c = Theme.ItemIcons
		for _, turn in { 0, 45 } do
			shape(root, c.Burst, 0.5, 0.5, 0.62, 0.62, turn, false)
		end
		for _, turn in { 22.5, 67.5 } do
			shape(root, c.BurstInner, 0.5, 0.5, 0.4, 0.4, turn, false)
		end
		shape(root, c.BurstCore, 0.5, 0.5, 0.2, 0.2, 0, true)
	end,
	-- A six-armed icy snowflake, a V of twigs on each arm, with a cream heart
	freeze = function(root: Frame)
		local c = Theme.ItemIcons
		for k = 0, 2 do
			shape(root, c.Ice, 0.5, 0.5, 0.84, 0.11, 30 + 60 * k, true)
		end
		for k = 0, 5 do
			local arm = math.rad(60 * k)
			local baseX, baseY = 0.5 + 0.24 * math.sin(arm), 0.5 - 0.24 * math.cos(arm)
			for _, side in { -45, 45 } do
				local twig = 60 * k + side
				local turn = math.rad(twig)
				shape(
					root,
					c.Ice,
					baseX + 0.085 * math.sin(turn),
					baseY - 0.085 * math.cos(turn),
					0.17,
					0.085,
					twig - 90,
					true
				)
			end
		end
		shape(root, c.IceCore, 0.5, 0.5, 0.16, 0.16, 0, true)
	end,
	-- A dark drop over a flat puddle, apart so the two never read as one lump, both edged in cream, with a cream gloss
	-- on each
	oilSlick = function(root: Frame)
		local c = Theme.ItemIcons
		local e = c.Edge
		shape(root, c.OilEdge, 0.5, 0.8, 0.84 + 2 * e, 0.14 + 2 * e, 0, true)
		drop(root, c.OilEdge, 0.5, 0.38, 0.36, 0, e)
		shape(root, c.Oil, 0.5, 0.8, 0.84, 0.14, 0, true)
		drop(root, c.Oil, 0.5, 0.38, 0.36, 0, 0)
		shape(root, c.OilShine, 0.43, 0.41, 0.09, 0.09, 0, true)
		shape(root, c.OilShine, 0.3, 0.79, 0.16, 0.05, 0, true)
	end,
	-- A black pocket in a painted-wood rim, with a gold lid across it
	pocketBlock = function(root: Frame)
		local c = Theme.ItemIcons
		local e = c.Edge
		shape(root, c.PocketRim, 0.5, 0.5, 0.84, 0.84, 0, true)
		shape(root, c.PocketHole, 0.5, 0.5, 0.62, 0.62, 0, true)
		shape(root, c.LidEdge, 0.5, 0.5, 0.92 + 2 * e, 0.2 + 2 * e, -35, true)
		shape(root, c.Lid, 0.5, 0.5, 0.92, 0.2, -35, true)
	end,
}

-- Fills `parent`, a square of any size, with `item`'s icon, replacing any icon drawn there before. An item it doesn't
-- know, like "", leaves it empty. Drawing the icon that's already there does nothing, so it's cheap to call again.
function ItemIcons.draw(item: string, parent: GuiObject)
	local old = parent:FindFirstChild(NAME)
	if old and old:GetAttribute("Item") == item then
		return
	elseif old then
		old:Destroy()
	end
	local drawing = DRAWINGS[item]
	if not drawing then
		return
	end
	local root = Instance.new("Frame")
	root.Name = NAME
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundTransparency = 1
	root.ZIndex = parent.ZIndex
	root:SetAttribute("Item", item)
	drawing(root)
	root.Parent = parent
end

return ItemIcons
