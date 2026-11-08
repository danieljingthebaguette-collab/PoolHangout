--!strict
-- Effects on the table, in docs/STYLE.md's look, built in code and only on this screen. For now the hit effects:
-- small chunky ink-edged sparks where a ball hits another ball or a rail hard, bigger on the break, and a ring that
-- pops out of a pocket a ball drops into. Then the white pulse on your balls as your turn starts. Item effects and
-- screen shake come in the Items and polish phases. Every look and timing is Theme.Effects.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Geometry = require(ReplicatedStorage.Shared.Physics.Geometry)
local PhysicsTestAccess = require(ReplicatedStorage.Shared.PhysicsTestAccess)
local TableSpace = require(ReplicatedStorage.Shared.TableSpace)
local Theme = require(ReplicatedStorage.Shared.Theme)

local Effects = {}

local look = Theme.Effects
-- How far away, in ball radii, the other ball of a hit can be by the end of the frame: about one frame's travel at
-- break speed
local PARTNER_REACH = 7
local TINY = Vector3.new(0.001, 0.001, 0.001)

-- Effect parts alive now, kept under look.MaxParts
local live = 0
-- Which spark color comes next
local nextColor = 0

-- A bare anchored part for an effect, that nothing can touch or click, parented to the felt so it goes if the table
-- does. It destroys itself after `seconds`. Callers check look.MaxParts first.
local function newPart(felt: BasePart, seconds: number, color: Color3, size: Vector3, cframe: CFrame): Part
	live += 1
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
	part.Parent = felt
	task.delay(seconds, function()
		live -= 1
		part:Destroy()
	end)
	return part
end

