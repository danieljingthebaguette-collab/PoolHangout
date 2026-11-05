--!strict
-- The top-down view's camera: fixed straight above the table, framed so the whole table fits between the HUD around it,
-- with its length across the screen. Entering it saves the normal camera, and leaving brings that back. ShotController
-- decides when.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local Theme = require(ReplicatedStorage.Shared.Theme)
local Hints = require(script.Parent.Hints)

local TopDownView = {}

export type View = {
	enter: () -> (),
	leave: () -> (),
	isOn: () -> boolean,
	-- Turns the normal camera to face the table from behind a seat's marker
	faceTable: (seat: number) -> (),
}

function TopDownView.new(tableModel: Model, felt: BasePart): View
	-- The camera's settings from before the view, and its framing's connection, while it's on
	local saved: { cameraType: Enum.CameraType, cframe: CFrame, fieldOfView: number, connection: RBXScriptConnection }? =
		nil

	-- Screen space, in pixels, the view keeps clear around the table for the HUD: the meter (and on phones the Lock
	-- button) on the left, the sunk-ball tray on the right, the top bar's cards above, and the gear and the control
	-- hints below
	local reserve = {
		left = Theme.Ui.MeterReserve
			+ (if UserInputService.TouchEnabled then Theme.Ui.LockButtonWidth + Theme.Ui.Padding else 0),
		right = Theme.Ui.TrayReserve,
		top = Theme.Ui.CardHeight + 2 * Theme.Ui.Padding,
		bottom = Hints.bottomBand(),
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

	local function enter()
		local camera = workspace.CurrentCamera
		saved = {
			cameraType = camera.CameraType,
			cframe = camera.CFrame,
			fieldOfView = camera.FieldOfView,
			connection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(frame),
		}
		camera.CameraType = Enum.CameraType.Scriptable
		frame()
	end

	local function leave()
		if not saved then
			return
		end
		local camera = workspace.CurrentCamera
		saved.connection:Disconnect()
		camera.CameraType = saved.cameraType
		camera.CFrame = saved.cframe
		camera.FieldOfView = saved.fieldOfView
		saved = nil
	end

	-- As a game starts the server moves each player to their seat (A1, B1, A2, B2 in turn order), and this turns their
	-- normal camera to face the table from behind it. Roblox's camera keeps only the direction and stays on the
	-- character. In the top-down view, it's the camera that leaving the view brings back.
	local function faceTable(seat: number)
		local folder = tableModel:FindFirstChild("Seats")
		local marker = folder and folder:FindFirstChild(`{if seat % 2 == 1 then "A" else "B"}{math.ceil(seat / 2)}`)
		if not (marker and marker:IsA("BasePart")) then
			return
		end
		local flat = ((felt.Position - marker.Position) * Vector3.new(1, 0, 1)).Unit
		local pitch = math.rad(Config.Camera.SeatPitch)
		local look = flat * math.cos(pitch) - Vector3.yAxis * math.sin(pitch)
		local cframe = CFrame.lookAt(marker.Position, marker.Position + look)
		if saved then
			saved.cframe = cframe
		else
			workspace.CurrentCamera.CFrame = cframe
		end
	end

	return {
		enter = enter,
		leave = leave,
		isOn = function(): boolean
			return saved ~= nil
		end,
		faceTable = faceTable,
	}
end

return TopDownView
