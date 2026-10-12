# Pool Hangout: Claude Code kit

Unzip this into your project folder (the one with `src/`), replacing the starter kit's files. From then on, every new Claude Code chat in that folder starts out knowing the whole game: what it is, how the code is built, what to build next, and where you left off.

## Setup (about 5 minutes)

1. Unzip into the project folder and replace files when asked. In Finder, press Cmd+Shift+. to see the hidden `.claude` folder.
2. Install Lune, which runs the physics and rules tests: `rokit add lune-org/lune`
3. Optional, for autocomplete in test files: `lune setup`
4. Check it: `lune run tests/run` should print "No tests yet."
5. Start `claude` in the folder and run `/context`. CLAUDE.md and the three docs should be listed under memory files.

## Every session

1. Commit your work first, so anything can be undone.
2. `/next-task`: Claude picks the next task, shows you a plan, and builds it after you say OK.
3. Try it in Studio yourself.
4. `/wrap-up`: Claude updates the status and proposes a commit.
5. Save the place in Studio.

Use a fresh chat (`/clear`) for each new task. The kit carries the context between chats.

## What's inside

| File | What it does |
| --- | --- |
| `CLAUDE.md` | Loaded into every chat: how Claude works with you, where code lives, code rules and testing. It pulls in the three docs below |
| `docs/GAME_SPEC.md` | Every game decision so far, the Later list, and what's ruled out |
| `docs/ARCHITECTURE.md` | How the code is built: the server as referee, pure physics, the shot pipeline, what the place must contain |
| `docs/BUILD_PLAN.md` | The five phases as checkboxes, plus a Status section Claude keeps current. This is now the working copy of your Build Plan doc |
| `.claude/rules/` | Extra rules that load only when Claude works on server, client, or physics and rules files |
| `.claude/skills/` | `/next-task`, `/playtest` and `/wrap-up` |
| `.claude/settings.json` | Pre-approves safe tools (Studio's read-only and playtest tools, lint, tests, git status) and auto-formats code |
| `tests/run.luau` | The test runner |
| `stylua.toml`, `selene.toml`, `.gitignore` | Same as the starter kit |

## Keeping it accurate

- Change your mind about the game in chat, and Claude updates GAME_SPEC.md.
- Spec items marked *(default)* are Claude's suggestions you haven't confirmed yet. Change any of them whenever you like.
- Everything here is plain text. Edit it yourself anytime.
