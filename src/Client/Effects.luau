--!strict
-- Effects on the table, in docs/STYLE.md's look, built from parts in code and only on this screen. For now the hit
-- effects: small chunky sparks where a ball hits another ball or a rail hard, and a small pop where one drops into a
-- pocket. Item effects and screen shake come in the Items and polish phases. Every look and timing is Theme.Effects.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local TableSpace = require(ReplicatedStorage.Shared.TableSpace)
local Theme = require(ReplicatedStorage.Shared.Theme)

local Effects = {}

local look = Theme.Effects
-- Canvas pixels across the pop ring's line: enough to keep its edge crisp
local RING_PIXELS = 8
-- How far away, in ball radii, the other ball of a hit can be by the end of the frame: about one frame's travel at
-- break speed
local PARTNER_REACH = 7

-- Effect parts alive now, kept under look.MaxParts
local live = 0
-- Which spark color comes next
local nextColor = 0

-- A bare anchored part for an effect, that nothing can touch or click, parented to the felt so it goes if the table does. It destroys
-- itself after `seconds`. Nil when too many effect parts are alive already.
local function newPart(felt: BasePart, seconds: number): Part?
	if live >= look.MaxParts then
		return nil
	end
	live += 1
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Material = Enum.Material.SmoothPlastic
	part.Parent = felt
	task.delay(seconds, function()
		live -= 1
		part:Destroy()
	end)
	return part
end

-- A few chunky sparks from (x, y) in table space, flying at an angle of sprayMin to sprayMax degrees either side
-- of the direction (ax, ay). `t` is how hard, 0 at SparkShare to 1 at full power.
local function sparks(
	felt: BasePart,
	r: number,
	x: number,
	y: number,
	ax: number,
	ay: number,
	t: number,
	sprayMin: number,
	sprayMax: number
)
	local count = math.round(look.SparkMinCount + (look.SparkMaxCount - look.SparkMinCount) * t)
	local reach = (look.SparkReachMin + (look.SparkReachMax - look.SparkReachMin) * t) * r
	local base = math.atan2(ay, ax)
	local info = TweenInfo.new(look.SparkSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local shrink = TweenInfo.new(look.SparkSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	for i = 1, count do
		local part = newPart(felt, look.SparkSeconds)
		if not part then
			return
		end
		-- Alternate sides, so even three sparks spray both ways
		local side = if i % 2 == 0 then 1 else -1
		local angle = base + side * math.rad(sprayMin + (sprayMax - sprayMin) * math.random())
		local dx, dy = math.cos(angle), math.sin(angle)
		local far = reach * (0.75 + 0.25 * math.random())
		-- Long along its path. A turn about Y by θ takes the part's X axis to (cos θ, 0, -sin θ).
		local turn = CFrame.Angles(0, math.atan2(-dy, dx), 0)
		nextColor = nextColor % #look.SparkColors + 1
		part.Color = look.SparkColors[nextColor]
		part.Size = Vector3.new(look.SparkLength, look.SparkThickness, look.SparkThickness) * r
		part.CFrame = TableSpace.toWorld(felt, x, y, look.SparkHeight * r) * turn
		local finish = TableSpace.toWorld(felt, x + dx * far, y + dy * far, (look.SparkHeight + look.SparkRise) * r)
		TweenService:Create(part, info, { CFrame = finish * turn }):Play()
		TweenService:Create(part, shrink, { Size = Vector3.new(0.001, 0.001, 0.001) }):Play()
	end
end

-- A flat cream ring that pops out from (x, y) in table space and fades
local function pop(felt: BasePart, r: number, x: number, y: number)
	local part = newPart(felt, look.PopSeconds)
	if not part then
		return
	end
	local line = look.PopLine * r
	part.Transparency = 1
	part.Size = Vector3.new(look.PopStartDiameter * r, 0.001, look.PopStartDiameter * r)
	part.CFrame = TableSpace.toWorld(felt, x, y, look.PopHeight * r)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Top
	gui.LightInfluence = 0
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = RING_PIXELS / line
	local ring = Instance.new("Frame")
	ring.Size = UDim2.fromScale(1, 1)
	ring.BackgroundTransparency = 1
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = ring
	local stroke = Instance.new("UIStroke")
	stroke.Color = look.PopColor
	stroke.Thickness = RING_PIXELS
	stroke.Transparency = look.PopTransparency
	stroke.Parent = ring
	ring.Parent = gui
	gui.Parent = part
	local diameter = look.PopEndDiameter * r
	TweenService:Create(
		part,
		TweenInfo.new(look.PopSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = Vector3.new(diameter, 0.001, diameter) }
	):Play()
	TweenService:Create(
		stroke,
		TweenInfo.new(look.PopSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Transparency = 1 }
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
	local t = math.clamp((share - look.SparkShare) / (1 - look.SparkShare), 0, 1)
	if kind == "rail" then
		-- The nearest cushion: an end rail if the ball is closer to the felt's end than its side
		local halfLength, halfWidth = felt.Size.X / 2, felt.Size.Z / 2
		if halfLength - math.abs(x) < halfWidth - math.abs(y) then
			local sign = math.sign(x)
			sparks(felt, r, sign * halfLength, y, -sign, 0, t, look.RailSprayMin, look.RailSprayMax)
		else
			local sign = math.sign(y)
			sparks(felt, r, x, sign * halfWidth, 0, -sign, t, look.RailSprayMin, look.RailSprayMax)
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
		sparks(felt, r, x + dx * edge, y + dy * edge, dx, dy, t, look.BallSprayMin, look.BallSprayMax)
	end
end

-- A hit from a replay, for the loudest few each frame. `kind` is "ball", "rail" or "pocket", `part` the ball that hit
-- or dropped, at the moment it happened, and `share` how hard, 0 to 1 of a full-power hit (1 for a pocket).
function Effects.hit(kind: string, part: BasePart, felt: BasePart, share: number)
	-- Deferred to the end of this frame, once the replay has drawn the balls where the hit left them: at break speed
	-- the frame before can be a whole stud away
	task.defer(show, kind, part, felt, share)
end

return Effects
