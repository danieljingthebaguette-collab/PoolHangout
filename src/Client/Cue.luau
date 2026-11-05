--!strict
-- The cue stick, a Part on the table that only this screen sees. ShotController lays it behind the cue ball while you
-- aim, slides it back as you pull, and strikes and follows through with it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local TableSpace = require(ReplicatedStorage.Shared.TableSpace)
local Theme = require(ReplicatedStorage.Shared.Theme)

local Cue = {}

-- The cue's part and its measures in studs: its length, and from the cue ball's center back to its tip and, at rest, to
-- its center, and how high above the felt it's drawn
export type Cue = { part: Part, length: number, tipBack: number, restBack: number, height: number }

-- Builds the cue on the table, hidden
function Cue.new(tableModel: Model): Cue
	local radius = Config.Table.BallRadius
	local length = Config.Aim.CueLength * Config.Table.Length
	local tipBack = radius * (1 + Config.Aim.CueTipGap)
	local part = Instance.new("Part")
	part.Name = "Cue"
	part.Shape = Enum.PartType.Cylinder
	part.Size = Vector3.new(length, 2 * radius * Config.Aim.CueThickness, 2 * radius * Config.Aim.CueThickness)
	part.Color = Theme.Colors.Cue
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Transparency = 1
	part.Parent = tableModel
	return {
		part = part,
		length = length,
		tipBack = tipBack,
		restBack = tipBack + length / 2,
		height = radius * Config.Aim.CueHeight,
	}
end

-- Lays the cue along `aim` (radians in table space) behind the table-space point (x, y), its center `back` studs
-- from it
function Cue.place(cue: Cue, felt: BasePart, x: number, y: number, aim: number, back: number)
	cue.part.CFrame = TableSpace.toWorld(felt, x - math.cos(aim) * back, y - math.sin(aim) * back, cue.height)
		* CFrame.Angles(0, -aim, 0)
end

return Cue
