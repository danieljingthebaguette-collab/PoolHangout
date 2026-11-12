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
local ICE = Color3.fromRGB(150, 215, 255) -- Freeze's icy blue, the one color outside the palette
local OIL = Color3.fromRGB(66, 50, 42)

local Theme = {
	-- Bold condensed, for every bit of HUD text. It's a Font, so set it as FontFace.
	Font = Font.new(Font.fromEnum(Enum.Font.RobotoCondensed).Family, Enum.FontWeight.Bold),
	TextSize = 18,
	-- For big moments only: an item's name shown big (docs/STYLE.md)
	DisplayFont = Font.fromEnum(Enum.Font.LuckiestGuy),

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
		PowerOver = ORANGE, -- the power meter's second fill past 100%, with Power Shot on
		BlastRing = ORANGE, -- the aim indicator's ring showing Blast Ball's reach
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
		ItemPicking = ACCENT, -- the outline round your ability's square while you pick its target
		ItemLine = Color3.fromRGB(98, 82, 70), -- an ability's line, on its row and in the Abilities panel: softer ink
		ItemRefusal = Color3.fromRGB(255, 138, 118), -- coral, the note above your squares saying why a target isn't allowed
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
		ClockPulseSeconds = 5, -- in its last seconds a coral border pulses round it, once a second...
		ClockPulseThickness = 4, -- ...this many pixels at the start of each second, thinning and fading
		ClockTurnHeight = 24, -- whose turn it is, on a dark box under the clock ("Your turn")
		ClockTurnTextSize = 16,
		-- Callouts on the banner: "Who breaks?" flicks between the names, every WhoBreaksFlick seconds at first and
		-- slowing by WhoBreaksSlowing each time, for WhoBreaksSeconds, then shows the breaker for BreakerSeconds
		WhoBreaksSeconds = 1.2,
		WhoBreaksFlick = 0.08,
		WhoBreaksSlowing = 1.25,
		BreakerSeconds = 1.5,
		CalloutSeconds = 2.5, -- "You're Solids", "Call your pocket"
		NiceShotTextSize = 30, -- "Nice shot!" over a pocket: gold with an ink edge...
		NiceShotEdge = 2,
		NiceShotWidth = 220,
		NiceShotRise = 40, -- ...rising this many pixels...
		NiceShotSeconds = 1.2, -- ...over this long, fading out over the second half
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
		BlastRingThickness = 3, -- pixels, the ring showing Blast Ball's reach round the ball the cue ball will hit
		PickRingThickness = 3, -- pixels, the ring showing what a click would pick while an item waits for its target
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
		ItemBarHeight = 4,
		ItemPopTextSize = 16, -- the "+4" that rises from a bar when it fills...
		ItemPopRise = 16, -- ...this many pixels...
		ItemPopSeconds = 0.8, -- ...as it fades out
		-- The Abilities panel the lobby's Abilities button opens in the middle of the screen, listing every ability.
		-- Placeholder looks until the GUI pass.
		AbilitiesPanelWidth = 680, -- room for the longest description on one line
		AbilitiesCloseWidth = 80,
		AbilitiesIconSize = 44, -- each ability's icon on its dark box...
		AbilitiesIconInset = 4, -- ...with this margin
		AbilitiesLineTextSize = 16, -- its one-line description, under its name at TextSize
		-- An item's name shown big at the top center as it's used, under the banner (ItemName)
		ItemNameTextSize = 40, -- in the display font...
		ItemNameLineTextSize = 18, -- ...with its one-line description under it...
		ItemNameHeight = 84, -- ...on a dark box...
		ItemNameIconSize = 60, -- ...with the item's icon beside them
		ItemNameSeconds = 3, -- on screen in all, long enough to read the line...
		ItemNamePopSeconds = 0.15, -- ...popping in...
		ItemNamePopScale = 0.6, -- ...from this size, with a little overshoot...
		ItemNameFadeSeconds = 0.3, -- ...and fading out at the end
	},

	-- The item icons (ItemIcons), drawn in code on the dark slots. Icy blue is the one color outside the palette, since
	-- Freeze glows icy blue (GAME_SPEC)
	ItemIcons = {
		Flame = ORANGE, -- Power Shot: an orange flame...
		FlameHeart = ACCENT, -- ...with a gold heart...
		FlameCore = CREAM, -- ...and a cream core
		Burst = ACCENT, -- Blast Ball: a gold burst...
		BurstInner = ORANGE, -- ...an orange one inside it...
		BurstCore = CREAM, -- ...and a cream core
		Ice = ICE, -- Freeze: an icy blue snowflake...
		IceCore = CREAM, -- ...with a cream heart
		Oil = OIL, -- Oil Slick: a dark drop over a puddle...
		OilEdge = CREAM, -- ...edged in cream, so they read on the dark slots...
		OilShine = CREAM, -- ...with a cream gloss on each
		PocketRim = Color3.fromRGB(122, 70, 40), -- Pocket Block: a black pocket in painted wood...
		PocketHole = Color3.fromRGB(14, 11, 9),
		Lid = ACCENT, -- ...with a gold lid across it...
		LidEdge = INK, -- ...edged in ink
		Edge = 0.05, -- the edges, as a share of the icon's width
	},

	-- Bottom center of the screen, sized for a 1080-pixel-high screen and scaled to the real one (UIScale). At a table
	-- (AbilitySlots): your 2 ability squares side by side, each with its key on a tab on its bottom edge, an outline
	-- when empty and the ability's icon on a dark tile when held, your ability bar under them in segments, and above
	-- them a coral note saying why a target was refused. In the lobby (LobbyButtons): a row of buttons in the same
	-- spot, each with its key letter on a tag above it. Placeholder looks until the GUI pass.
	Abilities = {
		DesignHeight = 1080, -- the screen height these sizes are for
		BottomMargin = 12, -- from the screen's bottom edge
		SlotSize = 100,
		SlotGap = 12,
		SlotCorner = 6,
		SlotOutline = 2, -- an empty square is just this outline, in cream...
		SlotOutlineTransparency = 0.15,
		PickingOutline = 4, -- ...gold and this thick round the square picking a target
		IconInset = 14, -- the icon's margin inside its square
		DimTransparency = 0.45, -- a dark veil over the squares while you can't use one
		TabWidth = 30, -- the key tab on each square's bottom edge, half over it
		TabHeight = 24,
		TabTextSize = 18,
		BarGap = 18, -- between the squares and the bar under them, room for the tabs
		BarWidth = 240, -- a little wider than both squares together
		BarHeight = 14,
		BarSegments = 4, -- Config.Items.BarPoints split evenly: 3 points each
		BarSegmentGap = 4,
		RefusalGap = 8, -- the coral note's gap above the squares
		RefusalHeight = 30,
		RefusalTextSize = 18,
		ButtonWidth = 200, -- the lobby's buttons
		ButtonHeight = 56,
		ButtonGap = 16,
		ButtonTextSize = 24,
		KeyTagSize = 28, -- the key letter's dark tag above each lobby button, half over its top edge
		KeyTagTextSize = 18,
	},

	-- The UI kit's values, measured from Illegal Soccer on 2026-11-12 (docs/audits/ILLEGAL_SOCCER.md, docs/STYLE.md's
	-- UI kit) for the step 7 style pass, which rebuilds every screen on them. Sizes are pixels on a 1080-pixel-high
	-- screen, scaled with UIScale; times are seconds. Nothing reads them until a screen is rebuilt.
	Kit = {
		DesignHeight = 1080,
		-- Second lines in warm grey: the same family as Theme.Font, regular weight
		LineFont = Font.new(Font.fromEnum(Enum.Font.RobotoCondensed).Family, Enum.FontWeight.Regular),
		Colors = {
			Cream = Color3.fromRGB(254, 250, 234), -- cards, labels, panels' bodies, tooltips
			CreamWhite = Color3.fromRGB(255, 254, 237), -- key tabs, the close button
			Ink = Color3.fromRGB(21, 19, 15), -- text on cream
			Dark = Color3.fromRGB(23, 21, 19), -- key boxes, the timer, header bars, dark labels
			Grey = Color3.fromRGB(128, 123, 111), -- second lines
			Band = Color3.fromRGB(235, 231, 219), -- section bands inside panels
			Tan = Color3.fromRGB(194, 146, 123), -- corner brackets, the dot texture, the timer's digits
			Mint = Color3.fromRGB(56, 255, 165), -- main action, toggles on, sliders, full bars, big-moment tags
			MintBright = Color3.fromRGB(68, 255, 171), -- the one main button
			MintEdge = Color3.fromRGB(212, 238, 213), -- the thin border round mint pieces
			Red = Color3.fromRGB(237, 16, 93), -- side A, warnings, badges
			Blue = Color3.fromRGB(51, 132, 250), -- side B
			Gold = Color3.fromRGB(248, 215, 52), -- only the turn and the called pocket
			WorldText = Color3.fromRGB(240, 238, 246), -- names over the world, with a dark edge
			ToggleTrack = ColorSequence.new(Color3.fromRGB(226, 222, 210), Color3.fromRGB(210, 206, 195)),
			-- Second-rank buttons, top to bottom
			PastelBlue = ColorSequence.new(Color3.fromRGB(219, 222, 219), Color3.fromRGB(189, 205, 224)),
			PastelBeige = ColorSequence.new(Color3.fromRGB(231, 221, 209), Color3.fromRGB(225, 208, 193)),
			PastelLilac = ColorSequence.new(Color3.fromRGB(229, 209, 218), Color3.fromRGB(214, 175, 222)),
			-- Only a full ability bar, scrolling sideways
			Rainbow = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(243, 92, 232)),
				ColorSequenceKeypoint.new(0.33, Color3.fromRGB(246, 179, 121)),
				ColorSequenceKeypoint.new(0.66, Color3.fromRGB(153, 255, 122)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(79, 184, 255)),
			}),
		},
		Margin = 17, -- from the screen's edges
		Border = 2, -- cream, round mint and pastel buttons and bar segments
		Bracket = { Arm = 13, Line = 2, Inset = 9 }, -- cards' corner brackets
		Dots = { Size = 2, Spacing = 5.5, Transparency = 0.85 }, -- the halftone grid, tan
		DimTransparency = 0.7, -- a control label you can't use right now lets the world through
		HoverGlow = 12,
		ScoreCard = { Height = 82, Width = 223, NumeralSize = 60, SideSquare = 19 },
		Timer = { Height = 40, Width = 103, Gap = 13, TextSize = 27 },
		Controls = { Height = 42, Pitch = 52, KeyBox = 29, TextSize = 21, Padding = 10, KeyInset = 5, Divider = 19 },
		MainButton = { Height = 83, Width = 234, TextSize = 45 },
		Button = { Height = 58, Width = 202, Gap = 13, TextSize = 29, KeyTag = 26, KeyTagTextSize = 18 },
		Tooltip = { Height = 28, TextSize = 19, Pointer = 9 },
		Badge = { Height = 34, Square = 15 },
		Slot = { Size = 85, Gap = 12, Tab = 28, Dash = 6, DashGap = 4 },
		ThinBar = { Height = 7, Width = 86 }, -- the pale bar over the slots
		Bar = { Height = 20, SegmentWidth = 84, Gap = 6, Below = 18 }, -- the ability bar's 4 segments
		Panel = { Width = 507, Header = 60, TitleSize = 31, Close = 36, CloseMargin = 12, Padding = 26 },
		Row = { Height = 61, TitleSize = 23, LineSize = 17, Band = 33, BandTextSize = 17 },
		Toggle = { Width = 69, Height = 34, Knob = 27 },
		Slider = { Width = 170, Height = 30, Segments = 10, Gap = 3 },
		BigMoment = { Height = 96, Width = 378, NameSize = 60, TagHeight = 40, TagTextSize = 22 },
		Ribbon = { Height = 82, Width = 275, TitleSize = 29, ReasonSize = 19, Tail = 30 },
		DarkLabel = { Height = 39 },
		InfoPill = { Height = 42, Transparency = 0.15 },
		Times = {
			PanelIn = 0.1,
			PanelOut = 0.13,
			CrossFade = 0.1,
			BigLine = 0.1, -- a big moment: the line wiping out...
			BigFlash = 0.15, -- ...the flash in the side's color...
			BigSettle = 0.1, -- ...brackets settling...
			BigLetter = 0.03, -- ...then the name typing on, per letter
			RainbowCycle = 1,
		},
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

	-- Item effects on the table (ItemEffects), on every screen. Placeholder looks until Phase 4. Sizes and heights are
	-- in ball radii, heights above the felt; the oil patch's size comes from Config and the lid's span from the pocket
	ItemEffects = {
		Frozen = ICE, -- a flat icy ring on the felt round a frozen ball...
		FrozenDiameter = 3, -- ...across its outer edge, hugging the ball...
		FrozenThickness = 0.45, -- ...its line...
		FrozenHeight = 0.1, -- ...just over the felt and the ball's shadow, like the turn-start ring
		FrozenFill = 0.7, -- and an icy tint and outline on the ball itself, the tint this see-through so its color reads
		Oil = OIL, -- a dark round patch on the felt...
		OilTransparency = 0.3, -- ...see-through enough that the felt reads under it...
		OilEdge = CREAM, -- ...edged in cream, like its icon...
		OilEdgeThickness = 0.2,
		OilEdgeTransparency = 0.5,
		OilShine = CREAM, -- ...with a soft cream gloss near one edge
		OilShineTransparency = 0.65,
		OilHeight = 0.01, -- just over the felt, under the balls' shadows
		Lid = ACCENT, -- a gold slab across a blocked pocket's mouth, from jaw to jaw...
		LidDepth = 1, -- ...reaching back into the pocket this many times its width, so it covers the hole...
		LidTop = 1.2, -- ...up to under the cushions' tops, so the cushions and plates trim it to the pocket's opening...
		LidEdgeColor = INK, -- ...with a thin ink edge where it meets the felt
		LidEdge = 0.15,
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
		OnTableSeeThrough = 0.6, -- a shooter standing on top of the table is this see-through (40% opaque)...
		OnTableAccessories = 1, -- ...with their accessories (hair, hats, wings) this see-through: hidden
	},
}

return Theme
