--!strict
-- The banner: a cream card at the top center, under the top bar, for a message from the server, like a foul and who
-- has ball in hand, or who won and why. It has its own screen, shown in either view, since "Starting..." comes before
-- anyone's in the top-down view. It's for everyone at the table: watching from above, waiting to play, or standing near
-- it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Theme = require(ReplicatedStorage.Shared.Theme)
local Card = require(script.Parent.Card)
local TopBar = require(script.Parent.TopBar)
local Ui = require(script.Parent.Ui)

local Banner = {}

-- The banner's card and text, once it's built, and how many messages it has shown, so an older message's timer leaves
-- a newer one up
local banner: { box: Frame, text: TextLabel }? = nil
local bannersShown = 0

-- The card, hidden until a message comes
local function bannerCard(gui: ScreenGui)
	local box = Instance.new("Frame")
	box.AnchorPoint = Vector2.new(0.5, 0)
	-- Under the top bar's cards and their item strips
	box.Position = UDim2.new(0.5, 0, 0, TopBar.height() + Theme.Ui.Padding)
	box.Size = UDim2.fromOffset(Theme.Ui.BannerWidth, Theme.Ui.BannerHeight)
	box.Visible = false
	Card.style(box)
	box.Parent = gui
	local text = Ui.label("", box)
	text.Size = UDim2.new(1, -4 * Theme.Ui.Padding, 1, -Theme.Ui.Padding)
	text.AnchorPoint = Vector2.new(0.5, 0.5)
	text.Position = UDim2.fromScale(0.5, 0.5)
	-- Long names shrink the text to fit rather than spill out
	text.TextScaled = true
	local fit = Instance.new("UITextSizeConstraint")
	fit.MaxTextSize = Theme.Ui.LargeTextSize
	fit.Parent = text
	banner = { box = box, text = text }
end

-- Shows a message for `seconds`, replacing any message still up
local function showBanner(message: string, seconds: number)
	if not banner then
		return
	end
	bannersShown += 1
	local shown = bannersShown
	banner.text.Text = message
	banner.box.Visible = true
	task.delay(seconds, function()
		if banner and bannersShown == shown then
			banner.box.Visible = false
		end
	end)
end

-- Whether this player is watching a table in the top-down view, from Banner.start
local inView: ((Model) -> boolean)? = nil

-- Whether this player is at a table, so its messages are for them: watching it in the top-down view, joined, or
-- standing near it
function Banner.atTable(tableModel: Model): boolean
	local player = Players.LocalPlayer
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local felt = tableModel:FindFirstChild("Felt")
	return (inView ~= nil and inView(tableModel))
		or player:GetAttribute("JoinedTable") == tableModel.Name
		or (
			root ~= nil
			and root:IsA("BasePart")
			and felt ~= nil
			and felt:IsA("BasePart")
			and (root.Position - felt.Position).Magnitude <= Config.Join.BannerDistance
		)
end

-- Builds the banner's screen and shows the server's messages for a table while this player is at it. `inViewOf` says
-- whether they're watching a table in the top-down view.
function Banner.start(playerGui: Instance, inViewOf: (Model) -> boolean)
	inView = inViewOf
	local bannerGui = Instance.new("ScreenGui")
	bannerGui.Name = "Banner"
	bannerGui.ResetOnSpawn = false
	bannerGui.IgnoreGuiInset = true -- so it lines up under the top bar's cards
	bannerCard(bannerGui)
	bannerGui.Parent = playerGui
	Remotes.Banner.OnClientEvent:Connect(function(model: Model?, message: string, seconds: number)
		if model and Banner.atTable(model) then
			showBanner(message, seconds)
		end
	end)
end

return Banner
