# Architecture

How the code fits together. Follow it. If something here is wrong or gets in the way, propose the change, and update this file once I agree.

## Principles

1. **The server is the referee.** It owns every table's state, seats, turns, clocks, the shot simulation and rule decisions. Clients send intents ("shoot this way with this power") and draw what the server says happened.
2. **Pure core.** Ball physics (`src/Shared/Physics/`) and 8-ball rules (`src/Shared/Rules/`) are plain Luau with no Roblox APIs. Plain tables and numbers go in and come out, and Lune tests cover them.
3. **Same simulation everywhere.** The server simulates each shot for the rules. Clients run the same deterministic simulation from the same inputs to animate it, then snap to the server's final positions. No Roblox physics touches the balls.
4. **One config.** All tuning lives in `src/Shared/Config.luau` as plain numbers, strings and booleans, so Lune can load it too. Colors, fonts and UI sizes go in `src/Shared/Theme.luau`, in the look `docs/STYLE.md` describes.
5. **Code finds the world by name.** Tables in the place follow the place contract below.

## Modules (planned; create each when a task needs it)

| File (under `src/`) | Job |
| --- | --- |
| `Shared/Config.luau` | Every tuning number |
| `Shared/Theme.luau` | Colors, fonts, UI sizes |
| `Shared/Remotes.luau` | Creates (server) or finds (client) every remote. Remote names appear nowhere else |
| `Shared/TableSpace.luau` | World ↔ table space, from a table's `Felt` |
| `Shared/Physics/Geometry.luau` | Rails, pockets, head line, foot spot and rack positions, from Config |
| `Shared/Physics/Simulate.luau` | A stepper: start it from balls, a shot, the item effects and params (Config by default), advance it N steps at a time, read the `ShotResult` when done. `run()` does it all at once for tests |
| `Shared/Physics/Preview.luau` | Where the cue ball first touches a ball, rail or pocket, for the aim indicator, and after a hit, which way each ball goes and with what share of the speed. Same contacts and hit rule as Simulate, solved exactly, with frozen balls and pocket lids as walls |
| `Shared/Seat.luau` | Who sits in a seat: a player, or Coach's character model. Its name, character and avatar id either way |
| `Shared/Rules/ShotPicker.luau` | Shots for bots: Coach's easiest clear pot (ghost ball aimed at the middle of the pocket's mouth, power from the distances and the steady slowdown, a small random aim error, and with ball in hand the cue ball straight behind its best pot), and the legal targets the whole-game test bots use. Pure, so Lune tests it in `tests/games.spec.luau`, where Coach plays Coach |
| `Shared/Pull.luau` | The slingshot pull's power: how far the pointer has moved from where it pressed, straight back toward the stick. Forward lowers it to 0, sideways does nothing. Pure, so Lune tests it |
| `Shared/Items.luau` | A game's items as plain tables: slots, each player's item bar, active effects, and what each side targeted last. Adds bar points, awards items, checks every item rule and builds the simulation's `effects`. Pure, so Lune tests it (see Items) |
| `Shared/Rules/EightBall.luau` | New game, resolve a shot, timeouts, forfeits, per-player game stats |
| `Shared/Rules/TableFlow.luau` | How a table runs, by seat number: seat names, sides and counts, turn order, who shoots for a seat whose player left, joining and the countdown's token, every shot-request check, and what a shot leaves behind (the next seat, ball in hand, the 8 and the cue ball put back). `TableService` and `Match` call it and keep the players, remotes, timers and ball parts. Tested in `tests/tableflow.spec.luau`, and in `tests/games.spec.luau`, where seeded bots play whole 1v1 and 2v2 games through it with `Simulate` and `EightBall` |
| `Server/Main.server.luau` | Starts the services |
| `Server/TableService.luau` | Finds tables, runs their Join prompts, countdowns and signs, moves players to their seats, starts and resets games |
| `Server/Balls.luau` | Each table's ball parts and where its balls rest, and playing a shot on them: simulate in slices, `ShotStarted`, wait out the replay. Games and the test mode both shoot through it |
| `Server/Match.luau` | One game: seats, turn order, shot clock, ball in hand, items (through `Items.luau`), takeovers, end-screen data |
| `Server/StatsService.luau` | Lifetime stats. The only module that touches DataStores |
| `Server/PhysicsTest.luau` | Physics test mode on Table1 (Studio, or the owner in a published server): rack and test shots while no game is on, and the sliders |
| `Server/TableBuilder.luau` | Builds a greybox table's cushions, rails, plates, pockets, body and legs around its `Felt`, from table params. `tools/BuildTable.luau` runs it in edit mode from Config; the test mode runs it live when a pocket slider moves |
| `Client/Main.local.luau` | Starts the controllers |
| `Client/TableView.luau` | Replays shots on the ball parts, plays their sounds, draws the balls' shadows, and starts the shooter's shot before the server's copy arrives |
| `Client/ShotController.luau` | The shot controls: F and when the view turns on and off, placing the cue ball, aim, pocket call, using items (keys 1 and 2, slot taps, picking a target), the pull for power, the cue's strike and follow-through. The three modules below draw what it decides |
| `Client/TopDownView.luau` | The top-down camera: framing the table between the HUD's reserves, saving and bringing back the normal camera, and turning it to face the table from a seat |
| `Client/AimIndicator.luau` | The aim indicator (the line, circle and dot, and the cue ball's and hit ball's lines), the faint ring with ball in hand and the called pocket's ring, drawn on the screen |
| `Client/Cue.luau` | The cue stick, a Part only the shooter's screen sees, and laying it along the aim |
| `Client/Hud.luau` | Starts the HUD's parts below, shows them in the top-down view, and "TEST MODE"; later item slots with icons drawn in code and the item's name shown big |
| `Client/ShotClock.luau` | The shot clock between the top bar's cards, counting to the server's clock end time |
| `Client/TurnArrow.luau` | The gold "Turn" card over each table's shooter in the normal view |
| `Client/TopBar.luau` | Each side's card: avatars, names, the turn glow, and the group with its balls; later every card's item slots and bar with its "+4" pops |
| `Client/Banner.luau` | The banner under the top bar for the server's messages, for everyone at the table |
| `Client/LeaveButton.luau` | The Leave button and the question it asks mid-game |
| `Client/EndScreen.luau` | The end screen: who won and why, each player's stats, Rematch and Back to lobby |
| `Client/PowerMeter.luau` | The power meter and its % |
| `Client/Tray.luau` | The sunk-ball tray |
| `Client/Hints.luau` | The control hints, bottom right |
| `Client/SettingsPanel.luau` | The gear and its card with the sound volume |
| `Client/Ui.luau` | Small shared builders: rounded corners, labels, accent buttons and ball icons |
| `Client/Effects.luau` | Effects on the table, built from parts in code once per effect and destroyed when it ends. Today: chunky sparks on hard hits and a pop at the pocket, from `TableView`'s loudest few events per frame, capped at `Theme.Effects.MaxParts`. Later the item effects and screen shake: flame trail, blast, frozen balls, oil patches, pocket lids |
| `Client/Slider.luau` | A labelled slider row for mouse and touch, for the settings and the test panel |
| `Client/Card.luau` | The card look from `docs/STYLE.md`: cream or dark, with corner brackets and a faint dot texture |
| `Client/Spectate.luau` | "Watch from above" |
| `Client/PhysicsTestPanel.luau` | Physics test mode controls (Studio, or the owner in a published server) |

