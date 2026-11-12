--!strict
-- Finds the tables, makes and racks their balls, and starts and ends their games. Players join a table with the
-- "Join table" prompt over its centre: the first takes side A, the next side B. The prompt only joins; the HUD's
-- Leave button leaves, calls off a start, or leaves a game (see Match.leave). Once every seat is taken, everyone at the
-- table sees "Starting...", and after the countdown each player is moved once to their seat's spot, facing the table,
-- and the game starts. Players walk freely the whole time. When a game is decided its end screen shows, then the same
-- players play again if they all pressed Rematch, or the table re-racks and opens. It also ends, with no winner, when
-- one of its players leaves the server, unless they had already pressed Leave. Roblox's own name tags are off for
-- everyone joined to or playing at a table, and for Coach, since they'd float over the felt; the Turn card names the
-- shooter instead.
-- Testing alone (Config.Debug): with Coach on, Coach, the bot, takes every other seat of a table a tester joins while
-- alone in the server (in 2v2, a teammate and both opponents); otherwise, in Studio with SoloTables, one player is
-- enough and takes every turn.
-- ponytail: no sign or takeovers yet. Phase 4 adds them, with the table's states and its reset.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local EightBall = require(ReplicatedStorage.Shared.Rules.EightBall)
local Geometry = require(ReplicatedStorage.Shared.Physics.Geometry)
local PhysicsTestAccess = require(ReplicatedStorage.Shared.PhysicsTestAccess)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Seat = require(ReplicatedStorage.Shared.Seat)
local TableFlow = require(ReplicatedStorage.Shared.Rules.TableFlow)
local Theme = require(ReplicatedStorage.Shared.Theme)
local Balls = require(script.Parent.Balls)
local Match = require(script.Parent.Match)

local TableService = {}

local matches: { [Model]: Match.Match } = {}
-- The players who have joined each table and are waiting for its game, and its countdown, when nobody can join
local lobbies: { [Model]: TableFlow.Lobby<Seat.Seat> } = {}
local prompts: { [Model]: ProximityPrompt } = {}
local random = Random.new()

function TableService.hasGame(tableModel: Model): boolean
	return matches[tableModel] ~= nil
end

local function inGame(player: Player): boolean
	for _, match in matches do
		local seat = table.find(match.seats, player)
		if seat and not match.left[seat] then
			return true
		end
	end
	return false
end

local function isWaiting(player: Player): boolean
	for _, lobby in lobbies do
		if table.find(lobby.joined, player) then
			return true
		end
	end
	return false
end

-- How many seats the table has, from its Mode, not from its seat markers, so a table still opens with one missing
local function seatCount(tableModel: Model): number
	return TableFlow.seatCount(tableModel:GetAttribute("Mode"))
end

-- The table's seat marker for a seat in turn order, if the builder has made it
local function seatMarker(tableModel: Model, seat: number): BasePart?
	local folder = tableModel:FindFirstChild("Seats")
	local marker = folder and folder:FindFirstChild(TableFlow.SEAT_NAMES[seat])
	return if marker and marker:IsA("BasePart") then marker else nil
end

-- Whether Coach fills the other seats here, for a tester alone in the server, while Config.Debug.Coach is on
local function coachTable(): boolean
	return Config.Debug.Coach and #Players:GetPlayers() == 1
end

-- How many players a game on this table needs: one per seat, or one in Studio solo where Coach doesn't play
local function needed(tableModel: Model): number
	local solo = RunService:IsStudio() and Config.Debug.SoloTables and #Players:GetPlayers() == 1 and not coachTable()
	return TableFlow.needed(seatCount(tableModel), solo)
end

-- Shows or hides the Roblox name tag over a seat's character. Set here, it reaches every screen.
local function showNameTag(seat: Seat.Seat, shown: boolean)
	local character = Seat.character(seat)
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		-- Viewer is Roblox's own setting for players, which the place keeps
		humanoid.DisplayDistanceType = if shown
			then Enum.HumanoidDisplayDistanceType.Viewer
			else Enum.HumanoidDisplayDistanceType.None
	end
end

local function pick(n: number): number
	return random:NextInteger(1, n)
end

local function rack(tableModel: Model)
	Balls.place(tableModel, EightBall.rack(Geometry.build(PhysicsTestAccess.params().Table), pick))
end

-- The prompt's words: how many have joined, which is all a table in use shows. The client shows "Waiting for
-- players" instead to a player who has joined.
local function updatePrompt(tableModel: Model)
	local prompt = prompts[tableModel]
	local lobby = lobbies[tableModel]
	local match = matches[tableModel]
	local count = `{if match then #match.seats else #lobby.joined}/{seatCount(tableModel)}`
	if match then
		prompt.ActionText, prompt.ObjectText = `{count} joined`, ""
	elseif lobby.countdown then
		prompt.ActionText, prompt.ObjectText = "Starting…", `{count} joined`
	else
		prompt.ActionText, prompt.ObjectText = "Join table", `{count} joined`
	end
