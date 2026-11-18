--!strict
-- The shooter's ready-to-shoot pose, for every table, on every screen: while it's their turn and they stand still, their
-- R6 character leans over the table, the back arm drawn back as if holding a cue and the front arm reaching out along
-- the felt. It eases in, and out again while their shot rolls or when the turn passes. Built from joint offsets in code,
-- with no animation asset; each screen poses the shooters it sees, players and Coach alike. A shooter casts no shadow,
-- on or beside the table, and one standing on top of it is drawn see-through on every screen, with their accessories
-- (hair, hats, wings) hidden, so the balls under them stay easy to see. On a screen in the top-down view, its own
-- character is hidden completely from the moment the view opens until it closes, and any other character standing on a
-- table is hidden whole, face and accessories included, never part by part: the cue shows who's shooting.

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

-- A posed joint: its offset at the full pose, the animation's own pose to add it to, and the Transform last written
-- here, to tell whether the animation has written a newer one since
type Joint = { offset: CFrame, base: CFrame, written: CFrame? }
-- A posed character: how far into the pose it is, 0 to 1, and its joints
type Posed = { blend: number, joints: { [Motor6D]: Joint } }
-- A character's parts and decals, each with whether it's on an accessory, found once rather than every frame. Adding
-- or removing anything in the character finds them again.
type Look = { items: { { item: Instance, accessory: boolean } }, changed: { RBXScriptConnection } }

-- How far a table reaches from its centre, in table space: its felt and rails
local HALF_X = Config.Table.Length / 2 + Config.Stance.TableEdge
local HALF_Y = Config.Table.Width / 2 + Config.Stance.TableEdge

-- Each table's shooter, and whether their shot is rolling
local shooters: { [Model]: { seat: Seat.Seat, rolling: boolean } } = {}
local posed: { [Model]: Posed } = {}
-- Characters drawn other than normal now (see-through, or with parts hidden), and the set being built for the next frame
local faded: { [Model]: boolean } = {}
local fading: { [Model]: boolean } = {}
-- Every character in the world, players' and Coach's: the models straight in Workspace
local characters: { [Model]: boolean } = {}
-- Whether this screen is in the top-down view, where its own character and anyone standing on a table are hidden
local topDown = false
-- This frame's characters to draw and how see-through, and those hidden whole
local drawn: { [Model]: number } = {}
local hidden: { [Model]: boolean } = {}
-- Shooters' characters casting no shadow now, with each part's own CastShadow to give back after
local unshadowed: { [Model]: { [BasePart]: boolean } } = {}
local looks: { [Model]: Look } = {}
-- Reused every frame, so nothing new is made per frame
local wanted: { [Model]: boolean } = {}
local shooting: { [Model]: boolean } = {}

-- No offset at all, where each joint's pose blends from
local NONE = CFrame.new()
-- Each R6 joint's offset at the full pose, from Theme.Pose
local OFFSETS: { [string]: CFrame } = {
	-- The root joint tips the whole body forward from the hips; the hips tip the legs back so they stay upright
	RootJoint = CFrame.Angles(math.rad(Theme.Pose.Lean), 0, 0),
	["Right Hip"] = CFrame.Angles(0, 0, math.rad(Theme.Pose.Lean)),
	["Left Hip"] = CFrame.Angles(0, 0, -math.rad(Theme.Pose.Lean)),
	["Right Shoulder"] = CFrame.Angles(0, 0, math.rad(Theme.Pose.BackArm)),
	["Left Shoulder"] = CFrame.Angles(0, 0, -math.rad(Theme.Pose.FrontArm)),
	Neck = CFrame.Angles(-math.rad(Theme.Pose.Head), 0, 0),
}

local function joints(character: Model): { [Motor6D]: Joint }
	local found: { [Motor6D]: Joint } = {}
	for _, joint in character:GetDescendants() do
		local offset = OFFSETS[joint.Name]
		if offset and joint:IsA("Motor6D") then
			found[joint] = { offset = offset, base = joint.Transform, written = nil }
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

-- The pose goes on each joint's Transform, on top of the animation's own pose, since rewriting C0 makes Roblox rebuild
-- the character's body every frame. Animations write their Transforms before PreSimulation, where this runs; a joint
-- no animation moves, like Coach's, still holds what was written here, so its base stays as it was.
local function step(dt: number)
	table.clear(wanted)
	for _, shooter in shooters do
		local character = Seat.character(shooter.seat)
		if character and character.Parent and not shooter.rolling and still(character) then
			wanted[character] = true
		end
	end
	for character in wanted do
		if not posed[character] then
			posed[character] = { blend = 0, joints = joints(character) }
		end
	end
	local change = dt / Theme.Pose.EaseSeconds
	for character, pose in posed do
		local target = if wanted[character] then 1 else 0
		pose.blend = if target > pose.blend then math.min(pose.blend + change, 1) else math.max(pose.blend - change, 0)
		-- Smooth in and out
		local eased = pose.blend * pose.blend * (3 - 2 * pose.blend)
		for joint, state in pose.joints do
			if joint.Parent then
				local now = joint.Transform
				if now ~= state.written then
					state.base = now
				end
				joint.Transform = NONE:Lerp(state.offset, eased) * state.base
				state.written = joint.Transform
			end
		end
		if pose.blend == 0 and target == 0 then
			posed[character] = nil
		end
	end
