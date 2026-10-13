--!strict
-- Who may use the physics test mode: everyone in Studio, and in a published server only the place's owner,
-- while Config.Debug.PhysicsTestLive is on. The server checks it on every test request, so another player's
-- client can't use the test remotes even if it fires them.

local RunService = game:GetService("RunService")

local Config = require(script.Parent.Config)

local PhysicsTestAccess = {}

-- May yield on a group-owned place, which asks Roblox for the player's rank the first time
function PhysicsTestAccess.canTest(player: Player): boolean
	if not Config.Debug.PhysicsTest then
		return false
	end
	if RunService:IsStudio() then
		return true
	end
	if not Config.Debug.PhysicsTestLive then
		return false
	end
	if game.CreatorType == Enum.CreatorType.User then
		return player.UserId == game.CreatorId
	end
	-- 255 is a group's owner
	local ok, rank = pcall(player.GetRankInGroup, player, game.CreatorId)
	return ok and rank == 255
end

return PhysicsTestAccess
