# Pool! — model brief

Pool! is a cozy, blocky Roblox bar where players hang out on voice chat and play 8-ball pool. Every model in the game today is a grey placeholder. This brief covers what the final models need so they drop straight into the place with no code changes.

**Style:** blocky Roblox look, cozy and warm. Tables in classic green felt and warm wood: dark green cushions, slim warm brown rails with white diamonds, black pockets.

**Content rule:** no alcohol anywhere: no bottles, taps, beer signs, wine glasses or drink names. The bar serves sodas, milkshakes and coffee.

## How the models connect to the game

- The game finds parts **by exact name**, so the names below must match, including capitals.
- Sizes and pocket positions come from the game's settings, not from the models. A table can look however you like, but its playing surface, cushions and pockets must line up with the numbers below, or balls will bounce off empty air.
- Units are Roblox studs. Every number below is final.

## Table

A Model containing the items below. The rails are slim: the whole table, cushions and wooden rails included, is about **18.2 × 10.2 studs** (about 1.1 studs on every side of the playing surface) and must stay within 20 × 12. Black plates cover the corner pockets, the side pockets are set into the rails, the cushions are angled at each pocket mouth, and white diamonds sit on the rails: 6 on each long rail, every eighth of the length, and 3 on each end. The felt's top sits about **2.5 studs** above the floor, about an avatar's hip height.

| Name | What it is | Must have |
| --- | --- | --- |
| `Felt` | The playing surface | A single flat Part or MeshPart, exactly **16 × 8 studs** on top (its X axis along the length, Z across). Its top face is where the balls sit. Its center is the table's center. Any thickness |
| `Platforms` | A Folder | The platforms below |
| Anything else | Rails, pockets, body, legs, trim | Any names and any number of parts |

**Cushions:** the face the balls bounce off must sit exactly on the felt's edges: 8 studs either side of the center along the length, and 4 studs either side across it. Keep the rail tops no more than **0.8 studs** above the felt, because the cue is drawn just above them.

**Pockets:** 6 of them, measured from the felt's center at its top face (X along the length, Z across):

| Pocket | Center (X, Z) | Mouth |
| --- | --- | --- |
| 4 corners | (±8, ±4) | 1.0 studs, measured diagonally across the opening. The cushions on either side end **0.71 studs** from the corner along each edge |
| 2 sides | (0, ±4) | 1.1 studs. The cushions on either side end **0.55 studs** from the center of the side |

The cushion ends are the pockets' jaws. Inside the pocket, anything that looks like a hole works: a ball disappears once its center is over the opening.

**1v1 and 2v2 tables are the same size.** One table model serves both.

## Platforms

Players stand on a platform to join a table, and the game lights a platform up when a spot opens mid-game.

- Each platform is **a single Part or MeshPart**, named `A1`, `B1`, and on 2v2 tables also `A2` and `B2`, inside the table's `Platforms` folder.
- `A` platforms go on one long side of the table (the felt's −Z side), `B` platforms on the other. On 2v2 tables, A1 and A2 sit side by side along their long side, and so do B1 and B2.
- Current placeholder: 4 × 3 studs, 0.2 thick, about 7 studs from the table's center, just clear of the rails. The game checks whether a player is standing within the platform's footprint, so make its top the area a player stands on.
- The game may change the platform's color or material to light it up, so keep the part you stand on plain enough to tint.

## Cue

- A Model named `Cue` whose PrimaryPart's **X axis runs from the butt to the tip**.
- An Attachment named `Tip` at the very center of the tip's end face. The game places it just behind the cue ball.
- Length about **9.6 studs**, and a tip about **0.24 studs** across.
- No collisions needed; the game anchors the cue and moves it.

## Balls

- 16 spheres named `Ball0` (the cue ball) to `Ball15`, each exactly **0.3 studs** across, centered on its origin.
- 1–7 solids, 8 black, 9–15 stripes. Standard colors: 1 and 9 yellow, 2 and 10 blue, 3 and 11 red, 4 and 12 purple, 5 and 13 orange, 6 and 14 green, 7 and 15 maroon. Numbers on the balls are welcome.
- The game creates, moves and hides them, so they need no collisions.

## The bar

- A Folder named `Tables` in Workspace holding `Table1` to `Table8`. Each is a table model with an attribute **`Mode`** set to `"1v1"` (4 tables) or `"2v2"` (4 tables).
- 30 players per server. Leave room around each table for its platforms and for people to walk past and watch. Voices fade with distance, so spread the tables out enough that each one has its own conversation.
- A counter serving sodas, milkshakes and coffee, places to sit, and warm lamps over each table.
- Don't build signs over the tables, arrows, buttons or screens; the game makes those.

## For every model

- Anchored, with no scripts inside.
- Light enough for phones: reuse meshes and textures, and avoid lots of transparent parts and lights. The game has to hold 30 fps on a mid-range phone.
- Send the source files (.fbx or .obj, plus textures) and an .rbxm of each model. I'll upload the assets to my account.
