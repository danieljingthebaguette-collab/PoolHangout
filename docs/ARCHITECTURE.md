# Architecture

How the code fits together. Follow it. If something here is wrong or gets in the way, propose the change, and update this file once I agree.

## Principles

1. **The server is the referee.** It owns every table's state, seats, turns, clocks, the shot simulation and rule decisions. Clients send intents ("shoot this way with this power") and draw what the server says happened.
2. **Pure core.** Ball physics (`src/Shared/Physics/`) and 8-ball rules (`src/Shared/Rules/`) are plain Luau with no Roblox APIs. Plain tables and numbers go in and come out, and Lune tests cover them.
3. **Same simulation everywhere.** The server simulates each shot for the rules. Clients run the same deterministic simulation from the same inputs to animate it, then snap to the server's final positions. No Roblox physics touches the balls.
4. **One config.** All tuning lives in `src/Shared/Config.luau` as plain numbers, strings and booleans, so Lune can load it too. Colors, fonts and UI sizes go in `src/Shared/Theme.luau`.
5. **Code finds the world by name.** Tables in the place follow the place contract below.

## Modules (planned; create each when a task needs it)

| File (under `src/`) | Job |
| --- | --- |
| `Shared/Config.luau` | Every tuning number |
| `Shared/Theme.luau` | Colors, fonts, UI sizes |
| `Shared/Remotes.luau` | Creates (server) or finds (client) every remote. Remote names appear nowhere else |
| `Shared/TableSpace.luau` | World ↔ table space, from a table's `Felt` |
| `Shared/Physics/Geometry.luau` | Rails, pockets, head line, foot spot and rack positions, from Config |
| `Shared/Physics/Simulate.luau` | A stepper: start it from balls, a shot and params (Config by default), advance it N steps at a time, read the `ShotResult` when done. `run()` does it all at once for tests |
| `Shared/Physics/Preview.luau` | Where the cue ball first touches a ball, rail or pocket, and which way a hit ball goes, for the aim indicator. Same contacts as Simulate, solved exactly |
| `Shared/Rules/EightBall.luau` | New game, resolve a shot, timeouts, forfeits, per-player game stats |
| `Server/Main.server.luau` | Starts the services |
| `Server/TableService.luau` | Finds tables, watches platforms, runs countdowns and signs, starts and resets games |
| `Server/Match.luau` | One game: seats, turn order, shot clock, ball in hand, takeovers, end-screen data |
| `Server/StatsService.luau` | Lifetime stats. The only module that touches DataStores |
| `Server/PhysicsTest.luau` | Physics test mode on Table1 (Studio only): ball parts, rack, test shots |
| `Client/Main.local.luau` | Starts the controllers |
| `Client/TableView.luau` | Replays shots on the ball parts and plays their sounds |
| `Client/ShotController.luau` | F and the top-down camera, placing the cue ball, aim, pocket call, power meter |
| `Client/Hud.luau` | Shot clock, end screen, Leave button |
| `Client/Spectate.luau` | "Watch from above" |
| `Client/PhysicsTestPanel.luau` | Physics test mode controls (Studio only) |

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
- **Accurate:** the step is small enough that the fastest ball moves less than a third of its radius per step (a test checks this against Config).
- **Fast:** skip pairs where neither ball moves. Time a full break in Lune; if it takes more than about 50 ms, speed it up before building on it. Nobody runs a whole shot in one frame in the game: the server and clients both advance the stepper a slice at a time.
- **`ShotResult`** holds the final balls, timestamped events (ball hit, rail hit, pocketed) for sounds and rules, the first ball the cue ball touched, pocketed balls in order with their pockets, and the duration.

Starting values for Config (tune by feel):

| Setting | Start | Why |
| --- | --- | --- |
| Table length × width | 10 × 5 studs | About 1.5× a 7-foot bar table |
| Ball radius | 0.15 studs | Real ball-to-table proportion |
| Pocket mouth, corner / side | 0.75 / 0.8 studs | About 20% wider than real |
| Full-power speed | 20 studs/s | |
| Rolling slowdown | 1.5 studs/s² | Full power rolls about 133 studs, about 13 table lengths |
| Rail bounce | 0.8 | Keeps about 80% of the speed |
| Ball bounce | 0.9 | |
| Follow | 0.25 | Natural roll in real pool is 2/7; with ball bounce 0.9 a straight hit keeps about 29% |
| Rack gap | 0 studs | A tight rack |
| Stop speed / time step / time cap | 0.02 studs/s / 1/960 s / 20 s | 1/960 keeps the test mode's top speed of 40 under a third of a radius per step |
| Shot clock / warning | 45 s / last 10 s | |
| Countdown / takeover / open-spot wait / end screen | 5 / 5 / 15 / 10 s | |
| Aim nudge / hold speed | 0.25° / 15°/s rising to 120°/s over 1 s | |
| Full-power pull | A quarter of the table length | Measured on the table, so it's the same share of the screen on every device |
| Shortest pull that shoots | 5% of a full pull | Stops twitches from firing |

## A shot, end to end