Pure modules require each other only by relative string path, like `require("./Geometry")` or `require("../Config")`. That form works in both Roblox and Lune.

## Table space

- Physics runs in 2D table space, in studs. The origin is the center of the playing surface, x runs along the length (head end negative, foot end positive), and y runs across the width.
- A ball is `{ id, x, y, vx, vy, pocket }`. Id 0 is the cue ball, 1–7 the solids, 8 the 8, 9–15 the stripes. `pocket` is nil until it drops.
- The head line is at x = −Length/4 and the foot spot at x = +Length/4.
- World ↔ table: each table's `Felt` part. Table x is the Felt's local X axis, table y its local Z axis, and balls rest on the Felt's top face. Keep this conversion in one helper.

## Physics

- **Deterministic:** the same balls and shot give the same result on every machine. Fixed time step, balls processed in id order, no `math.random`, no clock reads, no `--!native`.
- **Model:** balls travel in straight lines and slow at a constant rate. Ball-to-ball hits are equal-mass collisions with a restitution value, resolved at the exact moment the balls touch. A ball that rolls into a hit keeps `Follow` of the speed the hit takes away, like natural roll. Rails reflect a ball at the angle it came in and cut its speed. The shot ends when every ball is below the stop speed, or at a safety time cap.
- **Pockets:** one at each corner of the felt and one in the middle of each long side. A ball drops when its center comes within half the pocket's mouth of that point. A corner mouth is measured across its diagonal opening, so the rails stop `CornerPocketMouth / √2` from each corner, and the rails' ends act as the pockets' jaws. Only a pocket's opening lets a ball's center past the edge of the felt, so that drops it too.
- **Accurate:** no ball moves more than `MaxStepTravel` (a third of its radius) in one step. A normal shot fits the fixed step (a test checks this against Config); while any ball is faster, like on the break, the step splits into equal sub-steps, so nothing passes through a ball or rail.
- **Tuning:** `tools/BreakStats.luau` runs 20 breaks in Lune and summarizes them (balls sunk, bunched, spread, where the cue ball stops, time to stop), for comparing with 8 Ball Duels.
- **Fast:** skip pairs where neither ball moves. Time a full break in Lune; if it takes more than about 50 ms, speed it up before building on it. Nobody runs a whole shot in one frame in the game: the server and clients both advance the stepper a slice at a time.
- **`ShotResult`** holds the final balls, timestamped events (ball hit, rail hit, pocketed) for sounds and rules, the first ball the cue ball touched, pocketed balls in order with their pockets, and the duration.

