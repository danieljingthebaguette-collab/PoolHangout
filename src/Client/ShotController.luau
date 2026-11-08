--!strict
-- The shooter's controls. F (phones: an on-screen button) eases into a top-down view of the table and back. In a
-- game, your turn starting eases you into it, and your turn passing eases you back to your normal camera, so you see
-- the next shooter's pose. While it isn't your turn, F's top-down view sits a little farther out.
-- You can only aim and shoot from the view: walking is off and a cue stick lies behind the cue ball.
-- Aim: on PC only the mouse aims; on phones dragging turns the aim around the cue ball. Power is a slingshot
-- pull, like 8 Ball Duels: hold the mouse button anywhere (phones: touch near the cue ball), best in front of the
-- cue ball, and drag back toward it and the stick. Power is how far the pointer has moved straight back from where
-- it pressed (Shared/Pull has the rule). Letting go shoots; letting go back inside the cancel zone cancels.
-- Space (phones: the Lock button) optionally locks the aim first, and then a pull can start anywhere.
-- The aim indicator shows where the cue ball first touches something and which way a hit ball goes. It's
-- see-through while you aim or when letting go would cancel, and solid while the aim is locked. When you let
-- go, the cue strikes forward and the shot starts on this screen the moment it reaches the ball.
-- In a game you can only shoot on your turn. With ball in hand the cue ball follows the mouse, stopping at the nearest
-- spot it's allowed, until a click sets it down; a click on it picks it up again until you shoot. The server checks
-- the spot when the shot goes. On the 8, a gold ring marks the called pocket: the one the 8's yellow line points
-- at, until a click on a pocket calls that one for the rest of the shot. With no game on, the physics test mode lets
-- testers shoot any time. TopDownView moves the camera, AimIndicator draws the indicator and the rings, and Cue is the
-- stick; this module decides what they show.
-- Items: on your turn, before the shot, 1 or 2 uses the item in that slot. Freeze, Oil Slick and Pocket Block first ask
-- for a target, a click on a ball, a spot on the felt or a pocket, and the same key again backs out. One item a shot,
-- never mid-pull; the server checks it all again (Items.use).
-- Live aim: in a game the shooter's screen sends its aim, pull, placed cue ball and called pocket a few times a second,
-- and every other screen in the top-down view draws the shooter's cue and aim indicator from it, easing towards each
-- update so a slow connection only makes it lag. Display only: the shot itself goes by RequestShot.

local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local EightBall = require(ReplicatedStorage.Shared.Rules.EightBall)
local Geometry = require(ReplicatedStorage.Shared.Physics.Geometry)
local Items = require(ReplicatedStorage.Shared.Items)
local PhysicsTestAccess = require(ReplicatedStorage.Shared.PhysicsTestAccess)
local Preview = require(ReplicatedStorage.Shared.Physics.Preview)
local Pull = require(ReplicatedStorage.Shared.Pull)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local TableFlow = require(ReplicatedStorage.Shared.Rules.TableFlow)
local TableSpace = require(ReplicatedStorage.Shared.TableSpace)
local Theme = require(ReplicatedStorage.Shared.Theme)
local AimIndicator = require(script.Parent.AimIndicator)
local Cue = require(script.Parent.Cue)
local Hud = require(script.Parent.Hud)
local Stance = require(script.Parent.Stance)
local TableView = require(script.Parent.TableView)
local TopDownView = require(script.Parent.TopDownView)
local Ui = require(script.Parent.Ui)

