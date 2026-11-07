---
description: Playtest the open place in Roblox Studio and report errors. Use after gameplay code changes or when asked to test something.
argument-hint: "[what to test]"
---

Playtest the game in Roblox Studio with the Roblox_Studio MCP tools. Don't edit any code while this runs.

1. Call `list_roblox_studios` and pass its `studio_id` on every call. If no Studio is connected, stop and tell me to open the place and turn on the MCP server.
2. Start a playtest with `start_stop_play` and wait about 10 seconds for the character to spawn. If the server's `workspace.DistributedGameTime` is well past that, you joined a playtest that was already running, with old code and old state: stop it and start a fresh one.
3. Test what I asked for: $ARGUMENTS. Act as a player with `character_navigation`, `user_keyboard_input` and `user_mouse_input`. If I didn't ask for anything specific, test the newest feature in the current phase. For anything involving a game, walk to a table and press E at its "Join table" prompt; with `Config.Debug.Coach` on, Coach (a bot) takes the other seat of a 1v1 table and the game starts after the 3-second "Starting..." (with Coach off and `Config.Debug.SoloTables` on, it starts with just you). Press F for the top-down view. Then use the real controls (GAME_SPEC's "Taking a shot"):
   - Mouse positions are GUI points below Roblox's top bar, not screenshot pixels. Get them from a table-space point (x, y) with `workspace.CurrentCamera:WorldToScreenPoint((felt.CFrame * CFrame.new(x, felt.Size.Y / 2 + radius, y)).Position)` in a Client `execute_luau`.
   - The cue always points from the cue ball at the cursor; no keys aim. Space locks the aim.
   - To shoot, in one `user_mouse_input` call: move to a point in front of the cue ball along the aim and wait a moment, press, move back toward the cue ball in small steps, then let go. Power is how far you moved straight back: full power is the cancel zone plus `FullPullDistance` (6.6 studs today), and letting go inside the cancel zone fires nothing. A right-click cancels a pull.
   - With ball in hand, press on the cue ball's center (within `Aim.PlaceGrabRadius`) and drag it, in one call.
   - With no game on the table, R racks it for the physics test mode.
   - Check a drag or a pull with a per-frame log from `execute_luau` (input events, the cue ball's position, the meter's %), since a button held across separate calls can get pressed again.
4. Read `get_console_output`. It can miss server prints, so also read the server's `LogService:GetLogHistory()` with a Server `execute_luau`. Read game state from the place (ball parts, attributes): a `require` from `execute_luau` gets its own copy of a module, not the game's. Take a `screen_capture` at the moments that matter, like the top-down view and after the balls stop.
5. Stop the playtest with `start_stop_play`.
6. Report in under 10 lines: each error or warning with its script and line, what the screenshots show, and the fix you'd make.
