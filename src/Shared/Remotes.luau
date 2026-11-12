--!strict
-- Creates (server) or finds (client) every remote. Remote names appear nowhere else.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local folder: Instance
if RunService:IsServer() then
	folder = Instance.new("Folder")
	folder.Name = "Remotes"
	folder.Parent = ReplicatedStorage
else
	folder = ReplicatedStorage:WaitForChild("Remotes")
end

local function remote(name: string): RemoteEvent
	if RunService:IsServer() then
		local event = Instance.new("RemoteEvent")
		event.Name = name
		event.Parent = folder
		return event
	end
	return folder:WaitForChild(name) :: RemoteEvent
end

-- For updates that can be dropped, like live aim: the next one replaces any that's lost
local function unreliable(name: string): UnreliableRemoteEvent
	if RunService:IsServer() then
		local event = Instance.new("UnreliableRemoteEvent")
		event.Name = name
		event.Parent = folder
		return event
	end
	return folder:WaitForChild(name) :: UnreliableRemoteEvent
end

return {
	-- client → server: (dirX, dirY, power, cueX?, cueY?, calledPocket?), a direction in table space and power 0–1 (up to
	-- Config.Items.PowerShotMax while the shooter's Power Shot is on),
	-- with ball in hand where the shooter placed the cue ball (nil leaves it where it is, and is the only choice
	-- without it), and on the 8 the pocket id called for it
	RequestShot = remote("RequestShot"),
	-- server → clients: (table model, shooter, ball in hand, seats, call pocket, groups, balls down, clock ends at),
	-- ball in hand being true when the shooter may place the cue ball anywhere, seats the game's players in turn order
	-- (A1, B1, A2, B2, so odd seats are side A, and a 2v2 player who left shows as their teammate), call pocket true
	-- when the shooter is on the 8, groups each side's group by "A" and "B" (empty while the table is open), balls down
	-- the ids of the balls pocketed, and clock ends at when the shooter's shot clock runs out, in the server's time
	-- (workspace:GetServerTimeNow()). Seats with no shooter: the game is over and its result is showing, so nobody
	-- shoots. No seats means no game is on the table: the game just ended, the player left it, or the physics test mode
	-- is saying whether testers have ball in hand.
	TurnStarted = remote("TurnStarted"),
	-- server → clients: (table model, text, seconds), a message for everyone at the table, like a foul, or who won for
	-- anyone near the table who wasn't playing
	Banner = remote("Banner"),
	-- server → each player still in a game that's just been decided: (table model, who won and why, winning side, rows,
	-- can rematch, closes at), rows being each seat's { player, side, shots, kept, sunk, bestRun, fouls } in turn order,
	-- can rematch false once someone pressed Leave, and closes at the end screen's close time in the server's time
	GameOver = remote("GameOver"),
	-- client → server: (rematch), true for Rematch and false for Back to lobby, once per game. server → each player still
	-- in the game: (table model, answers), the list of { player, rematch } answers so far
	Rematch = remote("Rematch"),
	-- client → server: (), once this player's scripts are listening. The server answers with TurnStarted for every game
	-- on, and the physics test mode's ball in hand, since what it fired before then may not have reached them.
	ClientReady = remote("ClientReady"),
	-- server → client: (settings, saving), this player's saved settings (SaveData.Settings) once their record is
	-- loaded, and whether changes will be saved: false when it couldn't be loaded, so they last this session only
	PlayerDataLoaded = remote("PlayerDataLoaded"),
	-- client → server: (settings), the whole settings page after a change. The server cleans every field
	-- (SaveData.cleanSettings) and takes one at most every Config.Data.SaveCooldown.
	SaveSettings = remote("SaveSettings"),
	-- client → server: (), the Leave button. Off the table this player joined, calling off its start, or out of
	-- their game: the server decides which.
	LeaveTable = remote("LeaveTable"),
	-- client → server, unreliable: (aim, pull, held, placing, cueX?, cueY?, pocket?), the shooter's live aim at most
	-- Config.Aim.RelayRate times a second: the angle in table space, the pull 0–1, whether the aim is locked or
	-- pulling, whether the cue ball is following the mouse with ball in hand, where they've moved it, and on the 8 the
	-- pocket called. Display only: the shot is checked again when it's asked for.
	AimUpdate = unreliable("AimUpdate"),
	-- server → clients, unreliable: (table model, aim), that shooter's live aim as TableFlow.AimState, to everyone but
	-- the shooter, so anyone in the top-down view sees their cue and aim indicator move
	AimRelay = unreliable("AimRelay"),
	-- client → server: (slot, target?), the shooter uses the item in slot 1 or 2 before their shot, with for Freeze a
	-- ball id, for Oil Slick a spot { x, y } in table space, and for Pocket Block a pocket id
	UseItem = remote("UseItem"),
	-- server → clients: (table model, seat, item, target), an item was used, for the big name and its effect
	ItemUsed = remote("ItemUsed"),
	-- server → the shooter: (table model, slot, why), their item's target was turned down, with why in words, like
	-- "Can't freeze the 8"
	ItemRefused = remote("ItemRefused"),
	-- server → clients: (table model, bars, pops, effects), each seat's item bar in turn order as Items.Bar (its points
	-- and its slots, each an item name or false when empty), pops the { seat, points } earned since the last message,
	-- for each bar's "+4", and the effects on the table now (Simulate.Effects: lists of frozen ball ids, blocked pocket
	-- ids and oil spots { x, y } in table space, and blast). No bars: no game is on, so no bars, slots or effects show.
	ItemsChanged = remote("ItemsChanged"),
	-- server → clients: (table model, starting balls, shot, physics params, effects) to replay, effects being what items
	-- change about the shot (Simulate.Effects)
	ShotStarted = remote("ShotStarted"),
	-- server → clients: (table model, final balls)
	ShotResolved = remote("ShotResolved"),
	-- server → clients: (table model, pocket id), the shooter's pot off a rail or across the table, for "Nice shot!"
	-- over that pocket
	NiceShot = remote("NiceShot"),

	-- Physics test mode, Studio and the owner only (PhysicsTestAccess). client → server: ()
	TestRack = remote("TestRack"),
	-- client → server: (dirX, dirY, power, cueX?, cueY?), like RequestShot
	TestShoot = remote("TestShoot"),
	-- client → server: (slider name, value). The server keeps each slider's current value as an attribute on
	-- this remote, so every screen shows the same numbers, including players who join later. server → client: ()
	-- when it turned that player's change down, like a pocket size during a game, so their panel shows the kept values.
	TestTune = remote("TestTune"),
	-- client → server: (item name), puts that item in the sender's first empty slot in their game
	GiveItem = remote("GiveItem"),
	-- client → server: (). The server prints the sliders' values, so they show in Studio's Output in any playtest
	-- and under Server in a published server's console (F9)
	TestPrint = remote("TestPrint"),
}
