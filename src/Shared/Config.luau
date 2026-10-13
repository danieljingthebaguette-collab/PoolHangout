--!strict
-- Every tuning number lives here. Plain numbers, strings, booleans and lists of them, so Lune can load it too.
-- Distances are in studs, times in seconds, speeds in studs/s.
-- The 30-player server size is set in Studio's Game Settings, not by this file.
-- The modeler's brief, docs/MODELS.md, repeats the table, ball, pocket and cue numbers: change both together.

local Config = {
	Table = {
		Length = 16,
		Width = 8,
		BallRadius = 0.24,
		CornerPocketMouth = 1.0,
		SidePocketMouth = 1.1,
		RackGap = 0.025, -- space between neighboring balls in the rack: 0 is a tight rack
	},

	Physics = {
		FullPowerSpeed = 30,
		RollingSlowdown = 2.3, -- studs/s², so full power rolls about 196 studs, about 12 table lengths
		RailBounce = 0.7, -- fraction of speed kept after a rail hit
		BallBounce = 0.9,
		Follow = 0.3, -- forward roll a ball keeps after running into another: 0 stops it dead, 0.29 is natural roll
		PowerCurve = 1.2, -- shot speed is pull ^ PowerCurve of full power: 1 is even, above 1 gives soft shots more pull
		StopSpeed = 0.032,
		TimeStep = 1 / 960,
		TimeCap = 20,
	},

	Shot = {
		ClockSeconds = 45,
		ClockWarningSeconds = 10,
		CancelRadius = 2.5, -- ball radii: the cancel zone around where you press to pull. Letting go back inside it cancels
		FullPullDistance = 0.25, -- share of the table length you drag past the cancel zone for full power
		MeterSpringSeconds = 0.15, -- how long the cue takes to slide back to rest from a full pull
		StrikeSeconds = 0.08, -- how long the cue takes to strike forward into the cue ball after you let go
		FollowThroughSeconds = 0.15, -- after the strike, how long the cue carries on forward while it fades out
		DropSeconds = 0.2, -- how long a ball takes to sink into a pocket. Keep under ResolveBufferSeconds
		DropDepth = 3, -- ball radii a pocketed ball sinks, enough to go fully under the felt
		-- If the server never starts a shot this screen already started, put the balls back after this long
		PredictTimeoutSeconds = 2,
		TimeoutsToRemove = 2, -- timeouts in a row that remove a player
		ServerStepsPerFrame = 480, -- physics steps the server runs per frame: far ahead of the replay, about 1 ms of work
		ResolveBufferSeconds = 0.25, -- extra wait after a shot's replay ends before the result is sent
	},

	Aim = {
		ShowAimLine = true, -- the aim indicator's line from the cue ball and the circle where it first touches something
		ShowTargetLine = true, -- the aim indicator's short line showing which way the hit ball goes
		TargetLineLength = 6, -- ball radii
		DragDeadZone = 2, -- ball radii: a pointer this close to the cue ball doesn't turn the aim, where it would jump
		GrabRadius = 4, -- ball radii: on phones, an unlocked touch this close to the cue ball or the cue pulls instead of aiming
		CueLength = 0.6, -- share of the table length
		CueThickness = 0.5, -- share of a ball's width
		CueTipGap = 1, -- ball radii between the cue ball and the cue's tip
		CuePullBack = 6, -- ball radii the cue slides back at a full pull
		CueFollowThrough = 2, -- ball radii the cue carries on past where the cue ball was, after the strike
		CueHeight = 4, -- ball radii above the felt, clear of the rails; from straight above it looks the same as ball height
	},

	-- Placeholder sounds, the free "Pool Table SFX" set by m6oru on the Creator Store. Final ones come in Phase 4.
	Sounds = {
		CueStrike = "rbxassetid://99615500877700",
		BallHit = "rbxassetid://117508975923124",
		BallHitLight = "rbxassetid://80983335100955",
		RailHit = "rbxassetid://76430601675724",
		Pocket = "rbxassetid://117731873975344",
		Volume = 1, -- at a full-power hit; softer hits are quieter
		LightHitShare = 0.15, -- ball hits slower than this share of full-power speed use the light clip
		MaxPerFrame = 4, -- only the loudest few sounds play in a single frame, so a break isn't a wall of clicks
		FullVolumeDistance = 10, -- studs: closer than this, sounds play at full volume
		SilentDistance = 60, -- studs: sounds fade to nothing this far away, so each table sounds like its own
	},

	Camera = {
		-- Degrees, top to bottom. Narrow and high above, so balls near the table's edges don't look stretched.
		TopDownFieldOfView = 20,
		TopDownMargin = 1.3, -- studs of room the top-down view shows around the playing surface: the rails plus a little
	},

	Timers = {
		CountdownSeconds = 5,
		TakeoverSeconds = 5,
		OpenSpotWaitSeconds = 15,
		EndScreenSeconds = 10,
	},

	-- Studio only; the server also checks RunService:IsStudio() before using these, except PhysicsTestLive.
	Debug = {
		SoloTables = true,
		LogShots = true,
		PhysicsTest = true, -- R racks Table1, the shot controls work on it, sliders tune the physics live
		-- Also runs the physics test mode in published servers, for the place's owner only. Off before launch.
		PhysicsTestLive = true,
		-- The physics test mode's live sliders: the Config value each one sets, its range and its step
		TestSliders = {
			{ group = "Physics", name = "RollingSlowdown", min = 1.6, max = 24, step = 0.1 },
			{ group = "Physics", name = "FullPowerSpeed", min = 8, max = 64, step = 0.5 },
			{ group = "Physics", name = "RailBounce", min = 0.3, max = 1, step = 0.01 },
			{ group = "Physics", name = "BallBounce", min = 0.5, max = 1, step = 0.01 },
			{ group = "Physics", name = "Follow", min = 0, max = 0.6, step = 0.01 },
			{ group = "Physics", name = "PowerCurve", min = 0.5, max = 3, step = 0.05 },
			{ group = "Table", name = "RackGap", min = 0, max = 0.08, step = 0.001 },
		},
	},
}

return Config
