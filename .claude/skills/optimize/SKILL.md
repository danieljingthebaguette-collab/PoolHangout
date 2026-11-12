---
description: Make Pool! faster, lighter on memory or network, or cleaner, based on Roblox's official performance, Luau and networking docs. Use before any optimization, cleanup or refactor of a module (ShotController, Match and the like), and for code-health reviews. Measure first, change one module at a time, behaviour stays the same.
argument-hint: "[module or problem to look at]"
---

Pool!'s rules for changing code for speed, memory, network traffic or tidiness. Everything here comes from the official pages under **Sources**, read 2026-11-11, applied to our code. When a rule here and CLAUDE.md disagree, CLAUDE.md wins and you tell Daniel.

## The workflow

1. **Measure the problem first** (section 1). No number, no optimization: write down what you measured, how, and on what.
2. **Find the cause** with the tools in section 1, starting where section 3 points.
3. **Change one module**, following section 4.
4. **Measure again** in the same scenario. Keep the change only if the number moved the right way.
5. **Check behaviour:** `lune run tests/run` passes unchanged, lint and the type check pass, and a playtest of the same scenario looks the same. For anything beyond a one-line change, have the `code-reviewer` subagent read it fresh before you commit.
6. **Commit that module alone**, with the before and after numbers in the commit message, like `Break: worst server frame 13.0 → 3.4 ms (Lune, quiet Mac, median of 3)`.

## 1. Measure first

- **Same scenario before and after.** Pool!'s standard ones:
  - **A. Lobby:** idle, not at a table.
  - **B. Your turn:** a Coach game on Table1, in the top-down view, aiming.
  - **C. Watching:** the top-down view while Coach shoots.
  - **D. Break:** a full-power break.
  - **E. Long session:** 10 minutes of B and C, for memory growth.
- **Timings are noisy.** On this Mac a full-power break measured 17 ms quiet and 85 ms with Chrome and Studio busy. Run each measurement 3 times, use the median, and note what else was running. Studio numbers run high because Studio runs the server and the client together (design.md, identify.md). Compare Studio to Studio, never to a live server.
- **Frame time is 16.67 ms at 60 FPS**, for everything. The server's heartbeat is capped at 60 (identify.md).

**The tools:**

- **Developer Console** (F9; design.md, identify.md, developer-console.md):
  - **Memory:** watch **LuaHeap** (growing means a leak), **InstanceCount** (growing means instances still referenced) and **PlaceScriptMemory** (per script).
  - **Server Jobs → Heartbeat:** **Steps Per Sec** is the server's frame rate.
  - **Server Stats:** average data ping.
- **MicroProfiler** (Ctrl+Alt+F6, or ⌘⌥F6 on Mac):
  - **Reading it:** bars all one height mean something costly runs every frame; tall single bars are spikes. Ctrl+P (⌘P) pauses into detailed mode, and you hover down the stack to find the script.
  - **Scopes for us:**
    - `RunService.PreRender` and `RunService.PreSimulation`, and `RunService.Heartbeat` (or `RunService.PostSimulation`), for our per-frame code.
    - `stepAnimation`, and `updateInvalidatedFastClusters` above about 4 ms, which means avatar joints are being rewritten.
    - `ProcessPackets` (incoming remotes) and `Allocate Bandwidth and Run Senders` (outgoing).
  - **Network:** traffic only shows in a saved frame dump. Set the Network menu to Low or High first (use-microprofiler.md, network.md, improve.md).
- **Your own labels:** wrap suspect code in `debug.profilebegin("Pool: what it is")` … `debug.profileend()` and find the label in the MicroProfiler (use-microprofiler.md, debug.md). Remove the labels before committing, unless Daniel wants one kept.
- **Script Profiler:** time spent per function. It marks functions running as native code (native-code-gen.md).
- **Overlays:** Shift+F5 shows the frame-rate summary, and Ctrl+Alt+F7 (⌘⌥F7) shows Performance Stats (identify.md).
- **The `Stats` service through the Studio MCP** (`execute_luau`; Stats.md):
  - **Readable by scripts:**
    - `FrameTime` and `RenderCPUFrameTime`: client only, in seconds.
    - `HeartbeatTime`: the server's frame work, in seconds.
    - `DataReceiveKbps` and `DataSendKbps`: on the server, its total to and from all clients.
    - `InstanceCount`, and `GetTotalMemoryUsageMb()`.
    - Per-tag memory only works while `MemoryTrackingEnabled` is true.
  - **Keep each call short:** a long `execute_luau` call resets the camera type when it returns. Sample like this on the Client, and the same on the Server with `HeartbeatTime`:

