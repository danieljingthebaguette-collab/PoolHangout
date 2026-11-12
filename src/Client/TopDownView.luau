--!strict
-- The top-down view's camera: fixed straight above the table, framed so the whole table fits between the HUD around it,
-- with its length across the screen and the long side farthest from you at the top: from your seat, or if you have
-- none, from where you stand as the view opens. It stays that way while the view is on, so it never swirls as your
-- character moves. Close in on your turn, and a little farther out when it isn't, so you can tell at a glance. Every change eases over Config.Camera.EaseSeconds: into the view, between close and far, and back out to
-- your normal camera behind your character, which then takes over again. ShotController decides when.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local Theme = require(ReplicatedStorage.Shared.Theme)
local Hints = require(script.Parent.Hints)
local ItemSlots = require(script.Parent.ItemSlots)
local TopBar = require(script.Parent.TopBar)
local UiScale = require(script.Parent.UiScale)

local TopDownView = {}

export type View = {
	-- Eases into the view, close in or (with `far`) farther out, turned for `seat` (in turn order) if this player has one
	enter: (far: boolean, seat: number?) -> (),
	-- Eases back to the normal camera, or at once with `instant`
	leave: (instant: boolean?) -> (),
	-- Eases between close in and farther out while the view is on
	setFar: (far: boolean) -> (),
	isOn: () -> boolean,
	-- Whether it's turned round for this player, with the felt's +Z long side at the top
	isTurned: () -> boolean,
	-- Turns the normal camera to face the table from behind a seat's marker
	faceTable: (seat: number) -> (),
}

-- The normal camera to come back to: its type, which way it looks, how far it sits from your character, and its field
-- of view
type Normal = { cameraType: Enum.CameraType, look: Vector3, distance: number, fieldOfView: number }

-- The "Camera glide" setting: on, every change of view eases over Config.Camera.EaseSeconds; off, it cuts
local glide = true

function TopDownView.setGlide(on: boolean)
	glide = on
end