end

local function forgetLook(character: Model)
	local look = looks[character]
	if look then
		for _, connection in look.changed do
			connection:Disconnect()
		end
		looks[character] = nil
	end
end

-- This character's parts and decals, found once and kept until something is added to it or removed from it
local function lookOf(character: Model): Look
	local look = looks[character]
	if look then
		return look
	end
	local items: { { item: Instance, accessory: boolean } } = {}
	for _, item in character:GetDescendants() do
		if item:IsA("BasePart") or item:IsA("Decal") then
			table.insert(items, {
				item = item :: Instance,
				accessory = item:FindFirstAncestorOfClass("Accessory") ~= nil,
			})
		end
	end
	local function changed()
		forgetLook(character)
	end
	local made: Look = {
		items = items,
		changed = { character.DescendantAdded:Connect(changed), character.DescendantRemoving:Connect(changed) },
	}
	looks[character] = made
	return made
end

-- Draws a character on this screen: hidden whole with `hide`, every part, decal and accessory at once, so it never
-- shows half a body; otherwise see-through by `amount`, with its accessories hidden while that's more than 0. Returns
-- whether it's drawn other than normal.
local function setLook(character: Model, amount: number, hide: boolean): boolean
	for _, entry in lookOf(character).items do
		-- Both have it, but the type checker can't write to a mix of two classes
		local item: any = entry.item
		item.LocalTransparencyModifier = if hide
			then Theme.Pose.TopDownHidden
			elseif amount > 0 and entry.accessory then Theme.Pose.OnTableAccessories
			else amount
	end
	return hide or amount > 0
end

-- These characters cast no shadow, parts added since included; every other character gets its parts' own back. A
-- character that's gone is just forgotten.
local function dropShadows()
	for character in shooting do
		local saved = unshadowed[character] or {}
		unshadowed[character] = saved
		for _, entry in lookOf(character).items do
			local part = entry.item
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

-- Shooters cast no shadow, and those standing on top of their table are see-through. In the top-down view, this
-- screen's own character is hidden whole, and so is anyone else whose root is over a table. Anyone who stepped off,
-- stopped shooting or left the table gets back what they had.
local function fade()
	table.clear(fading)
	table.clear(shooting)
	table.clear(drawn)
	table.clear(hidden)
	for tableModel, shooter in shooters do
		local character = Seat.character(shooter.seat)
		if character and character.Parent then
			shooting[character] = true
		end
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local felt = tableModel:FindFirstChild("Felt")
		if character and root and root:IsA("BasePart") and felt and felt:IsA("BasePart") then
			local x, y = TableSpace.toTable(felt, root.Position)
			if ShotStance.overTable(x, y, HALF_X, HALF_Y) then
				drawn[character] = Theme.Pose.OnTableSeeThrough
			end
		end
	end
	if topDown then
		local mine = Players.LocalPlayer.Character
		if mine and mine.Parent then
			hidden[mine] = true
		end
		local tables = workspace:FindFirstChild("Tables")
		for character in characters do
			local root = character:FindFirstChild("HumanoidRootPart")
			if tables and not hidden[character] and root and root:IsA("BasePart") then
				for _, tableModel in tables:GetChildren() do
					local felt = tableModel:FindFirstChild("Felt")
					if felt and felt:IsA("BasePart") then
						local x, y = TableSpace.toTable(felt, root.Position)
						if ShotStance.overTable(x, y, HALF_X, HALF_Y) then
							hidden[character] = true
							break
						end
					end
				end
			end
		end
	end
	for character, amount in drawn do
		if setLook(character, amount, hidden[character] == true) then
			fading[character] = true
		end
	end
	for character in hidden do
		if not drawn[character] and setLook(character, 0, true) then
			fading[character] = true
		end
	end
	for character in faded do
		if not (drawn[character] or hidden[character]) and character.Parent then
			setLook(character, 0, false)
		end
	end
	faded, fading = fading, faded
	dropShadows()
	-- A character not shooting, drawn or hidden this frame needs no parts list
	for character in looks do
		if not (shooting[character] or faded[character] or drawn[character] or hidden[character]) then
			forgetLook(character)
		end
	end
end

function ShotPose.setTopDown(on: boolean)
	topDown = on
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
	local function watch(child: Instance)
		if child:IsA("Model") then
			characters[child] = true
		end
	end
	for _, child in workspace:GetChildren() do
		watch(child)
	end
	workspace.ChildAdded:Connect(watch)
	workspace.ChildRemoved:Connect(function(child: Instance)
		if child:IsA("Model") then
			characters[child] = nil
		end
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		for model, shooter in shooters do
			if shooter.seat == player then
				shooters[model] = nil
			end
		end
	end)
end

return ShotPose