Starting values for Config (tune by feel):

| Setting | Start | Why |
| --- | --- | --- |
| Table length × width | 16 × 8 studs | 2:1 like a real table; about 18.2 × 10.2 with the cushions and rails |
| Ball radius | 0.22 studs | 8 Ball Duels' ball-to-table proportion, measured from recordings |
| Pocket mouth, corner / side | 0.68 / 0.71 studs | 8 Ball Duels' mouths in ball widths, about 1.55 and 1.6, measured from recordings. The test panel's sliders tune them |
| Full-power speed | 25 studs/s | Measured from 8 Ball Duels, like the rows below |
| Break power | 2.5 | The break's full power is 2.5× a normal shot's, about 62.5 studs/s |
| Softest shot / power curve | 0.21 / 2 | Speed is full × (0.21 + 0.79 × pull²): even the softest shot leaves at 21% of full speed and rolls about half the table, 50% on the meter gives about 41% of full speed and 76% about 67% |
| Rolling slowdown | 1.84 studs/s² | Full power rolls about 170 studs, about 11 table lengths. Matches 8 Ball Duels' rail-to-rail shot |
| Speed drag | 0 | Optional extra slowdown per stud/s of speed, so fast balls lose speed quicker while slow rolls barely change. 0 is a steady slowdown, like 8 Ball Duels |
| Rail bounce | 0.73 | Keeps about 73% of the speed, from 8 Ball Duels' rail-to-rail shot |
| Ball bounce | 0.94 | A full hit leaves the cue ball 3% of its speed, almost dead |
| Follow | 0 | No follow, like 8 Ball Duels: a cut sends the cue ball along the tangent line. Natural roll in real pool would be 2/7 |
| Rack gap | 0.01 studs | Nearly tight, like 8 Ball Duels' rack, so the break spreads like theirs |
| Stop speed / time step / time cap | 0.032 studs/s / 1/960 s / 20 s | 1/960 keeps any normal shot under a third of a radius per step |
| Max step travel | 1/3 ball radius | A faster ball, like on the break, splits the step into equal sub-steps, so hits stay exact at any speed |
| Shot clock / warning | 45 s / last 10 s | |
| Coach | 1.5 s pause, 1.5 s aim, 1 s pull; 0.25° aim error; cuts up to 70° | Slow enough to watch. Coach-vs-Coach keeps the turn on about 55% of shots after the break, about 20 shots a game |
| Countdown / takeover / open-spot wait / end screen | 3 / 5 / 15 / 10 s | |
| Cancel zone | 2.5 ball radii | The first stretch of pull back, roughly fingertip size on a phone. Letting go back inside it cancels |
| Full-power pull | 6 studs past the cancel zone, straight back from the shot | 6.6 studs in all, about 41% of the table length. Measured on the table, so it's the same share of the screen on every device. Tuned on the test panel's slider |

