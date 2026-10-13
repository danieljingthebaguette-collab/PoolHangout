--!strict
-- Colors, fonts and UI sizes for everything built in code.

local YELLOW = Color3.fromRGB(245, 196, 30)
local BLUE = Color3.fromRGB(30, 70, 190)
local RED = Color3.fromRGB(200, 35, 35)
local PURPLE = Color3.fromRGB(100, 40, 150)
local ORANGE = Color3.fromRGB(240, 120, 30)
local GREEN = Color3.fromRGB(20, 120, 60)
local MAROON = Color3.fromRGB(120, 25, 35)

local Theme = {
	Font = Enum.Font.GothamMedium,
	TextSize = 16,

	Colors = {
		Panel = Color3.fromRGB(43, 32, 26), -- dark warm wood
		Button = Color3.fromRGB(122, 84, 52),
		Text = Color3.fromRGB(248, 236, 218),
		Track = Color3.fromRGB(84, 62, 48),
		Fill = Color3.fromRGB(236, 168, 72), -- warm lamp glow
		Cue = Color3.fromRGB(214, 170, 112), -- light maple
		AimLine = Color3.fromRGB(255, 255, 255),
		BallMark = Color3.fromRGB(245, 242, 230), -- the white on the placeholder balls: stripes and number dots
		CueBallMark = Color3.fromRGB(200, 35, 35),
		-- The HUD around the top-down view
		HudPanel = Color3.fromRGB(30, 38, 56), -- dark navy cards
		HudText = Color3.fromRGB(255, 255, 255),
		HudSubtle = Color3.fromRGB(140, 150, 168), -- the power meter's % readout
		Tray = Color3.fromRGB(10, 10, 14),
		BallShadow = Color3.fromRGB(10, 20, 40),
	},

	Ui = {
		Padding = 8,
		Corner = 8,
		ButtonHeight = 44, -- big enough for a thumb
		PanelWidth = 240,
		SliderBar = 6,
		MeterReserve = 72, -- screen width the top-down view keeps clear on the left for the power meter
		MeterTrack = 24, -- width of the power meter
		MeterHeight = 0.5, -- share of the screen's height
		PercentTextSize = 22, -- the % under the power meter
		TrayReserve = 72, -- screen width the top-down view keeps clear on the right for the sunk-ball tray
		TrayWidth = 36,
		TrayHeight = 0.6, -- share of the screen's height
		CardWidth = 260, -- the player card in the top bar
		CardHeight = 56,
		HudTransparency = 0.15, -- the top bar's cards and the settings panel
		AimLineThickness = 2, -- pixels, for the aim indicator's lines and circle
		AimFaintTransparency = 0.6, -- the aim indicator while aiming or about to cancel; solid while locked
		LockButtonWidth = 80, -- the phones' Lock button, beside the power meter
	},

	-- The placeholder balls' markings, so you can see them roll, in ball radii. Solids, the 8 and the cue ball
	-- get a dot on top and bottom, stripes a band of color around a white ball.
	BallMarks = {
		DotDiameter = 0.8,
		DotThickness = 0.05,
		BandWidth = 1,
		BandDiameter = 1.96, -- a little under the ball's 2, so the band and the ball don't flicker where they meet
	},

	-- The soft shadow under each ball, in ball radii: a little down and right of the ball, as if lit from above left
	BallShadow = {
		Diameter = 2.1,
		Offset = 0.25,
		Transparency = 0.55,
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
