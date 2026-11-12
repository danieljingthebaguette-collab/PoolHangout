--!strict
-- The aim indicator, like 8 Ball Duels: a line from the cue ball to a circle where it first touches something, a dot at
-- the circle's center, a white line where the cue ball goes after a hit and a yellow line where the hit ball goes. Also
-- the faint ring round the cue ball while it follows the mouse with ball in hand, the gold ring round the pocket
-- called for the 8, and with Blast Ball on, a ring round the ball the cue ball will hit, as far as the blast reaches. Only this screen sees them. They're drawn on the screen over the fixed top-down view: 3D line
-- adornments came out broken up and hidden behind balls, and a hollow cylinder shows nothing from straight above.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Geometry = require(ReplicatedStorage.Shared.Physics.Geometry)
local PhysicsTestAccess = require(ReplicatedStorage.Shared.PhysicsTestAccess)
local Preview = require(ReplicatedStorage.Shared.Physics.Preview)
local Simulate = require(ReplicatedStorage.Shared.Physics.Simulate)
local TableSpace = require(ReplicatedStorage.Shared.TableSpace)
local Theme = require(ReplicatedStorage.Shared.Theme)
local Ui = require(script.Parent.Ui)

local CIRCLE = UDim.new(0.5, 0)

local AimIndicator = {}

export type Indicator = {
	hide: () -> (),
	-- See-through while aiming or about to cancel, solid while the aim is locked
	fade: (faint: boolean) -> (),
	-- Draws the indicator for an aim from the cue ball at (x, y), over the balls this screen shows, with the items on
	-- the table: frozen balls and lids stop it, and Blast Ball shows its reach. Returns the pocket the 8's yellow line
	-- points at when the aim is on the 8.
	draw: (cueX: number, cueY: number, aim: number, balls: { Preview.Ball }, effects: Simulate.Effects?) -> number?,
	showPocketRing: (pocket: number) -> (),
	showPlaceRing: (cueX: number, cueY: number) -> (),
	-- While an item waits for its target: a ring of `across` ball radii round (x, y), in the item's color, showing
	-- what a click would pick
	showPickRing: (x: number, y: number, across: number, color: Color3) -> (),
	destroy: () -> (),
}

