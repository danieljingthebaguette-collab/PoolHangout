--!strict
-- Which table this screen's shot controls and HUD follow: the one this player is in a game at, else the one they've
-- joined, else the nearest. Ball replays, sounds, the Turn arrow and the end screen work on every table at once; only
-- the controls and the HUD follow one.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local ActiveTable = {}

local player = Players.LocalPlayer
local tables: Instance? = nil
local current: Model? = nil
-- The table this player has a seat at in a game, from TurnStarted, until that game ends for them
local playingAt: Model? = nil
local listeners: { (Model) -> () } = {}

-- How far a table's felt is from this player's character, or infinity with no character
local function distance(tableModel: Model): number
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local felt = tableModel:FindFirstChild("Felt")
	if not (root and root:IsA("BasePart") and felt and felt:IsA("BasePart")) then
		return math.huge
	end
	return (root.Position - felt.Position).Magnitude
end

local function decide(): Model?
	if playingAt and playingAt.Parent then
		return playingAt
	end
	local joined = player:GetAttribute("JoinedTable")
	if type(joined) == "string" and tables then
		local joinedTable = tables:FindFirstChild(joined)
		if joinedTable and joinedTable:IsA("Model") then
			return joinedTable
		end
	end
	-- The nearest, but only clearly nearer than the one followed now, so standing between two doesn't flip-flop
	local best, bestDistance = current, if current then distance(current) - Config.Join.ActiveTableMargin else math.huge
	for _, child in (tables :: Instance):GetChildren() do
		if child:IsA("Model") and child:FindFirstChild("Felt") and distance(child) < bestDistance then
			best, bestDistance = child, distance(child)
		end
	end
	return best
end

local function update()
	local new = decide()
	if new and new ~= current then
		current = new
		for _, listener in listeners do
			task.spawn(listener, new)
		end
	end
end

-- The table followed now. Waits for the first one at the start.
function ActiveTable.get(): Model
	while not current do
		task.wait()
	end
	return current :: Model
end

-- Calls `listener` with each new table followed
function ActiveTable.onChanged(listener: (Model) -> ())
	table.insert(listeners, listener)
end

function ActiveTable.start()
	tables = workspace:WaitForChild("Tables")
	current = (tables :: Instance):WaitForChild("Table1") :: Model
	Remotes.TurnStarted.OnClientEvent:Connect(function(model: Model?, _: unknown, _: unknown, seats: { Instance }?)
		if not model then
			return
		elseif seats and table.find(seats, player) then
			playingAt = model
		elseif model == playingAt then
			playingAt = nil
		end
		update()
	end)
	player:GetAttributeChangedSignal("JoinedTable"):Connect(update)
	task.spawn(function()
		while true do
			update()
			task.wait(Config.Join.ActiveTableCheckSeconds)
		end
	end)
end

return ActiveTable