end

-- Puts a player's character on a seat's spot, facing the table's centre. Only once, as the game starts: they walk
-- freely after.
local function moveToSeat(player: Seat.Seat, marker: BasePart, felt: BasePart)
	local character = Seat.character(player)
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (character and humanoid and root and root:IsA("BasePart")) then
		return
	end
	-- An R15 root part floats HipHeight above the floor; an R6 one stands on 2-stud legs
	local legs = if humanoid.RigType == Enum.HumanoidRigType.R6 then 2 else humanoid.HipHeight
	local height = marker.Position.Y + marker.Size.Y / 2 + legs + root.Size.Y / 2
	local spot = Vector3.new(marker.Position.X, height, marker.Position.Z)
	character:PivotTo(CFrame.lookAt(spot, Vector3.new(felt.Position.X, height, felt.Position.Z)))
end

-- Coach's figure for a seat: a plain grey R6 character, standing still on that seat's spot. In 2v2 the second and
-- third are "Coach 2" and "Coach 3".
local function spawnCoach(tableModel: Model, seat: number, count: number): Model
	local description = Instance.new("HumanoidDescription")
	for _, bodyPart in { "HeadColor", "TorsoColor", "LeftArmColor", "RightArmColor", "LeftLegColor", "RightLegColor" } do
		(description :: any)[bodyPart] = Theme.Colors.Coach
	end
	local model = Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R6)
	model.Name = if count == 1 then "Coach" else `Coach {count}`
	local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	humanoid.DisplayName = model.Name
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart
	root.Anchored = true
	model.Parent = workspace
	local marker = seatMarker(tableModel, seat)
	if marker then
		moveToSeat(model, marker, tableModel:FindFirstChild("Felt") :: BasePart)
	end
	return model
end

-- Ends the game and opens the table, then re-racks once any shot still rolling has stopped, so its last frame can't
-- land on the new rack. A game started meanwhile has already racked. Coach goes too.
local function endGame(tableModel: Model, match: Match.Match)
	Match.destroy(match)
	for _, seat in match.seats do
		if Seat.isBot(seat) then
			seat:Destroy()
		else
			showNameTag(seat, true)
		end
	end
	matches[tableModel] = nil
	updatePrompt(tableModel)
	task.spawn(function()
		while Balls.isRolling(tableModel) do
			task.wait()
		end
		if not matches[tableModel] then
			rack(tableModel)
		end
	end)
end

-- Starts a game on the table with these players in seat order, moving each to their seat. When it's over and its end
-- screen closes, it's a rematch with the same players, or the game ends and the table opens.
local function startMatch(tableModel: Model, players: { Seat.Seat })
	local felt = tableModel:FindFirstChild("Felt") :: BasePart
	for i, player in players do
		local marker = seatMarker(tableModel, i)
		if marker then
			moveToSeat(player, marker, felt)
		end
	end
	local match: Match.Match
	match = Match.new(tableModel, players, pick, function(rematch: boolean)
		-- A player who left while the end screen showed has already ended this game
		if matches[tableModel] ~= match then
			return
		end
		if rematch then
			Match.destroy(match)
			startMatch(tableModel, players)
		else
			endGame(tableModel, match)
		end
	end)
	matches[tableModel] = match
	updatePrompt(tableModel)
end

-- Every seat is taken: "Starting in 3", "2", "1" for everyone at the table, then the players go to their seats and the game
-- starts. A player who leaves meanwhile calls it off (see unjoin), and the rest stay joined.
local function startGame(tableModel: Model, token: {})
	local lobby = lobbies[tableModel]
	updatePrompt(tableModel)
	-- "Starting in 3", "2", "1", one a second, while the countdown is still on
	for left = Config.Timers.CountdownSeconds, 1, -1 do
		task.delay(Config.Timers.CountdownSeconds - left, function()
			if lobby.countdown == token then
				Remotes.Banner:FireAllClients(tableModel, `Starting in {left}`, 1)
			end
		end)
	end
	task.delay(Config.Timers.CountdownSeconds, function()
		-- A test shot still rolling finishes before the game racks
		while Balls.isRolling(tableModel) and lobby.countdown == token do
			task.wait()
		end
		if lobby.countdown ~= token then
			return
		end
		local players = TableFlow.endCountdown(lobby, token, needed(tableModel))
		if not players then
			updatePrompt(tableModel)
			return
		end
		for _, player in players do
			player:SetAttribute("JoinedTable", nil)
		end
		startMatch(tableModel, players)
	end)
end

-- Takes a player off the table they joined and are waiting at, if any. During the countdown that calls the start off
-- at once, and the others stay joined, except Coach, who only came to play them.
local function unjoin(player: Player)
	for tableModel, lobby in lobbies do
		local wasJoined, calledOff = TableFlow.unjoin(lobby, player)
		if not wasJoined then
			continue
		end
		player:SetAttribute("JoinedTable", nil)
		showNameTag(player, true)
		if calledOff then
			Remotes.Banner:FireAllClients(
				tableModel,
				`Start called off: {player.DisplayName} left.`,
				Config.Timers.NoticeSeconds
			)
		end
		for _, other in table.clone(lobby.joined) do
			if Seat.isBot(other) then
				TableFlow.unjoin(lobby, other)
				other:Destroy()
			end
		end
		updatePrompt(tableModel)
	end
