--!strict
-- Each player's saved record, in one DataStore key: what's in it, its defaults, and turning an older or damaged
-- record into today's. Pure, so Lune can test it; Server/PlayerData does the saving.
--
-- Version 1 holds the settings page. The tutorial (finished or skipped), XP, coins and owned items go at the top level
-- when they're built, each with a version bump and a step in `migrate`, so older records keep working.

local Config = require("./Config")

local SaveData = {}

SaveData.VERSION = 1

export type Settings = {
	music: number,
	sound: number,
	cameraGlide: boolean,
	screenShake: boolean,
	controlHints: boolean,
	uiScale: number,
	showStats: boolean,
}

export type Record = { version: number, settings: Settings }

function SaveData.defaultSettings(): Settings
	local s = Config.Settings
	return {
		music = s.Music,
		sound = s.Sound,
		cameraGlide = s.CameraGlide,
		screenShake = s.ScreenShake,
		controlHints = s.ControlHints,
		uiScale = s.UiScale,
		showStats = s.ShowStats,
	}
end

function SaveData.new(): Record
	return { version = SaveData.VERSION, settings = SaveData.defaultSettings() }
end

local function isNumber(value: unknown): boolean
	return type(value) == "number" and value == value and math.abs(value) ~= math.huge
end

-- A volume from 0 to 1, or the default
local function share(value: unknown, default: number): number
	return if isNumber(value) then math.clamp(value :: number, 0, 1) else default
end

local function flag(value: unknown, default: boolean): boolean
	return if type(value) == "boolean" then value else default
end

-- Settings from anywhere, a client or an old record, made valid: every field the right type and in range, a missing
-- or wrong one back to its default, and the UI scale on one of its steps
function SaveData.cleanSettings(raw: unknown): Settings
	local default = SaveData.defaultSettings()
	if type(raw) ~= "table" then
		return default
	end
	local input = raw :: { [string]: unknown }
	local s = Config.Settings
	local scale = default.uiScale
	if isNumber(input.uiScale) then
		local steps =
			math.round((math.clamp(input.uiScale :: number, s.UiScaleMin, s.UiScaleMax) - s.UiScaleMin) / s.UiScaleStep)
		-- In hundredths, so a step lands exactly on 1 rather than 0.9999…
		scale = math.round((s.UiScaleMin + steps * s.UiScaleStep) * 100) / 100
	end
	return {
		music = share(input.music, default.music),
		sound = share(input.sound, default.sound),
		cameraGlide = flag(input.cameraGlide, default.cameraGlide),
		screenShake = flag(input.screenShake, default.screenShake),
		controlHints = flag(input.controlHints, default.controlHints),
		uiScale = scale,
		showStats = flag(input.showStats, default.showStats),
	}
end

-- A record as loaded, nothing for a new player, turned into today's version. Fields this version doesn't know are
-- kept, so a newer server's data survives an older one.
function SaveData.migrate(raw: unknown): Record
	if type(raw) ~= "table" then
		return SaveData.new()
	end
	local record = table.clone(raw :: { [string]: any })
	record.settings = SaveData.cleanSettings(record.settings)
	record.version = math.max(if isNumber(record.version) then record.version else 0, SaveData.VERSION)
	return record :: any
end

return SaveData
