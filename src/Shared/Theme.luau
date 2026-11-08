--!strict
-- Colors, fonts and UI sizes for everything built in code. docs/STYLE.md describes the look they make.

local YELLOW = Color3.fromRGB(245, 196, 30)
local BLUE = Color3.fromRGB(30, 70, 190)
local RED = Color3.fromRGB(200, 35, 35)
local PURPLE = Color3.fromRGB(100, 40, 150)
local ORANGE = Color3.fromRGB(240, 120, 30)
local GREEN = Color3.fromRGB(20, 120, 60)
local MAROON = Color3.fromRGB(120, 25, 35)

local CREAM = Color3.fromRGB(246, 239, 224)
local INK = Color3.fromRGB(36, 28, 22)
local NEAR_BLACK = Color3.fromRGB(32, 26, 22)
local ACCENT = Color3.fromRGB(255, 196, 46) -- sunny gold

local Theme = {
	-- Bold condensed, for every bit of HUD text. It's a Font, so set it as FontFace.
	Font = Font.new(Font.fromEnum(Enum.Font.RobotoCondensed).Family, Enum.FontWeight.Bold),
	TextSize = 18,

	Colors = {
		Panel = CREAM, -- cards and panels
		Text = INK, -- text on cards and accent buttons, and the cards' corner brackets and dot texture
		Dark = NEAR_BLACK, -- dark boxes: key boxes, the % readout, the tray
		DarkText = CREAM, -- text and corner brackets on dark boxes
		Button = ACCENT, -- bright accent buttons
		LeaveButton = Color3.fromRGB(255, 138, 118), -- coral, for leaving a table
		ClockWarning = Color3.fromRGB(255, 138, 118), -- coral, the shot clock's last seconds
		TurnArrow = ACCENT, -- the "Turn" card over the shooter's head
		LobbyButton = NEAR_BLACK, -- the end screen's Back to lobby, with DarkText, so gold Rematch leads
		WinnerRow = ACCENT, -- behind the winners' lines on the end screen
		Coach = Color3.fromRGB(150, 150, 150), -- Coach's plain grey body
		Fill = ACCENT, -- the power meter's and the sliders' fill
		Track = Color3.fromRGB(214, 200, 176), -- a slider's bar, on a cream card
		Cue = Color3.fromRGB(214, 170, 112), -- light maple
		AimLine = Color3.fromRGB(255, 255, 255),
		TargetLine = Color3.fromRGB(255, 214, 60), -- the aim indicator's yellow line from the hit ball
		AimOutline = Color3.fromRGB(24, 18, 14), -- the thin dark edge round every part of the aim indicator
		CalledPocket = ACCENT, -- the ring round the pocket called for the 8
		TurnGlow = ACCENT, -- the glow round the top bar card whose turn it is, and the ring round its shooter's avatar
		SunkBall = Color3.fromRGB(176, 166, 152), -- a sunk ball on a top bar card, greyed out on the cream
		BallMark = Color3.fromRGB(245, 242, 230), -- the white on the placeholder balls: stripes and number dots
		CueBallMark = Color3.fromRGB(200, 35, 35),
		BallShadow = Color3.fromRGB(10, 20, 40),
	},

	Ui = {
		Padding = 8,
		Corner = 4, -- cards and buttons are nearly square
		ButtonHeight = 44, -- big enough for a thumb
		PanelWidth = 240,
		SliderBar = 6,
		LargeTextSize = 24, -- the player's name, the % readout and the gear
		BracketLength = 10, -- the thin corner brackets on cards
		BracketThickness = 2,
		BracketInset = 4,
		DotSize = 10, -- text size of the faint dot texture on cream cards, which sets the dots about 12 px apart
		DotTransparency = 0.75,
		HintHeight = 28, -- a control hint on the bottom right: a label and its key box
		HintRows = 2, -- the most control hints shown at once, so the bottom right keeps room for them
		MeterReserve = 72, -- screen width the top-down view keeps clear on the left for the power meter
		MeterTrack = 24, -- width of the power meter
		MeterHeight = 0.5, -- share of the screen's height
		TrayReserve = 72, -- screen width the top-down view keeps clear on the right for the sunk-ball tray
		TrayWidth = 36,
		CardWidth = 300, -- each side's card in the top bar: room for two avatars and a group's eight balls in 2v2
		CardHeight = 56,
		TopBarGap = 120, -- the space between the top bar's two cards, kept for the shot clock
		ClockWidth = 96, -- the shot clock's dark box in that gap, as tall as the cards
		ClockWarningTextSize = 34, -- the shot clock's seconds in its last stretch, bigger than LargeTextSize
		TurnArrowWidth = 64, -- the "Turn" card over the shooter's head, in pixels whatever the distance; the narrowest
		-- it gets, since it widens to fit the shooter's name
		TurnArrowHeight = 42, -- two lines: "Turn", then the shooter's name
		TurnArrowNameSize = 15, -- text size of the name under "Turn"
		TurnArrowMaxWidth = 200, -- room for the longest name; only the card and its point show
		TurnArrowPoint = 10, -- the point under the card, aiming at the head
		TurnArrowStuds = 2.7, -- studs above the head's center
		EndScreenWidth = 520, -- the end screen's card, in the middle of the screen
		EndRowHeight = 28, -- each line of its stats table, and its status and countdown lines
		EndNameShare = 0.4, -- share of a stats line the player's name gets; the four numbers split the rest
		EndButtonWidth = 160, -- Rematch and Back to lobby
		WinnerRowTransparency = 0.6,
		CardBallSize = 14, -- the group's ball icons on a top bar card
		TurnGlow = 3, -- pixels, the gold outline on the card whose turn it is and the ring round its shooter's avatar
		TurnHalo = 6, -- pixels the soft gold glow reaches out round that card
		TurnHaloTransparency = 0.55,
		HudTransparency = 0.2, -- the control hints' label boxes, a touch see-through over the table
		AimLineThickness = 2, -- pixels, for the aim indicator's lines and circle
		AimDotSize = 6, -- pixels, the dot at the aim circle's center
		AimOutline = 1, -- pixels of dark edge round the aim indicator's lines, circle and dot, so they read on any ball
		AimFaintTransparency = 0.6, -- the aim indicator while aiming or about to cancel; solid while locked
		PocketRingThickness = 3, -- pixels, the ring round the pocket called for the 8
		BannerWidth = 560, -- the banner under the top bar naming a foul or the winner
		LeaveButtonWidth = 80, -- the Leave button top right, and the Yes and No under its question
		AskWidth = 360, -- the card asking "Leave and lose this game?"
		BannerHeight = 44,
		LockButtonWidth = 80, -- the phones' Lock button, beside the power meter
		TestButtonWidth = 80, -- the physics test panel's Test button, beside the settings gear
		-- Under each avatar on a top bar card: its seat's 2 item slots side by side, as wide as the avatar together, and
		-- the item bar under them. Placeholder looks until the GUI pass.
		ItemStripGap = 3, -- between the card and the slots
		ItemSlotGap = 2, -- between the two slots, and between the slots and the bar
		ItemSlotTextSize = 12, -- the short name on a slot, until slots get icons
		ItemBarHeight = 4,
		ItemPopTextSize = 16, -- the "+4" that rises from a bar when it fills...
		ItemPopRise = 16, -- ...this many pixels...
		ItemPopSeconds = 0.8, -- ...as it fades out
	},

	-- The placeholder balls' markings, so you can see them roll, in ball radii. Solids, the 8 and the cue ball
	-- get a dot on top and bottom, stripes a band of color around a white ball.
	BallMarks = {
		DotDiameter = 0.8,
		DotThickness = 0.1, -- thick enough that the dot's edge sinks into the ball while its face sits just above it
		DotRaise = 0.01, -- how far the dot's face sits above the ball's surface
		BandWidth = 1,
		BandDiameter = 1.96, -- a little under the ball's 2, so the band and the ball don't flicker where they meet
	},

	-- The soft shadow under each ball, in ball radii: a little down and right of the ball, as if lit from above left
	BallShadow = {
		Diameter = 2.1,
		Offset = 0.25,
		Transparency = 0.55,
	},

	-- The hit effects on the table (Effects.luau). Sizes, distances and heights are in ball radii, so they scale
	-- with the table; heights are above the felt and stay under the cue's (Config.Aim.CueHeight).
	Effects = {
		SparkShare = 0.5, -- ball and rail hits softer than this share of full-power speed get no sparks
		SparkMinCount = 3, -- ball-hit sparks at SparkShare...
		SparkMaxCount = 5, -- ...up to a full-power hit
		SparkRailMinCount = 4, -- rail hits never get fewer
		-- A hit faster than full power is the break (it leaves at Config.Physics.BreakPower): more, bigger sparks
		SparkBreakCount = 6,
		SparkColors = { ACCENT, CREAM }, -- taken in turn, so each burst mixes gold and cream
		SparkOutlineColor = INK, -- a block just under each spark, so they read on the white and yellow balls
		-- Squat blocks, never longer than 2:1. A ball width is 2 ball radii.
		SparkLength = 0.9,
		SparkThickness = 0.5, -- across and tall
		SparkBreakLength = 1.4,
		SparkBreakThickness = 0.8,
		SparkOutline = 0.12, -- the ink edge round each spark, about 2 px from the top-down view at 1080p
		SparkHeight = 1, -- where they start: ball center height
		SparkRise = 0.8, -- how much higher they end
		SparkReach = 2.4, -- how far they fly
		SparkBreakReach = 4,
		-- Degrees off the line between the two balls: sparks squirt out sideways from where they touch, clear of both
		BallSprayMin = 55,
		BallSprayMax = 125,
		-- Degrees off the line straight out from the cushion: sparks squirt along it, clear of the ball
		RailSprayMin = 35,
		RailSprayMax = 85,
		SparkSeconds = 0.25,
		-- The ring that pops out round a pocket a ball drops into: it grows and thins as it fades, never holding still
		PopColor = CREAM, -- never gold, so it isn't mistaken for the called-pocket ring
		PopStartScale = 1, -- times the pocket's mouth...
		PopEndScale = 1.7, -- ...growing to this
		PopLineStart = 5, -- screen pixels across its line...
		PopLineEnd = 1, -- ...thinning to this
		PopHeight = 1.8, -- just over the corner plates, so they never cover it
		PopTransparency = 0.1, -- at the start; it fades to nothing
		PopSeconds = 0.25,
		-- Your balls when your turn starts: a flat ring on the felt round each, that grows and fades out once. It
		-- follows its ball if you shoot before it's done and goes when the ball drops; the balls keep their own colors
		PulseSeconds = 2,
		PulseColor = ACCENT, -- flat sunny gold, with no light on it
		PulseDiameter = 3.6, -- across its outer edge: 1.8 ball widths...
		PulseGrow = 1.6, -- ...growing to this many times that
		PulseThickness = 0.5, -- its line, a quarter of a ball width
		PulseHeight = 0.1, -- just over the felt and the balls' shadows, under the balls' middles
		PulseTransparency = 0, -- at the start; it fades to nothing
		-- The most effect parts alive at once, so a full-power break stays cheap on phones: 18 outlined sparks, the
		-- break's first three bursts. Uncapped, a full-power break would reach about 100
		MaxParts = 36,
	},

	-- By ball id. Each stripe shares its solid's color.
	BallColors = {
		[0] = Color3.fromRGB(245, 242, 230),
		[1] = YELLOW,
		[2] = BLUE,
		[3] = RED,
		[4] = PURPLE,
		[5] = ORANGE,
		[6] = GREEN,
		[7] = MAROON,
		[8] = Color3.fromRGB(20, 20, 20),
		[9] = YELLOW,
		[10] = BLUE,
		[11] = RED,
		[12] = PURPLE,
		[13] = ORANGE,
		[14] = GREEN,
		[15] = MAROON,
	} :: { [number]: Color3 },

	-- The shooter's ready-to-shoot R6 pose (ShotPose), in degrees at the full pose
	Pose = {
		Lean = 35, -- the body tips forward over the table from the hips; the legs stay upright
		BackArm = 60, -- the back (right) arm drawn back and down, as if holding a cue
		FrontArm = 80, -- the front (left) arm reaching forward along the felt
		Head = 20, -- the head tilts up a little, to look along the shot
		EaseSeconds = 0.25, -- into and out of the pose
		StillSpeed = 1, -- studs/s: slower than this counts as standing still
		OnTableSeeThrough = 0.6, -- a shooter standing on top of the table is this see-through (40% opaque)
	},
}

return Theme