local VIEW_ACTION = "TopDownView"
local LOCK_ACTION = "LockAim"
local ITEM_ACTION = "UseItem"
-- Control hints, shown on the bottom right as a label and its key, top to bottom. Keep each list within
-- Theme.Ui.HintRows rows.
local HINTS = {
	keyboard = {
		aiming = { { "Lock aim", "Space" }, { "Shoot", "Hold + drag back" } },
		locked = { { "Unlock", "Space" }, { "Shoot", "Drag back" } },
		-- Aiming on the 8. Space still locks, but there's only room for two hints.
		calling = { { "Call pocket", "Click a pocket" }, { "Shoot", "Hold + drag back" } },
		-- While the cue ball follows the mouse with ball in hand
		placing = { { "Place ball", "Click" } },
	},
	touch = {
		aiming = { { "Lock aim to pull from anywhere", "Tap Lock" }, { "Shoot", "Drag back from ball" } },
		locked = { { "Unlock", "Tap Lock" }, { "Shoot", "Drag back" } },
		-- ponytail: the same as aiming until the Mobile phase brings calling a pocket to phones
		calling = { { "Lock aim to pull from anywhere", "Tap Lock" }, { "Shoot", "Drag back from ball" } },
		-- ponytail: the same as aiming until the Mobile phase brings ball in hand to phones
		placing = { { "Lock aim to pull from anywhere", "Tap Lock" }, { "Shoot", "Drag back from ball" } },
	},
	cancel = { { "Cancel", "Let go" } },
	-- Choosing an item's target, by what it needs and the slot's key, which backs out. Filled in below.
	picking = {} :: { [string]: { { { string } } } },
}
local PICK_TEXT: { [string]: string } = { ball = "Pick a ball", spot = "Pick a spot", pocket = "Pick a pocket" }
for kind, text in PICK_TEXT do
	HINTS.picking[kind] = { { { text, "Click" }, { "Back", "1" } }, { { text, "Click" }, { "Back", "2" } } }
end

local ShotController = {}

-- One table's shot controls, until the screen follows another table (ActiveTable)
export type Controller = { destroy: () -> () }

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

local function styleText(textItem: TextLabel | TextButton, text: string)
	-- Both have these text properties, but the type checker can't write to a mix of two classes
	local label: TextLabel = textItem :: any
	label.FontFace = Theme.Font
	label.TextSize = Theme.TextSize
	label.TextColor3 = Theme.Colors.Text
	label.Text = text
end

