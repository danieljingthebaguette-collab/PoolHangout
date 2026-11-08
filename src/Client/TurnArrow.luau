--!strict
-- The "Turn" arrow over each table's shooter, for everyone to see in the normal view: a gold card reading "Turn" and the
-- shooter's name, with a point under it, over their head. Roblox's own name tags are off at the tables (TableService),
-- so this names them. Drawn from the server's TurnStarted, and gone while nobody's turn is on. The top-down view hides
-- it, since the top bar's glow shows the turn there.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Seat = require(ReplicatedStorage.Shared.Seat)
local Theme = require(ReplicatedStorage.Shared.Theme)
local Ui = require(script.Parent.Ui)

local TurnArrow = {}

-- Each table's arrow, its shooter, and the connection that moves it onto their new character after a respawn
type Arrow = { gui: BillboardGui, name: TextLabel, shooter: Seat.Seat?, connection: RBXScriptConnection? }
local arrows: { [Model]: Arrow } = {}
local hidden = false
local playerGui: Instance? = nil

-- The arrow's gui, and the label for the shooter's name
local function build(): (BillboardGui, TextLabel)
	local ui = Theme.Ui
	local gui = Instance.new("BillboardGui")
	gui.Name = "TurnArrow"
	gui.Size = UDim2.fromOffset(ui.TurnArrowMaxWidth, ui.TurnArrowHeight + ui.TurnArrowPoint)
	gui.StudsOffset = Vector3.new(0, ui.TurnArrowStuds, 0)
	gui.LightInfluence = 0
	gui.ResetOnSpawn = false
	gui.Enabled = false
	-- A square turned 45°, half under the card, so its lower corner points down at the head
	local side = ui.TurnArrowPoint * math.sqrt(2)
	local point = Instance.new("Frame")
	point.AnchorPoint = Vector2.new(0.5, 0.5)
	point.Position = UDim2.new(0.5, 0, 0, ui.TurnArrowHeight)
	point.Size = UDim2.fromOffset(side, side)
	point.Rotation = 45
	point.BackgroundColor3 = Theme.Colors.TurnArrow
	point.BorderSizePixel = 0
	point.Parent = gui
	-- Centered, and widening past TurnArrowWidth to fit the name
	local card = Instance.new("Frame")
	card.AnchorPoint = Vector2.new(0.5, 0)
	card.Position = UDim2.fromScale(0.5, 0)
	card.Size = UDim2.fromOffset(ui.TurnArrowWidth, ui.TurnArrowHeight)
	card.AutomaticSize = Enum.AutomaticSize.X
	card.BackgroundColor3 = Theme.Colors.TurnArrow
	card.BorderSizePixel = 0
	Ui.roundCorners(card)
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, ui.Padding)
	padding.PaddingRight = UDim.new(0, ui.Padding)
	padding.Parent = card
	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.Parent = card
	local title = Ui.label("Turn", card)
	title.Size = UDim2.fromOffset(0, Theme.TextSize)
	title.AutomaticSize = Enum.AutomaticSize.X
	title.LayoutOrder = 1
	local name = Ui.label("", card)
	name.TextSize = ui.TurnArrowNameSize
	name.Size = UDim2.fromOffset(0, ui.TurnArrowNameSize)
	name.AutomaticSize = Enum.AutomaticSize.X
	name.LayoutOrder = 2
	card.Parent = gui
	gui.Parent = playerGui
	return gui, name
end

local function update(arrow: Arrow)
	local character = arrow.shooter and Seat.character(arrow.shooter)
	local head = character and character:FindFirstChild("Head")
	-- Nil takes the arrow off, though the type says an Adornee is always there
	arrow.gui.Adornee = head :: Instance
	arrow.gui.Enabled = head ~= nil and not hidden
	arrow.name.Text = if arrow.shooter then Seat.name(arrow.shooter) else ""
end

-- Puts a table's arrow over its shooter, or takes it away with nil
local function show(tableModel: Model, shooter: Seat.Seat?)
	local arrow = arrows[tableModel]
	if not arrow then
		local gui, name = build()
		arrow = { gui = gui, name = name, shooter = nil, connection = nil }
		arrows[tableModel] = arrow
	end
	if arrow.connection then
		arrow.connection:Disconnect()
		arrow.connection = nil
	end
	arrow.shooter = shooter
	if shooter and shooter:IsA("Player") then
		arrow.connection = shooter.CharacterAdded:Connect(function(character: Model)
			character:WaitForChild("Head")
			update(arrow)
		end)
	end
	update(arrow)
end

-- Hides every arrow while this player is in the top-down view
function TurnArrow.setHidden(inView: boolean)
	hidden = inView
	for _, arrow in arrows do
		update(arrow)
	end
end

function TurnArrow.start()
	playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	Remotes.TurnStarted.OnClientEvent:Connect(function(model: Model?, shooter: Seat.Seat?)
		if model then
			show(model, shooter)
		end
	end)
end

return TurnArrow
