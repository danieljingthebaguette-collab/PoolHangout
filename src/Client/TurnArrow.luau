--!strict
-- The "Turn" arrow over each table's shooter, for everyone to see in the normal view: a gold card with a point under it,
-- over the shooter's head. Drawn from the server's TurnStarted, and gone while nobody's turn is on. The top-down view
-- hides it, since the top bar's glow shows the turn there.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Theme = require(ReplicatedStorage.Shared.Theme)
local Ui = require(script.Parent.Ui)

local TurnArrow = {}

-- Each table's arrow, its shooter, and the connection that moves it onto their new character after a respawn
type Arrow = { gui: BillboardGui, shooter: Player?, connection: RBXScriptConnection? }
local arrows: { [Model]: Arrow } = {}
local hidden = false
local playerGui: Instance? = nil

local function build(): BillboardGui
	local ui = Theme.Ui
	local gui = Instance.new("BillboardGui")
	gui.Name = "TurnArrow"
	gui.Size = UDim2.fromOffset(ui.TurnArrowWidth, ui.TurnArrowHeight + ui.TurnArrowPoint)
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
	local card = Ui.label("Turn", gui)
	card.Size = UDim2.new(1, 0, 0, ui.TurnArrowHeight)
	card.BackgroundTransparency = 0
	card.BackgroundColor3 = Theme.Colors.TurnArrow
	Ui.roundCorners(card)
	gui.Parent = playerGui
	return gui
end

local function update(arrow: Arrow)
	local character = arrow.shooter and arrow.shooter.Character
	local head = character and character:FindFirstChild("Head")
	-- Nil takes the arrow off, though the type says an Adornee is always there
	arrow.gui.Adornee = head :: Instance
	arrow.gui.Enabled = head ~= nil and not hidden
end

-- Puts a table's arrow over its shooter, or takes it away with nil
local function show(tableModel: Model, shooter: Player?)
	local arrow = arrows[tableModel]
	if not arrow then
		arrow = { gui = build(), shooter = nil, connection = nil }
		arrows[tableModel] = arrow
	end
	if arrow.connection then
		arrow.connection:Disconnect()
		arrow.connection = nil
	end
	arrow.shooter = shooter
	if shooter then
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
	Remotes.TurnStarted.OnClientEvent:Connect(function(model: Model?, shooter: Player?)
		if model then
			show(model, shooter)
		end
	end)
end

return TurnArrow