## A shot, end to end

1. `Match` starts a turn: it sets the shooter, `clockEndsAt` from `workspace:GetServerTimeNow()`, the ball-in-hand area, whether a pocket must be called, any item the shooter earns for the turn, everyone's held items and the active effects, then fires `TurnStarted` to everyone.
2. The shooter's `ShotController` runs the camera, placement, aim, pocket call, any item use and power meter locally, then fires `RequestShot` with the aim direction, power (0–1, or up to `PowerShotMax` while the shooter's Power Shot is on), cue ball placement and called pocket. An item goes first, through `UseItem` (see Items).
3. The server validates the request (see `.claude/rules/server.md`) and normalizes the direction.
4. It fires `ShotStarted` with the exact start balls, the shot, the item effects and the physics params it used, so every client simulates with the server's numbers even while test mode changes them live. Then it simulates the shot in slices of a couple of milliseconds per frame, so even a break never stalls the server. It finishes long before the replay does.
5. Each client steps the same simulation as it plays the shot back in real time, so every client sees the same shot and no frame does much work.
6. Once the server's simulation is done and the shot's duration plus a short buffer has passed, the server runs `EightBall.resolveShot`, moves the ball parts to their final positions and fires `ShotResolved` with the final balls, the outcome and any item earned by sinking. Clients snap to those positions, which also corrects any drift.
7. Then the next turn, or the end of the game.

- **Ball parts** are anchored, non-colliding parts the server creates for each table and moves only between shots. During a replay each client moves them locally. Players who join later get the resting positions through normal replication.
- **Live aim for everyone at the table (Phase 2, after the health pass):** while aiming, the shooter's client sends `AimUpdate` over an UnreliableRemoteEvent at most 10 times a second: the aim, the pull and the called pocket. The server checks the sender is the shooter and relays it as `AimRelay`. Every other client in the top-down view smooths it and draws the cue, the aim indicator and the pocket ring from it. It's display only: the shot still comes from `RequestShot` alone, so a late or lost update never changes it.

## Items

