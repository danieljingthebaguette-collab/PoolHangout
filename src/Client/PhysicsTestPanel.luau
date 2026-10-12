--!strict
-- Physics test mode (Studio only, see Config.Debug.PhysicsTest): R or the Rack button racks Table1, and
-- clicking or tapping the felt shoots the cue ball toward that spot.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local TableSpace = require(ReplicatedStorage.Shared.TableSpace)
local Theme = require(ReplicatedStorage.Shared.Theme)

-- How far from the camera a click can find the felt
local CLICK_REACH = 1000

local PhysicsTestPanel = {}

local function style(item: TextLabel | TextButton, text: string)
	item.Size = UDim2.new(1, 0, 0, Theme.Ui.ButtonHeight)
	item.BackgroundTransparency = 1
	item.Font = Theme.Font
	item.TextSize = Theme.TextSize
	item.TextColor3 = Theme.Colors.Text
	item.Text = text
end

function PhysicsTestPanel.start()
	local tableModel = workspace:WaitForChild("Tables"):WaitForChild("Table1")
	local felt = tableModel:WaitForChild("Felt") :: BasePart
	local feltOnly = RaycastParams.new()
	feltOnly.FilterType = Enum.RaycastFilterType.Include
	feltOnly.FilterDescendantsInstances = { felt }

	local function shootAt(viewportPoint: Vector2)
		local cue = tableModel:FindFirstChild("Ball0", true) :: BasePart?
		local ray = workspace.CurrentCamera:ViewportPointToRay(viewportPoint.X, viewportPoint.Y)
		local hit = workspace:Raycast(ray.Origin, ray.Direction * CLICK_REACH, feltOnly)
		if not (cue and hit) then
			return
		end
		local x, y = TableSpace.toTable(felt, hit.Position)
		local cueX, cueY = TableSpace.toTable(felt, cue.Position)
		Remotes.TestShoot:FireServer(x - cueX, y - cueY, 1)
	end

	UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
		if gameProcessed then
			return
		elseif input.KeyCode == Enum.KeyCode.R then
			Remotes.TestRack:FireServer()
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			shootAt(UserInputService:GetMouseLocation())
		end
	end)
	UserInputService.TouchTapInWorld:Connect(function(position: Vector2, processedByUI: boolean)
		if not processedByUI then
			shootAt(position)
		end
	end)

	local gui = Instance.new("ScreenGui")
	gui.Name = "PhysicsTest"
	gui.ResetOnSpawn = false

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0, 0.5)
	panel.Position = UDim2.new(0, Theme.Ui.Padding, 0.5, 0)
	panel.Size = UDim2.fromOffset(Theme.Ui.PanelWidth, 0)
	panel.AutomaticSize = Enum.AutomaticSize.Y
	panel.BackgroundColor3 = Theme.Colors.Panel
	panel.Active = true
	panel.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, Theme.Ui.Corner)
	corner.Parent = panel
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, Theme.Ui.Padding)
	padding.PaddingBottom = padding.PaddingTop
	padding.PaddingLeft = padding.PaddingTop
	padding.PaddingRight = padding.PaddingTop
	padding.Parent = panel
	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, Theme.Ui.Padding)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = panel

	local hint = Instance.new("TextLabel")
	style(hint, "Click the felt to shoot")
	hint.Parent = panel

	local rackButton = Instance.new("TextButton")
	style(rackButton, "Rack (R)")
	rackButton.BackgroundTransparency = 0
	rackButton.BackgroundColor3 = Theme.Colors.Button
	rackButton.LayoutOrder = 1
	corner:Clone().Parent = rackButton
	rackButton.Activated:Connect(function()
		Remotes.TestRack:FireServer()
	end)
	rackButton.Parent = panel

	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

return PhysicsTestPanel
