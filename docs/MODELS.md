# Models guide

How we build every model in Pool!. There's no modeler. Claude builds each model from parts with a script. For shapes parts can't do well, Claude writes prompts for Studio's AI model and texture tools, and I run them. Every model follows `docs/STYLE.md`.

## The rules

- **Config is the source of truth.** Anything the game measures (the felt, cushions, pockets, balls, cue and pocket lid) gets its size from `Config.luau`, never from a model, and the physics never reads a model's shape. When Config's table, ball, pocket or cue numbers change, rebuild with the builder script and update this file in the same change.
- **Found by name.** The game finds parts by exact name, so the names below must match, including capitals.
- **Place models come from builder scripts.** Tables, with their seat markers, and the arena are built by scripts in `tools/`, like `BuildTable.luau`. Each one reads Config, rebuilds its model from scratch so running it twice gives the same result, keeps the parts the game owns (like `Felt` and the runtime `Balls`), and supports Undo. Claude runs them through the MCP's `execute_luau` in edit mode, then I save the place (Cmd+S). The place file isn't in git but the scripts are, so the place can always be rebuilt.
- **Spawned models come from game code.** Balls, the cue, the pocket lid and item effects are built at runtime by the game's own modules, like the balls and the cue today, so they live in git and the place holds no copy.
- **Organic shapes come from Studio's AI tools.** For plants and other shapes parts can't do well, Claude writes a prompt (see AI prompts below), I run it, and the result goes in `ServerStorage/Props` under the prompt's name. The arena builder copies props from there into place. They live only in the place file, so their prompts are kept here, so we can generate one again if it's lost. Never use these tools for anything the game measures.

## The look

`docs/STYLE.md`, applied to parts:

- SmoothPlastic with flat, warm colors everywhere. Detail comes from shape and color, not textured materials. No Glass, Foil, Metal, DiamondPlate or Ice. Neon only for small accents inside effects.
- Chunky shapes that read from straight above, since players aim from a top-down view.
- Wood as strips or planks in two or three close tones with dark seams between them, like the test floor and the table's rails.
- Rock and crystal low-poly: wedges and blocks at angles, flat colors, and a lighter tone on the faces that point up. Crystals in one saturated hue with a soft glow.
- Reuse the colors in `BuildTable.luau` and `Theme.luau`, so everything matches.
- **Content:** no alcohol: no bottles, taps, beer signs, wine glasses or drink names; the counter serves sodas, milkshakes and coffee. No guns or weapons. Illegal Soccer is a mood reference only: never copy its models, textures or art, and never name it or any other game in an AI prompt.

## Table

Built by `src/Server/TableBuilder.luau` from table params. `tools/BuildTable.luau` runs it from `Config.Table` in edit mode, and the physics test mode runs it live when a pocket slider moves, without changing the saved place. Today it rebuilds Table1; Phase 2 adds Table2 as a 2v2 table, and Phase 4 builds all the tables.

The rails are slim: the whole table, cushions and wooden rails included, is about **18.2 × 10.2 studs** (about 1.1 studs on every side of the playing surface) and must stay within 20 × 12. Black plates cover the corner pockets, the side pockets are set into the rails, the cushions are angled at each pocket mouth, and white diamonds sit on the rails: 6 on each long rail, every eighth of the length, and 3 on each end. The felt's top sits about **2.5 studs** above the floor, about an avatar's hip height.

| Name | What it is | Must have |
| --- | --- | --- |
| `Felt` | The playing surface | A single flat Part, exactly **16 × 8 studs** on top (its X axis along the length, Z across). Its top face is where the balls sit. Its center is the table's center. Any thickness |
| `Seats` | A Folder | The seat markers below. The builder makes it |
| `Balls` | A Folder | Made by the game at runtime; the builder keeps it |
| Anything else | Rails, pockets, body, legs, trim | Any names and any number of parts |

**Cushions:** the face the balls bounce off sits exactly on the felt's edges: 8 studs either side of the center along the length, and 4 studs either side across it. Rail tops stay no more than **0.8 studs** above the felt, because the cue is drawn just above them.

**Pockets:** 6 of them, measured from the felt's center at its top face (X along the length, Z across):

| Pocket | Center (X, Z) | Mouth |
| --- | --- | --- |
| 4 corners | (±8, ±4) | 0.8 studs, measured diagonally across the opening. The cushions on either side end **0.57 studs** from the corner along each edge |
| 2 sides | (0, ±4) | 0.75 studs. The cushions on either side end **0.375 studs** from the center of the side |

