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
local ACCENT = Color3.fromRGB(255, 196, 46) -- sunny gold

local Theme = {
	-- Bold condensed, for every bit of HUD text. It's a Font, so set it as FontFace.
	Font = Font.new(Font.fromEnum(Enum.Font.RobotoCondensed).Family, Enum.FontWeight.Bold),
	TextSize = 18,

	Colors = {
		Panel = CREAM, -- cards and panels
		Text = INK, -- text on cards and accent buttons, and the cards' corner brackets and dot texture
		Dark = Color3.fromRGB(32, 26, 22), -- dark boxes: key boxes, the % readout, the tray
		DarkText = CREAM, -- text and corner brackets on dark boxes
		Button = ACCENT, -- bright accent buttons
		LeaveButton = Color3.fromRGB(255, 138, 118), -- coral, for leaving a table
		ClockWarning = Color3.fromRGB(255, 138, 118), -- coral, the shot clock's last seconds
		TurnArrow = ACCENT, -- the "Turn" card over the shooter's head
		LobbyButton = Color3.fromRGB(150, 205, 240), -- sky blue, the end screen's Back to lobby
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
		TurnArrowWidth = 64, -- the "Turn" card over the shooter's head, in pixels whatever the distance
		TurnArrowHeight = 28,
		TurnArrowPoint = 10, -- the point under the card, aiming at the head
		TurnArrowStuds = 2.5, -- studs above the head's center
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
		SparkMinCount = 3, -- sparks from a hit at SparkShare
		SparkMaxCount = 5, -- sparks from a full-power hit or harder, so even the break stays a few chunky bits
		SparkColors = { ACCENT, CREAM }, -- taken in turn, so each burst mixes gold and cream
		SparkLength = 1.3,
		SparkThickness = 0.55,
		SparkHeight = 1, -- where they start: ball center height
		SparkRise = 0.8, -- how much higher they end
		SparkReachMin = 2, -- how far they fly, from a hit at SparkShare...
		SparkReachMax = 4, -- ...up to a full-power one
		-- Degrees off the line between the two balls: sparks squirt out sideways from where they touch, clear of both
		BallSprayMin = 55,
		BallSprayMax = 125,
		-- Degrees off the line straight out from the cushion: sparks squirt along it, clear of the ball
		RailSprayMin = 35,
		RailSprayMax = 85,
		SparkSeconds = 0.25,
		PopColor = CREAM, -- the ring that pops out where a ball drops into a pocket
		PopStartDiameter = 2,
		PopEndDiameter = 5,
		PopLine = 0.35, -- the ring's thickness
		PopHeight = 1.8, -- just over the corner plates, so they never cover it
		PopTransparency = 0.1, -- at the start; it fades to nothing
		PopSeconds = 0.25,
		MaxParts = 30, -- the most effect parts alive at once, so a full-power break stays cheap on phones
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
}

return Theme