```lua
local Stats = game:GetService("Stats")
local frames, worst, t0 = 0, 0, os.clock()
local c = game:GetService("RunService").RenderStepped:Connect(function()
	frames += 1
	worst = math.max(worst, Stats.FrameTime)
end)
task.wait(3)
c:Disconnect()
return {
	fps = frames / (os.clock() - t0),
	worstFrameMs = worst * 1000,
	renderCpuMs = Stats.RenderCPUFrameTime * 1000,
	recvKbps = Stats.DataReceiveKbps,
	sendKbps = Stats.DataSendKbps,
	instances = Stats.InstanceCount,
	memoryMb = Stats:GetTotalMemoryUsageMb(),
}
```

- **Lune, for the pure physics:**
  - `lune run tools/BenchPhysics` times `Simulate.step(sim, Config.Shot.ServerStepsPerFrame)` slice by slice for a full-power break, over 5 runs, and checks the result matches stepping it all at once. `Steps=120` tries another slice size, `Runs=7` more runs.
  - Its worst slice is the server's worst frame at that table.
  - 6 tables can break in the same frames, so 6 × the worst slice must stay well under 16.67 ms.

## 2. The rules that apply to Pool!

**Work that runs every frame**

- Prefer event-driven code to per-frame work. Every frame shares the 16.67 ms (design.md). Use `RunService` events only where something must change every frame, like the camera or a replay (improve.md).
- **Allocate nothing per frame:** no new tables or closures, no `GetDescendants()` (it returns a new table), and no `table.clone`. In Pool! that also means no `Geometry.build(...)` and no `PhysicsTestAccess.params()` per frame. Allocations make the garbage collector step in mid-frame (luau.org/performance). Build these once and rebuild only when their input changes, for example when a test slider's attribute changes.
- **Call once, store the value, overwrite it when it changes** (design.md).
- **Write an Instance property only when its value changes.** Several of our HUD modules already keep a "shown" state for this: keep doing it.
- **Poses go through `Motor6D.Transform`, never `C0` or `C1`.** Rewriting `C0` or `C1` rebuilds the avatar's render clusters (`updateInvalidatedFastClusters`; improve.md, Humanoids).
- **Spread long work over frames,** as `Balls.shoot` does with `task.wait()` between slices, and size the slices so no frame goes over budget (design.md).
- **Keep transparency to 0 or 1 where the design allows:** partial transparency costs overdraw (design.md). The shooter's 40% opacity on the table is a design decision, so leave it.
- **Don't make tables slow:** create object-like tables with every field in one literal, use generalized iteration (`for k, v in t`), and never use `getfenv`, `setfenv` or `loadstring`, which turn off Luau's optimizations (luau.org/performance).

**Remote traffic**

- **Send less, less often, only to who needs it** (improve.md, networking):
  - Throttle anything driven by input. `AimUpdate` already sends at most `RelayRate` times a second.
  - Send per-table updates only to the players at or watching that table, not to the whole server.
  - Don't send what didn't change.
- **Unreliable events** (UnreliableRemoteEvent page, remote.md):
  - Over 1,000 bytes is dropped.
  - They're never resent and can arrive out of order. Add a sequence number or time if order matters.
  - They're discarded if nothing is listening yet.
- **Rate limit:** about 500 per second per client, client to server, shared by all remotes of the same type (UnreliableRemoteEvent page).
- **Reliable events** wait in a limited queue until a handler connects (remote.md).
- **Table arguments** (remote.md):
  - Never mix array and dictionary keys, and never leave `nil` holes: use `false`, as the slots do.
  - Non-string keys turn into strings, so key by `"A"`/`"B"` or use arrays, never Instances or sparse numbers.
  - Metatables are dropped, and tables arrive as copies.
- **Keep visuals and motion on the client** (improve.md: server-side TweenService, visual effects):
  - Anything the server moves every frame replicates every frame, like Coach's glide (`Match.glideCoach` calls `PivotTo` every frame).
  - The server only needs the outcome.