- **State:** `Shared/Items.luau` holds a game's items as plain tables, and `Match` owns that state: each player's slots and item bar (its points, and whether it's full and waiting for a slot), the active effects and when each one ends, and what each side targeted on its last turn. Its checks cover every item rule in GAME_SPEC, lock-outs included. It never calls `math.random`: the server passes in a random number for each item rolled, so tests can choose them.
- **Earning:** at the start of each turn, `Match` gives the shooter `TurnPoints`. After `EightBall.resolveShot` it passes the outcome to `Items.luau`. Each legal pot of the shooter's own group (any legal pot on an open table) gives the shooter `OwnBallPoints` and the other side's player who shoots next `OpponentBallPoints`, all of it, so points stay whole. Break pots, foul pots and the 8 give nothing. Every `BarPoints` gives a random item into the first empty slot. With both slots full, the bar stops at `BarPoints`, extra points are dropped, and the item arrives when the player uses one. With `SinkItemsWaitForTurnEnd` on, an item the shooter's own pots filled waits for the end of their turn. Every change to a bar is sent with how many points it added, for the pops.
- **The rules stay out of it:** `EightBall.luau` never sees items, because items only change how balls move. `Items.luau` reads its outcomes but never changes them. The one check that touches a rule, that nobody can call a blocked pocket, lives in `Items.luau`, and the server checks it when validating `RequestShot`.
- **Using an item:** the shooter's client fires `UseItem` with a slot and a target. The server checks it with `Items.luau`: it's their turn, before the shot, no item used yet this shot, the slot holds that item, and the target is allowed. Then it updates the state and fires `ItemUsed` to everyone, for the big name and the effect.
- **Power Shot isn't a simulation effect:** it only lets the shot's power go past 1. While it's on, `Pull.luau` keeps adding power at the same rate past full, up to `PowerShotMax` at `PowerShotMax` × `FullPullDistance`. Up to 1, speed follows the power curve as today; above 1 it's `FullPowerSpeed` × power, so 1.5 is 1.5× full speed. The server drops any `RequestShot` with power above 1 unless the shooter's Power Shot is on.
- **Into the simulation:** `Items.luau` turns the active effects into an `effects` table that goes with the shot in `ShotStarted`, so every client simulates the same shot. An empty table is a normal shot.
  - `blast`: at the cue ball's first ball contact, every other ball within the reach is pushed away from the hit ball's center, at a speed that fades to nothing at the edge. Not the cue ball, the hit ball or frozen balls.
  - `frozen`: ids of balls that never move. Other balls hit them as a fixed circle and keep `RailBounce` of their speed along the line of centers.
  - `oil`: circles where a ball whose center is inside slows at `OilSlowdown` × the normal rate.
  - `blocked`: ids of pockets whose mouth becomes a rail from jaw to jaw.
- **Still exact and deterministic:** no randomness or clock reads inside the simulation. A cap on contacts in one step stops a ball wedged between a frozen ball and a rail from looping forever. Each effect gets Lune tests, and every existing test still passes with empty `effects`.
- **Aim preview:** `Preview.luau` takes the same `effects`. Frozen balls and pocket lids are walls that stop the line, and with `blast` it reports the ring around the ball it would hit. It ignores oil, because oil changes how far balls roll, not where the cue ball first touches anything.
- **Client:** `ShotController` handles keys 1 and 2, slot taps and target picking; on phones, the nearest ball or pocket to the finger, within a tolerance. `Hud` draws the slots, their icons and the cards. `Effects.luau` draws each effect when it starts and destroys it when it ends, so nothing is created every frame.

Starting values for `Config.Items`, every one a default to tune by feel. Distances are in ball radii and speeds a share of full power:

| Setting | Start | Why |
| --- | --- | --- |
| `BarPoints` | 12 points per item | GAME_SPEC |
| `TurnPoints` | +3 at the start of each turn | GAME_SPEC |
| `OwnBallPoints` | +4 for each of your balls you sink | GAME_SPEC |
| `OpponentBallPoints` | +2 for each ball the other side sinks; in 2v2, all to the opponent who shoots next | The comeback: the side being run on still fills up. The balance pass tries 3 |
| `SinkItemsWaitForTurnEnd` | false | When true, an item your own sinks fill arrives at the end of your turn |
| `Slots` | 2 | GAME_SPEC |
| `Odds` | Equal for all 5 items | GAME_SPEC |
| `PowerShotMax` | 1.5: the meter reaches 150% at 1.5× `FullPullDistance`, for 1.5× full-power speed | GAME_SPEC |
| `BlastReach`, `BlastPush` | 6 ball radii (3 ball widths); 40% of full-power speed for a touching ball, fading to 0 at the edge | Clears a cluster without emptying the table |
| `OilRadius`, `OilSlowdown` | 5 ball radii (5 ball widths across); 0.25 × the normal rate | "Much less", while balls still stop |
| `NameSeconds` | 1.5 s for the item's name on screen | Long enough to read, short enough to keep play moving |
| `ShakeSpeed` | Shake on hits and rail bounces faster than 60% of full-power speed | The break, blasts and Power Shots shake; normal shots don't |

### Ready for items: where they plug in (written 2026-11-07)

Notes from the health pass on where each part of the Items phase joins today's code, so it starts without a refactor.

- **Turn hooks in `Match`:**
  - `startTurn` runs once at the start of every turn: after a shot passes it, after a timeout, for Coach, and for the 2v2 teammate taking over a leaver's turn. `TurnPoints` go in here.
  - `shoot` already has what `Items.luau` needs for the sink points: the `EightBall.resolveShot` outcome and `Simulate.dropped(sim)`, next to `EightBall.countShot`.
  - The point where `shoot` clears `match.clock` (the shot has gone) is where "an item was used this shot" resets.
  - Effects that last "until the end of the other side's next turn" end where the turn passes: `TableFlow.afterShot` or `TableFlow.afterTimeout` returning a different seat.
- **Key item state by seat number, not by player.** `stats` and `votes` are keyed by the seat's occupant (a Player or Coach's model). GAME_SPEC gives a player who takes over a leaver's spot that spot's items and bar, so slots and bars belong to the seat.
- **`TurnStarted` gets a table.** It already carries 8 values in order, and items add held items, bars, the points just added and the active effects. Switch it to one table argument in a single change: `Remotes.luau`, `Match`'s `turnMessage`, `PhysicsTest`, and the client listeners in `ShotController`, `Hud`, `TurnArrow` and `EndScreen`.
- **`effects` through the simulation.** `Simulate.start(balls, shot, params)` and `Preview` take no effects yet. Add an `effects` argument, where an empty table gives today's behavior, and pass it through `Balls.shoot`, `ShotStarted` and `TableView`'s replay and `predict`, so every screen simulates the same shot. Coach's `ShotPicker` can ignore effects at first.
- **Power past 100%.** Four places cap power at 1, and each needs `PowerShotMax` while the shooter's Power Shot is on:
  - `Pull.power`
  - `TableFlow.readShot` (power) and `TableFlow.readAim` (live-aim pull)
  - the speed formula in `Simulate.start`, which is linear above 1