function TopDownView.new(tableModel: Model, felt: BasePart): View
	-- Set while the view is on, and while it eases back out to it
	local saved: Normal? = nil
	local leaving: Normal? = nil
	local far = false
	-- Turned round, with the felt's +Z long side at the top, for a viewer on its −Z side (side A's seats)
	local flipped = false
	-- An ease under way: where it started, where it's headed (worked out each frame, since the character or the screen
	-- can move meanwhile), how far through, and what to do when it ends
	local easing: { from: CFrame, fromFov: number, target: () -> (CFrame, number), t: number, done: (() -> ())? }? = nil
	local connection: RBXScriptConnection? = nil

	-- Screen space, in pixels, the view keeps clear around the table for the HUD: the meter (and on phones the Lock
	-- button) on the left, the sunk-ball tray on the right, the top bar's cards and their item strips above, and the
	-- gear and the control hints below
	local reserve = {
		left = Theme.Ui.MeterReserve
			+ (if UserInputService.TouchEnabled then Theme.Ui.LockButtonWidth + Theme.Ui.Padding else 0),
		right = Theme.Ui.TrayReserve,
		top = TopBar.height() + Theme.Ui.Padding,
		bottom = Hints.bottomBand(),
	}

	-- The top-down camera, close in or farther out
	local function framing(): (CFrame, number)
		local camera = workspace.CurrentCamera
		local viewport = camera.ViewportSize
		local s = UiScale.get()
		local freeWidth = 1 - (reserve.left + reserve.right) * s / viewport.X
		-- The bottom keeps clear for the control hints and your ability squares and bar, which scale with the screen
		local bottom = math.max(reserve.bottom * s, ItemSlots.reserve(viewport.Y))
		local freeHeight = 1 - (reserve.top * s + bottom) / viewport.Y
		local tanHalfHeight = math.tan(math.rad(Config.Camera.TopDownFieldOfView / 2))
		local tanHalfWidth = tanHalfHeight * viewport.X / viewport.Y
		-- High enough that the whole table fits between the reserves, with its length across the screen
		local margin = Config.Camera.TopDownMargin
		local height = math.max(
			(Config.Table.Length / 2 + margin) / (tanHalfWidth * freeWidth),
			(Config.Table.Width / 2 + margin) / (tanHalfHeight * freeHeight)
		) * (if far then Config.Camera.WatchingHeight else 1)
		-- Slide the view so the table sits in the middle of the space the reserves leave. The screen's up is the
		-- felt's LookVector.
		local shiftX = (reserve.left - reserve.right) * s / viewport.X * height * tanHalfWidth
		local shiftY = (reserve.top * s - bottom) / viewport.Y * height * tanHalfHeight
		-- The screen's right and up: along the felt's length, and its far long side
		local right, up = felt.CFrame.RightVector, felt.CFrame.LookVector
		if flipped then
			right, up = -right, -up
		end
		return CFrame.fromMatrix(
			felt.Position + felt.CFrame.UpVector * height - right * shiftX + up * shiftY,
			right,
			up
		),
			Config.Camera.TopDownFieldOfView
	end

	-- Where the normal camera sits now: behind your character the way it looked before the view
	local function focus(): Vector3
		local character = Players.LocalPlayer.Character
		local head = character and character:FindFirstChild("Head")
		return if head and head:IsA("BasePart") then head.Position else workspace.CurrentCamera.Focus.Position
	end
	local function normal(state: Normal): (CFrame, number)
		local at = focus()
		-- Never straight up or down: Roblox's camera can't take a look that's exactly vertical
		local look = state.look
		if math.abs(look.Y) > Config.Camera.MaxNormalPitch then
			local flat = Vector3.new(look.X, 0, look.Z)
			flat = if flat.Magnitude > 1e-3 then flat.Unit else Vector3.new(0, 0, -1)
			local y = math.sign(look.Y) * Config.Camera.MaxNormalPitch
			look = flat * math.sqrt(1 - y * y) + Vector3.new(0, y, 0)
		end
		return CFrame.lookAt(at - look * state.distance, at), state.fieldOfView
	end

	local function update(dt: number)
		local camera = workspace.CurrentCamera
		local ease = easing
		if ease then
			ease.t = if glide then math.min(ease.t + dt / Config.Camera.EaseSeconds, 1) else 1
			local smooth = ease.t * ease.t * (3 - 2 * ease.t)
			local to, toFov = ease.target()
			camera.CFrame = ease.from:Lerp(to, smooth)
			camera.FieldOfView = ease.fromFov + (toFov - ease.fromFov) * smooth
			if ease.t >= 1 then
				easing = nil
				if ease.done then
					ease.done()
				end
			end
		elseif saved then
			-- Stay framed, even when the window changes size
			camera.CFrame, camera.FieldOfView = framing()
		end
		-- The view looks straight down, which Roblox's own camera can't handle, so it keeps the camera Scriptable
		-- even if something else switched it back
		if (easing or saved) and camera.CameraType ~= Enum.CameraType.Scriptable then
			camera.CameraType = Enum.CameraType.Scriptable
		end
		if not (easing or saved) and connection then
			connection:Disconnect()
			connection = nil
		end
	end

	local function easeTo(target: () -> (CFrame, number), done: (() -> ())?)
		local camera = workspace.CurrentCamera
		easing = { from = camera.CFrame, fromFov = camera.FieldOfView, target = target, t = 0, done = done }
		if not connection then
			connection = RunService.RenderStepped:Connect(update)
		end
	end

	local function setFar(newFar: boolean)
		if saved and far ~= newFar then
			far = newFar
			easeTo(framing)
		end
	end

	local function enter(newFar: boolean, seat: number?)
		if saved then
			setFar(newFar)
			return
		end
		far = newFar
		-- Side A's seats are on the felt's −Z side; with no seat, the side this player stands on
		if seat then
			flipped = seat % 2 == 1
		else
			flipped = felt.CFrame:PointToObjectSpace(focus()).Z < 0
		end
		local camera = workspace.CurrentCamera
		if leaving then
			-- Back in before the ease out finished: the normal camera to come back to is the same
			saved, leaving = leaving, nil
		else
			local offset = camera.CFrame.Position - focus()
			saved = {
				cameraType = camera.CameraType,
				look = camera.CFrame.LookVector,
				distance = offset.Magnitude,
				fieldOfView = camera.FieldOfView,
			}
		end
		camera.CameraType = Enum.CameraType.Scriptable
		easeTo(framing)
	end

	local function leave(instant: boolean?)
		local state = saved
		if not state then
			return
		end
		saved = nil
		local camera = workspace.CurrentCamera
		local function finish()
			leaving = nil
			camera.CameraType = state.cameraType
		end
		if instant then
			easing = nil
			camera.CFrame, camera.FieldOfView = normal(state)
			finish()
			return
		end
		leaving = state
		easeTo(function(): (CFrame, number)
			return normal(state)
		end, finish)
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
		local state = saved or leaving
		if state then
			state.look = look
		else
			workspace.CurrentCamera.CFrame = CFrame.lookAt(marker.Position, marker.Position + look)
		end
	end

	return {
		enter = enter,
		leave = leave,
		setFar = setFar,
		isOn = function(): boolean
			return saved ~= nil
		end,
		isTurned = function(): boolean
			return flipped
		end,
		faceTable = faceTable,
	}
end

return TopDownView