- The server still checks everything, as CLAUDE.md and `.claude/rules/server.md` say. Optimizing never skips a check.

**Cleaning up**

- **Every connection gets disconnected,** or its Instance or script gets destroyed (improve.md, script memory).
- **Player objects and characters aren't destroyed when a player leaves,** unless `Workspace.PlayerCharacterDestroyBehavior` is enabled (improve.md). So connections to a `Player` (like `CharacterAdded`) or to character parts leak until you disconnect them. Turning the property on is a place setting: ask Daniel first.
- **Tables keyed by a player, character, seat or table** lose their entry when that thing goes: on `PlayerRemoving`, a respawn, a game ending, or the screen switching tables (improve.md, tables).
- **Effects** are built once per effect and destroyed when it ends, with live parts capped (`Theme.Effects.MaxParts`).
- **Leak check:** in scenario E, LuaHeap and InstanceCount should level off, not keep climbing (monitor.md).

**Native code (`--!native` and `@native`)** (native-code-gen.md)

- **Where it runs:** native code only compiles on servers and Android clients. It helps numeric Luau with few Roblox API calls.
- **What compiles:** functions only, not the top level of a script.
- **What it costs:** server startup time and memory, and there's a total limit, so never put it everywhere.
- **Measure** with and without it (Script Profiler or the Lune bench), and type-annotate the arguments.
- **In Pool!** `Shared/Physics/Simulate.luau` is `--!native` since 2026-11-12: a fixed set of 40 breaks and 40 shots took 1,641 ms interpreted and 844 ms native on a Studio server, with bit-identical results.
  - **Shared module:** PCs and iPhones run it as bytecode, servers and Android natively, so every result must match exactly. It only uses exactly-rounded math in its hot loop (`.claude/rules/core-logic.md`).
  - **After any change to it:** `lune run tools/NativeCheck` prints a fingerprint of every ball's final place over that set; run the same body on a Studio server (Server `execute_luau`) and the fingerprints must match. Any difference means native comes off until it's found.
  - **Checking it's native:** the Script Profiler shows `<native>` beside its functions, and `debug.dumpcodesize()` from the Command Bar (Server view) lists its code size.
- **Where it won't help:** client UI, the camera and the HUD (today only servers and Android clients run native code; PC and iPhone don't), and code that's mostly Roblox API calls.