- **Client:**
  - `ShotController` owns input. Keys 1 and 2 bind only in the top-down view, like Space. Target picking catches the click in `pointerBegan` before a pull starts, the way ball in hand does.
  - `TopBar.showSide` draws each card, and the slots and bar go under the names.
  - The item slots sit bottom center, clear of the hints bottom right.
  - Item effects and screen shake join `Effects.luau`, which already caps live parts.
- **Tests.** The whole-game bots in `tests/games.spec.luau` can use a random held item now and then, to fuzz the item rules the way they fuzz the 8-ball rules.

## Tables

- States: `Idle` → `Countdown` → `Playing` → `GameOver` → reset → `Idle`.
- Joining: each table has a ProximityPrompt over its centre, made at runtime on an Attachment in the `Felt`. Pressing it only joins. The HUD's Leave button fires `LeaveTable`: off the table while waiting, the countdown called off at once, or mid-game `Match.leave`, which in 1v1 ends the game for the other side and in 2v2 leaves the teammate playing for the leaver's seat. A table's seat count comes from its `Mode` attribute, and joined players keep a display-only `JoinedTable` attribute so their own screen reads "Waiting for players". When every seat is taken, a countdown, then each player is moved once to their seat marker, facing the table, and their `ShotController` turns the normal camera to face the table from behind that marker (`Config.Camera.SeatPitch`). Players are never locked in place. Clients hide prompts in the top-down view, where they'd sit on the felt.
- Every state change goes through one function that updates the sign and fires `TableChanged`.
- Timers (countdown, shot clock, takeover window, end screen) carry the game id and the step they were made for, and do nothing if that step is over. This is what keeps tables from getting stuck.
- One `Match` object holds everything about a game. Resetting the table destroys it and disconnects everything it made.
- **Debug, Studio only:** with `Config.Debug.Coach` on, a tester (`PhysicsTestAccess`) alone in the server who joins a 1v1 table gets Coach in the other seat: a plain grey R6 figure that `TableService` makes on the B1 spot and destroys when the game ends or the tester leaves the start. `Match` plays Coach's turns with `ShotPicker`, showing its aim live (`Config.Coach`: a pause, the aim swinging onto the shot, the cue drawing back), through the same checks as a player's shot, and Coach always presses Rematch. Coach never joins with two players in the server, and like the test mode it only reaches published servers for the owner while `PhysicsTestLive` is on. With Coach off, `Config.Debug.SoloTables` and one player in the server, joining with the prompt starts the table and that player takes every turn. `Config.Debug.LogShots` prints each shot's input and outcome. `Config.Debug.PhysicsTest` turns on the physics test mode on Table1 while no game is on it. It plays like a game without turns: R or the Rack button racks an 8-ball rack, the next shot is the break from the middle of the head line, a scratch gives ball in hand anywhere, a small "TEST MODE" label shows bottom-left, anyone can shoot with the real shot controls while the balls are still, and sliders tune the settings in `Config.Debug.TestSliders` live for everyone. The two pocket sliders, `CornerPocketMouth` and `SidePocketMouth`, also rebuild Table1 with `Server/TableBuilder.luau` in the running game, never the saved place, so they only move while the test mode has the table: no game on it and the balls still. The server turns down a change any other time, and that player's slider goes back. The server keeps the slider values and sends the physics ones with each shot; the shot controls read the rest, like `FullPullDistance`, at the start of each pull. Print values prints them to Output. The first shot after a rack is the break; the server sets Table1's `BreakNext` attribute so the shooter's screen starts it at break power. All of them check `RunService:IsStudio()`, so they can never run in a live server, with one exception: `Config.Debug.PhysicsTestLive` also runs the physics test mode in published servers, for the place's owner only, so I can test on my real phone. `Shared/PhysicsTestAccess.luau` decides who may use it, and the server checks it on every test request. It's turned off before launch.

