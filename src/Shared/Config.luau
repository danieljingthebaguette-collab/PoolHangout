--!strict
-- Every tuning number lives here. Plain numbers, strings, booleans and lists of them, so Lune can load it too.
-- Distances are in studs, times in seconds, speeds in studs/s.
-- The 30-player server size is set in Studio's Game Settings, not by this file.
-- The models guide, docs/MODELS.md, repeats the table, ball, pocket and cue numbers: change both together.

local Config = {
	Table = {
		Length = 16,
		Width = 8,
		BallRadius = 0.22,
		CornerPocketMouth = 0.68,
		SidePocketMouth = 0.71,
		RackGap = 0.01, -- space between neighboring balls in the rack: 0 is a tight rack. 8 Ball Duels' is nearly tight
	},

	Physics = {
		-- Measured from 8 Ball Duels, frame by frame
		FullPowerSpeed = 25,
		BreakPower = 2.5, -- the break's full power, as a multiple of a normal shot's: about 62.5 studs/s, like 8 Ball Duels
		RollingSlowdown = 1.84, -- studs/s², so full power rolls about 170 studs, about 11 table lengths
		-- Extra slowdown per stud/s of speed: slowdown = RollingSlowdown + SpeedDrag × speed. Fast balls lose speed
		-- quicker while slow rolls barely change. 0 is a steady slowdown at every speed, like 8 Ball Duels.
		SpeedDrag = 0,
		RailBounce = 0.73, -- fraction of speed kept after a rail hit
		BallBounce = 0.94, -- a full hit leaves the cue ball (1 - BallBounce) / 2 of its speed: 3%, almost dead
		Follow = 0, -- forward roll a ball keeps after running into another: 0 stops it dead, 0.29 is natural roll
		-- A pull's speed, like 8 Ball Duels: even the softest shot leaves at SoftestShot of full speed (about 5 studs/s,
		-- rolling about half the table), and the rest of the speed rises with pull ^ PowerCurve
		SoftestShot = 0.21,
		PowerCurve = 2,
		StopSpeed = 0.032,
		TimeStep = 1 / 960,
		-- Ball radii the fastest ball may move in one step. A faster ball, like on the break, splits the step into
		-- smaller ones, so hits stay exact and nothing passes through a ball or rail at any speed.
		MaxStepTravel = 1 / 3,
		TimeCap = 20,
	},

	Shot = {
		ClockSeconds = 45,
		ClockWarningSeconds = 10,
		CancelRadius = 2.5, -- ball radii: the first stretch of a pull back, where letting go cancels
		-- Studs you pull straight back past the cancel zone for full power: 6.6 studs in all with the cancel zone, about
		-- 41% of the table length
		FullPullDistance = 6,
		MeterSpringSeconds = 0.15, -- how long the cue takes to slide back to rest from a full pull
		StrikeSeconds = 0.08, -- how long the cue takes to strike forward into the cue ball after you let go
		FollowThroughSeconds = 0.15, -- after the strike, how long the cue carries on forward while it fades out
		DropSeconds = 0.2, -- how long a ball takes to sink into a pocket. Keep under ResolveBufferSeconds
		DropDepth = 3, -- ball radii a pocketed ball sinks, enough to go fully under the felt
		-- If the server never starts a shot this screen already started, put the balls back after this long
		PredictTimeoutSeconds = 2,
		TimeoutsToRemove = 2, -- timeouts in a row that remove a player
		-- Physics steps the server runs per frame per table: 7.5× faster than the replay at 60 FPS, in slices small
		-- enough that 6 tables breaking at once fit in a frame (time it with tools/BenchPhysics.luau)
		ServerStepsPerFrame = 120,
		ResolveBufferSeconds = 0.25, -- extra wait after a shot's replay ends before the result is sent
		RequestCooldown = 0.5, -- the server ignores a player's shot requests closer together than this
		NiceShotLength = 0.5, -- "Nice shot!" for a pot off a rail, or one that crossed this share of the table's length
	},

	Aim = {
		-- The aim indicator's parts: the line from the cue ball to the circle where it first touches something, with a
		-- dot at the circle's center; the white line from that dot showing where the cue ball goes after the hit; and
		-- the yellow line from the hit ball showing where it goes
		ShowAimLine = true,
		ShowCueLine = true,
		ShowTargetLine = true,
		-- Ball radii. Each after-hit line is its longest times the share of the speed its ball gets, so a full hit
		-- draws a long yellow line and a short white one, but never shorter than LineMinLength.
		TargetLineLength = 6,
		CueLineLength = 6,
		LineMinLength = 1.5,
		DragDeadZone = 2, -- ball radii: a pointer this close to the cue ball doesn't turn the aim, where it would jump
		GrabRadius = 4, -- ball radii: on phones, an unlocked touch this close to the cue ball or the cue pulls instead of aiming
		PlaceGrabRadius = 3, -- ball radii: with ball in hand, clicking this close to the cue ball picks it up again
		PlaceRingRadius = 1.6, -- ball radii: the faint ring around the cue ball while it follows the mouse with ball in hand
		-- Ball radii: on the 8, the ring around the called pocket's middle, and how close a click must be to call one
		PocketPickRadius = 2.5,
		CueLength = 0.6, -- share of the table length
		CueThickness = 0.5, -- share of a ball's width
		CueTipGap = 1, -- ball radii between the cue ball and the cue's tip
		CuePullBack = 6, -- ball radii the cue slides back at a full pull
		CueFollowThrough = 2, -- ball radii the cue carries on past where the cue ball was, after the strike
		CueHeight = 4, -- ball radii above the felt, clear of the rails; from straight above it looks the same as ball height
		-- Live aim for everyone in the top-down view: how often the shooter's screen sends its aim, the closest together
		-- the server passes updates on, and how quickly other screens catch up with the latest one
		RelayRate = 10, -- updates a second
		RelayMinGap = 0.08, -- seconds
		RelaySmoothSeconds = 0.1,
	},

	-- Items (GAME_SPEC, Items): each player's item bar gives a random item every BarPoints, into the first empty slot
	Items = {
		BarPoints = 12,
		TurnPoints = 3, -- at the start of each of your turns; the break is the breaker's first turn
		OwnBallPoints = 4, -- for each of your own group's balls you sink, when the balls stop. On an open table, any legal pot
		-- For each ball the other side sinks that earns them OwnBallPoints, to the other side's player who shoots next
		OpponentBallPoints = 2,
		-- When true, an item your own sinks fill waits for the end of your turn, instead of arriving at once
		SinkItemsWaitForTurnEnd = false,
		Slots = 2,
		-- Power Shot: the meter goes past 100% up to this, at this many times FullPullDistance, and the shot leaves at
		-- this many times full-power speed
		PowerShotMax = 1.5,
		-- Blast Ball: at the cue ball's first hit, balls within BlastReach ball radii of the hit ball's center are
		-- pushed away from it, a touching ball at BlastPush of full-power speed, fading to nothing at the edge
		BlastReach = 6,
		BlastPush = 0.4,
		-- Oil Slick: a patch OilRadius ball radii round its spot (5 ball widths across), where balls slow at OilSlowdown
		-- of the normal rate. Patches don't stack.
		OilRadius = 5,
		OilSlowdown = 0.25,
		UseCooldown = 0.5, -- the server ignores a player's item uses closer together than this
		PickRadius = 2, -- ball radii: picking a ball for Freeze takes the nearest one within this of the click
		-- Every item a bar can give, each equally likely
		List = { "powerShot", "blastBall", "freeze", "oilSlick", "pocketBlock" },
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
		MaxNormalPitch = 0.97, -- leaving the top-down view, the normal camera never looks more nearly straight down than this
		-- Degrees, top to bottom. Narrow and high above, so balls near the table's edges don't look stretched.
		TopDownFieldOfView = 20,
		TopDownMargin = 1.3, -- studs of room the top-down view shows around the playing surface: the rails plus a little
		-- Degrees down: as a game starts, each player's normal camera turns to face the table from behind their seat
		SeatPitch = 25,
		EaseSeconds = 0.6, -- how long the camera takes to ease into or out of the top-down view, or between its heights
		WatchingHeight = 1.25, -- while it isn't your turn, the top-down view sits this many times higher
	},

	Join = {
		PromptHeight = 3, -- studs above the felt's top: the "Join table" prompt over each table's centre
		PromptDistance = 12, -- studs: how close a player must be to use it
		BannerDistance = 25, -- studs from a table's centre within which players see its banners, like "Starting..."
		-- The table a screen's shot controls and HUD follow, when this player isn't playing at or joined to one: the
		-- nearest, checked this often, and only once another is this many studs nearer than the one followed now
		ActiveTableCheckSeconds = 0.5,
		ActiveTableMargin = 2,
	},

	Timers = {
		CountdownSeconds = 3, -- the "Starting..." banner once every seat is taken, before the game starts
		TakeoverSeconds = 5,
		OpenSpotWaitSeconds = 15,
		EndScreenSeconds = 10, -- the end screen, before the table re-racks unless every player pressed Rematch
		FoulBannerSeconds = 3, -- the banner naming a foul and who has ball in hand
		NoticeSeconds = 3, -- short banners, like a start called off because someone left
		ResultSeconds = 5, -- the banner with who won and why, for anyone near the table who wasn't playing
	},

	-- The shot pose: on their turn the shooter glides to stand behind the cue ball, facing along the shot, on top of the
	-- table when that spot is over it (ShotStance), and steps off afterwards
	Stance = {
		Distance = 3, -- studs behind the cue ball, along the aim
		-- Studs to the left of the shot's line, so the cue passes the back (right) hand rather than through the head
		Side = 1,
		TableEdge = 1.1, -- studs the table reaches past its felt: the rails. Closer in than this, they stand on top
		TableStandHeight = 0.35, -- studs above the felt they stand on, level with the rails' tops
		Speed = 16, -- studs/s across, about a player's walking speed
		Climb = 12, -- studs/s up onto the table or down off it
		-- Studs a shooter standing beside the table keeps from its edge, aiming or stepping off after their turn, so no
		-- body hangs over the rails. The seat markers are this far out too (docs/MODELS.md)
		Clear = 2,
	},

	-- Coach, the bot opponent: for testing alone (see Debug.Coach), and later the tutorial's bot. Never in normal
	-- matches. How it plays, for Shared/Rules/ShotPicker.
	Coach = {
		-- Its turn, slow enough to follow, with its aim showing live: it waits, swings its aim onto the shot from AimSwing
		-- degrees off, draws the cue back, then shoots
		ReadySeconds = 1.5,
		AimSeconds = 1.5,
		PullSeconds = 1,
		AimSwing = 20,
		MaxCut = 70, -- degrees: the thinnest cut it tries
		AimError = 0.25, -- degrees: its aim is off by up to this much either way, so it misses now and then
		PowerMargin = 1.3, -- times the speed a pot needs, so the ball reaches the pocket with some to spare
		PlaceDistances = { 1, 1.8, 2.8 }, -- studs behind the ball it places the cue ball with ball in hand
	},

	-- Studio only; the server also checks RunService:IsStudio() before using these, except PhysicsTestLive.
	-- Each player's settings page: the defaults and the UI scale's range. Saved in their record (SaveData).
	Settings = {
		Music = 0.5, -- volume, 0 to 1
		Sound = 1,
		CameraGlide = true, -- the camera eases between views; off, it cuts
		ScreenShake = true,
		ControlHints = true,
		UiScale = 1,
		ShowStats = false, -- frame rate and ping, bottom left
		UiScaleMin = 0.8,
		UiScaleMax = 1.25,
		UiScaleStep = 0.05, -- 10 steps from min to max
	},

	-- The saved player record (SaveData, Server/PlayerData)
	Data = {
		StoreName = "PlayerData",
		KeyPrefix = "player_",
		Tries = 3, -- a load or save tries this many times...
		RetrySeconds = 2, -- ...this far apart
		AutosaveSeconds = 120, -- changed records are saved this often, and when the player leaves
		SaveCooldown = 0.5, -- the server takes a player's settings at most this often
	},

	Debug = {
		SoloTables = true,
		-- Coach takes every other seat when a tester (PhysicsTestAccess) alone in the server joins a table, instead of
		-- solo play. Like the test mode, it also works in published servers for the owner while PhysicsTestLive is on.
		Coach = true,
		LogShots = true,
		PhysicsTest = true, -- R racks Table1, the shot controls work on it, sliders tune the physics live
		-- Also runs the physics test mode in published servers, for the place's owner only. Off before launch.
		PhysicsTestLive = true,
		-- The physics test mode's live sliders: the Config value each one sets, its range and its step
		TestSliders = {
			{ group = "Physics", name = "RollingSlowdown", min = 1, max = 24, step = 0.01 },
			{ group = "Physics", name = "SpeedDrag", min = 0, max = 0.1, step = 0.001 },
			{ group = "Physics", name = "FullPowerSpeed", min = 8, max = 45, step = 0.5 },
			{ group = "Physics", name = "BreakPower", min = 1, max = 5, step = 0.1 },
			{ group = "Physics", name = "RailBounce", min = 0.3, max = 1, step = 0.01 },
			{ group = "Physics", name = "BallBounce", min = 0.5, max = 1, step = 0.01 },
			{ group = "Physics", name = "Follow", min = 0, max = 0.6, step = 0.01 },
			{ group = "Physics", name = "PowerCurve", min = 0.5, max = 3, step = 0.05 },
			{ group = "Table", name = "RackGap", min = 0, max = 0.08, step = 0.001 },
			-- These two rebuild Table1 to match, so they only move while the test mode has the table
			{ group = "Table", name = "CornerPocketMouth", min = 0.6, max = 1.2, step = 0.01 },
			{ group = "Table", name = "SidePocketMouth", min = 0.6, max = 1.3, step = 0.01 },
			{ group = "Shot", name = "FullPullDistance", min = 2, max = 10, step = 0.1 },
		},
	},
}

return Config
