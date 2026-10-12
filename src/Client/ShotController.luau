--!strict
-- The shooter's controls. F (phones: an on-screen button) switches to a top-down view of the table and back.
-- In the view, walking is off, a cue stick lies behind the cue ball, and A/D, the arrow keys or dragging
-- around the cue ball turn it.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local TableSpace = require(ReplicatedStorage.Shared.TableSpace)
local Theme = require(ReplicatedStorage.Shared.Theme)

local VIEW_ACTION = "TopDownView"
local AIM_ACTION = "Aim"
-- Negative turns the aim to the shooter's left, which is counterclockwise on screen
local TURN_KEYS: { [Enum.KeyCode]: number } = {
	[Enum.KeyCode.A] = -1,
	[Enum.KeyCode.Left] = -1,
	[Enum.KeyCode.D] = 1,
	[Enum.KeyCode.Right] = 1,
}

local ShotController = {}

-- `leftReserve` is screen width, in pixels, that the view keeps clear on the left for other UI
function ShotController.start(tableModel: Model, leftReserve: number)
	local felt = tableModel:WaitForChild("Felt") :: BasePart
	local cueBall = tableModel:WaitForChild("Balls"):WaitForChild("Ball0") :: BasePart
	-- Roblox's current player module lives in StarterPlayer and moves the character through input actions, so
	-- switching off its character context is what stops walking and jumping. Disabling its controls hides the
	-- phone thumbstick and jump button.
	local playerModule = StarterPlayer:WaitForChild("PlayerModule")
	local characterInput = playerModule:WaitForChild("InputContexts"):WaitForChild("CharacterContext") :: InputContext
	local controls = require(playerModule:WaitForChild("ControlModule") :: ModuleScript) :: any

	local radius = Config.Table.BallRadius
	local cueLength = Config.Aim.CueLength * Config.Table.Length
	-- From the cue ball's center to the cue's center
	local cueBack = radius * (1 + Config.Aim.CueTipGap) + cueLength / 2
	local cueHeight = radius * Config.Aim.CueHeight

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

	-- Radians in table space: 0 aims along +x, at the rack
	local aim = 0
	-- The key turning the aim, which way, and when it went down
	local turning: { key: Enum.KeyCode, sign: number, since: number }? = nil
	-- The mouse button or finger dragging the aim, and its last angle around the cue ball
	local drag: { input: InputObject, angle: number? }? = nil
	local rolling = false

	-- The camera's settings from before the view, and everything the view connected, while it's on
	local saved: { cameraType: Enum.CameraType, cframe: CFrame, fieldOfView: number, connections: { RBXScriptConnection } }? =
		nil

	local function frame()
		local camera = workspace.CurrentCamera
		local viewport = camera.ViewportSize
		local rightReserve = Theme.Ui.MeterReserve
		local freeShare = 1 - (leftReserve + rightReserve) / viewport.X
		local tanHalfHeight = math.tan(math.rad(Config.Camera.TopDownFieldOfView / 2))
		local tanHalfWidth = tanHalfHeight * viewport.X / viewport.Y
		-- High enough that the whole table fits between the reserves, with its length across the screen
		local height = Config.Camera.TopDownMargin
			* math.max(Config.Table.Length / 2 / (tanHalfWidth * freeShare), Config.Table.Width / 2 / tanHalfHeight)
		-- Slide the view so the table sits in the middle of the space the reserves leave
		local shift = (leftReserve - rightReserve) / viewport.X * height * tanHalfWidth
		camera.FieldOfView = Config.Camera.TopDownFieldOfView
		camera.CFrame = CFrame.fromMatrix(
			felt.Position + felt.CFrame.UpVector * height - felt.CFrame.RightVector * shift,
			felt.CFrame.RightVector,
			felt.CFrame.LookVector
		)
	end

	-- The pointer's angle around the cue ball in table space, or nil too close to the ball to be steady
	local function pointerAngle(screenPosition: Vector3): number?
		local ray = workspace.CurrentCamera:ScreenPointToRay(screenPosition.X, screenPosition.Y)
		local up = felt.CFrame.UpVector
		-- Where the ray meets the plane of the felt's top, so a drag off the table edge still turns the aim
		local distance = (felt.Position + up * felt.Size.Y / 2 - ray.Origin):Dot(up) / ray.Direction:Dot(up)
		local x, y = TableSpace.toTable(felt, ray.Origin + ray.Direction * distance)
		local cueX, cueY = TableSpace.toTable(felt, cueBall.Position)
		local dx, dy = x - cueX, y - cueY
		if dx * dx + dy * dy < (Config.Aim.DragDeadZone * radius) ^ 2 then
			return nil
		end
		return math.atan2(dy, dx)
	end

	local function render(dt: number)
		if turning then
			local heldFor = os.clock() - turning.since - Config.Aim.HoldDelaySeconds
			if heldFor > 0 then
				local ramp = math.min(heldFor / Config.Aim.HoldRampSeconds, 1)
				local speed = Config.Aim.HoldStartSpeed + (Config.Aim.HoldMaxSpeed - Config.Aim.HoldStartSpeed) * ramp
				aim += turning.sign * math.rad(speed) * dt
			end
		end
		local hidden = rolling or cueBall.Transparency == 1
		cue.Transparency = if hidden then 1 else 0
		if not hidden then
			local cueX, cueY = TableSpace.toTable(felt, cueBall.Position)
			cue.CFrame = TableSpace.toWorld(
				felt,
				cueX - math.cos(aim) * cueBack,
				cueY - math.sin(aim) * cueBack,
				cueHeight
			) * CFrame.Angles(0, -aim, 0)
		end
	end

	local function turnByKey(_, state: Enum.UserInputState, input: InputObject): Enum.ContextActionResult
		local sign = TURN_KEYS[input.KeyCode]
		if state == Enum.UserInputState.Begin then
			aim += sign * math.rad(Config.Aim.NudgeDegrees)
			turning = { key = input.KeyCode, sign = sign, since = os.clock() }
		elseif turning and turning.key == input.KeyCode then
			turning = nil
		end
		return Enum.ContextActionResult.Sink
	end

	local function dragBegan(input: InputObject, gameProcessed: boolean)
		if
			not gameProcessed
			and (
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			drag = { input = input, angle = pointerAngle(input.Position) }
		end
	end

	local function dragMoved(input: InputObject)
		if
			drag
			and (
				input == drag.input
				or (
					input.UserInputType == Enum.UserInputType.MouseMovement
					and drag.input.UserInputType == Enum.UserInputType.MouseButton1
				)
			)
		then
			local angle = pointerAngle(input.Position)
			if angle and drag.angle then
				-- The aim turns as far as the pointer swept around the cue ball, the short way round
				aim += (angle - drag.angle + math.pi) % (2 * math.pi) - math.pi
			end
			drag.angle = angle
		end
	end

	local function dragEnded(input: InputObject)
		if drag and input == drag.input then
			drag = nil
		end
	end

	local function leaveView()
		if not saved then
			return
		end
		local camera = workspace.CurrentCamera
		for _, connection in saved.connections do
			connection:Disconnect()
		end
		ContextActionService:UnbindAction(AIM_ACTION)
		turning, drag = nil, nil
		cue.Transparency = 1
		camera.CameraType = saved.cameraType
		camera.CFrame = saved.cframe
		camera.FieldOfView = saved.fieldOfView
		saved = nil
		characterInput.Enabled = true
		controls:Enable()
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
				UserInputService.InputBegan:Connect(dragBegan),
				UserInputService.InputChanged:Connect(dragMoved),
				UserInputService.InputEnded:Connect(dragEnded),
			},
		}
		camera.CameraType = Enum.CameraType.Scriptable
		frame()
		characterInput.Enabled = false
		controls:Disable()
		ContextActionService:BindAction(
			AIM_ACTION,
			turnByKey,
			false,
			Enum.KeyCode.A,
			Enum.KeyCode.D,
			Enum.KeyCode.Left,
			Enum.KeyCode.Right
		)
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

	Remotes.ShotStarted.OnClientEvent:Connect(function(shotTable: Model?)
		if shotTable == tableModel then
			rolling = true
		end
	end)
	Remotes.ShotResolved.OnClientEvent:Connect(function(shotTable: Model?)
		if shotTable == tableModel then
			rolling = false
		end
	end)

	-- A new character gets fresh controls and camera, so start it in the normal view
	Players.LocalPlayer.CharacterAdded:Connect(leaveView)
end

return ShotController
