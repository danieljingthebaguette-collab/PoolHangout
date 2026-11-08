# Style guide

How Pool! looks: the full look rulebook. Every task that adds or changes something players see follows this file. Written 2026-10-16, when the art direction moved from a chill bar to an intense, item-based look in the spirit of the Roblox game Illegal Soccer; made the full rulebook 2026-11-03. Items marked **(approve)** are Claude's proposals that Daniel hasn't approved yet.

- **A guide, not a source.** Screenshots in `references/` show the style we're after: lodge rooms, real pool halls, and the feel of Illegal Soccer and 8 Ball Duels. Never copy their models, textures, images, UI art or effects. Everything in Pool! is made by us: in code, in Studio, or with Studio's AI tools from our own prompts, which never name another game.
- **Spec vs style.** Where GAME_SPEC.md and this file disagree about how things look, this file wins. For how the game plays, GAME_SPEC.md wins.
- **Placeholders.** The table and floor in the place are early versions in this style until Phase 4's final-look pass. `docs/MODELS.md` covers how models are built.

## In one line

Warm, golden and readable at a glance: chunky shapes and flat painted colors in a soft, glowing world, with bold UI that pops on top.

## Palette

Eight colors carry the whole game, plus icy blue for Freeze alone. Everything else is a lighter or darker tone of one of them, except the balls' own colors in `Theme.BallColors`.

| Color | Hex | Used for |
| --- | --- | --- |
| Cream | `#F6EFE0` | Cards and panels, text on dark boxes, the rails' diamonds |
| Ink | `#241C16` | Text on cards and buttons, card brackets, outlines |
| Near-black | `#201A16` | Dark boxes: key boxes, the % readout, the tray, the timer |
| Sunny gold | `#FFC42E` | The main accent: buttons, the power meter's fill, the turn glow, the called pocket, the ring round each of your balls as your turn starts |
| Coral | `#FF8A76` | Buttons that leave or undo, like Leave and Yes on "Leave and lose this game?", and warnings: the shot clock's last 10 seconds, and the label beside your slots saying why an ability can't be used |
| Felt green | `#327A4C` | The playing surface, the strongest color in the room |
| Cushion green | `#225834` | Cushions |
| Painted wood | `#7A4628` | The table's rails and wood; its darker tone is the body and legs |
| Icy blue | `#96D7FF` | Only for Freeze: its icon, and the ring and tint on a frozen ball |

## Fonts

- **RobotoCondensed Bold** (`Theme.Font`) for all UI text: names, numbers, hints, banners.
- **Luckiest Guy** (`Theme.DisplayFont`) only for big moments, never for small text or long lines. Approved for an item's name shown big; its other big moments, like the winner and "Starting...", wait for the GUI pass.
- Two fonts at most. Both are in Roblox's built-in set, so nothing is uploaded.

## Lighting

Warm golden light, soft shadows, warm color grading, a light haze and gentle bloom. The place's Lighting service holds these values; change them together with this table.

| Setting | Value | Why |
| --- | --- | --- |
| Technology | Future | Soft shadows, and lantern light later. Set it by hand in Properties; scripts can't |
| ClockTime, GeographicLatitude | 16, 30 | A late-afternoon sun: low enough to be golden, high enough that shadows stay short |
| Brightness, ExposureCompensation | 2.4, 0.1 | |
| Ambient, OutdoorAmbient | (96, 74, 58), (150, 120, 92) | Shade stays warm, never grey |
| ColorShift_Top, ColorShift_Bottom | (255, 222, 178), (70, 48, 34) | A golden tint on lit faces |
| EnvironmentDiffuseScale, EnvironmentSpecularScale | 0.5, 0 | No reflections, so everything stays matte |
| ShadowSoftness | 0.6 | Soft shadows |
| Atmosphere | Density 0.25, Offset 0.1, Color (255, 220, 176), Decay (214, 150, 104), Glare 0.1, Haze 1 | A light warm haze. Keep it light so the top-down view stays crisp |
| Bloom | Intensity 0.4, Size 28, Threshold 1.6 | Gentle: only bright accents and effects glow |
| WarmGrade (a ColorCorrectionEffect) | Brightness 0.02, Contrast 0.06, Saturation 0.03, TintColor (255, 240, 220) | The warm grade over everything |
| DepthOfField | Off | It would blur the top-down view |