-- `count` chunky sparks from (x, y) in table space, flying at an angle of sprayMin to sprayMax degrees either side of
-- the direction (ax, ay). `big` is the break's bigger, farther-flying look. Each spark sits on a slightly bigger ink
-- block, its outline.
local function sparks(
	felt: BasePart,
	r: number,
	x: number,
	y: number,
	ax: number,
	ay: number,
	count: number,
	big: boolean,
	sprayMin: number,
	sprayMax: number
)
	local length = (if big then look.SparkBreakLength else look.SparkLength) * r
	local thickness = (if big then look.SparkBreakThickness else look.SparkThickness) * r
	local reach = (if big then look.SparkBreakReach else look.SparkReach) * r
	local edge = look.SparkOutline * r
	local size = Vector3.new(length, thickness, thickness)
	local outlineSize = size + Vector3.new(2 * edge, 0, 2 * edge)
	-- The outline sits an edge lower, so from above it shows only round the spark
	local under = CFrame.new(0, -edge, 0)
	local base = math.atan2(ay, ax)
	local info = TweenInfo.new(look.SparkSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local shrink = TweenInfo.new(look.SparkSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	for i = 1, count do
		if live + 2 > look.MaxParts then
			return
		end
		-- Alternate sides, so even three sparks spray both ways
		local side = if i % 2 == 0 then 1 else -1
		local angle = base + side * math.rad(sprayMin + (sprayMax - sprayMin) * math.random())
		local dx, dy = math.cos(angle), math.sin(angle)
		local far = reach * (0.75 + 0.25 * math.random())
		-- Long along its path. A turn about Y by θ takes the part's X axis to (cos θ, 0, -sin θ).
		local turn = CFrame.Angles(0, math.atan2(-dy, dx), 0)
		local start = TableSpace.toWorld(felt, x, y, look.SparkHeight * r) * turn
		local finish = TableSpace.toWorld(felt, x + dx * far, y + dy * far, (look.SparkHeight + look.SparkRise) * r)
			* turn
		nextColor = nextColor % #look.SparkColors + 1
		local outline = newPart(felt, look.SparkSeconds, look.SparkOutlineColor, outlineSize, start * under)
		local spark = newPart(felt, look.SparkSeconds, look.SparkColors[nextColor], size, start)
		TweenService:Create(outline, info, { CFrame = finish * under }):Play()
		TweenService:Create(outline, shrink, { Size = TINY }):Play()
		TweenService:Create(spark, info, { CFrame = finish }):Play()
		TweenService:Create(spark, shrink, { Size = TINY }):Play()
	end
end

-- A flat cream ring round the pocket nearest (x, y) in table space, that grows and thins as it fades
local function pop(felt: BasePart, r: number, x: number, y: number)
	if live >= look.MaxParts then
		return
	end
	-- The pockets of the table the shot used, sliders and all
	local pocket: Geometry.Pocket? = nil
	local nearest = math.huge
	for _, each in Geometry.build(PhysicsTestAccess.params().Table).pockets do
		local distSq = (each.x - x) ^ 2 + (each.y - y) ^ 2
		if distSq < nearest then
			pocket, nearest = each, distSq
		end
	end
	if not pocket then
		return
	end
	local mouth = 2 * pocket.radius
	local start = look.PopStartScale * mouth
	local finish = look.PopEndScale * mouth
	local cframe = TableSpace.toWorld(felt, pocket.x, pocket.y, look.PopHeight * r)
	local part = newPart(felt, look.PopSeconds, look.PopColor, Vector3.new(start, 0.001, start), cframe)
	part.Transparency = 1
	-- Canvas pixels the size of screen pixels here, so the line's width is in screen pixels from any view
	local camera = workspace.CurrentCamera
	local a = camera:WorldToViewportPoint(cframe.Position)
	local b = camera:WorldToViewportPoint(cframe.Position + camera.CFrame.RightVector)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Top
	gui.LightInfluence = 0
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = math.max(Vector2.new(b.X - a.X, b.Y - a.Y).Magnitude, 1)
	local ring = Instance.new("Frame")
	ring.Size = UDim2.fromScale(1, 1)
	ring.BackgroundTransparency = 1
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = ring
	local stroke = Instance.new("UIStroke")
	stroke.Color = look.PopColor
	stroke.Thickness = look.PopLineStart
	stroke.Transparency = look.PopTransparency
	stroke.Parent = ring
	ring.Parent = gui
	gui.Parent = part
	-- Fast out of the gate and fading from the first frame, so it never holds still at full strength
	TweenService:Create(
		part,
		TweenInfo.new(look.PopSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = Vector3.new(finish, 0.001, finish) }
	):Play()
	TweenService:Create(
		stroke,
		TweenInfo.new(look.PopSeconds, Enum.EasingStyle.Linear),
		{ Thickness = look.PopLineEnd, Transparency = 1 }
	):Play()
end

local function show(kind: string, part: BasePart, felt: BasePart, share: number)
	if not (part.Parent and felt.Parent) then
		return
	end
	local r = part.Size.X / 2
	local x, y = TableSpace.toTable(felt, part.Position)
	if kind == "pocket" then
		pop(felt, r, x, y)
		return
	end
	if share < look.SparkShare then
		return
	end
	-- Only the break, at Config.Physics.BreakPower, hits harder than full power
	local big = share > 1
	local count = if big
		then look.SparkBreakCount
		else math.round(
			look.SparkMinCount
				+ (look.SparkMaxCount - look.SparkMinCount) * (share - look.SparkShare) / (1 - look.SparkShare)
		)
	if kind == "rail" then
		count = math.max(count, look.SparkRailMinCount)
		-- The nearest cushion: an end rail if the ball is closer to the felt's end than its side
		local halfLength, halfWidth = felt.Size.X / 2, felt.Size.Z / 2
		if halfLength - math.abs(x) < halfWidth - math.abs(y) then
			local sign = math.sign(x)
			sparks(felt, r, sign * halfLength, y, -sign, 0, count, big, look.RailSprayMin, look.RailSprayMax)
		else
			local sign = math.sign(y)
			sparks(felt, r, x, sign * halfWidth, 0, -sign, count, big, look.RailSprayMin, look.RailSprayMax)
		end
		return
	end
	-- From where the two balls touch: the point on this ball's edge facing the nearest other ball. By the end of the
	-- frame they've parted, but along the line between them, so that point is still about where they met.
	local otherX, otherY, nearest = 0, 0, (PARTNER_REACH * r) ^ 2
	for _, other in (part.Parent :: Instance):GetChildren() do
		if other ~= part and other:IsA("BasePart") and other.Transparency ~= 1 then
			local ox, oy = TableSpace.toTable(felt, other.Position)
			local distSq = (ox - x) ^ 2 + (oy - y) ^ 2
			if distSq < nearest then
				otherX, otherY, nearest = ox, oy, distSq
			end
		end
	end
	if nearest < (PARTNER_REACH * r) ^ 2 then
		local dx, dy = otherX - x, otherY - y
		local edge = r / math.sqrt(nearest)
		sparks(felt, r, x + dx * edge, y + dy * edge, dx, dy, count, big, look.BallSprayMin, look.BallSprayMax)
	end
end

-- The pulse showing now, so a new one replaces it instead of stacking
local pulsing: { Highlight } = {}

-- Your turn started: these balls, yours to hit, pulse once over Theme.Effects.PulseSeconds so you can see which they are.
-- A Highlight on each ball washes it and its marks white and outlines it, follows it if it moves, and hides behind the
-- cue and the felt, so a ball sinking mid-pulse takes it down with it.
function Effects.pulse(balls: { BasePart })
	for _, old in pulsing do
		old:Destroy()
	end
	table.clear(pulsing)
	-- Half the time in, then the same back out
	local info = TweenInfo.new(look.PulseSeconds / 2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 0, true)
	for _, ball in balls do
		local glow = Instance.new("Highlight")
		glow.DepthMode = Enum.HighlightDepthMode.Occluded
		glow.FillColor = look.PulseColor
		glow.OutlineColor = look.PulseColor
		glow.FillTransparency = 1
		glow.OutlineTransparency = 1
		glow.Parent = ball
		TweenService:Create(glow, info, { FillTransparency = look.PulseFill, OutlineTransparency = look.PulseOutline })
			:Play()
		table.insert(pulsing, glow)
		task.delay(look.PulseSeconds, glow.Destroy, glow)
	end
end

-- A hit from a replay, for the loudest few each frame. `kind` is "ball", "rail" or "pocket", `part` the ball that hit
-- or dropped, at the moment it happened, and `share` how hard, as a share of a full-power hit: up to 1 for a normal
-- shot, about Config.Physics.BreakPower on the break, and 1 for a pocket.
function Effects.hit(kind: string, part: BasePart, felt: BasePart, share: number)
	-- Deferred to the end of this frame, once the replay has drawn the balls where the hit left them: at break speed
	-- the frame before can be a whole stud away
	task.defer(show, kind, part, felt, share)
end

return Effects
