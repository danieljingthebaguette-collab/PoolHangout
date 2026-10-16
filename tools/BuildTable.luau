--!strict
-- Rebuilds the greybox Table1 in the place from Config: felt, cushions with angled jaws, slim wooden rails with
-- diamonds, black corner plates, side pocket holes, body and legs. Keeps Felt (resized to Config), Platforms and
-- the runtime Balls folder; replaces every other part. Placeholder until the commissioned table arrives. The look
-- follows docs/STYLE.md: matte, painted-looking flat colors (SmoothPlastic everywhere, no textured materials).
--
-- Not synced to Studio. Run it in Studio's command bar in edit mode, or have Claude run it through the MCP's
-- execute_luau. Undo works (Ctrl+Z). Save the place afterwards.

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any

local tableModel = workspace:WaitForChild("Tables"):WaitForChild("Table1") :: Model
local felt = tableModel:WaitForChild("Felt") :: BasePart

-- Where the playing surface sits: its center on the floor plan, and its top's height. Kept from the current Felt.
local CENTER_X, CENTER_Z = felt.Position.X, felt.Position.Z
local FELT_TOP = felt.Position.Y + felt.Size.Y / 2

local L, W = Config.Table.Length, Config.Table.Width
local CORNER_MOUTH, SIDE_MOUTH = Config.Table.CornerPocketMouth, Config.Table.SidePocketMouth
local CUSHION_WIDTH, WOOD_WIDTH = 0.35, 0.75
local OUT_X, OUT_Z = L / 2 + CUSHION_WIDTH + WOOD_WIDTH, W / 2 + CUSHION_WIDTH + WOOD_WIDTH
-- Heights relative to the felt's top. Rails stay under Config.Aim.CueHeight ball radii, where the cue is drawn.
local FELT_THICKNESS = 0.4
local CUSHION_BOTTOM, CUSHION_TOP = FELT_TOP - FELT_THICKNESS, FELT_TOP + 0.3
local RAIL_BOTTOM, WOOD_TOP, PLATE_TOP = FELT_TOP - 0.6, FELT_TOP + 0.35, FELT_TOP + 0.37
local BODY_BOTTOM = FELT_TOP - 0.9
local INSET, PLATE_RADIUS = 0.35, 0.5 -- how far corner plates reach onto the felt; their outer corner's rounding
local SIDE_HOLE_RADIUS, SIDE_HOLE_OUT = 0.6, 0.1 -- side pocket holes, and how far past the felt's edge they center
local CORNER_JAW_SLOPE, SIDE_JAW_SLOPE = 1, math.tan(math.rad(20)) -- how far each cushion's back runs past its nose

local FELT_COLOR = Color3.fromRGB(50, 122, 76)
local CUSHION_COLOR = Color3.fromRGB(34, 88, 52)
local WOOD_COLOR = Color3.fromRGB(122, 70, 40) -- painted reddish-brown, darker than the honey floor planks
local BODY_COLOR = Color3.fromRGB(86, 50, 30)
local DIAMOND_COLOR = Color3.fromRGB(246, 239, 224) -- the HUD's cream
local BLACK = Color3.fromRGB(20, 16, 14)
local MATTE = Enum.Material.SmoothPlastic

local recording = ChangeHistoryService:TryBeginRecording("Rebuild Table1")

local function world(x: number, y: number, z: number): Vector3
	return Vector3.new(CENTER_X + x, y, CENTER_Z + z)
end

local function part(
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material?,
	shape: Enum.PartType?
): Part
	local item = Instance.new("Part")
	item.Name = name
	item.Anchored = true
	item.Size = size
	item.CFrame = cframe
	item.Color = color
	item.Material = material or Enum.Material.SmoothPlastic
	item.Shape = shape or Enum.PartType.Block
	item.TopSurface = Enum.SurfaceType.Smooth
	item.BottomSurface = Enum.SurfaceType.Smooth
	return item
end