-- The shot controls for one table, until `destroy`. `testMode` lets this player shoot while no game is on the table.
-- `onView` hears when the top-down view turns on and off, for the HUD and anything else that only shows there.
function ShotController.start(tableModel: Model, testMode: boolean, onView: (boolean) -> ()): Controller
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
	local cancelRadius = Config.Shot.CancelRadius * radius

	-- Only this screen sees the cue. From the cue ball's center to the cue's tip, and at rest to the cue's center.
	local cue = Cue.new(tableModel)
	local tipBack, cueLength, cueBack = cue.tipBack, cue.length, cue.restBack

	-- The phones' Lock button, a bright accent button beside the power meter. Hud draws the meter and the hints.
	local controlsGui = Instance.new("ScreenGui")
	controlsGui.Name = "ShotControls"
	controlsGui.ResetOnSpawn = false
	controlsGui.Enabled = false
	-- Beside the meter, where a thumb resting near it reaches
	local lockButton = Instance.new("TextButton")
	lockButton.AnchorPoint = Vector2.new(0, 0.5)
	lockButton.Position = UDim2.new(0, Theme.Ui.MeterReserve, 0.5, 0)
	lockButton.Size = UDim2.fromOffset(Theme.Ui.LockButtonWidth, Theme.Ui.ButtonHeight)
	lockButton.BackgroundColor3 = Theme.Colors.Button
	lockButton.AutoButtonColor = true
	lockButton.Visible = UserInputService.TouchEnabled
	lockButton.Parent = controlsGui
	styleText(lockButton, "Lock")
	Ui.roundCorners(lockButton, UDim.new(0, Theme.Ui.Corner))
	controlsGui.Parent = playerGui

	-- The aim indicator, the faint ring with ball in hand and the called pocket's ring
	local indicator = AimIndicator.new(playerGui, felt, ballParts)

	-- Radians in table space: 0 aims along +x, at the rack
	local aim = 0
	-- Locked with Space or the Lock button. A pull also holds the aim still, locked or not.
	local locked = false
	-- The finger dragging the aim around the cue ball, and its last angle there
	local drag: { input: InputObject, angle: number? }? = nil
	-- The mouse button or finger pulling for power, and where it pressed and how far back it has gone
	local pulling: { input: InputObject, state: Pull.Pull }? = nil
	-- How far the cue is pulled back, 0 to 1: the shot's power
	local pull = 0
	-- After you let go: the shot's power and how far the cue has come forward, 0 to 1, until it reaches the ball
	local strike: { power: number, t: number }? = nil
	-- After the strike: the cue carries on a little past where the cue ball was and fades out. How far through, 0 to
	-- 1, and where the cue ball and aim were when it struck.
	local followThrough: { t: number, x: number, y: number, aim: number }? = nil
	-- This table's game, from the server's TurnStarted: whether it's this player's turn, and whether they're playing in
	-- it at all rather than watching. Nil with no game on.
	local turn: { mine: boolean, seated: boolean, seat: number? }? = nil
	-- Whether the cue ball may be placed anywhere before the next shot, from TurnStarted
	local ballInHand = false
	-- With ball in hand, whether the cue ball is following the mouse rather than set down
	local holding = false
	local placed: { x: number, y: number, from: CFrame }? = nil
	-- On the 8, from TurnStarted: the pocket called for it, and whether a click chose it, after which it stops
	-- following the aim. Nil when it's not this player's turn on the 8.
	local calling: { pocket: number, clicked: boolean }? = nil
	-- Live aim while someone else shoots: the latest update the server passed on, what this screen draws as it eases
	-- towards it, and where the cue ball was before the update moved it here. Nil until one arrives this turn.
	local relayed: { target: TableFlow.AimState, aim: number, pull: number, x: number?, y: number?, from: CFrame? }? = nil
	-- When this player's own live aim was last sent, and what it said, so only changes go out
	local sentAt, lastSent = -math.huge, ""
	-- Items, from ItemsChanged and ItemUsed: every seat's bar and slots, whether this player has used an item on this
	-- shot, whether their Power Shot is on, and the slot whose item is waiting for a target
	local bars: { Items.Bar }? = nil
	local usedThisShot, powerOn = false, false
	local picking: { slot: number, kind: string }? = nil

	-- The top-down view's camera, and everything the view connected while it's on
	local view = TopDownView.new(tableModel, felt)
	local connections: { RBXScriptConnection } = {}
	-- Everything else this table's controls connected, until they're destroyed
	local lasting: { RBXScriptConnection } = {}

	-- The balls on the table as this screen shows them
	local function shownBalls(): { Preview.Ball }
		local balls: { Preview.Ball } = {}
		for id, part in ballParts do
			if part.Transparency ~= 1 then
				local x, y = TableSpace.toTable(felt, part.Position)
				table.insert(balls, { id = id, x = x, y = y })
			end
		end
		return balls
	end

	local function canShoot(): boolean
		local allowed = if turn then turn.mine else testMode
		return allowed and not TableView.isBusy(tableModel) and cueBall.Transparency ~= 1
	end

	-- Whether this player may place the cue ball now
	local function canPlace(): boolean
		return ballInHand and canShoot()
	end

	-- This player's item slots, while they're playing at this table
	local function mySlots(): { Items.Item | false }?
		local bar = if bars and turn and turn.seat then bars[turn.seat] else nil
		return if bar then bar.slots else nil
	end

	-- Whether this player may use an item now: their turn, the balls still, no pull under way and none used this shot
	local function canUseItem(): boolean
		return turn ~= nil and turn.mine and canShoot() and not (pulling or strike or usedThisShot)
	end

	-- The cue has reached the ball: the shot goes, here at once and to the server
	local function fire()
		local power = (strike :: { power: number, t: number }).power
		strike = nil
		pull = 0
		-- The server says whether this is the break; this screen only needs it to start the same shot
		local isBreak = tableModel:GetAttribute("BreakNext") == true
		local shot = { dirX = math.cos(aim), dirY = math.sin(aim), power = power, isBreak = isBreak }
		local cueX, cueY = TableSpace.toTable(felt, cueBall.Position)
		followThrough = { t = 0, x = cueX, y = cueY, aim = aim }
		local remote = if turn then Remotes.RequestShot else Remotes.TestShoot
		remote:FireServer(
			shot.dirX,
			shot.dirY,
			shot.power,
			placed and placed.x,
			placed and placed.y,
			calling and calling.pocket
		)
		-- Placing and calling end with the shot, even before the server's next TurnStarted arrives
		ballInHand, holding, placed, calling = false, false, nil, nil
		TableView.predict(tableModel, shot, PhysicsTestAccess.params())
		TableView.playSound(cueBall, "CueStrike", power)
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

	-- The pocket within PocketPickRadius of a point, if any
	local function pocketAt(x: number, y: number): number?
		local reach = Config.Aim.PocketPickRadius * radius
		for index, pocket in Geometry.build(PhysicsTestAccess.params().Table).pockets do
			if (x - pocket.x) ^ 2 + (y - pocket.y) ^ 2 <= reach * reach then
				return index
			end
		end
		return nil
	end

	-- The pocket nearest the 8 as this screen shows it, called until the aim or a click picks another
	local function pocketNearEight(): number
		local x, y = TableSpace.toTable(felt, ballParts[8].Position)
		local best, bestSq = 1, math.huge
		for index, pocket in Geometry.build(PhysicsTestAccess.params().Table).pockets do
			local distSq = (x - pocket.x) ^ 2 + (y - pocket.y) ^ 2
			if distSq < bestSq then
				best, bestSq = index, distSq
			end
		end
		return best
	end

	-- What a click at (x, y) picks for an item: the nearest ball within PickRadius but the cue ball and the 8, a spot on
	-- the felt, or a pocket. Nil for nothing there.
	local function pickTarget(kind: string, x: number, y: number): Items.Target?
		if kind == "pocket" then
			return pocketAt(x, y)
		elseif kind == "spot" then
			local tableParams = PhysicsTestAccess.params().Table
			local onFelt = math.abs(x) <= tableParams.Length / 2 and math.abs(y) <= tableParams.Width / 2
			return if onFelt then { x = x, y = y } else nil
		end
		local best: number?, bestSq = nil, (Config.Items.PickRadius * radius) ^ 2
		for _, ball in shownBalls() do
			local distSq = (ball.x - x) ^ 2 + (ball.y - y) ^ 2
			if ball.id ~= 0 and ball.id ~= 8 and distSq <= bestSq then
				best, bestSq = ball.id, distSq
			end
		end
		return best
	end

	-- 1 or 2: uses that slot's item, or for one that needs a target, waits for a click on it. The same key again backs
	-- out.
	local function useSlot(slot: number)
		local slots = mySlots()
		local item = if slots and slots[slot] then slots[slot] :: Items.Item else nil
		if not item or not canUseItem() or (item == "powerShot" and powerOn) then
			return
		elseif picking and picking.slot == slot then
			picking = nil
			return
		end
		local kind = Items.TARGETS[item]
		if kind then
			picking = { slot = slot, kind = kind }
			drag = nil
		else
			picking = nil
			Remotes.UseItem:FireServer(slot)
		end
	end

	-- Ball in hand: moves the cue ball to the allowed spot nearest the pointer. Where none turns up, like over a cluster
	-- of balls, it stays where it was. Only this screen sees it move until the shot.
	local function placeAt(ray: Ray)
		local x, y = pointerOnTable(ray)
		-- It reads only each ball's id, place and pocket, which the shown balls have; they have no speeds
		local spotX, spotY = EightBall.nearestCueSpot(shownBalls() :: any, x, y, PhysicsTestAccess.params().Table)
		if spotX and spotY then
			placed = { x = spotX, y = spotY, from = if placed then placed.from else cueBall.CFrame }
			cueBall.CFrame = cueBall.CFrame.Rotation + TableSpace.toWorld(felt, spotX, spotY, radius).Position
		end
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

	-- The shooter's live aim, for everyone else at the table: at most Config.Aim.RelayRate times a second, and only
	-- when something changed
	local function sendAim(held: boolean, placing: boolean)
		local now = os.clock()
		if now - sentAt < 1 / Config.Aim.RelayRate then
			return
		end
		local cueX, cueY = if placed then placed.x else nil, if placed then placed.y else nil
		local pocket = if calling then calling.pocket else nil
		local said = `{aim} {pull} {held} {placing} {cueX} {cueY} {pocket}`
		if said == lastSent then
			return
		end
		sentAt, lastSent = now, said
		Remotes.AimUpdate:FireServer(aim, pull, held, placing, cueX, cueY, pocket)
	end

	-- Draws someone else's live aim, easing towards the latest update, while the balls are still
	local function drawRelayed(dt: number)
		if not (relayed and turn and not turn.mine) or TableView.isBusy(tableModel) or cueBall.Transparency == 1 then
			return
		end
		local target = relayed.target
		local ease = 1 - math.exp(-dt / Config.Aim.RelaySmoothSeconds)
		relayed.aim += ((target.aim - relayed.aim + math.pi) % (2 * math.pi) - math.pi) * ease
		relayed.pull += (target.pull - relayed.pull) * ease
		if target.cueX and target.cueY then
			-- With ball in hand, the cue ball follows the shooter's mouse here too, until the server places it
			relayed.from = relayed.from or cueBall.CFrame
			local x = if relayed.x then relayed.x + (target.cueX - relayed.x) * ease else target.cueX
			local y = if relayed.y then relayed.y + (target.cueY - relayed.y) * ease else target.cueY
			relayed.x, relayed.y = x, y
			cueBall.CFrame = cueBall.CFrame.Rotation + TableSpace.toWorld(felt, x, y, radius).Position
		end
		local cueX, cueY = TableSpace.toTable(felt, cueBall.Position)
		if target.pocket then
			indicator.showPocketRing(target.pocket)
		end
		if target.placing then
			indicator.showPlaceRing(cueX, cueY)
			return
		end
		indicator.fade(not target.held)
		indicator.draw(cueX, cueY, relayed.aim, shownBalls())
		Cue.place(cue, felt, cueX, cueY, relayed.aim, cueBack + relayed.pull * radius * Config.Aim.CuePullBack)
		cue.part.Transparency = 0
	end

	local function render(dt: number)
		if pulling and not stillHeld(pulling.input) then
			cancelPull()
		end
		local placing = holding and canPlace()
		if placing and UserInputService.MouseEnabled then
			local mouse = UserInputService:GetMouseLocation()
			placeAt(workspace.CurrentCamera:ViewportPointToRay(mouse.X, mouse.Y))
		end
		Hud.setTestMode(testMode and turn == nil)
		-- On PC the cue points at the mouse, worked out every frame rather than only when the mouse moves, so it stays
		-- on the cursor when the cue ball moves under a still mouse: after a shot or a rack, or on entering the view.
		-- GetMouseLocation counts from the screen's very top, so it pairs with ViewportPointToRay.
		if UserInputService.MouseEnabled and not (locked or pulling or strike or drag or placing) then
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
		if followThrough then
			followThrough.t = math.min(followThrough.t + dt / Config.Shot.FollowThroughSeconds, 1)
			local t = followThrough.t
			-- Slowing as it goes, from the tip touching the ball to CueFollowThrough past it
			local back = cueBack - radius * (Config.Aim.CueTipGap + Config.Aim.CueFollowThrough * t * (2 - t))
			Cue.place(cue, felt, followThrough.x, followThrough.y, followThrough.aim, back)
			cue.part.Transparency = t
			if t >= 1 then
				followThrough = nil
			end
		else
			cue.part.Transparency = if hidden or placing then 1 else 0
		end
		controlsGui.Enabled = not hidden
		Hud.setPower(if hidden then nil else pull)
		local held = locked or pulling ~= nil or strike ~= nil
		-- Back inside the cancel zone after leaving it, where letting go cancels
		local cancelling = pulling ~= nil and pulling.state.left and pull == 0
		if picking and not canUseItem() then
			picking = nil
		end
		Hud.setHints(
			if hidden
				then nil
				elseif picking then HINTS.picking[picking.kind][picking.slot]
				elseif placing then hints.placing
				elseif cancelling then HINTS.cancel
				elseif held then hints.locked
				elseif calling then hints.calling
				else hints.aiming
		)
		lockButton.Text = if held then "Unlock" else "Lock"
		-- Your slots show while you play here, dimmed when you can't use an item
		Hud.setSlots(if turn and turn.seated then mySlots() else nil, if picking then picking.slot else nil, canUseItem())
		indicator.hide()
		if hidden then
			Stance.stop()
			drawRelayed(dt)
			return
		end
		local cueX, cueY = TableSpace.toTable(felt, cueBall.Position)
		if turn and turn.mine then
			sendAim(held, placing)
			-- Your character walks round to stand behind the cue ball
			Stance.update(felt, cueX, cueY, aim)
		end
		if calling then
			indicator.showPocketRing(calling.pocket)
		end
		if placing then
			indicator.showPlaceRing(cueX, cueY)
			return
		end
		indicator.fade(cancelling or not held)
		-- On the 8, the called pocket follows the 8's yellow line until a click picks one
		local aimed = indicator.draw(cueX, cueY, aim, shownBalls())
		if aimed and calling and not calling.clicked then
			calling.pocket = aimed
		end
		local back = cueBack + (pull + strikeOffset) * radius * Config.Aim.CuePullBack
		Cue.place(cue, felt, cueX, cueY, aim, back)
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
		-- Choosing an item's target, a click picks it; a click on nothing waits for another
		if picking then
			local target = pickTarget(picking.kind, x, y)
			if target then
				Remotes.UseItem:FireServer(picking.slot, target)
				picking = nil
			end
			return
		end
		-- With ball in hand, a click sets the following cue ball down, and a click on it picks it up again
		if canPlace() then
			local cueX, cueY = TableSpace.toTable(felt, cueBall.Position)
			if holding or (x - cueX) ^ 2 + (y - cueY) ^ 2 <= (Config.Aim.PlaceGrabRadius * radius) ^ 2 then
				holding = not holding
				return
			end
		end
		-- Unlocked, a touch away from the cue ball turns the aim instead
		if locked or not isTouch or nearCue(x, y) then
			if canShoot() then
				-- The full pull comes from the test panel's slider when there is one, read fresh for each pull
				local fullPull = PhysicsTestAccess.shot().FullPullDistance
				pulling = { input = input, state = Pull.new(x, y, cancelRadius, fullPull) }
				pull = 0
			end
		elseif not drag then
			drag = { input = input, angle = pointerAngle(inputRay(input)) }
		end
	end

	local function pointerMoved(input: InputObject)
		if pulling then
			if movesPointer(input, pulling.input) then
				-- Only how far it has moved straight back from where it pressed counts
				local x, y = pointerOnTable(inputRay(input))
				Pull.moveTo(pulling.state, x, y, math.cos(aim), math.sin(aim))
				pull = Pull.power(pulling.state)
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
			elseif calling and not pulling.state.left then
				-- On the 8, a click that never pulled back calls the pocket it's on
				local pocket = pocketAt(pulling.state.pressX, pulling.state.pressY)
				if pocket then
					calling.pocket, calling.clicked = pocket, true
				end
			end
			pulling = nil
		elseif drag and input == drag.input then
			drag = nil
		end
	end

	table.insert(lasting, lockButton.Activated:Connect(toggleLock))

	local function leaveView(instant: boolean?)
		if not view.isOn() then
			return
		end
		for _, connection in connections do
			connection:Disconnect()
		end
		connections = {}
		ContextActionService:UnbindAction(LOCK_ACTION)
		ContextActionService:UnbindAction(ITEM_ACTION)
		picking = nil
		Stance.stop()
		-- A shot you've let go of still goes
		if strike then
			fire()
		end
		followThrough = nil
		-- Leaving mid-pull cancels the shot, and the view starts over unlocked
		drag, pulling, pull, locked = nil, nil, 0, false
		cue.part.Transparency = 1
		controlsGui.Enabled = false
		Hud.setPower(nil)
		indicator.hide()
		view.leave(instant)
		characterInput.Enabled = true
		controls:Enable()
		onView(false)
	end

	-- Close in on your turn, farther out when it isn't, turned so the long side across from your seat is at the top
	local function enterView()
		view.enter(not (turn and turn.mine), if turn then turn.seat else nil)
		TableView.turnShadows(view.isTurned())
		connections = {
			RunService.RenderStepped:Connect(render),
			UserInputService.InputBegan:Connect(pointerBegan),
			UserInputService.InputChanged:Connect(pointerMoved),
			UserInputService.InputEnded:Connect(pointerEnded),
			-- Esc opens Roblox's menu, which the game can't bind, so opening the menu is what cancels
			GuiService.MenuOpened:Connect(cancelPull),
		}
		characterInput.Enabled = false
		controls:Disable()
		onView(true)
		ContextActionService:BindAction(LOCK_ACTION, function(_, state: Enum.UserInputState)
			if state == Enum.UserInputState.Begin then
				toggleLock()
			end
			return Enum.ContextActionResult.Sink
		end, false, Enum.KeyCode.Space)
		ContextActionService:BindAction(ITEM_ACTION, function(_, state: Enum.UserInputState, input: InputObject)
			if state == Enum.UserInputState.Begin then
				useSlot(if input.KeyCode == Enum.KeyCode.One then 1 else 2)
			end
			return Enum.ContextActionResult.Sink
		end, false, Enum.KeyCode.One, Enum.KeyCode.Two)
	end

	ContextActionService:BindAction(VIEW_ACTION, function(_, state: Enum.UserInputState)
		if state == Enum.UserInputState.Begin then
			if view.isOn() then
				leaveView()
			else
				enterView()
			end
		end
		return Enum.ContextActionResult.Sink
	end, true, Enum.KeyCode.F)
	ContextActionService:SetTitle(VIEW_ACTION, "View")

	lasting[#lasting + 1] = Remotes.TurnStarted.OnClientEvent:Connect(
		function(model: Model?, shooter: Player?, inHand: boolean?, seats: { Player }?, callPocket: boolean?)
			if model ~= tableModel then
				return
			end
			-- A cue ball moved here but never shot goes back where the server has it
			if placed then
				cueBall.CFrame = placed.from
			end
			if relayed and relayed.from then
				cueBall.CFrame = relayed.from
			end
			relayed, lastSent = nil, ""
			-- Each shot may use an item; Power Shot stays on for the rest of a turn
			usedThisShot, picking = false, nil
			local wasSeated = turn ~= nil and turn.seated
			local wasMine = turn ~= nil and turn.mine
			local seated = table.find(seats or {}, Players.LocalPlayer) ~= nil
			-- Seats with no shooter: the game is over and its result is showing, so nobody shoots
			turn = if seats
				then { mine = shooter == Players.LocalPlayer, seated = seated, seat = table.find(seats, Players.LocalPlayer) }
				else nil
			if seats and seated and not wasSeated then
				view.faceTable(table.find(seats, Players.LocalPlayer) :: number)
			end
			-- Ball in hand starts with the cue ball following the mouse
			ballInHand, holding = inHand == true, inHand == true
			placed, pulling = nil, nil
			calling = if callPocket == true
					and turn
					and turn.mine
				then { pocket = pocketNearEight(), clicked = false }
				else nil
			-- Your turn starting eases you into the top-down view close in, even if F took you out of it. Your turn
			-- passing to someone else, or the game ending, eases you back to the normal view to watch the shooter's pose.
			-- F still switches any time, and nobody waiting or watching is moved.
			local mine = turn ~= nil and turn.mine
			powerOn = powerOn and mine and wasMine
			if (wasSeated and not seated) or (wasMine and shooter ~= nil and not mine) then
				leaveView()
			elseif mine and not wasMine then
				if view.isOn() then
					view.setFar(false)
				else
					enterView()
				end
			end
		end
	)

	lasting[#lasting + 1] = Remotes.AimRelay.OnClientEvent:Connect(function(model: Model?, state: TableFlow.AimState)
		if model ~= tableModel or not (turn and not turn.mine) then
			return
		elseif relayed then
			relayed.target = state
		else
			relayed = { target = state, aim = state.aim, pull = state.pull, x = nil, y = nil, from = nil }
		end
	end)
	lasting[#lasting + 1] = Remotes.ItemsChanged.OnClientEvent:Connect(function(model: Model?, newBars: { Items.Bar }?)
		if model == tableModel then
			bars = newBars
		end
	end)
	lasting[#lasting + 1] = Remotes.ItemUsed.OnClientEvent:Connect(function(model: Model?, seat: number, item: string)
		if model == tableModel and turn and turn.mine and seat == turn.seat then
			usedThisShot, picking = true, nil
			powerOn = powerOn or item == "powerShot"
		end
	end)
	-- Once the shot goes, the replay places the balls and the live aim is done with
	lasting[#lasting + 1] = Remotes.ShotStarted.OnClientEvent:Connect(function(model: Model?)
		if model == tableModel then
			relayed = nil
		end
	end)

	-- A new character gets fresh controls, so it starts in the normal view, and on your own turn goes back to the
	-- top-down view. Roblox only points the camera at a new character while the camera isn't Scriptable, so a respawn
	-- in the view would leave it on the old one: point it here.
	lasting[#lasting + 1] = Players.LocalPlayer.CharacterAdded:Connect(function(character: Model)
		leaveView(true)
		local camera = workspace.CurrentCamera
		camera.CameraSubject = character:WaitForChild("Humanoid") :: Humanoid
		if turn and turn.mine then
			enterView()
		end
	end)

	return {
		destroy = function()
			leaveView(true)
			for _, connection in lasting do
				connection:Disconnect()
			end
			ContextActionService:UnbindAction(VIEW_ACTION)
			-- A cue ball moved here but never shot goes back where the server has it
			if placed then
				cueBall.CFrame = placed.from
			elseif relayed and relayed.from then
				cueBall.CFrame = relayed.from
			end
			controlsGui:Destroy()
			indicator.destroy()
			cue.part:Destroy()
		end,
	}
end

return ShotController
