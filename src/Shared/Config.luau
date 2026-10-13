--!strict
-- Every tuning number lives here. Plain numbers, strings, booleans and lists of them, so Lune can load it too.
-- Distances are in studs, times in seconds, speeds in studs/s.
-- The 30-player server size is set in Studio's Game Settings, not by this file.
-- The modeler's brief, docs/MODELS.md, repeats the table, ball, pocket and cue numbers: change both together.

local Config = {
	Table = {
		Length = 10,
		Width = 5,
		BallRadius = 0.15,
		CornerPocketMouth = 0.75,
		SidePocketMouth = 0.8,
		RackGap = 0, -- space between neighboring balls in the rack: 0 is a tight rack
	},

	Physics = {
		FullPowerSpeed = 20,
		RollingSlowdown = 1.5, -- studs/s², so full power rolls about 133 studs, about 13 table lengths
		RailBounce = 0.8, -- fraction of speed kept after a rail hit
		BallBounce = 0.9,
		Follow = 0.25, -- forward roll a ball keeps after running into another: 0 stops it dead, 0.29 is natural roll
		StopSpeed = 0.02,
		TimeStep = 1 / 960,
		TimeCap = 20,
	},

	Shot = {
		ClockSeconds = 45,
		ClockWarningSeconds = 10,
		MinPull = 0.05, -- shortest pull (share of a full pull) that shoots, so twitches don't fire
		FullPullDistance = 0.25, -- share of the table length you drag for full power, in any direction
		MeterSpringSeconds = 0.15, -- how long the cue takes to slide back to rest from a full pull
		TimeoutsToRemove = 2, -- timeouts in a row that remove a player
		ServerStepsPerFrame = 480, -- physics steps the server runs per frame: far ahead of the replay, about 1 ms of work
		ResolveBufferSeconds = 0.25, -- extra wait after a shot's replay ends before the result is sent
	},

	Aim = {
		ShowAimLine = true, -- the aim indicator's line from the cue ball and the circle where it first touches something
		ShowTargetLine = true, -- the aim indicator's short line showing which way the hit ball goes
		TargetLineLength = 6, -- ball radii
		NudgeDegrees = 0.25,
		HoldStartSpeed = 15, -- degrees/s
		HoldMaxSpeed = 120, -- degrees/s
		HoldRampSeconds = 1,
		HoldDelaySeconds = 0.25, -- a key held this long starts turning, so a tap is only a nudge
		DragDeadZone = 2, -- ball radii: a pointer this close to the cue ball doesn't turn the aim, where it would jump
		GrabRadius = 4, -- ball radii: a touch this close to the cue ball or the cue pulls for power instead of aiming
		CueLength = 0.6, -- share of the table length
		CueThickness = 0.5, -- share of a ball's width
		CueTipGap = 1, -- ball radii between the cue ball and the cue's tip
		CuePullBack = 6, -- ball radii the cue slides back at a full pull
		CueHeight = 4, -- ball radii above the felt, clear of the rails; from straight above it looks the same as ball height
	},

	Camera = {
		-- Degrees, top to bottom. Narrow and high above, so balls near the table's edges don't look stretched.
		TopDownFieldOfView = 20,
		TopDownMargin = 1.15, -- the top-down view shows the table plus this share of room around it
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
		PhysicsTest = true, -- R racks Table1, the shot controls work on it, sliders tune the physics live
		-- The physics test mode's live sliders: the Config value each one sets, its range and its step
		TestSliders = {
			{ group = "Physics", name = "RollingSlowdown", min = 1, max = 15, step = 0.1 },
			{ group = "Physics", name = "FullPowerSpeed", min = 5, max = 40, step = 0.5 },
			{ group = "Physics", name = "RailBounce", min = 0.3, max = 1, step = 0.01 },
			{ group = "Physics", name = "BallBounce", min = 0.5, max = 1, step = 0.01 },
			{ group = "Physics", name = "Follow", min = 0, max = 0.6, step = 0.01 },
			{ group = "Table", name = "RackGap", min = 0, max = 0.05, step = 0.001 },
		},
	},
}

return Config
