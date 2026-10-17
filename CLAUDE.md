# Pool!

An intense, item-based Roblox pool game: 8-ball, 1v1 or 2v2, in a big warm wooden arena, where players earn gadgets by taking turns and sinking balls, gadgets that bend the physics but never the rules, and players talk on voice chat between turns. It's my first Roblox game. You write most of the code; I design, build in Studio, review your changes and playtest. Launch target: Friday, Dec 11, 2026.

The documents imported at the bottom are the source of truth: what the game is (GAME_SPEC), how it looks (STYLE), how the code is built (ARCHITECTURE), and what to build when, plus where we are now (BUILD_PLAN).

## Working with me

- I'm new to Roblox scripting. After each change, explain what it does in a sentence or two of plain English. When I need to do something in Studio, give me the exact clicks.
- PC only for now. I test every step and every phase's "Done when" on PC. Leave the existing touch code in place, but don't test it, extend it or add touch versions of new features until the Mobile phase in BUILD_PLAN.md, and don't ask me to check a phone or the phone emulator before then.
- Work on the current phase in BUILD_PLAN.md, one task at a time. Don't build anything from a later phase or the Later list early, even if it's quick.
- For anything bigger than a small fix, plan first and wait for my OK before writing code.
- Keep changes small. Don't rename, restructure or refactor code the task doesn't need.
- If a request conflicts with GAME_SPEC.md, point it out and ask. When I change a decision, update the spec in the same session.
- Spec items marked *(default)* are your proposals I haven't confirmed. Build them as written unless I say otherwise. Ask before deciding anything players would notice that the spec doesn't cover.
- Don't re-propose anything on the spec's "Decided against" list unless I bring it up.
- Ask before you publish, change game settings, upload assets, insert Creator Store models, add third-party code, change how data is saved, or delete anything from the place.
- Don't commit or push unless I ask. `/wrap-up` proposes a commit at the end of a session.

## Where code lives

Studio's Script Sync mirrors these folders both ways.

| On disk | In Studio | Runs on |
| --- | --- | --- |
| `src/Server` | ServerScriptService/Server | Server |
| `src/Client` | StarterPlayer/StarterPlayerScripts/Client | Each player |
| `src/Shared` | ReplicatedStorage/Shared | Both |
| `tests/`, `docs/` | Not synced | Lune tests, docs |
| `tools/` | Not synced | Scripts Claude runs: Studio scripts through the MCP, like `BuildTable.luau` that rebuilds the greybox table from Config, and Lune scripts, like `BreakStats.luau` that summarizes 20 breaks |

- File names set the script type: `Name.server.luau` = server Script, `Name.local.luau` = LocalScript, `Name.luau` = ModuleScript, a folder = Folder. Don't use `init.luau` files; use plain folders of modules.
- Only scripts and folders sync. Parts, models and lighting live only in the place file, which isn't in git. After you build or change anything in the place, remind me to save it (Cmd+S).
- Never put attributes or tags on scripts: Script Sync skips those scripts. Attributes on parts and models are fine.
- Script Sync's "Sync to…" copies Studio's version onto disk, so never link a Studio folder that's empty while its folder on disk has files. If sync breaks, commit first and ask me.

## Code rules

- `--!strict` at the top of every file. Type function parameters and return values.
- Two entry scripts only: `src/Server/Main.server.luau` and `src/Client/Main.local.luau`. Everything else is a ModuleScript they start.
- The server decides everything that matters: seats, turns, the shot clock, ball physics and rule outcomes. Clients send requests through `src/Shared/Remotes.luau`, and the server validates every argument.
- Every tuning number lives in `src/Shared/Config.luau`. No magic numbers in systems.
- Ball physics and 8-ball rules are pure Luau with no Roblox APIs, covered by Lune tests (see ARCHITECTURE.md).
- Build UI (screens, signs, the Turn arrow) in code, with colors and fonts from `src/Shared/Theme.luau`, so it lives in git.
- Use `task.wait`, `task.spawn` and `task.delay`, never the deprecated `wait`, `spawn` and `delay`.
- Every connection and timer belongs to a table, a game or a player, and is cleaned up when that ends.
- Names: PascalCase for modules and types, camelCase for functions and variables, UPPER_SNAKE_CASE for constants.
- Comments explain why, not what.
- You build every model; there's no modeler. Models that stay in the place (tables, platforms, the arena) come from builder scripts in `tools/`, like `BuildTable.luau`; models the game spawns (balls, the cue, the pocket lid, effects) come from game code. For shapes parts can't do well, like plants, write me prompts for Studio's AI model and texture tools and I'll run them. Keep code independent of models, so any model can be rebuilt or restyled with no code changes: Config is the source of truth for sizes and pocket positions, the physics never reads a model's shape, and scripts find parts by name. `docs/MODELS.md` is the guide for how we build models; when Config's table, ball, pocket or cue numbers change, update it in the same change.

## Tools and testing

- Studio is connected through the `Roblox_Studio` MCP server. Call `list_roblox_studios` first and pass its `studio_id` on every call. Studio must be open with the place loaded; if it isn't connected, stop and tell me.
- Edit code as files on disk, never with Studio's script tools, so formatting and git see every change.
- Use the MCP tools to inspect the place, build greybox parts, playtest, read the console and take screenshots.
- A hook runs StyLua on every `.luau` file you edit. Before calling code done, run `selene src` and fix what it reports.
- `lune run tests/run` runs every `tests/**/*.spec.luau` (add a word to filter, like `lune run tests/run physics`). Run it after any change to physics, rules or Config. Every bug fixed there gets a test.
- `/playtest` checks gameplay in Studio. The MCP tools control one player, so solo playtests rely on `Config.Debug.SoloTables`. For real multiplayer checks, ask me to run Test → Clients and Servers.
- The MCP's mouse input uses GUI points below Roblox's top bar, like `InputObject.Position`, not screenshot pixels. A button held across separate `user_mouse_input` calls can get pressed again, so do a whole drag in one call and check it with a per-frame log from `execute_luau`.
- A playtest started before Script Sync picks up an edit runs the old code. After changing code, restart the playtest and check the change is live.
- Scripts can't set `Lighting.Technology`; ask me to set it in Studio's Properties.
- Nothing is done until lint, tests and a playtest pass, or I've tested it myself.

## Sessions

- Start with `/next-task`, or with whatever I ask for.
- When a task is done, tick its box in BUILD_PLAN.md and update the Status section there.
- End with `/wrap-up`. It updates the status, notes known issues and proposes a commit.

## Project documents (loaded every session)

- Game spec: @docs/GAME_SPEC.md
- Style guide: @docs/STYLE.md
- Architecture: @docs/ARCHITECTURE.md
- Build plan and status: @docs/BUILD_PLAN.md