## Materials

- **Matte and hand-painted looking, no shine.** Use SmoothPlastic with flat, warm colors, and get detail from shape and color, not from textured materials. Don't use Glass, Foil, Metal, DiamondPlate or Ice. Neon is only for small accents inside effects.
- **Painted wood grain.** Show wood as strips or planks in two or three close tones with dark seams between them, not with the Wood material's realistic grain. The test floor is built this way.
- **Low-poly rock and crystal.** Faceted shapes made of wedges and blocks at angles, flat colors, a lighter tone on the faces that point up. Crystals use one saturated hue with a soft glow.
- **Content.** GAME_SPEC.md's rule still applies: no alcohol anywhere, so no bottles, taps or drink signs among the lodge props.

## Setting

One cozy lodge room: timber beams, plank floors, plants, and lanterns that throw warm pools of light over each table. Mostly warm reds, oranges and browns, some green from the plants, and the pool felt as the strongest color in the middle of each table.

## Balls

Stylized balls with icons on them (details coming). Until then, the placeholder balls: a solid color or a white ball with a colored band, with a dot to show them roll.

## Characters

Normal Roblox avatars on the R6 rig only (set in the game's avatar settings), otherwise unchanged. Roblox's own name tags are hidden at the tables, since they'd be bare text over the felt; the "Turn" card names the shooter. Each player has a soft ring at their feet: a thin cream circle with a faint glow, a little wider than the avatar. The ring isn't built yet.

## UI

Every value lives in `src/Shared/Theme.luau`, and UI is built in code. `src/Client/Card.luau` draws the card look.

| Piece | Look |
| --- | --- |
| Cards | Cream (246, 239, 224) with ink (36, 28, 22) text, thin dark corner brackets set just inside each corner, and a faint dot texture. Corners nearly square (4 px) |
| Font | RobotoCondensed Bold, `Theme.Font`, set as `FontFace`: big and bold for names and numbers. Big moments use the display font (see Fonts) |
| Dark boxes | Near-black (32, 26, 22) with cream text: key boxes, the % readout, the power meter's track. Bigger ones, like the sunk-ball tray and later the timer, get cream corner brackets |
| Timer | A dark box at the top center, between the top bar's two cards |
| Control hints | Down the right side, stacked from the bottom: a slightly see-through cream label box, then a dark key box with the key or a short word, like "Lock aim" `Space` |
| Item slots | Players see items called "Abilities" everywhere on screen; code and docs keep "items". Every player's 2 slots are the small dark squares under their avatar on the top bar card, with the item bar under them. On your own: a gold outline round the slot you're picking a target for, a dark veil over both while you can't use one, and, when one is refused, a small solid coral label with ink text saying why, right beside your strip on the card's outer side (past your teammate's strip in 2v2, so it covers no one's slots), until it's cleared |
| Abilities button and panel | While you're not at a table (exactly when the Leave button doesn't show), a gold "Abilities" button at the bottom center. It opens a cream card in the middle of the screen: "Abilities" at the top with a near-black Close button, two plain lines for 10-year-olds on earning and using them, then every ability in order, each its icon on a dark box beside its name and, in a softer ink, its one-line description. Close, Esc and joining a table close it |
| Buttons | A bright accent with ink text: sunny gold (255, 196, 46) for the main action, coral for leaving or undoing. A second choice beside a gold one, like Back to lobby beside Rematch, is a near-black button with cream text, so the gold one leads. Only the palette's colors; never neon |
| Text over the world | Always on a card or a dark box, never bare, so it reads on any background |