## Place contract

What the code expects in the place. Claude builds it with builder scripts in `tools/`, following `docs/MODELS.md`. Code finds everything by these names, so any model can be rebuilt or restyled without code changes.

```text
Workspace
└─ Tables (Folder)
   └─ Table1 … Table6 (Model, attribute Mode = "1v1" or "2v2")
      ├─ Felt (Part): the playing surface. Size X and Z match Config's table length and width
      └─ Seats (Folder): A1 and B1, plus A2 and B2 on 2v2 tables (invisible Parts where each seat's player
                         is moved when a game starts). A seats on one long side, B on the other
```

- Rails and pocket visuals must line up with Config. When pocket or table sizes change in Config, rebuild the greybox with `tools/BuildTable.luau`, which reads Config and runs `Server/TableBuilder.luau`.
- Ball parts, the Join prompts, signs, the Turn arrow and all UI are made by code at runtime. Don't build them in the place.
- At startup, TableService warns in the output about anything missing or mismatched.

## Remotes (starting list; `Remotes.luau` is the source of truth)

| Remote | Direction | Carries |
| --- | --- | --- |
| `RequestShot` | client → server | Aim direction, power, cue ball placement, called pocket |
| `AimUpdate` | client → server, unreliable | The shooter's live aim, at most `Config.Aim.RelayRate` (10) a second and only on change: angle, pull, locked or pulling, placing, the placed cue ball and the called pocket. The server checks it with `TableFlow.readAim`, drops ones closer than `RelayMinGap` and passes it on |
| `LeaveTable` | client → server | The Leave button |
| `ClientReady` | client → server | Once the player's scripts listen. The server answers with `TurnStarted` for every game on, and the test mode's ball in hand, which a player who just joined would have missed |
| `SayPhrase` | client → server | A quick phrase, by index (Later list) |
| `UseItem` | client → server | Slot, and a target: a ball id, a point on the felt or a pocket id |
| `TableChanged` | server → clients | Sign text, state, seats |
| `TurnStarted` | server → clients | Shooter, the game's players in turn order (a 2v2 player who pressed Leave shows as their teammate), clock end time, ball in hand (true or false), pocket call needed, each side's group and the balls down (the top bar draws from these, so every screen agrees), held items, item bars and the points just added, any item earned, active effects. Players with no shooter: the game is over and its result is showing, so nobody shoots. No players means no game is on: the game just ended, or the physics test mode's ball in hand |
| `ItemUsed` | server → clients | Who used which item, and its target |
| `ShotStarted` | server → clients | Start balls, shot, item effects and physics params to replay |
| `ShotResolved` | server → clients | Final balls, the outcome, item bars and the points just added, and any item earned |
| `Banner` | server → clients | A message for everyone at the table and how many seconds to show it: a foul and who has ball in hand, or until the end screen, who won and why |
| `GameOver` | server → clients | To each player still in a decided game: who won and why, the winning side, each seat's stats, whether a rematch is possible, and when the end screen closes |
| `Rematch` | client → server, and server → clients | Rematch (true) or Back to lobby (false), once per game. Back to the game's players: every answer so far |
| `AimRelay` | server → clients, unreliable | That aim to everyone but the shooter. Screens in the top-down view draw the cue and aim indicator from it, easing towards each update over `RelaySmoothSeconds` |
| `TestRack` | client → server | Physics test mode: rack Table1 |
| `TestShoot` | client → server | Physics test mode: direction, power and cue ball placement |
| `TestTune` | client → server, and server → client | Physics test mode: a slider's name and value. Its attributes hold every slider's current value. Back to one client, with nothing, when the server turned its change down, so its panel shows the kept values |
| `TestPrint` | client → server | Physics test mode: the server prints every slider's value to the Output |