The cushion ends are the pockets' jaws. Inside the pocket, anything that looks like a hole works: a ball disappears once its center is over the opening.

**1v1 and 2v2 tables are the same size.** One builder serves both.

## Seats

Players join a table with its "Join table" prompt, which the game makes. When the game starts, each player is moved to their seat's marker, facing the table.

- Each marker is **a single invisible Part**, named `A1`, `B1`, and on 2v2 tables also `A2` and `B2`, inside the table's `Seats` folder. They don't collide, so nobody trips on them.
- `A` seats go on one long side of the table (the felt's −Z side), `B` seats on the other. On 2v2 tables, A1 and A2 sit side by side along their long side, and so do B1 and B2.
- 4 × 3 studs, 0.2 thick, on the floor 7.1 studs from the table's center, just clear of the rails: where the platforms they replaced were. A player is placed standing on the marker's top.

## Cue

Built in code by `src/Client/ShotController.luau`, on the shooter's screen only: a cylinder Part named `Cue`, `Config.Aim.CueLength` of the table length long (**9.6 studs**) and `CueThickness` of a ball's width thick (**0.24 studs**), drawn `CueHeight` ball radii (**0.96 studs**) above the felt.

## Balls

Built at runtime by the server (today in `src/Server/PhysicsTest.luau`): 16 spheres named `Ball0` (the cue ball) to `Ball15`, `2 × Config.Table.BallRadius` across (**0.48 studs**), in the table's `Balls` folder. They're anchored and don't collide; the game moves them.

- 1–7 solids, 8 black, 9–15 stripes. Standard colors, flat and matte: 1 and 9 yellow, 2 and 10 blue, 3 and 11 red, 4 and 12 purple, 5 and 13 orange, 6 and 14 green, 7 and 15 maroon.
- Today's welded-on marks are placeholders, so you can see a ball roll.

## Pocket lid

Built in code with the item effects while Pocket Block covers a pocket. It spans the pocket's mouth from jaw to jaw, where the Pockets table above puts the cushion ends, because the physics bounces balls off that line. Its top stays below the rail tops, so the cue still clears it. Plain and chunky, in a color that reads as "closed" against the black pocket.

## The arena

- A Folder named `Tables` in Workspace holding `Table1` to `Table6`. Each is a table model with an attribute **`Mode`** set to `"1v1"` (3 tables) or `"2v2"` (3 tables).
- `tools/BuildArena.luau` builds everything else into a Workspace folder named `Arena`. In Phase 4 it's first a blockout in plain parts: the room, the floor, the table spots, the lobby spawn and the counter. Then it gets the full look of one cozy lodge room: timber beams, a plank floor, lanterns that throw warm pools of light over each table, places to sit, the counter, and the plants and rocks.
- Mostly warm reds, oranges and browns, with some green from the plants. The felt stays the strongest color in the room.
- One lodge room, 24 players per server. Leave room around each table for its seats and for people to walk past and watch. Voices fade with distance, so spread the tables out enough that each one has its own conversation.
- The builders don't make signs over the tables, arrows, buttons, screens or item effects; the game makes those.

## AI prompts

For shapes parts can't do well: plants, leaves, and rounded or organic props. Claude writes each prompt as a block I can paste:

- **Name:** what it's called in `ServerStorage/Props`, like `FernPot`.
- **Prompt:** what it is, then the look: low-poly and chunky, stylized, not realistic, with flat, matte, hand-painted colors, no shine and the warm palette.
- **Size:** in studs, for the tool's bounding box.
- **Budget:** a triangle limit if the tool asks for one, about 2,000 for a small prop, so phones hold 30 fps.

For the texture tool, the same look words: "flat, matte, hand-painted colors, no shine, no realistic texture".

Example:

> **Name:** `FernPot` · **Size:** 3 × 4 × 3 studs · **Budget:** 2,000 triangles
>
> A potted fern for a warm wooden lodge. Low-poly and chunky, stylized, not realistic. Flat, matte, hand-painted colors with no shine: leaves in two or three close greens, a terracotta pot. One piece.

Before a prop is used, check that it's the right size, matte, anchored and within its triangle budget. The arena's prompt list gets added here in Phase 4.

## For every model

- Anchored, with no scripts inside. Builder scripts live in `tools/`.
- Light enough for phones: keep part counts low and merge static decoration where you can, avoid lots of transparent parts, and keep lights few, with only a few casting shadows. The game has to hold 30 fps on a mid-range phone.
- After a builder runs or a prop goes in, Claude reminds me to save the place (Cmd+S).
