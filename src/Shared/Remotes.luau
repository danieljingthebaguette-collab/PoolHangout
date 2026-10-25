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

return {
	-- client → server: (dirX, dirY, power, cueX?, cueY?, calledPocket?), a direction in table space and power 0–1,
	-- with ball in hand where the shooter placed the cue ball (nil leaves it where it is, and is the only choice
	-- without it), and on the 8 the pocket id called for it
	RequestShot = remote("RequestShot"),
	-- server → clients: (table model, shooter, ball in hand, seats, call pocket), ball in hand being true when the
	-- shooter may place the cue ball anywhere, seats the game's players in turn order, and call pocket true when the
	-- shooter is on the 8. Seats with no shooter: the game is over and its result is showing, so nobody shoots. No
	-- seats means no game is on the table: the game just ended, or the physics test mode is saying whether testers
	-- have ball in hand.
	TurnStarted = remote("TurnStarted"),
	-- server → clients: (table model, text, seconds), a message for everyone at the table, like a foul or the winner
	Banner = remote("Banner"),
	-- server → clients: (table model, starting balls, shot, physics params) to replay
	ShotStarted = remote("ShotStarted"),
	-- server → clients: (table model, final balls)
	ShotResolved = remote("ShotResolved"),

	-- Physics test mode, Studio and the owner only (PhysicsTestAccess). client → server: ()
	TestRack = remote("TestRack"),
	-- client → server: (dirX, dirY, power, cueX?, cueY?), like RequestShot
	TestShoot = remote("TestShoot"),
	-- client → server: (slider name, value). The server keeps each slider's current value as an attribute on
	-- this remote, so every screen shows the same numbers, including players who join later. server → client: ()
	-- when it turned that player's change down, like a pocket size during a game, so their panel shows the kept values.
	TestTune = remote("TestTune"),
	-- client → server: (). The server prints the sliders' values, so they show in Studio's Output in any playtest
	-- and under Server in a published server's console (F9)
	TestPrint = remote("TestPrint"),
}