## Tutorial (Phase 4, planned)

- **One place, two modes.** A new player who joins the lodge is sent with `TeleportService` to a reserved server of the same place (`ReserveServer`), with teleport data marking it as the tutorial. That server sees it's reserved and runs in tutorial mode: one table, Coach in the other seat, no prompt to join. It's the same synced code, so there's no second place to keep in step.
- **The steps** are a small scripted layer over a normal `Match` with Coach: each step places the balls it needs (like Studio's test racks), shows its tip card, waits for the shot it teaches, and tries again on a miss. Coach's turns use `ShotPicker` and the live aim, as in Studio. The item step gives the player an item through `Items.luau`.
- **Skip and the end** teleport the player to a public lodge server. Whether they've finished or skipped is one more saved field, `tutorialDone`, in `StatsService`, which needs my OK before it's added. If saving fails, the player gets the tutorial again, never an error.
- Teleports and reserved servers only work in a published game, so they're tested in a private published version, not in Studio. In Studio a debug switch runs tutorial mode directly.

## Saving and analytics

- `StatsService` is the only module that touches DataStores. Use ProfileStore for session locking, copied into `src/Server/Packages/` once I approve adding it.
- Saved per player: `{ version = 1, gamesPlayed, wins, shots, successfulShots, ballsSunk, fouls, bestRun }`. Bump `version` and migrate old data when the shape changes.
- If saving fails, the game carries on. For saving to work in Studio playtests, I turn on Game Settings → Security → Enable Studio Access to API Services.
- Analytics (Phase 4): server-side `AnalyticsService:LogOnboardingFunnelStepEvent` with steps 1 joined, 2 first game started, 3 first game finished, 4 second game started. It only reports from published games.

## Performance

- Hold 30+ fps on a mid-range phone. Replays move only balls that are moving, and nothing creates Instances every frame.
- Watch connections: one RenderStepped connection per active system at most, disconnected when it's done.
