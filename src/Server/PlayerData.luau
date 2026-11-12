--!strict
-- Each player's saved record (SaveData): loaded when they join and sent to their screen, kept up to date from their
-- settings page, and saved when it changed, every few minutes, when they leave and when the server shuts down. Every
-- DataStore call in the game is here, wrapped in pcall, tried a few times, and never holding up play.
--
-- If a player's record can't be loaded they play on the defaults, their screen is told saving is off, and nothing is
-- saved for them that session, so a hiccup can't wipe their real record.
-- ponytail: no session locking; a player in two servers at once could have one server's save overwrite the other's.
-- Add it with progression, when coins make that matter.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local SaveData = require(ReplicatedStorage.Shared.SaveData)

local PlayerData = {}

type Entry = { record: SaveData.Record, canSave: boolean, dirty: boolean, lastTake: number }

local entries: { [Player]: Entry } = {}
local store: DataStore? = nil
-- Saves under way, which shutting down waits for
local inFlight = 0

local function key(player: Player): string
	return Config.Data.KeyPrefix .. player.UserId
end

-- Runs `call` up to Config.Data.Tries times, Config.Data.RetrySeconds apart, until it works. Returns whether it did,
-- and its result.
local function try(call: () -> any): (boolean, any)
	local ok, result = false, nil
	for attempt = 1, Config.Data.Tries do
		ok, result = pcall(call)
		if ok then
			break
		elseif attempt < Config.Data.Tries then
			task.wait(Config.Data.RetrySeconds)
		end
	end
	return ok, result
end

local function load(player: Player)
	local ok, raw = false, nil
	if store then
		local dataStore = store
		ok, raw = try(function()
			return dataStore:GetAsync(key(player))
		end)
	end
	if not player.Parent then
		return
	end
	if not ok then
		warn(`[PlayerData] couldn't load {player.Name}'s record, so nothing is saved for them this session: {raw}`)
	end
	local entry =
		{ record = if ok then SaveData.migrate(raw) else SaveData.new(), canSave = ok, dirty = false, lastTake = 0 }
	entries[player] = entry
	Remotes.PlayerDataLoaded:FireClient(player, entry.record.settings, entry.canSave)
end

-- Writes a player's record if it changed. Fields another server added since are kept; the settings are this one's.
local function save(player: Player, entry: Entry)
	local dataStore = store
	if not (dataStore and entry.canSave and entry.dirty) then
		return
	end
	entry.dirty = false
	inFlight += 1
	local settings = entry.record.settings
	local ok, problem = try(function()
		return dataStore:UpdateAsync(key(player), function(old: unknown)
			local merged = SaveData.migrate(old)
			merged.settings = settings
			return merged
		end)
	end)
	inFlight -= 1
	if not ok then
		-- Tried again at the next autosave, or when they leave
		entry.dirty = true
		warn(`[PlayerData] couldn't save {player.Name}'s record: {problem}`)
	end
end

-- The player's settings page changed: kept once a second at most, cleaned of anything out of range
local function takeSettings(player: Player, raw: unknown)
	local entry = entries[player]
	local now = os.clock()
	if not entry or now - entry.lastTake < Config.Data.SaveCooldown then
		return
	end
	entry.lastTake = now
	entry.record.settings = SaveData.cleanSettings(raw)
	entry.dirty = true
end

function PlayerData.start()
	local ok, found = pcall(DataStoreService.GetDataStore, DataStoreService, Config.Data.StoreName)
	store = if ok then found else nil
	Players.PlayerAdded:Connect(function(player: Player)
		task.spawn(load, player)
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(load, player)
	end
	Players.PlayerRemoving:Connect(function(player: Player)
		local entry = entries[player]
		entries[player] = nil
		if entry then
			save(player, entry)
		end
	end)
	Remotes.SaveSettings.OnServerEvent:Connect(takeSettings)
	task.spawn(function()
		while true do
			task.wait(Config.Data.AutosaveSeconds)
			for player, entry in entries do
				task.spawn(save, player, entry)
			end
		end
	end)
	-- Shutting down: save everyone still here, all at once, and wait for every save under way, leavers' included
	game:BindToClose(function()
		for player, entry in entries do
			task.spawn(save, player, entry)
		end
		task.wait()
		while inFlight > 0 do
			task.wait()
		end
	end)
end

return PlayerData
