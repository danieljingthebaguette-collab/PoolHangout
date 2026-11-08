--!strict
-- Item effects on the table, on every screen and every table, from the server's ItemsChanged: an icy ring and tint on
-- each frozen ball, a dark glossy patch on the felt for each oil slick, and a gold lid across each blocked pocket's
-- mouth. Placeholder looks until Phase 4 (docs/STYLE.md), in Theme.ItemEffects. Each message lists everything on now:
-- new effects are built once, gone ones destroyed, the rest left as they are.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Geometry = require(ReplicatedStorage.Shared.Physics.Geometry)
local PhysicsTestAccess = require(ReplicatedStorage.Shared.PhysicsTestAccess)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local TableSpace = require(ReplicatedStorage.Shared.TableSpace)
local Theme = require(ReplicatedStorage.Shared.Theme)
local Effects = require(script.Parent.Effects)

-- What ItemsChanged says is on a table: nil when no game is on
export type Shown = {
	blast: boolean?,
	frozen: { number }?,
	blocked: { number }?,
	oil: { { x: number, y: number } }?,
}

local ItemEffects = {}

local look = Theme.ItemEffects
-- Canvas pixels a ball radius, so the rings' and the patch's edges are sharp from any view
local PIXELS = 50

-- What each table draws now, by key like "frozen3", "lid2" or "oil2.000,1.000": one instance each, destroyed when it goes
local drawn: { [Model]: { [string]: Instance } } = {}

local function newPart(color: Color3, size: Vector3, cframe: CFrame, parent: Instance): Part
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Material = Enum.Material.SmoothPlastic
	part.Color = color
	part.Size = size
	part.CFrame = cframe
	part.Parent = parent
	return part
end

local function round(frame: GuiObject)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = frame
end

-- An icy ring on the felt round ball `id`, following its part, and an icy tint and outline on the ball. Nil while the
-- part hasn't streamed in; the next message tries again.
local function freeze(tableModel: Model, felt: BasePart, folder: Folder, id: number): Instance?
	local balls = tableModel:FindFirstChild("Balls")
	local ball = balls and balls:FindFirstChild("Ball" .. id)
	if not (ball and ball:IsA("BasePart")) then
		return nil
	end
	local r = ball.Size.X / 2
	local line = look.FrozenThickness * r
	-- The part is the ring's inside, since the stroke draws outside it
	local inside = look.FrozenDiameter * r - 2 * line
	local ring = newPart(look.Frozen, Vector3.new(inside, 0.001, inside), felt.CFrame, folder)
	local stroke = Effects.ringOn(ring, PIXELS / r, look.FrozenThickness * PIXELS, 0)
	local glow = Instance.new("Highlight")
	glow.Adornee = ball
	glow.DepthMode = Enum.HighlightDepthMode.Occluded
	glow.FillColor = look.Frozen
	glow.FillTransparency = look.FrozenFill
	glow.OutlineColor = look.Frozen
	glow.Parent = ring
	local function follow()
		local x, y = TableSpace.toTable(felt, ball.Position)
		ring.CFrame = TableSpace.toWorld(felt, x, y, look.FrozenHeight * r)
		stroke.Enabled = ball.Transparency ~= 1
		glow.Enabled = stroke.Enabled
	end
	follow()
	local moved = ball:GetPropertyChangedSignal("CFrame"):Connect(follow)
	local shown = ball:GetPropertyChangedSignal("Transparency"):Connect(follow)
	ring.Destroying:Once(function()
		moved:Disconnect()
		shown:Disconnect()
	end)
	return ring
end

-- A dark, see-through round patch on the felt at (x, y), edged in cream with a soft gloss
local function oil(felt: BasePart, folder: Folder, r: number, x: number, y: number): Instance
	local across = 2 * Config.Items.OilRadius * r
	local patch = newPart(
		look.Oil,
		Vector3.new(across, 0.001, across),
		TableSpace.toWorld(felt, x, y, look.OilHeight * r),
		folder
	)
	patch.Transparency = 1
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Top
	gui.LightInfluence = 0
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = PIXELS / r
	-- Inset by the edge, which the stroke draws outside it, so the whole patch is OilRadius across
	local edge = look.OilEdgeThickness * PIXELS
	local puddle = Instance.new("Frame")
	puddle.AnchorPoint = Vector2.new(0.5, 0.5)
	puddle.Position = UDim2.fromScale(0.5, 0.5)
	puddle.Size = UDim2.new(1, -2 * edge, 1, -2 * edge)
	puddle.BackgroundColor3 = look.Oil
	puddle.BackgroundTransparency = look.OilTransparency
	puddle.BorderSizePixel = 0
	round(puddle)
	local stroke = Instance.new("UIStroke")
	stroke.Color = look.OilEdge
	stroke.Thickness = edge
	stroke.Transparency = look.OilEdgeTransparency
	stroke.Parent = puddle
	local shine = Instance.new("Frame")
	shine.AnchorPoint = Vector2.new(0.5, 0.5)
	shine.Position = UDim2.fromScale(0.34, 0.3)
	shine.Size = UDim2.fromScale(0.36, 0.12)
	shine.Rotation = -35
	shine.BackgroundColor3 = look.OilShine
	shine.BackgroundTransparency = look.OilShineTransparency
	shine.BorderSizePixel = 0
	round(shine)
	shine.Parent = puddle
	puddle.Parent = gui
	gui.Parent = patch
	return patch