-- Builds the indicator's screen, hidden. `ballParts` are the table's balls by id.
function AimIndicator.new(playerGui: Instance, felt: BasePart, ballParts: { [number]: BasePart }): Indicator
	local radius = Config.Table.BallRadius
	local indicatorGui = Instance.new("ScreenGui")
	indicatorGui.Name = "AimIndicator"
	indicatorGui.ResetOnSpawn = false
	indicatorGui.IgnoreGuiInset = true -- so the camera's viewport points place it directly
	-- Every part gets a thin dark edge, so the lines read over white and yellow balls. The edges fade with the
	-- indicator, so it keeps them all.
	local outlines: { UIStroke } = {}
	local function outline(item: GuiObject, thickness: number): UIStroke
		local stroke = Instance.new("UIStroke")
		stroke.Color = Theme.Colors.AimOutline
		stroke.Thickness = thickness
		stroke.Parent = item
		table.insert(outlines, stroke)
		return stroke
	end
	local function indicatorLine(color: Color3): Frame
		local line = Instance.new("Frame")
		line.AnchorPoint = Vector2.new(0.5, 0.5)
		line.BackgroundColor3 = color
		line.BorderSizePixel = 0
		line.Visible = false
		line.Parent = indicatorGui
		outline(line, Theme.Ui.AimOutline)
		return line
	end
	-- The line to the circle, the cue ball's line after the hit, and the hit ball's yellow line
	local pathLine = indicatorLine(Theme.Colors.AimLine)
	local cueLine = indicatorLine(Theme.Colors.AimLine)
	local targetLine = indicatorLine(Theme.Colors.TargetLine)
	-- The circle's dark edge: a thicker dark ring just inside the white one and drawn under it, so a dark line shows
	-- on both sides of the white
	local ghostEdge = Instance.new("Frame")
	ghostEdge.AnchorPoint = Vector2.new(0.5, 0.5)
	ghostEdge.BackgroundTransparency = 1
	ghostEdge.Visible = false
	ghostEdge.Parent = indicatorGui
	Ui.roundCorners(ghostEdge, CIRCLE)
	outline(ghostEdge, Theme.Ui.AimLineThickness + 2 * Theme.Ui.AimOutline)
	-- A ball-sized ring where the cue ball will be when it first touches something
	local ghost = Instance.new("Frame")
	ghost.AnchorPoint = Vector2.new(0.5, 0.5)
	ghost.BackgroundTransparency = 1
	ghost.Visible = false
	ghost.Parent = indicatorGui
	Ui.roundCorners(ghost, CIRCLE)
	local ghostOutline = Instance.new("UIStroke")
	ghostOutline.Color = Theme.Colors.AimLine
	ghostOutline.Thickness = Theme.Ui.AimLineThickness
	ghostOutline.Parent = ghost
	-- A small dot at the circle's center, where the line ends and the cue ball's line starts
	local dot = Instance.new("Frame")
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.Size = UDim2.fromOffset(Theme.Ui.AimDotSize, Theme.Ui.AimDotSize)
	dot.BackgroundColor3 = Theme.Colors.AimLine
	dot.BorderSizePixel = 0
	dot.Visible = false
	dot.Parent = indicatorGui
	Ui.roundCorners(dot, CIRCLE)
	outline(dot, Theme.Ui.AimOutline)
	-- A faint ring around the cue ball while it follows the mouse with ball in hand
	local placeRing = Instance.new("Frame")
	placeRing.AnchorPoint = Vector2.new(0.5, 0.5)
	placeRing.BackgroundTransparency = 1
	placeRing.Visible = false
	placeRing.Parent = indicatorGui
	Ui.roundCorners(placeRing, CIRCLE)
	local placeRingStroke = Instance.new("UIStroke")
	placeRingStroke.Color = Theme.Colors.AimLine
	placeRingStroke.Thickness = Theme.Ui.AimLineThickness
	placeRingStroke.Transparency = Theme.Ui.AimFaintTransparency
	placeRingStroke.Parent = placeRing
	-- A gold ring round the pocket called for the 8
	local pocketRing = Instance.new("Frame")
	pocketRing.AnchorPoint = Vector2.new(0.5, 0.5)
	pocketRing.BackgroundTransparency = 1
	pocketRing.Visible = false
	pocketRing.Parent = indicatorGui
	Ui.roundCorners(pocketRing, CIRCLE)
	local pocketRingStroke = Instance.new("UIStroke")
	pocketRingStroke.Color = Theme.Colors.CalledPocket
	pocketRingStroke.Thickness = Theme.Ui.PocketRingThickness
	pocketRingStroke.Parent = pocketRing
	-- With Blast Ball on, the blast's reach round the ball the cue ball will hit
	local blastRing = Instance.new("Frame")
	blastRing.AnchorPoint = Vector2.new(0.5, 0.5)
	blastRing.BackgroundTransparency = 1
	blastRing.Visible = false
	blastRing.Parent = indicatorGui
	Ui.roundCorners(blastRing, CIRCLE)
	local blastRingStroke = Instance.new("UIStroke")
	blastRingStroke.Color = Theme.Colors.BlastRing
	blastRingStroke.Thickness = Theme.Ui.BlastRingThickness
	blastRingStroke.Parent = blastRing
	-- What a click would pick while an item waits for its target
	local pickRing = Instance.new("Frame")
	pickRing.AnchorPoint = Vector2.new(0.5, 0.5)
	pickRing.BackgroundTransparency = 1
	pickRing.Visible = false
	pickRing.Parent = indicatorGui
	Ui.roundCorners(pickRing, CIRCLE)
	local pickRingStroke = Instance.new("UIStroke")
	pickRingStroke.Thickness = Theme.Ui.PickRingThickness
	pickRingStroke.Parent = pickRing
	indicatorGui.Parent = playerGui

	-- Where a table-space point at ball-center height is on the screen
	local function toScreen(x: number, y: number): Vector2
		local point = workspace.CurrentCamera:WorldToViewportPoint(TableSpace.toWorld(felt, x, y, radius).Position)
		return Vector2.new(point.X, point.Y)
	end

	local function hide()
		placeRing.Visible = false
		pocketRing.Visible = false
		blastRing.Visible = false
		pickRing.Visible = false
		pathLine.Visible, cueLine.Visible, targetLine.Visible = false, false, false
		ghost.Visible, ghostEdge.Visible, dot.Visible = false, false, false
	end

	local function fade(faint: boolean)
		local transparency = if faint then Theme.Ui.AimFaintTransparency else 0
		for _, part in { pathLine, cueLine, targetLine, dot } do
			part.BackgroundTransparency = transparency
		end
		ghostOutline.Transparency = transparency
		for _, stroke in outlines do
			stroke.Transparency = transparency
		end
	end

	local function showLine(line: Frame, fromX: number, fromY: number, toX: number, toY: number)
		local from, to = toScreen(fromX, fromY), toScreen(toX, toY)
		local middle, along = (from + to) / 2, to - from
		line.Position = UDim2.fromOffset(middle.X, middle.Y)
		line.Size = UDim2.fromOffset(along.Magnitude, Theme.Ui.AimLineThickness)
		line.Rotation = math.deg(math.atan2(along.Y, along.X))
		line.Visible = true
	end

	local function draw(
		cueX: number,
		cueY: number,
		aim: number,
		balls: { Preview.Ball },
		effects: Simulate.Effects?
	): number?
		-- The hit uses the table and physics the shot will use, sliders and all
		local params = PhysicsTestAccess.params()
		local layout = Geometry.build(params.Table)
		local contact =
			Preview.firstContact(balls, math.cos(aim), math.sin(aim), params.Table, layout, params.Physics, effects)
		if Config.Aim.ShowAimLine then
			-- The line runs to the circle's center, which the dot marks
			showLine(pathLine, cueX, cueY, contact.x, contact.y)
			local middle = toScreen(contact.x, contact.y)
			local diameter = 2 * (toScreen(contact.x + radius, contact.y) - middle).Magnitude
			ghost.Position = UDim2.fromOffset(middle.X, middle.Y)
			ghost.Size = UDim2.fromOffset(diameter, diameter)
			ghost.Visible = true
			local edgeDiameter = diameter - 2 * Theme.Ui.AimOutline
			ghostEdge.Position = ghost.Position
			ghostEdge.Size = UDim2.fromOffset(edgeDiameter, edgeDiameter)
			ghostEdge.Visible = true
			dot.Position = ghost.Position
			dot.Visible = true
		end
		local hit = contact.hit
		if not (contact.ball and hit) then
			return nil
		end
		local hitX, hitY = TableSpace.toTable(felt, ballParts[contact.ball].Position)
		if effects and effects.blast then
			local middle = toScreen(hitX, hitY)
			local diameter = 2 * (toScreen(hitX + Config.Items.BlastReach * radius, hitY) - middle).Magnitude
			blastRing.Position = UDim2.fromOffset(middle.X, middle.Y)
			blastRing.Size = UDim2.fromOffset(diameter, diameter)
			blastRing.Visible = true
		end
		local aimed = if contact.ball == 8
			then Preview.aimedPocket(layout, hitX, hitY, contact.pushX :: number, contact.pushY :: number)
			else nil
		-- Each line is its longest times the share of the speed its ball gets, but never shorter than the minimum
		local function length(share: number, longest: number): number
			return math.max(Config.Aim.LineMinLength, share * longest) * radius
		end
		if Config.Aim.ShowCueLine then
			local afterLength = length(hit.cueShare, Config.Aim.CueLineLength)
			showLine(
				cueLine,
				contact.x,
				contact.y,
				contact.x + hit.cueX * afterLength,
				contact.y + hit.cueY * afterLength
			)
		end
		if Config.Aim.ShowTargetLine then
			local ballLength = length(hit.ballShare, Config.Aim.TargetLineLength)
			showLine(
				targetLine,
				hitX,
				hitY,
				hitX + (contact.pushX :: number) * ballLength,
				hitY + (contact.pushY :: number) * ballLength
			)
		end
		return aimed
	end

	local function showPocketRing(index: number)
		local pocket = Geometry.build(PhysicsTestAccess.params().Table).pockets[index]
		local middle = toScreen(pocket.x, pocket.y)
		local diameter = 2 * (toScreen(pocket.x + Config.Aim.PocketPickRadius * radius, pocket.y) - middle).Magnitude
		pocketRing.Position = UDim2.fromOffset(middle.X, middle.Y)
		pocketRing.Size = UDim2.fromOffset(diameter, diameter)
		pocketRing.Visible = true
	end

	local function showPlaceRing(cueX: number, cueY: number)
		local middle = toScreen(cueX, cueY)
		local diameter = 2 * (toScreen(cueX + Config.Aim.PlaceRingRadius * radius, cueY) - middle).Magnitude
		placeRing.Position = UDim2.fromOffset(middle.X, middle.Y)
		placeRing.Size = UDim2.fromOffset(diameter, diameter)
		placeRing.Visible = true
	end

	local function showPickRing(x: number, y: number, across: number, color: Color3)
		local middle = toScreen(x, y)
		local diameter = 2 * (toScreen(x + across * radius, y) - middle).Magnitude
		pickRing.Position = UDim2.fromOffset(middle.X, middle.Y)
		pickRing.Size = UDim2.fromOffset(diameter, diameter)
		pickRingStroke.Color = color
		pickRing.Visible = true
	end

	return {
		hide = hide,
		fade = fade,
		draw = draw,
		showPocketRing = showPocketRing,
		showPlaceRing = showPlaceRing,
		showPickRing = showPickRing,
		destroy = function()
			indicatorGui:Destroy()
		end,
	}
end

return AimIndicator
