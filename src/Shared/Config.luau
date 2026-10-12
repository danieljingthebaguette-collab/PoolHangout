--!strict
-- Every tuning number lives here. Plain numbers, strings and booleans only, so Lune can load it too.
-- Distances are in studs, times in seconds, speeds in studs/s.
-- The 30-player server size is set in Studio's Game Settings, not by this file.

local Config = {
	Table = {
		Length = 10,
		Width = 5,
		BallRadius = 0.15,
		CornerPocketMouth = 0.75,
		SidePocketMouth = 0.8,
	},

	Physics = {
		FullPowerSpeed = 20,
		RollingSlowdown = 5, -- studs/s², so full power rolls 40 studs, about 4 table lengths
		RailBounce = 0.8, -- fraction of speed kept after a rail hit
		BallBounce = 0.95,
		Follow = 0.29, -- forward roll a ball keeps after running into another: 0 stops it dead, 0.29 is natural roll
		StopSpeed = 0.02,
		TimeStep = 1 / 480,
		TimeCap = 20,
	},

	Shot = {
		ClockSeconds = 45,
		ClockWarningSeconds = 10,
		MinPull = 0.05, -- shortest pull (share of the meter) that shoots, so twitches don't fire
		TimeoutsToRemove = 2, -- timeouts in a row that remove a player
	},

	Aim = {
		ShowAimLine = true,
		NudgeDegrees = 0.25,
		HoldStartSpeed = 15, -- degrees/s
		HoldMaxSpeed = 120, -- degrees/s
		HoldRampSeconds = 1,
	},

	Timers = {
		CountdownSeconds = 5,
		TakeoverSeconds = 5,
		OpenSpotWaitSeconds = 15,
		EndScreenSeconds = 10,
	},

	-- Studio only; the server also checks RunService:IsStudio() before using these.
	Debug = {
		SoloTables = true,
		LogShots = true,
	},
}

return Config