end

-- A gold slab across pocket `index`'s mouth, from jaw to jaw and back into the pocket, under the cushions' tops so they
-- trim it to the opening, with a thin ink edge on the felt side
local function lid(felt: BasePart, folder: Folder, tableParams: Geometry.TableParams, index: number): Instance
	local jaws = Geometry.lid(tableParams, index)
	local r = tableParams.BallRadius
	local dx, dy = jaws.bx - jaws.ax, jaws.by - jaws.ay
	local width = math.sqrt(dx * dx + dy * dy)
	local midX, midY = (jaws.ax + jaws.bx) / 2, (jaws.ay + jaws.by) / 2
	-- Across the mouth, pointing out of the table into the pocket
	local nx, ny = dy / width, -dx / width
	if nx * midX + ny * midY < 0 then
		nx, ny = -nx, -ny
	end
	local depth = look.LidDepth * width
	local height = look.LidTop * r
	local edge = look.LidEdge * r
	-- Its X axis along the jaws, Z across them. A turn about Y by θ takes the part's X axis to (cos θ, 0, -sin θ).
	local cframe = TableSpace.toWorld(felt, midX + nx * depth / 2, midY + ny * depth / 2, height / 2)
		* CFrame.Angles(0, math.atan2(-dy, dx), 0)
	local slab = newPart(look.Lid, Vector3.new(width, height, depth), cframe, folder)
	-- An edge lower and an edge wider each side, so from above it shows only as a line along the mouth
	newPart(look.LidEdgeColor, Vector3.new(width, height, depth + 2 * edge), cframe * CFrame.new(0, -edge, 0), slab)
	return slab
end

-- Draws a table's item effects from an ItemsChanged message: `shown` nil clears them all
function ItemEffects.show(tableModel: Model, shown: Shown?)
	local now: { [string]: Instance } = drawn[tableModel] or {}
	drawn[tableModel] = now
	local builds: { [string]: () -> Instance? } = {}
	local felt = tableModel:FindFirstChild("Felt")
	if shown and felt and felt:IsA("BasePart") then
		local folder = tableModel:FindFirstChild("ItemEffects") :: Folder?
		if not folder then
			local newFolder = Instance.new("Folder")
			newFolder.Name = "ItemEffects"
			newFolder.Parent = tableModel
			folder = newFolder
		end
		local into = folder :: Folder
		-- The table the shots use, sliders and all, as the server's lids and patches do
		local tableParams = PhysicsTestAccess.params().Table
		for _, id in (shown.frozen or {}) :: { number } do
			builds["frozen" .. id] = function()
				return freeze(tableModel, felt, into, id)
			end
		end
		for _, spot in (shown.oil or {}) :: { { x: number, y: number } } do
			builds[string.format("oil%.3f,%.3f", spot.x, spot.y)] = function()
				return oil(felt, into, tableParams.BallRadius, spot.x, spot.y)
			end
		end
		for _, index in (shown.blocked or {}) :: { number } do
			builds["lid" .. index] = function()
				return lid(felt, into, tableParams, index)
			end
		end
	end
	for key, instance in now do
		if not builds[key] then
			instance:Destroy()
			now[key] = nil
		end
	end
	for key, build in builds do
		if not now[key] then
			-- Nil while a ball hasn't streamed in; the next message tries again
			local instance = build()
			if instance then
				now[key] = instance
			end
		end
	end
end

function ItemEffects.start()
	Remotes.ItemsChanged.OnClientEvent:Connect(function(tableModel: Model?, _bars: any, _pops: any, shown: Shown?)
		if tableModel then
			ItemEffects.show(tableModel, shown)
		end
	end)
end

return ItemEffects
