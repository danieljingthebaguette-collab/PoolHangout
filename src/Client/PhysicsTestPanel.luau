--!strict
-- Physics test mode (Studio only, see Config.Debug.PhysicsTest): R or the Rack button racks Table1,
-- clicking or tapping the felt shoots the cue ball toward that spot with the Power slider's power, C or the
-- Top view button looks straight down at the table, and the other sliders tune the physics live for everyone.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
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

local function addCorner(item: GuiObject)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, Theme.Ui.Corner)
	corner.Parent = item
end

local function button(text: string, order: number, onPress: () -> ()): TextButton
	local item = Instance.new("TextButton")
	style(item, text)
	item.BackgroundTransparency = 0
	item.BackgroundColor3 = Theme.Colors.Button
	item.LayoutOrder = order
	addCorner(item)
	item.Activated:Connect(onPress)
	return item
end

function PhysicsTestPanel.start()
	local tableModel = workspace:WaitForChild("Tables"):WaitForChild("Table1")
	local felt = tableModel:WaitForChild("Felt") :: BasePart
	local feltOnly = RaycastParams.new()
	feltOnly.FilterType = Enum.RaycastFilterType.Include
	feltOnly.FilterDescendantsInstances = { felt }
	local power = 1

	local function shootAt(viewportPoint: Vector2)
		local cue = tableModel:FindFirstChild("Ball0", true) :: BasePart?
		local ray = workspace.CurrentCamera:ViewportPointToRay(viewportPoint.X, viewportPoint.Y)
		local hit = workspace:Raycast(ray.Origin, ray.Direction * CLICK_REACH, feltOnly)
		if not (cue and hit) then
			return
		end
		local x, y = TableSpace.toTable(felt, hit.Position)
		local cueX, cueY = TableSpace.toTable(felt, cue.Position)
		Remotes.TestShoot:FireServer(x - cueX, y - cueY, power)
	end

	-- The camera's settings from before the top view, while it's on
	local savedCamera: { cameraType: Enum.CameraType, subject: Instance? }? = nil
	local function toggleTopView()
		local camera = workspace.CurrentCamera
		if savedCamera then
			camera.CameraType = savedCamera.cameraType
			camera.CameraSubject = savedCamera.subject
			savedCamera = nil
			return
		end
		savedCamera = { cameraType = camera.CameraType, subject = camera.CameraSubject }
		-- High enough that the whole table fits beside the panel, with its length across the screen
		local panelShare = (Theme.Ui.PanelWidth + 2 * Theme.Ui.Padding) / camera.ViewportSize.X
		local tanHalfHeight = math.tan(math.rad(camera.FieldOfView / 2))
		local tanHalfWidth = tanHalfHeight * camera.ViewportSize.X / camera.ViewportSize.Y
		local height = Config.Debug.TopDownMargin
			* math.max(
				Config.Table.Length / 2 / (tanHalfWidth * (1 - panelShare)),
				Config.Table.Width / 2 / tanHalfHeight
			)
		-- Slide the view left so the table sits in the middle of the space the panel leaves
		local shift = panelShare * height * tanHalfWidth
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = CFrame.fromMatrix(
			felt.Position + felt.CFrame.UpVector * height - felt.CFrame.RightVector * shift,
			felt.CFrame.RightVector,
			felt.CFrame.LookVector
		)
	end

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
	addCorner(panel)
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, Theme.Ui.Padding)
	padding.PaddingBottom = padding.PaddingTop
	padding.PaddingLeft = padding.PaddingTop
	padding.PaddingRight = padding.PaddingTop
	padding.Parent = panel
	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, Theme.Ui.Padding / 2)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = panel

	-- Rack and Top view side by side, to keep the panel short enough for small screens
	local buttonRow = Instance.new("Frame")
	buttonRow.Size = UDim2.new(1, 0, 0, Theme.Ui.ButtonHeight)
	buttonRow.BackgroundTransparency = 1
	buttonRow.Parent = panel
	local rackButton = button("Rack (R)", 0, function()
		Remotes.TestRack:FireServer()
	end)
	local topButton = button("Top view (C)", 0, toggleTopView)
	for i, item in { rackButton, topButton } do
		item.Size = UDim2.new(0.5, -Theme.Ui.Padding / 4, 1, 0)
		item.Position = UDim2.fromScale(i - 1, 0)
		item.AnchorPoint = Vector2.new(i - 1, 0)
		item.Parent = buttonRow
	end

	-- The slider being dragged, if any: where to move it, and what to do when it's let go
	local dragging: { moveTo: (number) -> (), release: () -> () }? = nil

	-- Returns a function that shows a new value on the slider
	local function slider(
		label: string,
		range: { min: number, max: number, step: number },
		value: number,
		order: number,
		onRelease: (number) -> ()
	): (number) -> ()
		local row = Instance.new("TextButton")
		style(row, "")
		row.AutoButtonColor = false
		row.LayoutOrder = order
		local text = Instance.new("TextLabel")
		style(text, "")
		text.Size = UDim2.fromScale(1, 0.5)
		text.TextXAlignment = Enum.TextXAlignment.Left
		text.Parent = row
		local bar = Instance.new("Frame")
		bar.AnchorPoint = Vector2.new(0, 0.5)
		bar.Position = UDim2.fromScale(0, 0.75)
		bar.Size = UDim2.new(1, 0, 0, Theme.Ui.SliderBar)
		bar.BackgroundColor3 = Theme.Colors.Track
		bar.BorderSizePixel = 0
		bar.Parent = row
		local fill = Instance.new("Frame")
		fill.BackgroundColor3 = Theme.Colors.Fill
		fill.BorderSizePixel = 0
		fill.Parent = bar

		local function show(newValue: number)
			value = newValue
			fill.Size = UDim2.fromScale((value - range.min) / (range.max - range.min), 1)
			text.Text = `{label}   {string.format("%g", value)}`
		end
		show(value)

		local function moveTo(x: number)
			local share = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
			local raw = range.min + share * (range.max - range.min)
			show(math.clamp(math.round(raw / range.step) * range.step, range.min, range.max))
		end
		row.InputBegan:Connect(function(input: InputObject)
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				dragging = {
					moveTo = moveTo,
					release = function()
						onRelease(value)
					end,
				}
				moveTo(input.Position.X)
			end
		end)
		row.Parent = panel
		return show
	end

	slider("Power", { min = Config.Shot.MinPull, max = 1, step = 0.01 }, power, 1, function(value: number)
		power = value
	end)
	for i, range in Config.Debug.TestSliders do
		local show = slider(
			range.name,
			range,
			Remotes.TestTune:GetAttribute(range.name) or (Config :: any)[range.group][range.name],
			i + 1,
			function(value: number)
				Remotes.TestTune:FireServer(range.name, value)
			end
		)
		Remotes.TestTune:GetAttributeChangedSignal(range.name):Connect(function()
			show(Remotes.TestTune:GetAttribute(range.name))
		end)
	end

	local printButton = button("Print values", #Config.Debug.TestSliders + 2, function()
		local lines = { "Physics test values, as the server has them:" }
		for _, range in Config.Debug.TestSliders do
			local value = string.format("%g", Remotes.TestTune:GetAttribute(range.name))
			table.insert(lines, `  {range.group}.{range.name} = {value},`)
		end
		print(table.concat(lines, "\n"))
	end)
	printButton.Parent = panel

	UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
		if gameProcessed then
			return
		elseif input.KeyCode == Enum.KeyCode.R then
			Remotes.TestRack:FireServer()
		elseif input.KeyCode == Enum.KeyCode.C then
			toggleTopView()
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			shootAt(UserInputService:GetMouseLocation())
		end
	end)
	UserInputService.TouchTapInWorld:Connect(function(position: Vector2, processedByUI: boolean)
		if not processedByUI then
			shootAt(position)
		end
	end)
	UserInputService.InputChanged:Connect(function(input: InputObject)
		if
			dragging
			and (
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			dragging.moveTo(input.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(input: InputObject)
		if
			dragging
			and (
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			dragging.release()
			dragging = nil
		end
	end)

	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

return PhysicsTestPanel