**Screen layout:**
- **Top center:** each side's card, yours on the left, with the timer between them. The side whose turn it is glows gold. Under the cards, the banner, and under the banner an item's name shown big, so the two never overlap.
- **Top right:** the coral Leave button while you're at a table, in both views. The spin control goes beside it later.
- **Left:** the power meter, with the phones' Lock button beside it.
- **Right:** the sunk-ball tray, with the control hints under it.
- **Bottom left:** the settings gear and, in test mode, the Test button.
- **Bottom center:** the Abilities button while you're not at a table. Nothing there at a table.

Touch targets stay at least 44 px, and everything fits a phone held sideways. Both are checked in the Mobile phase; until then the UI is built and tested on PC.

**Built so far:** cards, the font, dark boxes, control hints, accent buttons, the top bar's side cards, the banner, the timer and the gold "Turn" card over the shooter's head, with their name under "Turn". Placeholder item looks until the GUI pass: item icons drawn in code (an orange flame, a gold burst, an icy snowflake, a dark oil drop over a puddle edged in cream, a black pocket with a gold lid), shown on each card's small slots (see Item slots above), the Abilities button and panel, and the item's name shown big at the top center under the banner: the name in Luckiest Guy with its one-line description under it in `Theme.Font`, on a dark box with its icon, popping in and fading out. Placeholder item effects on the table until Phase 4: an icy blue ring and tint on a frozen ball, a dark glossy oil patch edged in cream, and a gold lid across a blocked pocket. **Not built yet:** the ring at players' feet, and the final item effects (flame trail, blast burst, screen shake).

## Effects

Stylized and chunky, never realistic:
- **Auras:** flame and energy auras made of a few big, soft particles in flat colors with a bright core.
- **Trails:** dashed trails behind fast-moving things.
- **Sparks:** small, short bursts of chunky sparks on impact.

Keep them short so the game stays readable, and keep particle counts low for phones. Custom particle and trail textures are assets, so ask before uploading any.

**Timings:**

| What | Rule |
| --- | --- |
| Feedback | Every input and hit answers within 100 ms: a sound, a click, a pressed button |
| Hit stop | A 0.05–0.1 s hold on big moments only: the break, a winning 8, a blast. Default 0.06 s **(approve)**. It holds only the picture, never the physics, so every screen still shows the same shot |
| Screen shake | 2–10 px, about 0.2 s, fading out: 2–4 px for hard hits and rail bounces, up to 10 px for the break and the blast **(approve)** |
| Sparks and small pops | 0.2–0.3 s |
| Item name | About 3 s on screen, long enough to read its line, popping in and fading out (`Theme.Ui.ItemNameSeconds`) |
| Banners | 3 s for fouls and notices, 5 s for the result (`Config.Timers`) |

**Hit effects (built):** chunky gold and cream spark blocks with a thin ink edge on hard ball and rail hits (bigger and farther on the break), and a cream ring that pops out of a pocket, growing and fading in 0.25 s. Values in `Theme.Effects`.

**Big effects only for big moments:** the break, a winning 8, an item, a foul. A normal pot gets a small pop and its sound, nothing more.

## Never

Things that make a game look generic or AI-made:
- The default Roblox look: a grey baseplate, studs, the default sky, default fonts like Legacy, Arial or SourceSans, or unstyled Roblox buttons.
- Glossy or gradient buttons, bevels, drop shadows on everything, or see-through "glass" panels.
- Neon glow and bloom on everything, lens flares, or sparkles and stars as decoration.
- Purple-and-blue "gamer" gradients, or random rainbow colors from outside the palette.
- Emoji or stock icons in the UI. Icons are drawn in code, in this style.
- Text straight over the world without a card or dark box, more than two fonts, or mixed corner roundness.
- Photoreal textures, shiny materials or realistic wood grain next to flat painted color.
- Free models dropped in as they are, or props in perfect grids, in mirror symmetry, or all the same size.
- AI-made meshes or textures left as generated: mushy detail, melted edges, or garbled text or logos. Clean them up or make them again.
- Effects that hide the balls or the aim line, or more than a few big particles in one effect.

## Performance

Hold 30+ fps on a mid-range phone:
- Future lighting scales itself down on weaker devices.
- Merge static decoration where you can.
- Keep only a few lights casting shadows.
- Keep particle counts low.
