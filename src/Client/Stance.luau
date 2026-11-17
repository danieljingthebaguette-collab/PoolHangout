--!strict
-- On your turn, while you aim in the top-down view, your character glides to stand a few studs behind the cue ball and
-- a little to the left of the shot's line, facing along it, on top of the table when that spot is over it and clear of
-- its edge when it isn't (ShotStance). Players watching in 3D see who's shooting and where, and ShotPose bends the
-- character into the pose once it stands still. When your turn or the view ends, a character on or close to the table
-- steps clear of it, so it's never in the next shooter's way. The character is yours, so moving it here shows on every
-- screen.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local ShotStance = require(ReplicatedStorage.Shared.ShotStance)
local TableSpace = require(ReplicatedStorage.Shared.TableSpace)

local Stance = {}

-- Where the character is headed and on which table, and the cue ball it faces while it gets ready to shoot (nil when
-- it's only stepping off). Nil once it's there with nothing to face.
local goal: { felt: BasePart, x: number, y: number, faceX: number?, faceY: number? }? = nil
local connection: RBXScriptConnection? = nil

-- How far the table reaches past its felt, in table space: over it, the shooter stands on top
local function tableHalf(): (number, number)
	local edge = Config.Stance.TableEdge
	return Config.Table.Length / 2 + edge, Config.Table.Width / 2 + edge
end

-- The height the character's root sits at when it stands at (x, y): on top of the table, or on the floor, which is where
-- the table's seat markers lie
local function standHeight(felt: BasePart, x: number, y: number, humanoid: Humanoid, root: BasePart): number
	local halfX, halfY = tableHalf()
	local surface = felt.Position.Y + felt.Size.Y / 2 + Config.Stance.TableStandHeight
	if not ShotStance.overTable(x, y, halfX, halfY) then
		local seats = (felt.Parent :: Instance):FindFirstChild("Seats")
		local marker = seats and seats:FindFirstChild("A1")
		surface = if marker and marker:IsA("BasePart") then marker.Position.Y + marker.Size.Y / 2 else surface
	end
	-- An R6 root sits on 2-stud legs; an R15 one floats HipHeight above the ground
	local legs = if humanoid.RigType == Enum.HumanoidRigType.R6 then 2 else humanoid.HipHeight
	return surface + legs + root.Size.Y / 2
end

local function step(dt: number)
	local character = Players.LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local target = goal
	if not (target and humanoid and root and root:IsA("BasePart")) or humanoid.Health <= 0 then
		return
	end
	local felt = target.felt
	local x, y = TableSpace.toTable(felt, root.Position)
	local stance = Config.Stance
	local toHeight = standHeight(felt, target.x, target.y, humanoid, root)
	local newX, newY, height =
		ShotStance.step(x, y, root.Position.Y, target.x, target.y, toHeight, stance.Speed, stance.Climb, dt)
	local spot = TableSpace.toWorld(felt, newX, newY, 0).Position
	local position = Vector3.new(spot.X, height, spot.Z)
	-- Facing the cue ball, or with none, keeping the way it faces now
	local look = root.CFrame.LookVector
	if target.faceX and target.faceY then
		local ball = TableSpace.toWorld(felt, target.faceX, target.faceY, 0).Position
		look = Vector3.new(ball.X - position.X, 0, ball.Z - position.Z)
	end
	root.CFrame = CFrame.lookAt(position, position + Vector3.new(look.X, 0, look.Z))
	root.AssemblyLinearVelocity = Vector3.zero
	local there = newX == target.x and newY == target.y and height == toHeight
	if there and not target.faceX then
		goal = nil
	end
end

local function run()
	if not connection then
		connection = RunService.Heartbeat:Connect(step)
	end
end

-- Keeps the character headed for its spot behind the cue ball at (cueX, cueY) for this aim, facing along the shot. Call
-- every frame while it's your turn in the view.
function Stance.update(felt: BasePart, cueX: number, cueY: number, aim: number)
	local stance = Config.Stance
	local spot, face = ShotStance.spot(cueX, cueY, aim, stance.Distance, stance.Side)
	local halfX, halfY = tableHalf()
	local at = ShotStance.clear(spot.x, spot.y, halfX, halfY, stance.Clear)
	goal = { felt = felt, x = at.x, y = at.y, faceX = face.x, faceY = face.y }
	run()
end

-- Your turn or the view ended: a character on the table, or too close to it, steps straight out to Config.Stance.Clear
-- from its edge, and one already clear stays put
function Stance.stop()
	local target = goal
	if not (target and target.faceX) then
		return
	end
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) then
		goal = nil
		return
	end
	local x, y = TableSpace.toTable(target.felt, root.Position)
	local halfX, halfY = tableHalf()
	local off = ShotStance.offTable(x, y, halfX, halfY, Config.Stance.Clear)
	goal = { felt = target.felt, x = off.x, y = off.y, faceX = nil, faceY = nil }
end

return Stance
