--!strict
-- This player's settings (SaveData.Settings): what the settings page shows, applied as soon as they change, and sent
-- to the server to save. It starts on the defaults and switches to the saved ones when the server sends them. If the
-- server couldn't load the record, changes still apply, but only for this session.
--
-- Music plays through SoundService's "Music" group, made here, and sounds through TableView's volume. Screen shake has
-- nothing to switch until it's built (Phase 4's item effects); it reads `get().screenShake`.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local SaveData = require(ReplicatedStorage.Shared.SaveData)
local Theme = require(ReplicatedStorage.Shared.Theme)
local Hints = require(script.Parent.Hints)
local TableView = require(script.Parent.TableView)
local TopDownView = require(script.Parent.TopDownView)
local UiScale = require(script.Parent.UiScale)
local Ui = require(script.Parent.Ui)

local Settings = {}

local current: SaveData.Settings = SaveData.defaultSettings()
-- Whether the server has the record, so changes are saved; and whether it has answered at all
local saving = false
local answered = false
local listeners: { () -> () } = {}
-- A change waiting to go to the server, so dragging a slider sends one message, not hundreds
local sendQueued = false
-- The frame rate and ping, bottom left, while Show stats is on
local statsGui: ScreenGui? = nil
local statsConnection: RBXScriptConnection? = nil

function Settings.get(): SaveData.Settings
	return current
end

-- Whether changes are saved: false before the server answers, and for good when it couldn't load the record
function Settings.saving(): boolean
	return saving
end

function Settings.answered(): boolean
	return answered
end

-- Calls `listener` whenever any setting changes, or the server's answer comes
function Settings.onChanged(listener: () -> ())
	table.insert(listeners, listener)
end

local function musicGroup(): SoundGroup
	local group = SoundService:FindFirstChild("Music")
	if group and group:IsA("SoundGroup") then
		return group
	end
	local made = Instance.new("SoundGroup")
	made.Name = "Music"
	made.Parent = SoundService
	return made
end

-- The frame rate and ping, counted over half a second at a time
local function showStats(on: boolean)
	local gui = statsGui :: ScreenGui
	gui.Enabled = on
	if statsConnection then
		statsConnection:Disconnect()
		statsConnection = nil
	end
	if not on then
		return
	end
	local label = gui:FindFirstChildWhichIsA("TextLabel") :: TextLabel
	local frames, since = 0, os.clock()
	statsConnection = RunService.Heartbeat:Connect(function()
		frames += 1
		local now = os.clock()
		if now - since >= Theme.Ui.StatsSeconds then
			local ping = math.round(Players.LocalPlayer:GetNetworkPing() * 1000)
			label.Text = `{math.round(frames / (now - since))} fps · {ping} ms`
			frames, since = 0, now
		end
	end)
end

local function apply()
	TableView.setVolume(current.sound)
	musicGroup().Volume = current.music
	TopDownView.setGlide(current.cameraGlide)
	Hints.setEnabled(current.controlHints)
	UiScale.set(current.uiScale)
	showStats(current.showStats)
	for _, listener in listeners do
		task.spawn(listener)
	end
end

-- From the settings page: changes one setting, applies it, and saves it a moment later
function Settings.set(field: string, value: any)
	local changed = table.clone(current) :: any
	changed[field] = value
	current = SaveData.cleanSettings(changed)
	apply()
	if saving and not sendQueued then
		sendQueued = true
		task.delay(Theme.Ui.SettingsSendSeconds, function()
			sendQueued = false
			Remotes.SaveSettings:FireServer(current)
		end)
	end
end

function Settings.start(playerGui: Instance)
	local gui = Instance.new("ScreenGui")
	gui.Name = "Stats"
	gui.ResetOnSpawn = false
	gui.Enabled = false
	local label = Ui.label("", gui)
	label.AnchorPoint = Vector2.new(0, 1)
	-- Over the gear, bottom left, so the two never overlap
	label.Position = UDim2.new(0, Theme.Ui.Padding, 1, -(Theme.Ui.ButtonHeight + 2 * Theme.Ui.Padding))
	label.Size = UDim2.fromOffset(0, Theme.Ui.StatsTextSize)
	label.AutomaticSize = Enum.AutomaticSize.X
	label.TextSize = Theme.Ui.StatsTextSize
	label.TextColor3 = Theme.Colors.DarkText
	label.TextStrokeTransparency = 0.4
	label.TextXAlignment = Enum.TextXAlignment.Left
	gui.Parent = playerGui
	statsGui = gui
	Remotes.PlayerDataLoaded.OnClientEvent:Connect(function(saved: unknown, canSave: boolean)
		current = SaveData.cleanSettings(saved)
		saving, answered = canSave == true, true
		apply()
	end)
	apply()
end

return Settings
