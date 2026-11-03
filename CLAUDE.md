# Pool!

Item-based 8-ball pool on Roblox, 1v1 and 2v2. Controls and physics match the feel of 8 Ball Duels; the look is inspired by Illegal Soccer (warm lodge, matte hand-painted). Solo project by Daniel, built with Claude Code. PC only for now. Launch target: Friday, Dec 18, 2026.

## Read first (only what the task needs)
| Task | Read |
|---|---|
| Rules, items, game flow | docs/GAME_SPEC.md (always loaded, below) |
| What to build next | docs/BUILD_PLAN.md (always loaded, below) |
| Code structure | docs/ARCHITECTURE.md |
| Anything visual | docs/STYLE.md and the images in references/ |
| Building models | docs/MODELS.md |
| Who the game is for and why | docs/VISION.md |

## Always
- The server decides everything: turns, fouls, ball results. Clients send inputs only (aim, power, item), through src/Shared/Remotes.luau.
- Check every request on the server: right player, their turn, values in range, one shot per turn.
- Keep the simulation and rules (src/Shared/Physics/, src/Shared/Rules/, src/Shared/Pull.luau) pure Luau with no Roblox services, so Lune can test them.
- Follow BUILD_PLAN order. Current phase: see BUILD_PLAN Status. No streaks, King of the Table, crates or purchases until the plan says so.
- PC only (mouse and keyboard): leave the existing touch code in place, but don't test or extend it until the Mobile phase. R6 avatars only.
- $0 budget: free tools and assets only.
- No guns or weapon items. No alcohol.
- Other games are references for feel only. Never copy their models, textures, images, effects or code.
- Never publish or change game permissions. The game stays Private until Daniel launches it.
- Ask before you change game settings, upload assets, insert Creator Store models, add third-party code, change how data is saved, or delete anything from the place.
- If a request conflicts with GAME_SPEC, point it out and ask. Spec items marked *(default)* are Claude's proposals Daniel hasn't confirmed: build them as written unless Daniel says otherwise.

## Never
- Insert Toolbox models that contain scripts without checking them first.
- Use code from leak, exploit or cheat sites.
- Refactor code the task didn't ask about.

## Where code lives
Script Sync mirrors src/Server → ServerScriptService/Server, src/Client → StarterPlayer/StarterPlayerScripts/Client and src/Shared → ReplicatedStorage/Shared, both ways. tests/, docs/ and tools/ aren't synced; tools/ holds scripts Claude runs, in Studio through the MCP (BuildTable.luau) or in Lune (BreakStats.luau).
- File names set the script type: Name.server.luau = Script, Name.local.luau = LocalScript, Name.luau = ModuleScript, a folder = Folder. No init.luau files.
- Two entry scripts only: src/Server/Main.server.luau and src/Client/Main.local.luau. Everything else is a ModuleScript they start.
- Every tuning number lives in src/Shared/Config.luau. UI is built in code. Every color, font, UI size and effect timing lives in src/Shared/Theme.luau, never hard-coded. Gameplay numbers stay in Config: table and ball sizes, the shot's feel, and every timer the server runs.
- `--!strict` and typed parameters in every file; `task.wait`/`task.spawn`/`task.delay`, never `wait`/`spawn`/`delay`; every connection and timer is cleaned up when its game or player ends.
- Only scripts and folders sync. Parts, models and lighting live only in the place file, which isn't in git, so after changing the place remind Daniel to save it (Cmd+S).
- Never put attributes or tags on scripts: Script Sync skips those scripts.
- Never "Sync to…" from a Studio folder that's empty while its folder on disk has files. If sync breaks, commit first and ask.

## How to work
1. For changes touching 3 or more files, plan first and wait for Daniel's OK.
2. Build one step at a time, and test after each step.
3. Edit code in the repo, never with Studio's script tools; Script Sync carries it into Studio.
4. When a choice is Daniel's (design, look, feel), recommend one option with a one-line reason. Don't decide silently. Don't re-propose anything on GAME_SPEC's "Decided against" list.
5. Explain in plain words. Daniel is learning Luau. For Studio steps, give the exact clicks.
6. When a decision changes, update the doc that owns it in the same task.
7. Ideas nobody asked for go at the end of your report, not into the code.
8. Start a session with /next-task and end it with /wrap-up. When a task is done, tick it in BUILD_PLAN and update the Status there.
9. Visual tasks go to the style-builder subagent. After it finishes, send its after screenshot to the art director.

## Testing
- Use the Studio MCP tools (the Roblox_Studio server) to playtest, screenshot and run Luau: call list_roblox_studios first and pass its studio_id on every call. /playtest runs a standard playtest. Check your own work before reporting.
- Tests: `lune run tests/run` (add a word to filter, like `lune run tests/run physics`). Lint: `selene src`. Both must pass before you say you're done. A hook runs StyLua on every .luau file you edit, and another runs lint and tests at the end of any turn that changed Luau code.
- The MCP controls one player, so solo playtests rely on Config.Debug.SoloTables. Its mouse input uses GUI points below Roblox's top bar; do a whole drag in one user_mouse_input call.
- A playtest started before Script Sync picks up an edit runs the old code: restart it and check the change is live.
- Multiplayer changes need a 2-player playtest. If you can't run it, give Daniel the steps (Test ▾ → Server & Clients → 2 players → Play, then End Session) and say exactly what to check.
- Visual changes get an art-director review. Put its top 3 fixes in your report.
- Table rebuilds: run tools/BuildTable.luau, then remind Daniel to save the place.
- If Studio isn't open or is still in Play mode, stop, tell Daniel the exact step, and wait for "Go".
- Scripts can't set Lighting.Technology; ask Daniel to set it in Properties.

## Commits
- Commit only after tests pass and Daniel confirms the playtest; that OK counts as the go-ahead to commit. One commit per task.

## End every task with this report (under 15 lines)
- Changed: what, and which files
- Tested: what you ran and the result
- Daniel needs to: any step in Studio, or "nothing"
- Next: the next step from BUILD_PLAN

## Before launch
- Turn off Config.Debug.PhysicsTestLive in src/Shared/Config.luau (owner-only test tool).

## Always loaded
- Game spec: @docs/GAME_SPEC.md
- Build plan and status: @docs/BUILD_PLAN.md
