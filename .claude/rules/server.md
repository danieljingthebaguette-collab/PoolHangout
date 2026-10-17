---
paths:
  - "src/Server/**"
  - "src/Shared/Remotes.luau"
---

# Server code

Never trust the client. For every remote the server receives:

1. **Check the sender may do this:** they're seated at that table, it's their turn, and the table is waiting for a shot.
2. **Check every argument:** `typeof` each one. Numbers must be finite (`x == x` and not `math.huge` or `-math.huge`) and inside their range: power 0–1, a direction of nonzero length, a pocket id that exists. Drop bad requests quietly; never throw on them.
3. **Rate-limit per player:** about 1 shot request per 0.5 s, 1 `UseItem` per 0.5 s, 10 `AimUpdate`s per second, 1 phrase per second.
4. **Take intent only.** Never accept positions, pocketed balls, scores or outcomes from a client. We take two positions: a ball-in-hand placement, only after checking it's inside the allowed area, not overlapping a ball and not too close to an item box; and an Oil Slick spot, only after checking it's on the felt.

Also:

- Each table's state lives on the server in its `Match`. Anything shown on the table model (attributes, sign text) is display only.
- Timers check that the game and step they were made for are still current before they act.
- Clean up on `PlayerRemoving` and when a game ends: seats, connections, the Turn arrow, timers.
- DataStore calls happen only in `StatsService`, wrapped in `pcall`, and never hold up gameplay.
- When a remote's arguments change, update `Remotes.luau`, both sides, and the remotes table in ARCHITECTURE.md together.
