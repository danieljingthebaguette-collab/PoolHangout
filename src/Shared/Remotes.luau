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
	-- server → clients: (table model, starting balls, shot, physics params) to replay
	ShotStarted = remote("ShotStarted"),
	-- server → clients: (table model, final balls)
	ShotResolved = remote("ShotResolved"),

	-- Physics test mode, Studio and the owner only (PhysicsTestAccess). client → server: ()
	TestRack = remote("TestRack"),
	-- client → server: (dirX, dirY, power), a direction in table space and power 0–1
	TestShoot = remote("TestShoot"),
	-- client → server: (slider name, value). The server keeps each slider's current value as an attribute on
	-- this remote, so every screen shows the same numbers, including players who join later.
	TestTune = remote("TestTune"),
}