**Style** (Roblox Lua Style Guide, wherever it doesn't conflict with CLAUDE.md or StyLua)

- Optimize for reading, not writing.
- Avoid magic like metatables.
- Keep functions to few arguments.
- Call `GetService` at the top of the file.
- Name local constants in `LOUD_SNAKE_CASE`.
- Name the file after the module it returns.
- Don't use section comments to break up a big file: split the file instead.

## 3. Where to look first in Pool!

Measure before believing any of these. They're the likely spots as of 2026-11-11, with line counts from that day.

1. **Per-frame client work:**
   - **`Client/ShotPose.luau`:**
     - Its `PreSimulation` step rebuilds the `offsets()` table every frame and writes every posed joint's `C0`.
     - Its `BindToRenderStep` fade calls `GetDescendants()` twice per shooter per frame (the see-through and the shadows).
     - It runs on every screen, for every table's shooter.
   - **`Client/AimIndicator.luau` `draw`:** calls `PhysicsTestAccess.params()` (two table clones plus an attribute read per slider) and `Geometry.build` every frame, for the shooter and everyone watching.
   - **Others to check:** `Client/ShotController.luau`'s `render` (856 lines in all), `TableView`'s replay `render` (it plays every table's shots), and `TopDownView`, `Stance`, `ShotClock` and `EndScreen`.
2. **The server's physics with 6 busy tables:**
   - **Where:** `Server/Balls.luau` runs `Config.Shot.ServerStepsPerFrame` (480) steps a frame per table.
   - **Measured on 2026-11-11 in Lune:** a full-power break takes 9 slices. On a quiet Mac the whole break took 17 ms, about 2 ms a slice on average. On a busy Mac it took 85 ms, with a worst slice of 10–13 ms.
   - **Fewer steps a frame** spread the same work thinner without changing any result. The server still finishes long before the replay ends: 120 steps a frame is still 7.5× real time.
   - **The simulation:** `Simulate.step`'s pair loop already skips pairs where neither ball moves. Fast balls split steps into substeps.
3. **Remote traffic:**
   - **Live aim:** `Server/Match.luau`'s `sendAim` relays live aim to every player but the shooter, up to 10 times a second per active table. With 6 tables and 24 players that's up to about 1,400 messages a second from the server, most to players at other tables.
   - **Broadcasts:** `TurnStarted`, `ItemsChanged`, `ShotStarted`, `ItemUsed` and `Banner` go to every player for every table.
   - **Payload:** check `ShotStarted`'s size (16 balls, physics params and effects).
4. **Cleaning up:**
   - **`TableService`'s `watchCharacter`** connects `CharacterAdded` for every player and never disconnects it.
   - **Ending and switching paths:** check `Match.destroy`, `TableService.endGame`, `ShotController`'s `destroy` when the screen switches tables, and Coach's figures and glides.
   - **Module-level tables keyed by Model:** in `ShotPose`, `ItemEffects`, `Effects` and `TurnArrow`.
5. **Big modules:**
   - **`ShotController` (856 lines):** item input and target picking, the live-aim relay, and ball in hand are separable.
   - **`Match` (728 lines):** Coach's turn and glide, and the items glue.
   - **`TopBar` (407) and `TableService` (389).**
6. **Duplicates and drift:**
   - Three "+4"/ring pop animations (`TopBar`, `ItemSlots`, `Effects`).
   - `isFinite` in three files (`TableFlow`, `Items`, `PhysicsTest`).
   - Theme keys nothing reads any more: `Ui.ItemRowsWidth`, `ItemRowIconInset`, `ItemLineTextSize`, `ItemDimText`, `ItemDimBox`, `ItemDimVeil` and `AbilitiesButtonWidth`.

## 4. Refactor rules

- **One module at a time.**
- **A separate commit for each module.**
- **Behaviour stays the same:**
  - `lune run tests/run` passes with the tests unchanged. Never edit a test to make a refactor pass.
  - Lint and the type check pass.
  - A playtest of the same scenario looks the same: same screenshot, same numbers.
- **Shorter only when it's also clearer.** Fewer lines that read worse is a regression.
- **No new libraries, packages or third-party code** unless Daniel says yes first (CLAUDE.md).
- **Only what the task names.** A refactor is its own task: don't fold one into a feature, and don't touch code the task didn't ask about (CLAUDE.md).
- **Keep every save runnable.** Script Sync puts each save live in Studio, where Daniel may be playing. Add the new thing before removing the old one, and never leave a `require` pointing at a deleted module or a Theme key you removed.
- **The pure modules stay pure:** `Shared/Physics`, `Shared/Rules`, `Pull` and `Items`. Numbers stay in Config, looks in Theme.
- **Update ARCHITECTURE** when a module splits, merges or moves.

## Sources (official; read each as Markdown by adding `.md`)

- Roblox docs for agents: https://create.roblox.com/docs/llms.txt
  - **Search:** `https://create.roblox.com/docs/api/search?q=<question>`, percent-encoded. Every result's `url` already points at Markdown.
  - **Paths:** never guess one. A 404 means a wrong path, not a missing topic.
- Performance:
  - https://create.roblox.com/docs/en-us/performance-optimization/design.md
  - https://create.roblox.com/docs/en-us/performance-optimization/identify.md
  - https://create.roblox.com/docs/en-us/performance-optimization/improve.md
  - https://create.roblox.com/docs/en-us/performance-optimization/monitor.md
- MicroProfiler:
  - https://create.roblox.com/docs/en-us/performance-optimization/microprofiler/use-microprofiler.md
  - https://create.roblox.com/docs/en-us/performance-optimization/microprofiler/network.md
- Luau:
  - https://create.roblox.com/docs/en-us/luau/native-code-gen.md
  - https://luau.org/performance
- Networking:
  - https://create.roblox.com/docs/en-us/scripting/events/remote.md
  - https://create.roblox.com/docs/en-us/reference/engine/classes/UnreliableRemoteEvent.md
- Measuring:
  - https://create.roblox.com/docs/en-us/reference/engine/classes/Stats.md
  - https://create.roblox.com/docs/en-us/reference/engine/libraries/debug.md
  - https://create.roblox.com/docs/en-us/studio/developer-console.md
- Style: https://roblox.github.io/lua-style-guide/
