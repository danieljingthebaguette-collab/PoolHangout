--!strict
-- "Nice shot!" rising from a pocket and fading, when the shooter sinks one of theirs off a rail or across the table (the
-- server's NiceShot). It floats over the pocket itself, so it shows in either view, for everyone at that table.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Geometry = require(ReplicatedStorage.Shared.Physics.Geometry)
local PhysicsTestAccess = require(ReplicatedStorage.Shared.PhysicsTestAccess)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local TableSpace = require(ReplicatedStorage.Shared.TableSpace)
local Theme = require(ReplicatedStorage.Shared.Theme)
local Banner = require(script.Parent.Banner)
local Ui = require(script.Parent.Ui)

local NiceShot = {}

local function show(tableModel: Model, pocketId: number)
	local felt = tableModel:FindFirstChild("Felt")
	local pocket = Geometry.build(PhysicsTestAccess.params().Table).pockets[pocketId]
	if not (felt and felt:IsA("BasePart") and pocket) then
		return
	end
	local look = Theme.Ui
	local anchor = Instance.new("Attachment")
	anchor.Parent = felt
	anchor.WorldPosition = TableSpace.toWorld(felt, pocket.x, pocket.y, 0).Position
	local board = Instance.new("BillboardGui")
	board.Size = UDim2.fromOffset(look.NiceShotWidth, look.NiceShotTextSize + look.NiceShotRise)
	board.AlwaysOnTop = true
	board.Adornee = anchor
	board.Parent = anchor
	local label = Ui.label("Nice shot!", board)
	label.AnchorPoint = Vector2.new(0.5, 1)
	label.Position = UDim2.fromScale(0.5, 1)
	label.Size = UDim2.new(1, 0, 0, look.NiceShotTextSize)
	label.TextSize = look.NiceShotTextSize
	label.TextColor3 = Theme.Colors.Button
	local edge = Instance.new("UIStroke")
	edge.Color = Theme.Colors.Text
	edge.Thickness = look.NiceShotEdge
	edge.Parent = label
	local rise = TweenInfo.new(look.NiceShotSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(label, rise, { Position = UDim2.new(0.5, 0, 1, -look.NiceShotRise) }):Play()
	-- Fades over the second half
	local fade = TweenInfo.new(
		look.NiceShotSeconds / 2,
		Enum.EasingStyle.Linear,
		Enum.EasingDirection.In,
		0,
		false,
		look.NiceShotSeconds / 2
	)
	TweenService:Create(label, fade, { TextTransparency = 1 }):Play()
	TweenService:Create(edge, fade, { Transparency = 1 }):Play()
	task.delay(look.NiceShotSeconds, anchor.Destroy, anchor)
end

function NiceShot.start()
	Remotes.NiceShot.OnClientEvent:Connect(function(model: Model?, pocketId: number)
		if model and Banner.atTable(model) then
			show(model, pocketId)
		end
	end)
end

return NiceShot
