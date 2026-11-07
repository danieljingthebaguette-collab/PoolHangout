--!strict
-- Who sits in a game's seat: a player, or Coach, the bot, whose seat holds its character model. These helpers let the
-- code that shows a seat work the same either way.

export type Seat = Player | Model

local Seat = {}

-- A player's display name, or the bot's name
function Seat.name(seat: Seat): string
	return if seat:IsA("Player") then seat.DisplayName else seat.Name
end

-- A player's character, or the bot's model itself
function Seat.character(seat: Seat): Model?
	return if seat:IsA("Player") then seat.Character else seat
end

-- The user id for a player's avatar picture, or nil for the bot
function Seat.userId(seat: Seat): number?
	return if seat:IsA("Player") then seat.UserId else nil
end

function Seat.isBot(seat: Seat): boolean
	return not seat:IsA("Player")
end

return Seat
