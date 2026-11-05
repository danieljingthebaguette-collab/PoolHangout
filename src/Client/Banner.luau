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
	box.Position = UDim2.new(0.5, 0, 0, Theme.Ui.CardHeight + 2 * Theme.Ui.Padding)
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

-- Builds the banner's screen and shows the server's messages for `tableModel` while this player is at it: in the
-- top-down view (`inView`), joined, or standing near it
function Banner.start(playerGui: Instance, tableModel: Model, inView: () -> boolean)
	local bannerGui = Instance.new("ScreenGui")
	bannerGui.Name = "Banner"
	bannerGui.ResetOnSpawn = false
	bannerGui.IgnoreGuiInset = true -- so it lines up under the top bar's cards
	bannerCard(bannerGui)
	bannerGui.Parent = playerGui
	local felt = tableModel:WaitForChild("Felt") :: BasePart
	local player = Players.LocalPlayer
	local function atTable(): boolean
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		return inView()
			or player:GetAttribute("JoinedTable") == tableModel.Name
			or (
				root ~= nil
				and root:IsA("BasePart")
				and (root.Position - felt.Position).Magnitude <= Config.Join.BannerDistance
			)
	end
	Remotes.Banner.OnClientEvent:Connect(function(model: Model?, message: string, seconds: number)
		if model == tableModel and atTable() then
			showBanner(message, seconds)
		end
	end)
end

return Banner
