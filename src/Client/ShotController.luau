--!strict
-- The shooter's controls. F (phones: an on-screen button) switches to a top-down view of the table and back.
-- You can only aim and shoot from the view: walking is off and a cue stick lies behind the cue ball.
-- Aim: on PC only the mouse aims; on phones dragging turns the aim around the cue ball. Power is a slingshot
-- pull: hold the mouse button anywhere (phones: touch near the cue ball) and drag. Power counts from the edge
-- of a small cancel zone around where you pressed, and letting go shoots; letting go back inside the zone
-- cancels. Space (phones: the Lock button) optionally locks the aim first, and then a pull can start anywhere.
-- The aim indicator shows where the cue ball first touches something and which way a hit ball goes. It's
-- see-through while you aim or when letting go would cancel, and solid while the aim is locked. When you let
-- go, the cue strikes forward and the shot starts on this screen the moment it reaches the ball.

local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local Geometry = require(ReplicatedStorage.Shared.Physics.Geometry)
local PhysicsTestAccess = require(ReplicatedStorage.Shared.PhysicsTestAccess)
local Preview = require(ReplicatedStorage.Shared.Physics.Preview)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local TableSpace = require(ReplicatedStorage.Shared.TableSpace)
local Theme = require(ReplicatedStorage.Shared.Theme)
local TableView = require(script.Parent.TableView)

local VIEW_ACTION = "TopDownView"
local LOCK_ACTION = "LockAim"
local CANCEL_HINT = "Let go to cancel"
local HINTS = {
	keyboard = { aiming = "Hold and drag to shoot · Space: lock aim", locked = "Drag to shoot · Space: unlock" },
	touch = {
		aiming = "Drag from the cue ball to shoot · Tap Lock to lock aim",
		locked = "Drag to shoot · Tap Lock to unlock",
	},
}

local ShotController = {}

-- Whether `input` moves the mouse button or finger that `started` pressed
local function movesPointer(input: InputObject, started: InputObject): boolean
	return input == started
		or (
			input.UserInputType == Enum.UserInputType.MouseMovement
			and started.UserInputType == Enum.UserInputType.MouseButton1
		)
end

-- False once a mouse button that `started` pressed is up. The game can miss its release, for example when it's
-- let go outside the window, and plain mouse movement would then keep dragging.
local function stillHeld(started: InputObject): boolean
	return started.UserInputType ~= Enum.UserInputType.MouseButton1
		or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
end

local function roundCorners(item: GuiObject, radius: UDim?)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = radius or UDim.new(0.5, 0)
	corner.Parent = item
end

local function styleText(label: TextLabel | TextButton, text: string)
	label.Font = Theme.Font
	label.TextSize = Theme.TextSize
	label.TextColor3 = Theme.Colors.Text
	label.Text = text
end

