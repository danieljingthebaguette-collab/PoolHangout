--!strict
-- The shooter's ready-to-shoot pose, for every table, on every screen: while it's their turn and they stand still, their
-- R6 character leans over the table, the back arm drawn back as if holding a cue and the front arm reaching out along
-- the felt. It eases in, and out again while their shot rolls or when the turn passes. Built from joint offsets in code,
-- with no animation asset; each screen poses the shooters it sees, players and Coach alike. A shooter casts no shadow,
-- on or beside the table, and one standing on top of it is drawn see-through on every screen, with their accessories
-- (hair, hats, wings) hidden, so the balls under them stay easy to see.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Seat = require(ReplicatedStorage.Shared.Seat)
local ShotStance = require(ReplicatedStorage.Shared.ShotStance)
local TableSpace = require(ReplicatedStorage.Shared.TableSpace)
local Theme = require(ReplicatedStorage.Shared.Theme)

local ShotPose = {}

-- A posed character: how far into the pose it is, 0 to 1, and each joint's resting C0 to blend from
type Posed = { blend: number, rest: { [Motor6D]: CFrame } }

-- Each table's shooter, and whether their shot is rolling
local shooters: { [Model]: { seat: Seat.Seat, rolling: boolean } } = {}
local posed: { [Model]: Posed } = {}
-- Characters drawn see-through now, on top of their table
local faded: { [Model]: boolean } = {}
-- Shooters' characters casting no shadow now, with each part's own CastShadow to give back after
local unshadowed: { [Model]: { [BasePart]: boolean } } = {}

-- Each R6 joint's offset at the full pose, from Theme.Pose
local function offsets(): { [string]: CFrame }
	local pose = Theme.Pose
	local lean = math.rad(pose.Lean)
	return {
		-- The root joint tips the whole body forward from the hips; the hips tip the legs back so they stay upright
		RootJoint = CFrame.Angles(lean, 0, 0),
		["Right Hip"] = CFrame.Angles(0, 0, lean),
		["Left Hip"] = CFrame.Angles(0, 0, -lean),
		["Right Shoulder"] = CFrame.Angles(0, 0, math.rad(pose.BackArm)),
		["Left Shoulder"] = CFrame.Angles(0, 0, -math.rad(pose.FrontArm)),
		Neck = CFrame.Angles(-math.rad(pose.Head), 0, 0),
	}
end

local function joints(character: Model): { [Motor6D]: string }
	local found: { [Motor6D]: string } = {}
	for _, joint in character:GetDescendants() do
		if joint:IsA("Motor6D") and offsets()[joint.Name] then
			found[joint] = joint.Name
		end
	end
	return found
end

-- Whether this character is standing still: walking or falling cancels the pose
local function still(character: Model): boolean
	local root = character:FindFirstChild("HumanoidRootPart")
	return root ~= nil
		and root:IsA("BasePart")
		and (root.Anchored or root.AssemblyLinearVelocity.Magnitude < Theme.Pose.StillSpeed)
end

local function step(dt: number)
	local wanted: { [Model]: boolean } = {}
	for _, shooter in shooters do
		local character = Seat.character(shooter.seat)
		if character and character.Parent and not shooter.rolling and still(character) then
			wanted[character] = true
		end
	end
	for character in wanted do
		if not posed[character] then
			local rest = {}
			for joint in joints(character) do
				rest[joint] = joint.C0
			end
			posed[character] = { blend = 0, rest = rest }
		end
	end
	local full = offsets()
	local none = CFrame.new()
	for character, pose in posed do
		local target = if wanted[character] then 1 else 0
		local change = dt / Theme.Pose.EaseSeconds
		pose.blend = if target > pose.blend then math.min(pose.blend + change, 1) else math.max(pose.blend - change, 0)
		-- Smooth in and out
		local eased = pose.blend * pose.blend * (3 - 2 * pose.blend)
		for joint, rest in pose.rest do
			if joint.Parent then
				joint.C0 = rest * none:Lerp(full[joint.Name], eased)
			end
		end
		if pose.blend == 0 and target == 0 then
			posed[character] = nil
		end
	end
end

-- See-through by `amount`, with accessories hidden while it's more than 0
local function setSeeThrough(character: Model, amount: number)
	for _, item in character:GetDescendants() do
		-- Both have it, but the type checker can't write to a mix of two classes
		if item:IsA("BasePart") or item:IsA("Decal") then
			local accessory = amount > 0 and item:FindFirstAncestorOfClass("Accessory") ~= nil
			(item :: any).LocalTransparencyModifier = if accessory then Theme.Pose.OnTableAccessories else amount
		end
	end
end

-- These characters cast no shadow, parts added since included; every other character gets its parts' own back. A
-- character that's gone is just forgotten.
local function dropShadows(shooting: { [Model]: boolean })
	for character in shooting do
		local saved = unshadowed[character] or {}
		unshadowed[character] = saved
		for _, part in character:GetDescendants() do
			if part:IsA("BasePart") and saved[part] == nil then
				saved[part] = part.CastShadow
				part.CastShadow = false
			end
		end
	end
	for character, saved in unshadowed do
		if not shooting[character] then
			for part, cast in saved do
				part.CastShadow = cast
			end
			unshadowed[character] = nil
		end
	end
end

-- Shooters cast no shadow, and those standing on top of their table are see-through; anyone who stepped off, or
-- stopped shooting, gets back what they had
local function fade()
	local halfX = Config.Table.Length / 2 + Config.Stance.TableEdge
	local halfY = Config.Table.Width / 2 + Config.Stance.TableEdge
	local wanted: { [Model]: boolean } = {}
	local shooting: { [Model]: boolean } = {}
	for tableModel, shooter in shooters do
		local character = Seat.character(shooter.seat)
		if character and character.Parent then
			shooting[character] = true
		end
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local felt = tableModel:FindFirstChild("Felt")
		if character and root and root:IsA("BasePart") and felt and felt:IsA("BasePart") then
			local x, y = TableSpace.toTable(felt, root.Position)
			if ShotStance.overTable(x, y, halfX, halfY) then
				wanted[character] = true
				setSeeThrough(character, Theme.Pose.OnTableSeeThrough)
			end
		end
	end
	for character in faded do
		if not wanted[character] and character.Parent then
			setSeeThrough(character, 0)
		end
	end
	faded = wanted
	dropShadows(shooting)
end

function ShotPose.start()
	Remotes.TurnStarted.OnClientEvent:Connect(function(model: Model?, shooter: Seat.Seat?)
		if model then
			if shooter then
				shooters[model] = { seat = shooter, rolling = false }
			else
				shooters[model] = nil
			end
		end
	end)
	Remotes.ShotStarted.OnClientEvent:Connect(function(model: Model?)
		local shooter = model and shooters[model]
		if shooter then
			shooter.rolling = true
		end
	end)
	-- Before physics each frame, after the animations, so the pose shows
	RunService.PreSimulation:Connect(step)
	-- Just after the camera each frame, since Roblox's camera sets your own character's see-through too
	RunService:BindToRenderStep("ShotPoseFade", Enum.RenderPriority.Camera.Value + 1, fade)
	Players.PlayerRemoving:Connect(function(player: Player)
		for model, shooter in shooters do
			if shooter.seat == player then
				shooters[model] = nil
			end
		end
	end)
end

return ShotPose
