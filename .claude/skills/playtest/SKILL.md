---
description: Playtest the open place in Roblox Studio and report errors. Use after gameplay code changes or when asked to test something.
argument-hint: "[what to test]"
---

Playtest the game in Roblox Studio with the Roblox_Studio MCP tools. Don't edit any code while this runs.

1. Call `list_roblox_studios` and pass its `studio_id` on every call. If no Studio is connected, stop and tell me to open the place and turn on the MCP server.
2. Start a playtest with `start_stop_play` and wait about 10 seconds for the character to spawn.
3. Test what I asked for: $ARGUMENTS. Act as a player with `character_navigation`, `user_keyboard_input` and `user_mouse_input`. If I didn't ask for anything specific, test the newest feature in the current phase. For anything involving a game, walk onto a table's platform; with `Config.Debug.SoloTables` on, the game starts with just you. Press F for the top-down view, aim with A/D, and drag the power icon to shoot.
4. Read `get_console_output`, and take a `screen_capture` at the moments that matter, like the top-down view and after the balls stop.
5. Stop the playtest with `start_stop_play`.
6. Report in under 10 lines: each error or warning with its script and line, what the screenshots show, and the fix you'd make.
