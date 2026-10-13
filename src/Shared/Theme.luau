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
	},

	Ui = {
		Padding = 8,
		Corner = 8,
		ButtonHeight = 44, -- big enough for a thumb
		PanelWidth = 240,
		SliderBar = 6,
		MeterReserve = 96, -- screen width the top-down view keeps clear on the right for the power meter
		MeterTrack = 16, -- width of the power meter
		MeterHeight = 0.45, -- share of the screen's height
	},

	-- By ball id. In the greybox each stripe shares its solid's color.
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
