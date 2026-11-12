--!strict
local Config = require("../src/Shared/Config")
local SaveData = require("../src/Shared/SaveData")

return function(test, check)
	test("a new player gets today's version with the default settings", function()
		local record = SaveData.migrate(nil)
		check.equal(record.version, SaveData.VERSION)
		check.equal(record.settings.sound, Config.Settings.Sound)
		check.equal(record.settings.cameraGlide, Config.Settings.CameraGlide)
	end)

	test("settings from a client are kept in range, and anything wrong goes back to its default", function()
		local clean = SaveData.cleanSettings({
			music = 2,
			sound = -1,
			cameraGlide = "yes",
			screenShake = false,
			controlHints = false,
			uiScale = 0.93,
			showStats = true,
		})
		check.equal(clean.music, 1, "music past 1")
		check.equal(clean.sound, 0, "sound under 0")
		check.equal(clean.cameraGlide, Config.Settings.CameraGlide, "not a boolean")
		check.equal(clean.screenShake, false)
		check.equal(clean.controlHints, false)
		check.equal(clean.uiScale, 0.95, "UI scale on its nearest step")
		check.equal(clean.showStats, true)
		check.equal(SaveData.cleanSettings({ uiScale = 1 }).uiScale, 1, "1 stays exactly 1")
		check.equal(SaveData.cleanSettings({ uiScale = 9 }).uiScale, Config.Settings.UiScaleMax, "past the top")
		check.equal(SaveData.cleanSettings({ music = 0 / 0 }).music, Config.Settings.Music, "NaN")
		check.equal(SaveData.cleanSettings("junk").sound, Config.Settings.Sound, "not a table")
	end)

	test("an old or damaged record is brought up to date, keeping fields this version doesn't know", function()
		local record = SaveData.migrate({ settings = { music = 0.2 }, coins = 40 }) :: any
		check.equal(record.version, SaveData.VERSION, "no version counts as older")
		check.equal(record.settings.music, 0.2)
		check.equal(record.settings.sound, Config.Settings.Sound, "missing settings get defaults")
		check.equal(record.coins, 40, "unknown fields are kept")
		check.equal((SaveData.migrate({ version = 99 }) :: any).version, 99, "a newer record keeps its version")
	end)
end
