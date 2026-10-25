--!strict
-- Finds the tables, makes and racks their balls, and starts and ends their games. A few times a second it checks
-- who stands on each table's platforms, and once every platform has a player a game starts. In Studio with
-- Config.Debug.SoloTables and one player in the server, one platform is enough. A game ends once its result has
-- shown, and the table re-racks; players still on the platforms then start a new one. It also ends when one of its
-- players leaves the server, leaving the balls where they are; walking away from the table doesn't count.
-- ponytail: no sign, countdown or end screen, and nobody is moved off the platforms. Phase 3 adds them, with the
-- table's states and its reset.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local EightBall = require(ReplicatedStorage.Shared.Rules.EightBall)
local Geometry = require(ReplicatedStorage.Shared.Physics.Geometry)
local PhysicsTestAccess = require(ReplicatedStorage.Shared.PhysicsTestAccess)
local Balls = require(script.Parent.Balls)
local Match = require(script.Parent.Match)

-- Platforms in turn order. A 1v1 table has the first two.
local SEAT_ORDER = { "A1", "B1", "A2", "B2" }

local TableService = {}

local matches: { [Model]: Match.Match } = {}
local random = Random.new()

function TableService.hasGame(tableModel: Model): boolean
	return matches[tableModel] ~= nil
end

local function inGame(player: Player): boolean
	for _, match in matches do
		if table.find(match.seats, player) then
			return true
		end
	end
	return false
end

-- Whether a root part is over the platform's footprint and no more than StandHeight above its top
local function standingOn(platform: BasePart, root: BasePart): boolean
	local offset = platform.CFrame:PointToObjectSpace(root.Position)
	local half = platform.Size / 2
	return math.abs(offset.X) <= half.X
		and math.abs(offset.Z) <= half.Z
		and offset.Y >= half.Y
		and offset.Y <= half.Y + Config.Platforms.StandHeight
end

-- The players on the table's platforms, in turn order, once enough platforms are filled for a game; nil until then.
-- A player can't hold two platforms, or one here while they're in a game.
local function seatsFilled(tableModel: Model): { Player }?
	local platforms = tableModel:FindFirstChild("Platforms")
	if not platforms then
		return nil
	end
	local seats: { Player } = {}
	local open = 0
	for _, name in SEAT_ORDER do
		local platform = platforms:FindFirstChild(name)
		if not (platform and platform:IsA("BasePart")) then
			continue
		end
		local found: Player? = nil
		for _, player in Players:GetPlayers() do
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if
				humanoid
				and humanoid.Health > 0
				and root
				and root:IsA("BasePart")
				and standingOn(platform, root)
				and not table.find(seats, player)
				and not inGame(player)
			then
				found = player
				break
			end
		end
		if found then
			table.insert(seats, found)
		else
			open += 1
		end
	end
	local solo = RunService:IsStudio() and Config.Debug.SoloTables and #Players:GetPlayers() == 1
	if #seats > 0 and (open == 0 or solo) then
		return seats
	end
	return nil
end

local function pick(n: number): number
	return random:NextInteger(1, n)
end

local function rack(tableModel: Model)
	Balls.place(tableModel, EightBall.rack(Geometry.build(PhysicsTestAccess.params().Table), pick))
end

function TableService.start()
	local tables: { Model } = {}
	for _, child in workspace:WaitForChild("Tables"):GetChildren() do
		if child:IsA("Model") then
			child:WaitForChild("Felt")
			Balls.create(child)
			rack(child)
			table.insert(tables, child)
		end
	end

	Players.PlayerRemoving:Connect(function(player: Player)
		for tableModel, match in matches do
			if table.find(match.seats, player) then
				Match.destroy(match)
				matches[tableModel] = nil
			end
		end
	end)

	task.spawn(function()
		while true do
			for _, tableModel in tables do
				-- A shot still rolling from an ended game finishes before the next game racks
				if matches[tableModel] or Balls.isRolling(tableModel) then
					continue
				end
				local seats = seatsFilled(tableModel)
				if seats then
					local match: Match.Match
					match = Match.new(tableModel, seats, pick, function()
						-- A player who left while the result showed has already ended this game
						if matches[tableModel] == match then
							Match.destroy(match)
							matches[tableModel] = nil
							rack(tableModel)
						end
					end)
					matches[tableModel] = match
				end
			end
			task.wait(Config.Platforms.CheckSeconds)
		end
	end)
end

return TableService