end

-- The "Join table" prompt over the table's centre. Pressing it joins; pressing it again does nothing.
local function makePrompt(tableModel: Model)
	local felt = tableModel:FindFirstChild("Felt") :: BasePart
	local attachment = Instance.new("Attachment")
	attachment.Name = "JoinPrompt"
	attachment.Position = Vector3.new(0, felt.Size.Y / 2 + Config.Join.PromptHeight, 0)
	attachment.Parent = felt
	local prompt = Instance.new("ProximityPrompt")
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = Config.Join.PromptDistance
	prompt.RequiresLineOfSight = false -- the table's own rails can hide the spot above its centre
	prompt.Parent = attachment
	prompts[tableModel] = prompt
	local lobby = TableFlow.lobby()
	lobbies[tableModel] = lobby
	updatePrompt(tableModel)

	prompt.Triggered:Connect(function(player: Player)
		local inUse = matches[tableModel] ~= nil
		local busy = inGame(player) or isWaiting(player)
		local joined, token = TableFlow.join(lobby, player, seatCount(tableModel), needed(tableModel), inUse, busy)
		if not joined then
			return
		end
		-- Display only, so this player's prompt reads "Waiting for players" and they see the table's banners
		player:SetAttribute("JoinedTable", tableModel.Name)
		showNameTag(player, false)
		-- Testing alone: Coach takes every other seat, and the last one starts the countdown
		if not token and coachTable() and PhysicsTestAccess.canTest(player) then
			local count = 0
			while not token and #lobby.joined < seatCount(tableModel) do
				count += 1
				local coach = spawnCoach(tableModel, #lobby.joined + 1, count)
				if not table.find(lobby.joined, player) then
					-- They left while Coach was being made
					coach:Destroy()
					break
				end
				local _, coachToken =
					TableFlow.join(lobby, coach, seatCount(tableModel), needed(tableModel), false, false)
				token = coachToken
			end
		end
		updatePrompt(tableModel)
		if token then
			startGame(tableModel, token)
		end
	end)
end

function TableService.start()
	for _, child in workspace:WaitForChild("Tables"):GetChildren() do
		if child:IsA("Model") then
			child:WaitForChild("Felt")
			Balls.create(child)
			rack(child)
			makePrompt(child)
			for seat = 1, seatCount(child) do
				if not seatMarker(child, seat) then
					warn(
						`[{child.Name}] no seat marker {TableFlow.SEAT_NAMES[seat]}: run tools/BuildTable.luau and save the place`
					)
				end
			end
		end
	end

	-- A character respawned at a table keeps its name tag off. Each player's connection is dropped when they leave:
	-- Roblox only destroys a Player, and what's connected to it, with Workspace.PlayerCharacterDestroyBehavior on.
	local respawns: { [Player]: RBXScriptConnection } = {}
	local function watchCharacter(player: Player)
		if respawns[player] then
			return
		end
		respawns[player] = player.CharacterAdded:Connect(function(character: Model)
			character:WaitForChild("Humanoid")
			if inGame(player) or isWaiting(player) then
				showNameTag(player, false)
			end
		end)
	end
	Players.PlayerAdded:Connect(watchCharacter)
	for _, player in Players:GetPlayers() do
		watchCharacter(player)
	end

	Players.PlayerRemoving:Connect(function(player: Player)
		local respawn = respawns[player]
		if respawn then
			respawn:Disconnect()
			respawns[player] = nil
		end
		for tableModel, match in matches do
			local seat = table.find(match.seats, player)
			if seat and not match.left[seat] then
				endGame(tableModel, match)
			end
		end
		unjoin(player)
	end)

	-- A player's scripts are running: tell them about every game on, which they joined the server too late to hear.
	-- ponytail: no rate limit, since it only answers the player who asked.
	Remotes.ClientReady.OnServerEvent:Connect(function(player: Player)
		for _, match in matches do
			Match.showTo(match, player)
		end
	end)

	-- Rematch or Back to lobby on the end screen. Each player answers once per game, so it needs no rate limit.
	Remotes.Rematch.OnServerEvent:Connect(function(player: Player, rematch: unknown)
		for _, match in matches do
			if table.find(match.seats, player) then
				Match.vote(match, player, rematch)
			end
		end
	end)

	Remotes.LeaveTable.OnServerEvent:Connect(function(player: Player)
		for _, match in matches do
			local seat = table.find(match.seats, player)
			if seat then
				Match.leave(match, player)
				-- Off the table now, even while a 2v2 teammate plays on
				if match.left[seat] then
					showNameTag(player, true)
				end
			end
		end
		unjoin(player)
	end)
end

return TableService