-- `onView` hears when the top-down view turns on and off, for the HUD and anything else that only shows there
function ShotController.start(tableModel: Model, onView: (boolean) -> ())
	local felt = tableModel:WaitForChild("Felt") :: BasePart
	local ballFolder = tableModel:WaitForChild("Balls")
	local ballParts: { [number]: BasePart } = {}
	for id = 0, 15 do
		ballParts[id] = ballFolder:WaitForChild(`Ball{id}`) :: BasePart
	end
	local cueBall = ballParts[0]
	-- Roblox's current player module lives in StarterPlayer and moves the character through input actions, so
	-- switching off its character context is what stops walking and jumping. Disabling its controls hides the
	-- phone thumbstick and jump button.
	local playerModule = StarterPlayer:WaitForChild("PlayerModule")
	local characterInput = playerModule:WaitForChild("InputContexts"):WaitForChild("CharacterContext") :: InputContext
	local controls = require(playerModule:WaitForChild("ControlModule") :: ModuleScript) :: any
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local hints = if UserInputService.TouchEnabled then HINTS.touch else HINTS.keyboard

	local radius = Config.Table.BallRadius
	local cueLength = Config.Aim.CueLength * Config.Table.Length
	-- From the cue ball's center to the cue's tip, and to the cue's center
	local tipBack = radius * (1 + Config.Aim.CueTipGap)
	local cueBack = tipBack + cueLength / 2
	local cueHeight = radius * Config.Aim.CueHeight
	local cancelRadius = Config.Shot.CancelRadius * radius
	local fullPull = Config.Shot.FullPullDistance * Config.Table.Length

	-- Only this screen sees the cue
	local cue = Instance.new("Part")
	cue.Name = "Cue"
	cue.Shape = Enum.PartType.Cylinder
	cue.Size = Vector3.new(cueLength, 2 * radius * Config.Aim.CueThickness, 2 * radius * Config.Aim.CueThickness)
	cue.Color = Theme.Colors.Cue
	cue.Anchored = true
	cue.CanCollide = false
	cue.CanTouch = false
	cue.CanQuery = false
	cue.CastShadow = false
	cue.Transparency = 1
	cue.Parent = tableModel

	-- The power meter on the left with its % readout, the phones' Lock button beside it, and the hint. The meter
	-- only shows the pull; you don't drag it.
	local meterGui = Instance.new("ScreenGui")
	meterGui.Name = "PowerMeter"
	meterGui.ResetOnSpawn = false
	meterGui.Enabled = false
	-- Centered in the space the view keeps clear on the left. Active, so pressing it doesn't start a pull.
	local track = Instance.new("Frame")
	track.AnchorPoint = Vector2.new(0.5, 0.5)
	track.Position = UDim2.new(0, Theme.Ui.MeterReserve / 2, 0.5, 0)
	track.Size = UDim2.new(0, Theme.Ui.MeterTrack, Theme.Ui.MeterHeight, 0)
	track.BackgroundColor3 = Theme.Colors.Track
	track.BorderSizePixel = 0
	track.Active = true
	track.Parent = meterGui
	roundCorners(track, UDim.new(0, Theme.Ui.Corner))
	-- Fills up from the bottom as you pull
	local fill = Instance.new("Frame")
	fill.AnchorPoint = Vector2.new(0, 1)
	fill.Position = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = Theme.Colors.Fill
	fill.BorderSizePixel = 0
	fill.Parent = track
	roundCorners(fill, UDim.new(0, Theme.Ui.Corner))
	local percent = Instance.new("TextLabel")
	percent.AnchorPoint = Vector2.new(0.5, 0)
	percent.Position = UDim2.new(0, Theme.Ui.MeterReserve / 2, 0.5 + Theme.Ui.MeterHeight / 2, Theme.Ui.Padding)
	percent.Size = UDim2.fromOffset(Theme.Ui.MeterReserve, Theme.Ui.PercentTextSize)
	percent.BackgroundTransparency = 1
	percent.Parent = meterGui
	styleText(percent, "0%")
	percent.TextSize = Theme.Ui.PercentTextSize
	percent.TextColor3 = Theme.Colors.HudSubtle
	-- Beside the meter, where a thumb resting near it reaches
	local lockButton = Instance.new("TextButton")
	lockButton.AnchorPoint = Vector2.new(0, 0.5)
	lockButton.Position = UDim2.new(0, Theme.Ui.MeterReserve, 0.5, 0)
	lockButton.Size = UDim2.fromOffset(Theme.Ui.LockButtonWidth, Theme.Ui.ButtonHeight)
	lockButton.BackgroundColor3 = Theme.Colors.Button
	lockButton.AutoButtonColor = true
	lockButton.Visible = UserInputService.TouchEnabled
	lockButton.Parent = meterGui
	styleText(lockButton, "Lock")
	roundCorners(lockButton, UDim.new(0, Theme.Ui.Corner))
	local hint = Instance.new("TextLabel")
	hint.AnchorPoint = Vector2.new(0.5, 1)
	hint.Position = UDim2.new(0.5, 0, 1, -Theme.Ui.Padding)
	hint.Size = UDim2.fromOffset(0, Theme.TextSize + Theme.Ui.Padding)
	hint.AutomaticSize = Enum.AutomaticSize.X
	hint.BackgroundColor3 = Theme.Colors.Panel
	hint.Parent = meterGui
	styleText(hint, hints.aiming)
	roundCorners(hint, UDim.new(0, Theme.Ui.Corner))
	local hintPadding = Instance.new("UIPadding")
	hintPadding.PaddingLeft = UDim.new(0, Theme.Ui.Padding)
	hintPadding.PaddingRight = hintPadding.PaddingLeft
	hintPadding.Parent = hint
	meterGui.Parent = playerGui

	-- The aim indicator, the lock icon and the cancel ring. Only this screen sees them. They're drawn on the
	-- screen over the fixed top-down view: 3D line adornments came out broken up and hidden behind balls, and a
	-- hollow cylinder shows nothing from straight above.
	local layout = Geometry.build(Config.Table)
	local indicatorGui = Instance.new("ScreenGui")
	indicatorGui.Name = "AimIndicator"
	indicatorGui.ResetOnSpawn = false
	indicatorGui.IgnoreGuiInset = true -- so the camera's viewport points place it directly
	local function indicatorLine(): Frame
		local line = Instance.new("Frame")
		line.AnchorPoint = Vector2.new(0.5, 0.5)
		line.BackgroundColor3 = Theme.Colors.AimLine
		line.BorderSizePixel = 0
		line.Visible = false
		line.Parent = indicatorGui
		return line
	end
	local pathLine, targetLine = indicatorLine(), indicatorLine()
	-- A ball-sized ring where the cue ball will be when it first touches something
	local ghost = Instance.new("Frame")
	ghost.AnchorPoint = Vector2.new(0.5, 0.5)
	ghost.BackgroundTransparency = 1
	ghost.Visible = false
	ghost.Parent = indicatorGui
	roundCorners(ghost)
	local ghostOutline = Instance.new("UIStroke")
	ghostOutline.Color = Theme.Colors.AimLine
	ghostOutline.Thickness = Theme.Ui.AimLineThickness
	ghostOutline.Parent = ghost
	indicatorGui.Parent = playerGui

	-- Radians in table space: 0 aims along +x, at the rack
	local aim = 0
	-- Locked with Space or the Lock button. A pull also holds the aim still, locked or not.
	local locked = false
	-- The finger dragging the aim around the cue ball, and its last angle there
	local drag: { input: InputObject, angle: number? }? = nil
	-- The mouse button or finger pulling for power, where it pressed in table space, and whether it has left
	-- the cancel ring yet
	local pulling: { input: InputObject, x: number, y: number, left: boolean }? = nil
	-- How far the cue is pulled back, 0 to 1: the shot's power
	local pull = 0
	-- After you let go: the shot's power and how far the cue has come forward, 0 to 1, until it reaches the ball
	local strike: { power: number, t: number }? = nil

	-- The camera's settings from before the view, and everything the view connected, while it's on
	local saved: { cameraType: Enum.CameraType, cframe: CFrame, fieldOfView: number, connections: { RBXScriptConnection } }? =
		nil

	-- Screen space, in pixels, the view keeps clear around the table for the HUD: the meter (and on phones the Lock
	-- button) on the left, the sunk-ball tray on the right, the top bar's cards above and the hint below
	local reserve = {
		left = Theme.Ui.MeterReserve
			+ (if UserInputService.TouchEnabled then Theme.Ui.LockButtonWidth + Theme.Ui.Padding else 0),
		right = Theme.Ui.TrayReserve,
		top = Theme.Ui.CardHeight + 2 * Theme.Ui.Padding,
		bottom = Theme.TextSize + 3 * Theme.Ui.Padding,
	}

	local function frame()
		local camera = workspace.CurrentCamera
		local viewport = camera.ViewportSize
		local freeWidth = 1 - (reserve.left + reserve.right) / viewport.X
		local freeHeight = 1 - (reserve.top + reserve.bottom) / viewport.Y
		local tanHalfHeight = math.tan(math.rad(Config.Camera.TopDownFieldOfView / 2))
		local tanHalfWidth = tanHalfHeight * viewport.X / viewport.Y
		-- High enough that the whole table fits between the reserves, with its length across the screen
		local margin = Config.Camera.TopDownMargin
		local height = math.max(
			(Config.Table.Length / 2 + margin) / (tanHalfWidth * freeWidth),
			(Config.Table.Width / 2 + margin) / (tanHalfHeight * freeHeight)
		)
		-- Slide the view so the table sits in the middle of the space the reserves leave. The screen's up is the
		-- felt's LookVector.
		local shiftX = (reserve.left - reserve.right) / viewport.X * height * tanHalfWidth
		local shiftY = (reserve.top - reserve.bottom) / viewport.Y * height * tanHalfHeight
		camera.FieldOfView = Config.Camera.TopDownFieldOfView
		camera.CFrame = CFrame.fromMatrix(
			felt.Position
				+ felt.CFrame.UpVector * height
				- felt.CFrame.RightVector * shiftX
				+ felt.CFrame.LookVector * shiftY,
			felt.CFrame.RightVector,
			felt.CFrame.LookVector
		)
	end

	-- Where a table-space point at ball-center height is on the screen
	local function toScreen(x: number, y: number): Vector2
		local point = workspace.CurrentCamera:WorldToViewportPoint(TableSpace.toWorld(felt, x, y, radius).Position)
		return Vector2.new(point.X, point.Y)
	end

	local function hideIndicator()
		pathLine.Visible, targetLine.Visible, ghost.Visible = false, false, false
	end

	-- See-through while aiming or about to cancel, solid while the aim is locked
	local function fadeIndicator(faint: boolean)
		local transparency = if faint then Theme.Ui.AimFaintTransparency else 0
		pathLine.BackgroundTransparency, targetLine.BackgroundTransparency = transparency, transparency
		ghostOutline.Transparency = transparency
	end

	local function showLine(line: Frame, fromX: number, fromY: number, toX: number, toY: number)
		local from, to = toScreen(fromX, fromY), toScreen(toX, toY)
		local middle, along = (from + to) / 2, to - from
		line.Position = UDim2.fromOffset(middle.X, middle.Y)
		line.Size = UDim2.fromOffset(along.Magnitude, Theme.Ui.AimLineThickness)
		line.Rotation = math.deg(math.atan2(along.Y, along.X))
		line.Visible = true
	end

	local function drawIndicator(cueX: number, cueY: number)
		local balls: { Preview.Ball } = {}
		for id, part in ballParts do
			if part.Transparency ~= 1 then
				local x, y = TableSpace.toTable(felt, part.Position)
				table.insert(balls, { id = id, x = x, y = y })
			end
		end
		local contact = Preview.firstContact(balls, math.cos(aim), math.sin(aim), Config.Table, layout)
		if Config.Aim.ShowAimLine then
			showLine(pathLine, cueX, cueY, contact.x, contact.y)
			local middle = toScreen(contact.x, contact.y)
			local diameter = 2 * (toScreen(contact.x + radius, contact.y) - middle).Magnitude
			ghost.Position = UDim2.fromOffset(middle.X, middle.Y)
			ghost.Size = UDim2.fromOffset(diameter, diameter)
			ghost.Visible = true
		end
		if Config.Aim.ShowTargetLine and contact.ball then
			local hitX, hitY = TableSpace.toTable(felt, ballParts[contact.ball].Position)
			local length = Config.Aim.TargetLineLength * radius
			showLine(
				targetLine,
				hitX,
				hitY,
				hitX + (contact.pushX :: number) * length,
				hitY + (contact.pushY :: number) * length
			)
		end
	end

	local function canShoot(): boolean
		return not TableView.isBusy(tableModel) and cueBall.Transparency ~= 1
	end

	-- The cue has reached the ball: the shot goes, here at once and to the server
	local function fire()
		local power = (strike :: { power: number, t: number }).power
		strike = nil
		pull = 0
		local shot = { dirX = math.cos(aim), dirY = math.sin(aim), power = power }
		-- ponytail: the test mode's remote, until Match (Phase 2) brings RequestShot and turns
		Remotes.TestShoot:FireServer(shot.dirX, shot.dirY, shot.power)
		TableView.predict(tableModel, shot, PhysicsTestAccess.params())
		TableView.playSound(cueBall, Config.Sounds.CueStrike, power)
	end

	-- The camera's ray through an input's position. Input positions sit below Roblox's top bar, and ScreenPointToRay
	-- allows for that.
	local function inputRay(input: InputObject): Ray
		return workspace.CurrentCamera:ScreenPointToRay(input.Position.X, input.Position.Y)
	end

	-- Where a ray from the camera meets the plane of the felt's top, in table space. Off the table's edge counts too.
	local function pointerOnTable(ray: Ray): (number, number)
		local up = felt.CFrame.UpVector
		local distance = (felt.Position + up * felt.Size.Y / 2 - ray.Origin):Dot(up) / ray.Direction:Dot(up)
		return TableSpace.toTable(felt, ray.Origin + ray.Direction * distance)
	end

	-- The pointer's angle around the cue ball, or nil too close to the ball to be steady
	local function pointerAngle(ray: Ray): number?
		local x, y = pointerOnTable(ray)
		local cueX, cueY = TableSpace.toTable(felt, cueBall.Position)
		local dx, dy = x - cueX, y - cueY
		if dx * dx + dy * dy < (Config.Aim.DragDeadZone * radius) ^ 2 then
			return nil
		end
		return math.atan2(dy, dx)
	end

	-- Whether a point is on or near the cue ball or the cue at rest
	local function nearCue(x: number, y: number): boolean
		local cueX, cueY = TableSpace.toTable(felt, cueBall.Position)
		local dirX, dirY = math.cos(aim), math.sin(aim)
		-- The closest point on the line from the cue ball's center back to the cue's butt
		local back = math.clamp(-((x - cueX) * dirX + (y - cueY) * dirY), 0, tipBack + cueLength)
		local dx, dy = x - (cueX - dirX * back), y - (cueY - dirY * back)
		return dx * dx + dy * dy <= (Config.Aim.GrabRadius * radius) ^ 2
	end

	-- Cancels a pull. The lock stays as it was before the pull: on if Space set it, off if not.
	local function cancelPull()
		pulling = nil
	end

	-- Space and the Lock button. Mid-pull, it cancels the pull and unlocks.
	local function toggleLock()
		drag = nil
		locked = not (locked or pulling ~= nil)
		pulling = nil
	end

	local function render(dt: number)
		if pulling and not stillHeld(pulling.input) then
			cancelPull()
		end
		-- On PC the cue points at the mouse, worked out every frame rather than only when the mouse moves, so it stays
		-- on the cursor when the cue ball moves under a still mouse: after a shot or a rack, or on entering the view.
		-- GetMouseLocation counts from the screen's very top, so it pairs with ViewportPointToRay.
		if UserInputService.MouseEnabled and not (locked or pulling or strike or drag) then
			local mouse = UserInputService:GetMouseLocation()
			aim = pointerAngle(workspace.CurrentCamera:ViewportPointToRay(mouse.X, mouse.Y)) or aim
		end
		local strikeOffset = 0
		if strike then
			strike.t = math.min(strike.t + dt / Config.Shot.StrikeSeconds, 1)
			-- Speeds up into the ball, from the pull to the tip touching it
			local touching = -Config.Aim.CueTipGap / Config.Aim.CuePullBack
			strikeOffset = strike.power + (touching - strike.power) * strike.t * strike.t - pull
			if strike.t >= 1 then
				fire()
				strikeOffset = 0
			end
		elseif not pulling and pull > 0 then
			pull = math.max(pull - dt / Config.Shot.MeterSpringSeconds, 0)
		end
		local hidden = not canShoot()
		cue.Transparency = if hidden then 1 else 0
		meterGui.Enabled = not hidden
		fill.Size = UDim2.fromScale(1, pull)
		percent.Text = `{math.round(pull * 100)}%`
		local held = locked or pulling ~= nil or strike ~= nil
		-- Back inside the cancel zone after leaving it, where letting go cancels
		local cancelling = pulling ~= nil and pulling.left and pull == 0
		hint.Text = if cancelling then CANCEL_HINT elseif held then hints.locked else hints.aiming
		lockButton.Text = if held then "Unlock" else "Lock"
		hideIndicator()
		if hidden then
			return
		end
		fadeIndicator(cancelling or not held)
		local cueX, cueY = TableSpace.toTable(felt, cueBall.Position)
		drawIndicator(cueX, cueY)
		local back = cueBack + (pull + strikeOffset) * radius * Config.Aim.CuePullBack
		cue.CFrame = TableSpace.toWorld(felt, cueX - math.cos(aim) * back, cueY - math.sin(aim) * back, cueHeight)
			* CFrame.Angles(0, -aim, 0)
	end

	local function pointerBegan(input: InputObject, gameProcessed: boolean)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			cancelPull()
			return
		end
		local isTouch = input.UserInputType == Enum.UserInputType.Touch
		if
			gameProcessed
			or pulling
			or strike
			or not (isTouch or input.UserInputType == Enum.UserInputType.MouseButton1)
		then
			return
		end
		local x, y = pointerOnTable(inputRay(input))
		-- Unlocked, a touch away from the cue ball turns the aim instead
		if locked or not isTouch or nearCue(x, y) then
			if canShoot() then
				pulling = { input = input, x = x, y = y, left = false }
				pull = 0
			end
		elseif not drag then
			drag = { input = input, angle = pointerAngle(inputRay(input)) }
		end
	end

	local function pointerMoved(input: InputObject)
		if pulling then
			if movesPointer(input, pulling.input) then
				local x, y = pointerOnTable(inputRay(input))
				-- Any direction counts, so a cue ball against a rail can still get full power. Power counts from
				-- the cancel ring's edge, so soft shots still work.
				local beyond = math.sqrt((x - pulling.x) ^ 2 + (y - pulling.y) ^ 2) - cancelRadius
				if beyond > 0 then
					pulling.left = true
				end
				pull = math.clamp(beyond / fullPull, 0, 1)
			end
		elseif drag and input == drag.input then
			local angle = pointerAngle(inputRay(input))
			if angle and drag.angle then
				-- The aim turns as far as the finger swept around the cue ball, the short way round
				aim += (angle - drag.angle + math.pi) % (2 * math.pi) - math.pi
			end
			drag.angle = angle
		end
	end

	local function pointerEnded(input: InputObject)
		if pulling and input == pulling.input then
			-- Letting go inside the cancel ring fires nothing, and the lock stays as it was
			if pull > 0 then
				strike = { power = pull, t = 0 }
				-- Each new shot starts unlocked
				locked = false
			end
			pulling = nil
		elseif drag and input == drag.input then
			drag = nil
		end
	end

	lockButton.Activated:Connect(toggleLock)

	local function leaveView()
		if not saved then
			return
		end
		local camera = workspace.CurrentCamera
		for _, connection in saved.connections do
			connection:Disconnect()
		end
		ContextActionService:UnbindAction(LOCK_ACTION)
		-- A shot you've let go of still goes
		if strike then
			fire()
		end
		-- Leaving mid-pull cancels the shot, and the view starts over unlocked
		drag, pulling, pull, locked = nil, nil, 0, false
		cue.Transparency = 1
		meterGui.Enabled = false
		hideIndicator()
		camera.CameraType = saved.cameraType
		camera.CFrame = saved.cframe
		camera.FieldOfView = saved.fieldOfView
		saved = nil
		characterInput.Enabled = true
		controls:Enable()
		onView(false)
	end

	local function enterView()
		local camera = workspace.CurrentCamera
		saved = {
			cameraType = camera.CameraType,
			cframe = camera.CFrame,
			fieldOfView = camera.FieldOfView,
			connections = {
				camera:GetPropertyChangedSignal("ViewportSize"):Connect(frame),
				RunService.RenderStepped:Connect(render),
				UserInputService.InputBegan:Connect(pointerBegan),
				UserInputService.InputChanged:Connect(pointerMoved),
				UserInputService.InputEnded:Connect(pointerEnded),
				-- Esc opens Roblox's menu, which the game can't bind, so opening the menu is what cancels
				GuiService.MenuOpened:Connect(cancelPull),
			},
		}
		camera.CameraType = Enum.CameraType.Scriptable
		frame()
		characterInput.Enabled = false
		controls:Disable()
		onView(true)
		ContextActionService:BindAction(LOCK_ACTION, function(_, state: Enum.UserInputState)
			if state == Enum.UserInputState.Begin then
				toggleLock()
			end
			return Enum.ContextActionResult.Sink
		end, false, Enum.KeyCode.Space)
	end

	ContextActionService:BindAction(VIEW_ACTION, function(_, state: Enum.UserInputState)
		if state == Enum.UserInputState.Begin then
			if saved then
				leaveView()
			else
				enterView()
			end
		end
		return Enum.ContextActionResult.Sink
	end, true, Enum.KeyCode.F)
	ContextActionService:SetTitle(VIEW_ACTION, "View")

	-- A new character gets fresh controls and camera, so start it in the normal view
	Players.LocalPlayer.CharacterAdded:Connect(leaveView)
end

return ShotController
