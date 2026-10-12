--!strict
-- The shooter's controls. F (phones: an on-screen button) switches to a top-down view of the table and back.
-- In the view, walking is off so the keys only aim.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Config = require(ReplicatedStorage.Shared.Config)
local Theme = require(ReplicatedStorage.Shared.Theme)

local VIEW_ACTION = "TopDownView"

local ShotController = {}

-- `leftReserve` is screen width, in pixels, that the view keeps clear on the left for other UI
function ShotController.start(tableModel: Model, leftReserve: number)
	local felt = tableModel:WaitForChild("Felt") :: BasePart
	-- Roblox's current player module lives in StarterPlayer and moves the character through input actions, so
	-- switching off its character context is what stops walking and jumping. Disabling its controls hides the
	-- phone thumbstick and jump button.
	local playerModule = StarterPlayer:WaitForChild("PlayerModule")
	local characterInput = playerModule:WaitForChild("InputContexts"):WaitForChild("CharacterContext") :: InputContext
	local controls = require(playerModule:WaitForChild("ControlModule") :: ModuleScript) :: any

	-- The camera's settings from before the view, and the connection that keeps the table framed, while it's on
	local saved: { cameraType: Enum.CameraType, cframe: CFrame, fieldOfView: number, resize: RBXScriptConnection }? = nil

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

	local function leaveView()
		if not saved then
			return
		end
		local camera = workspace.CurrentCamera
		saved.resize:Disconnect()
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
			resize = camera:GetPropertyChangedSignal("ViewportSize"):Connect(frame),
		}
		camera.CameraType = Enum.CameraType.Scriptable
		frame()
		characterInput.Enabled = false
		controls:Disable()
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