1. `Match` starts a turn: it sets the shooter, `clockEndsAt` from `workspace:GetServerTimeNow()`, the ball-in-hand area and whether a pocket must be called, then fires `TurnStarted` to everyone.
2. The shooter's `ShotController` runs the camera, placement, aim, pocket call and power meter locally, then fires `RequestShot` with the aim direction, power (0–1), cue ball placement and called pocket.
3. The server validates the request (see `.claude/rules/server.md`) and normalizes the direction.
4. It fires `ShotStarted` with the exact start balls, the shot and the physics params it used, so every client simulates with the server's numbers even while test mode changes them live. Then it simulates the shot in slices of a couple of milliseconds per frame, so even a break never stalls the server. It finishes long before the replay does.
5. Each client steps the same simulation as it plays the shot back in real time, so every client sees the same shot and no frame does much work.
6. Once the server's simulation is done and the shot's duration plus a short buffer has passed, the server runs `EightBall.resolveShot`, moves the ball parts to their final positions and fires `ShotResolved` with the final balls and the outcome. Clients snap to those positions, which also corrects any drift.
7. Then the next turn, or the end of the game.

- **Ball parts** are anchored, non-colliding parts the server creates for each table and moves only between shots. During a replay each client moves them locally. Players who join later get the resting positions through normal replication.
- **Live aim for watchers (Phase 3):** while aiming, the shooter's client sends `AimUpdate` over an UnreliableRemoteEvent at most 10 times a second. The server checks the sender is the shooter and relays it.

## Tables

- States: `Idle` → `Countdown` → `Playing` → `GameOver` → reset → `Idle`.
- Platforms: about 5 times a second, the server checks each living player's HumanoidRootPart position against each platform's footprint. Don't use Touched or TouchEnded; they miss players standing still.
- Every state change goes through one function that updates the sign and fires `TableChanged`.
- Timers (countdown, shot clock, takeover window, end screen) carry the game id and the step they were made for, and do nothing if that step is over. This is what keeps tables from getting stuck.
- One `Match` object holds everything about a game. Resetting the table destroys it and disconnects everything it made.
- **Debug, Studio only:** with `Config.Debug.SoloTables` on and one player in the server, standing on one platform starts the table and that player takes every turn. `Config.Debug.LogShots` prints each shot's input and outcome. `Config.Debug.PhysicsTest` turns on the physics test mode on Table1: R or the Rack button racks, anyone can shoot with the real shot controls while the balls are still, and sliders tune the settings in `Config.Debug.TestSliders` live for everyone. The server keeps the slider values and sends them with each shot; Print values prints them to Output. All of them check `RunService:IsStudio()`, so they can never run in a live server.

## Place contract

What the code expects in the place. Claude builds greybox versions through MCP. Every model is a placeholder until the commissioned art arrives, built to `docs/MODELS.md` with the same names, so it swaps in without code changes.

```text
Workspace
└─ Tables (Folder)
   └─ Table1 … Table8 (Model, attribute Mode = "1v1" or "2v2")
      ├─ Felt (Part): the playing surface. Size X and Z match Config's table length and width
      └─ Platforms (Folder): A1 and B1, plus A2 and B2 on 2v2 tables (Parts)
                             A platforms on one long side, B on the other
```

- Rails and pocket visuals must line up with Config. When pocket or table sizes change in Config, update the greybox to match.
- Ball parts, signs, the Turn arrow and all UI are made by code at runtime. Don't build them in the place.
- At startup, TableService warns in the output about anything missing or mismatched.

## Remotes (starting list; `Remotes.luau` is the source of truth)

| Remote | Direction | Carries |
| --- | --- | --- |
| `RequestShot` | client → server | Aim direction, power, cue ball placement, called pocket |
| `AimUpdate` | client → server, unreliable | Live aim for watchers |
| `LeaveTable` | client → server | The Leave button |
| `SayPhrase` | client → server | A quick phrase, by index |
| `TableChanged` | server → clients | Sign text, state, seats |
| `TurnStarted` | server → clients | Shooter, clock end time, ball in hand, pocket call needed |
| `ShotStarted` | server → clients | Start balls, shot and physics params to replay |
| `ShotResolved` | server → clients | Final balls and the outcome |
| `GameOver` | server → clients | Winner and each player's stats |
| `AimRelay` | server → clients, unreliable | Live aim for watchers |
| `TestRack` | client → server | Physics test mode: rack Table1 |
| `TestShoot` | client → server | Physics test mode: direction and power |
| `TestTune` | client → server | Physics test mode: a slider's name and value. Its attributes hold every slider's current value |

## Saving and analytics

- `StatsService` is the only module that touches DataStores. Use ProfileStore for session locking, copied into `src/Server/Packages/` once I approve adding it.
- Saved per player: `{ version = 1, gamesPlayed, wins, shots, successfulShots, ballsSunk, fouls, bestRun }`. Bump `version` and migrate old data when the shape changes.
- If saving fails, the game carries on. For saving to work in Studio playtests, I turn on Game Settings → Security → Enable Studio Access to API Services.
- Analytics (Phase 4): server-side `AnalyticsService:LogOnboardingFunnelStepEvent` with steps 1 joined, 2 first game started, 3 first game finished, 4 second game started. It only reports from published games.

## Performance

- Hold 30+ fps on a mid-range phone. Replays move only balls that are moving, and nothing creates Instances every frame.
- Watch connections: one RenderStepped connection per active system at most, disconnected when it's done.