local function block(
	name: string,
	x0: number,
	x1: number,
	y0: number,
	y1: number,
	z0: number,
	z1: number,
	color: Color3,
	material: Enum.Material?
): Part
	local cframe = CFrame.new(world((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2))
	return part(name, Vector3.new(math.abs(x1 - x0), y1 - y0, math.abs(z1 - z0)), cframe, color, material)
end

-- An upright cylinder. Roblox cylinders run along their X axis.
local function disc(name: string, radius: number, y0: number, y1: number, x: number, z: number, color: Color3): Part
	local cframe = CFrame.new(world(x, (y0 + y1) / 2, z)) * CFrame.Angles(0, 0, math.rad(90))
	return part(name, Vector3.new(y1 - y0, 2 * radius, 2 * radius), cframe, color, MATTE, Enum.PartType.Cylinder)
end

-- Unions or subtracts, keeping the first part's name, color and material
local function csg(first: BasePart, others: { BasePart }, subtract: boolean): BasePart
	first.Parent = workspace
	for _, other in others do
		other.Parent = workspace
	end
	local result = if subtract then first:SubtractAsync(others) else first:UnionAsync(others)
	result.Name = first.Name
	result.Anchored = true
	result.UsePartColor = true
	result.Color = first.Color
	result.Material = first.Material
	first:Destroy()
	for _, other in others do
		other:Destroy()
	end
	return result
end

local function sideHoleCutters(): { BasePart }
	local cutters = {}
	for _, side in { -1, 1 } do
		table.insert(cutters, disc("Cut", SIDE_HOLE_RADIUS, 0, FELT_TOP + 2, 0, side * (W / 2 + SIDE_HOLE_OUT), BLACK))
	end
	return cutters
end

local built: { BasePart } = {}
local function add(item: BasePart): BasePart
	table.insert(built, item)
	return item
end

-- A cushion with its nose from A to B on the felt's edge, `out` pointing away from the felt. Each end's back runs
-- `slope` × its width past its nose, so the end is cut at an angle into the pocket.
local function cushion(
	ax: number,
	az: number,
	bx: number,
	bz: number,
	outX: number,
	outZ: number,
	slopeA: number,
	slopeB: number,
	nearSide: boolean
)
	local a, b, out = Vector3.new(ax, 0, az), Vector3.new(bx, 0, bz), Vector3.new(outX, 0, outZ)
	local along = (b - a).Unit
	local length = (b - a).Magnitude + CUSHION_WIDTH * (slopeA + slopeB)
	local middle = (a + b) / 2 + along * (CUSHION_WIDTH * (slopeB - slopeA) / 2) + out * CUSHION_WIDTH / 2
	local y = (CUSHION_BOTTOM + CUSHION_TOP) / 2
	local base = part(
		"Cushion",
		Vector3.new(length, CUSHION_TOP - CUSHION_BOTTOM, CUSHION_WIDTH),
		CFrame.fromMatrix(world(middle.X, y, middle.Z), along, Vector3.yAxis),
		CUSHION_COLOR,
		MATTE
	)
	local cuts: { BasePart } = {}
	for _, finish in { { b, along, slopeB }, { a, -along, slopeA } } do
		local nose, direction, slope = finish[1], finish[2], finish[3]
		local back = nose + out * CUSHION_WIDTH + direction * CUSHION_WIDTH * slope
		local face = (back - nose).Unit
		local normal = Vector3.new(face.Z, 0, -face.X)
		if normal:Dot(direction) < 0 then
			normal = -normal
		end
		local center = (nose + back) / 2 + normal * 2
		table.insert(
			cuts,
			part(
				"Cut",
				Vector3.new(4, 4, 4),
				CFrame.fromMatrix(world(center.X, y, center.Z), normal, Vector3.yAxis),
				BLACK
			)
		)
	end
	if nearSide then
		for _, cutter in sideHoleCutters() do
			table.insert(cuts, cutter)
		end
	end
	add(csg(base, cuts, true))
end

local cornerGap, sideGap = CORNER_MOUTH / math.sqrt(2), SIDE_MOUTH / 2
for _, side in { -1, 1 } do
	cushion(-L / 2 + cornerGap, side * W / 2, -sideGap, side * W / 2, 0, side, CORNER_JAW_SLOPE, SIDE_JAW_SLOPE, true)
	cushion(sideGap, side * W / 2, L / 2 - cornerGap, side * W / 2, 0, side, SIDE_JAW_SLOPE, CORNER_JAW_SLOPE, true)
end
for _, side in { -1, 1 } do
	cushion(
		side * L / 2,
		-W / 2 + cornerGap,
		side * L / 2,
		W / 2 - cornerGap,
		side,
		0,
		CORNER_JAW_SLOPE,
		CORNER_JAW_SLOPE,
		false
	)
end

-- Wooden rails, ending where the corner plates begin so no two parts share a face (shared faces flicker)
local railEndX, railEndZ = L / 2 - INSET, W / 2 - INSET
for _, side in { -1, 1 } do
	local rail = block(
		"Rail",
		-railEndX,
		railEndX,
		RAIL_BOTTOM,
		WOOD_TOP,
		side * (W / 2 + CUSHION_WIDTH),
		side * OUT_Z,
		WOOD_COLOR,
		MATTE
	)
	add(csg(rail, sideHoleCutters(), true))
	add(
		block(
			"Rail",
			side * (L / 2 + CUSHION_WIDTH),
			side * OUT_X,
			RAIL_BOTTOM,
			WOOD_TOP,
			-railEndZ,
			railEndZ,
			WOOD_COLOR,
			MATTE
		)
	)
end

-- Diamonds, sunk a hair into the rail: every eighth of the length on the long rails, every quarter of the width on
-- the ends
local function diamond(x: number, z: number)
	local cframe = CFrame.new(world(x, WOOD_TOP + 0.005, z)) * CFrame.Angles(0, math.rad(45), 0)
	add(part("Diamond", Vector3.new(0.14, 0.02, 0.14), cframe, DIAMOND_COLOR))
end
for _, side in { -1, 1 } do
	for _, step in { -3, -2, -1, 1, 2, 3 } do
		diamond(step * L / 8, side * (W / 2 + CUSHION_WIDTH + WOOD_WIDTH / 2))
	end
	for _, step in { -1, 0, 1 } do
		diamond(side * (L / 2 + CUSHION_WIDTH + WOOD_WIDTH / 2), step * W / 4)
	end
end

-- Corner plates: one merged matte black part each, rounded on the outside, from where the rails end to the edge
for _, sx in { -1, 1 } do
	for _, sz in { -1, 1 } do
		local roundX, roundZ = sx * (OUT_X - PLATE_RADIUS), sz * (OUT_Z - PLATE_RADIUS)
		local plate = csg(
			block("CornerPlate", sx * railEndX, roundX, RAIL_BOTTOM, PLATE_TOP, sz * railEndZ, sz * OUT_Z, BLACK, MATTE),
			{
				block("P", roundX, sx * OUT_X, RAIL_BOTTOM, PLATE_TOP, sz * railEndZ, roundZ, BLACK),
				disc("P", PLATE_RADIUS, RAIL_BOTTOM, PLATE_TOP, roundX, roundZ, BLACK),
			},
			false
		)
		plate.CastShadow = false
		add(plate)
		add(disc("Pocket", CORNER_MOUTH / 2, FELT_TOP, FELT_TOP + 0.02, sx * L / 2, sz * W / 2, BLACK))
	end
end

-- Side pockets: the hole's black bottom, a touch wider than the hole so its walls stay hidden, and the opening on
-- the felt
for _, side in { -1, 1 } do
	add(
		disc(
			"SidePocket",
			SIDE_HOLE_RADIUS + 0.01,
			RAIL_BOTTOM + 0.1,
			FELT_TOP - 0.01,
			0,
			side * (W / 2 + SIDE_HOLE_OUT),
			BLACK
		)
	)
	add(disc("Pocket", SIDE_MOUTH / 2, FELT_TOP, FELT_TOP + 0.02, 0, side * W / 2, BLACK))
end

-- Body under the rails, set in from the edge, and legs
add(block("Body", -OUT_X + 0.2, OUT_X - 0.2, BODY_BOTTOM, RAIL_BOTTOM, -OUT_Z + 0.2, OUT_Z - 0.2, BODY_COLOR, MATTE))
for _, sx in { -1, 1 } do
	for _, sz in { -1, 1 } do
		add(
			block(
				"Leg",
				sx * (L / 2 - 1.5),
				sx * (L / 2 - 0.5),
				0,
				BODY_BOTTOM,
				sz * (W / 2 - 1.5),
				sz * (W / 2 - 0.5),
				BODY_COLOR,
				MATTE
			)
		)
	end
end

for _, item in built do
	if item.Name == "Pocket" or item.Name == "Diamond" or item.Name == "SidePocket" then
		item.CanCollide = false
		item.CastShadow = false
	end
end

local keep = { Felt = true, Platforms = true, Balls = true }
for _, child in tableModel:GetChildren() do
	if not keep[child.Name] and child:IsA("BasePart") then
		child:Destroy()
	end
end
for _, item in built do
	item.Parent = tableModel
end
felt.Size = Vector3.new(L, FELT_THICKNESS, W)
felt.Position = world(0, FELT_TOP - FELT_THICKNESS / 2, 0)
felt.Color = FELT_COLOR
felt.Material = MATTE

if recording then
	ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Commit)
end
print(`Rebuilt Table1 with {#built} parts. Save the place.`)
