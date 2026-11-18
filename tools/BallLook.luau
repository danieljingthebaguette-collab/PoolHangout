--!strict
-- Prints the balls' look from Theme.luau as JSON, for tools/BallTextures.py, so Theme stays the one place the balls'
-- colors and sizes live. Run from the project root: lune run tools/BallLook

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox") :: any
local serde = require("@lune/serde")

-- Theme uses Roblox's datatypes, which Lune's roblox library provides
local environment = {}
for _, name in
	{
		"Color3",
		"ColorSequence",
		"ColorSequenceKeypoint",
		"Enum",
		"Font",
		"NumberRange",
		"NumberSequence",
		"NumberSequenceKeypoint",
		"UDim",
		"UDim2",
		"Vector2",
		"Vector3",
	}
do
	environment[name] = roblox[name]
end
local Theme = luau.load(fs.readFile("src/Shared/Theme.luau"), { debugName = "Theme", environment = environment })()

local function rgb(color: any): { number }
	return { math.round(color.R * 255), math.round(color.G * 255), math.round(color.B * 255) }
end

local colors = {}
for id = 0, 15 do
	colors[tostring(id)] = rgb(Theme.BallColors[id])
end

print(serde.encode("json", {
	colors = colors,
	cream = rgb(Theme.Colors.BallMark),
	ink = rgb(Theme.Colors.BallInk),
	dot = rgb(Theme.Colors.CueBallMark),
	marks = Theme.BallMarks,
}))
