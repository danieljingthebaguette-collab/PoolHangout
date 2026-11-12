--!strict
-- The lobby's row of buttons, bottom center of the screen while this player isn't at a table (where their ability
-- squares sit at one): Abilities (Z), which opens the Abilities panel, and Invite (X), which opens Roblox's
-- invite-friends prompt. Each has its key letter on a dark tag above it. A centered row, so Shop and Inventory can join
-- it after launch. Sized for a 1080-pixel-high screen and scaled to the real one.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")

local Theme = require(ReplicatedStorage.Shared.Theme)
local AbilitiesPanel = require(script.Parent.AbilitiesPanel)
local Ui = require(script.Parent.Ui)

local LobbyButtons = {}

local ACTION = "LobbyButtons"

local look = Theme.Abilities
local gui: ScreenGui? = nil

-- Roblox's invite-friends prompt, if this player can send invites. Asking can wait or fail; then nothing opens.
local function invite()
	task.spawn(function()
		local player = Players.LocalPlayer
		local ok, can = pcall(SocialService.CanSendGameInviteAsync, SocialService, player)
		if ok and can then
			pcall(SocialService.PromptGameInvite, SocialService, player)
		end
	end)
end

-- Each button, in order: its words, its key and what it does
local BUTTONS = {
	{ text = "Abilities", key = Enum.KeyCode.Z, press = AbilitiesPanel.toggle },
	{ text = "Invite", key = Enum.KeyCode.X, press = invite },
}

local function button(parent: Frame, order: number, text: string, key: Enum.KeyCode, press: () -> ())
	local holder = Instance.new("Frame")
	holder.LayoutOrder = order
	holder.Size = UDim2.fromOffset(look.ButtonWidth, look.ButtonHeight)
	holder.BackgroundTransparency = 1
	holder.Parent = parent
	local main = Ui.accentButton(text, Theme.Colors.Button, holder)
	main.Size = UDim2.fromScale(1, 1)
	main.TextSize = look.ButtonTextSize
	main.Activated:Connect(press)
	-- The key letter on a dark tag, half over the button's top edge
	local tag = Ui.label(key.Name, holder)
	tag.AnchorPoint = Vector2.new(0.5, 0.5)
	tag.Position = UDim2.fromScale(0.5, 0)
	tag.Size = UDim2.fromOffset(look.KeyTagSize, look.KeyTagSize)
	tag.TextSize = look.KeyTagTextSize
	tag.BackgroundTransparency = 0
	tag.BackgroundColor3 = Theme.Colors.Dark
	tag.TextColor3 = Theme.Colors.DarkText
	tag.ZIndex = 2
	Ui.roundCorners(tag)
end

function LobbyButtons.build(playerGui: Instance)
	local screen = Instance.new("ScreenGui")
	screen.Name = "LobbyButtons"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true
	screen.Enabled = false
	local row = Instance.new("Frame")
	row.AnchorPoint = Vector2.new(0.5, 1)
	row.Position = UDim2.new(0.5, 0, 1, -look.BottomMargin)
	row.Size = UDim2.fromOffset(0, look.ButtonHeight)
	row.AutomaticSize = Enum.AutomaticSize.X
	row.BackgroundTransparency = 1
	row.Parent = screen
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, look.ButtonGap)
	layout.Parent = row
	local scale = Instance.new("UIScale")
	scale.Parent = row
	local function fit()
		scale.Scale = screen.AbsoluteSize.Y / look.DesignHeight
	end
	screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	for i, entry in BUTTONS do
		button(row, i, entry.text, entry.key, entry.press)
	end
	screen.Parent = playerGui
	fit()
	gui = screen
end

-- Shows the row, and its keys work, only while this player isn't at a table
function LobbyButtons.setAtTable(atTable: boolean)
	if gui then
		gui.Enabled = not atTable
	end
	ContextActionService:UnbindAction(ACTION)
	if not atTable then
		local keys = {}
		for _, entry in BUTTONS do
			table.insert(keys, entry.key)
		end
		ContextActionService:BindAction(ACTION, function(_, state: Enum.UserInputState, input: InputObject)
			if state == Enum.UserInputState.Begin then
				for _, entry in BUTTONS do
					if entry.key == input.KeyCode then
						entry.press()
					end
				end
			end
			return Enum.ContextActionResult.Sink
		end, false, table.unpack(keys))
	end
end

return LobbyButtons
