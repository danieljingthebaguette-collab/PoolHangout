---
paths:
  - "src/Shared/Physics/**"
  - "src/Shared/Rules/**"
  - "src/Shared/Config.luau"
  - "tests/**"
---

# Physics, rules and tests

- Everything in `src/Shared/Physics/`, `src/Shared/Rules/` and `Config.luau` is pure Luau. Don't use any Roblox API or global there: `game`, `workspace`, `script`, `Instance`, `task`, `Vector2`, `Vector3`, `CFrame`, `Random`, `tick`, `os.clock`. Plain tables and numbers in, plain tables out.
- Require other pure modules only by relative string path, like `require("./Geometry")` or `require("../Config")`. That form works in both Roblox and Lune.
- Keep physics deterministic: fixed time step, balls processed in id order, no `math.random`, no clock reads, and only arithmetic, `sqrt`, `abs`, `min`, `max`, `floor`/`ceil` and `clamp` in the hot loop (no `sin`, `cos`, `atan2` or `exp`, which can round differently on different machines). `Simulate.luau` runs `--!native` on servers and Android (twice as fast, verified bit-identical on 2026-11-12, and again with item shots on 2026-11-17); after changing it, rerun `tools/NativeCheck.luau` in Lune and the same body on a Studio server, and the two fingerprints must match. Native nowhere else in the physics without measuring first.
- Randomness comes in as arguments. The server picks the rack order and the breaker and passes them in.
- Rules return what happened (fouls, next shooter, groups, winner, stat changes) as data; they never reach into the game.
- Every 8-ball rule in GAME_SPEC.md has at least one test. Every bug fixed here gets a test that fails without the fix.
- Tests live in `tests/`, named `*.spec.luau`, in the format shown at the top of `tests/run.luau`. Tests may use Lune's libraries and `os.clock` for timing. Run `lune run tests/run` and include its summary line in your reply.
- Change a Config value only when the task is tuning, and tell me the old and new value.
