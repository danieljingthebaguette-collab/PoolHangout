# Style guide

How Pool! looks: the full look rulebook. Every task that adds or changes something players see follows this file. Written 2026-10-16, when the art direction moved from a chill bar to an intense, item-based look in the spirit of the Roblox game Illegal Soccer; made the full rulebook 2026-11-03. On 2026-11-12 Daniel decided the UI should match Illegal Soccer's tone, texture, shape and interactions almost one for one first, and more pool-like later: the measured spec is in `docs/audits/ILLEGAL_SOCCER.md`, its values are in `Theme.Kit`, and the step 7 style pass rebuilds every screen on them. Until a screen is rebuilt it keeps today's look, described in the UI table below. Items marked **(approve)** are Claude's proposals that Daniel hasn't approved yet.

- **A guide, not a source.** Screenshots in `references/` show the style we're after: lodge rooms, real pool halls, and the feel of Illegal Soccer and 8 Ball Duels. Never copy their models, textures, images, UI art or effects. Everything in Pool! is made by us: in code, in Studio, or with Studio's AI tools from our own prompts, which never name another game.
- **Spec vs style.** Where GAME_SPEC.md and this file disagree about how things look, this file wins. For how the game plays, GAME_SPEC.md wins.
- **Placeholders.** The table and floor in the place are early versions in this style until Phase 4's final-look pass. `docs/MODELS.md` covers how models are built.

## In one line

Warm, golden and readable at a glance: chunky shapes and flat painted colors in a soft, glowing world, with bold UI that pops on top.

## Palette

The UI's colors were sampled from Illegal Soccer's screens (`Theme.Kit.Colors`); the table and world colors are ours. Everything else is a lighter or darker tone of one of these, except the balls' own colors in `Theme.BallColors`. The step 7 style pass moves each screen from today's UI colors (`Theme.Colors`: cream `#F6EFE0`, ink `#241C16`, gold buttons, coral warnings) to these.

| Color | Hex | Used for |
| --- | --- | --- |
| Cream | `#FEFAEA` | Cards, labels, panels' bodies, tooltips; cream-white `#FFFEED` for key tabs and the close button |
| Ink | `#15130F` | Text on cream, and its lines |
| Dark box | `#171513` | Key boxes, the timer, panels' header bars, dark labels |
| Warm grey | `#807B6F` | Second lines: what a setting does, an award's reason. Section bands inside panels are `#EBE7DB` |
| Tan | `#C2927B` | Cards' corner brackets and the timer's digits |
| Mint | `#38FFA5` | The main action (Play, Rematch), toggles that are on, sliders' fill, full bars, the tag on a big moment. A thin `#D4EED5` border round mint pieces |
| Side red | `#ED105D` | Side A (a square by each name, the ring at their feet, their name tags underlined), warnings (the shot clock's last seconds, a refused target, Leave) and badges |
| Side blue | `#3384FA` | Side B, the same way |
| Gold | `#F8D734` | Only the turn (the shooter's card, the "Turn" card) and the called pocket |
| Pastels | blue `#DBDEDB`→`#BDCDE0`, beige `#E7DDD1`→`#E1D0C1`, lilac `#E5D1DA`→`#D6AFDE` | Second-rank buttons, as soft top-to-bottom gradients with a cream border and the dot texture |
| Rainbow | `#F35CE8`→`#F6B379`→`#99FF7A`→`#4FB8FF` | Only a full ability bar, scrolling |
| Felt green | `#327A4C` | The playing surface, the strongest color in the room |
| Cushion green | `#225834` | Cushions |
| Painted wood | `#7A4628` | The table's rails and wood; its darker tone is the body and legs |
| Icy blue | `#96D7FF` | Only for Freeze: its icon, and the ring and tint on a frozen ball |

## Fonts

- **RobotoCondensed Bold** (`Theme.Font`) for all UI text: names, numbers, labels, banners, and big moments too. Bold (700) is the heaviest weight Roblox ships for it (it has Light, Regular and Bold), so big text is simply Bold, big: the score's numerals are 5.6% of the screen's height.
- **RobotoCondensed Regular** for second lines in warm grey: what a setting does, an award's reason, "3 spots available".
- **Luckiest Guy** (`Theme.DisplayFont`) is retired in step 7: today it still shows an item's name big; the style pass moves that to RobotoCondensed Bold.
- One family, two weights. It's in Roblox's built-in set, so nothing is uploaded.

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

Flat, matte and numbered, built in step 2a. Each ball is one sphere with its paint in one texture, like a real pool ball: its color, the band on stripes, its numbers and the cue ball's dots. The textures are made in code by `tools/BallTextures.py` from `Theme.BallColors`, `Theme.Colors` and `Theme.BallMarks` (sizes in ball radii, so the look scales with `Config.Table.BallRadius`), then uploaded; `docs/MODELS.md` says how. The sphere is SmoothPlastic.

- **Solids 1–7:** one full color: yellow, blue, red, violet, orange, green, brick brown. The violet (`#8C50C8`) is clearly lighter than the 8, the green (`#58B83A`) light and yellow enough to stand out on the felt, and the brick brown (`#7A2E1C`) differs from red by hue, not just darkness.
- **The 8:** ink `#15130F`.
- **Stripes 9–15:** a cream `#FEFAEA` ball with one band of its solid's color, 70% of the ball's width: the width where its cream ends seen from the side and its colored ring seen end-on come out about the same, so a stripe passes neither for a solid nor for the cue ball.
- **Cue ball:** plain cream with two dark tan `#A8735C` roll dots on opposite sides, so one is always in view while it rolls.
- **Numbers:** every numbered ball has two cream number circles on opposite sides, on the middle of the band for stripes, painted on so they roll with the ball: sometimes facing you, sometimes sideways or away. Each circle is half the ball's width, with a thin ink ring (about half a pixel on a ball 30 px wide) and the number in plain ink, in Roboto Condensed Bold (`Theme.Font`'s face), so the circle still reads as cream when small. The number is as big as fits inside the ring: a single digit about 70% of the circle tall, two digits about 55%. They show at every size and distance. A fresh rack turns each numbered ball so one number faces straight up, at a random spin around the vertical, so the rack shows its numbers before the break.
- **Ink edge:** an ink line 0.15 of a ball radius thick (about 2.2 px on a ball 30 px wide, the top-down view at 1080p) just inside every ball's outline, drawn by each screen and always facing the camera, so balls read against the felt and against each other without looking bigger. Unlit, at every size and distance, and hidden while a ball sinks into a pocket.

## Characters

Normal Roblox avatars on the R6 rig only (set in the game's avatar settings), otherwise unchanged. Roblox's own name tags are hidden at the tables, since they'd be bare text over the felt; the "Turn" card names the shooter. Each player has a soft ring at their feet: a thin cream circle with a faint glow, a little wider than the avatar. The ring isn't built yet.

## UI

Every value lives in `src/Shared/Theme.luau`, and UI is built in code. `src/Client/Card.luau` draws the card look.

**The UI kit (step 7).** One client module holds every piece, each with its hover, press and selected states and its sounds built in, every value from `Theme.Kit` (sizes in pixels on a 1080-pixel-high screen, scaled with `UIScale`). Measured from Illegal Soccer (`docs/audits/ILLEGAL_SOCCER.md`):
- **Shape:** square corners everywhere, never rounded. Cards carry thin tan corner brackets (arms 13 px, lines 2 px, 9 px in from the edge) and a faint halftone dot grid (2 px dots every 5.5 px, tan at about 15%). No drop shadows; glows only for hover and big moments.
- **Card:** cream with ink text. **Button:** mint for the one main action, pastel gradients for second-rank ones, dark with cream text for a quiet choice; each with a 2 px cream border and the dot texture; hover adds a soft cream glow (12 px) at once; press darkens it.
- **Key tab:** a cream-white square with the key in ink, half over a button's top edge or about two-thirds inside a slot's bottom edge. On a dark label the key box is cream; on a cream label it's dark.
- **Toggle:** a square knob on a light track: mint on the right when on, ink on the left when off. **Slider:** 10 square segments, mint up to the value and ink after.
- **Tab row:** dark tabs in a header bar; the hovered tab lights up, the selected one gets a cream outline, and the content swaps at once.
- **Panel:** a black header bar with the title in cream and a square cream close button at its right; a cream body with section bands and rows that each have a bold title and a grey second line. Opens and closes with a 0.1 s fade, no slide.
- **Tooltip:** a cream card with a small pointer toward what it explains. **Badge:** a dark box with a red-pink square and white text ("! 21h"). **Ribbon:** a cream card with cut ribbon tails each side and a pointer down: a bold title over a one-line grey reason. **Timer box:** a dark box with tan corner brackets and tan digits.
- **Controls column:** every control in one column at the right edge, stacked from the bottom: a cream label with a black key box (Lock aim `Space`, Shoot, Watch from above `F`, Abilities `1` `2`, Join `E`), its label going about 30% see-through when you can't use it, its key box inverting while the key is held. It replaces the two hints at the bottom right and is the F reminder.
- **Sides:** red and blue mark the two sides: a square by each name, a ring at each player's feet, name tags underlined.
- **Big moments:** a short mint tag over a cream card (a potted 8, the winner), in the goal banner's timing: a line wipes out, the card flashes in the side's color, its name types on. At the end, award ribbons over players' heads, each a bold title and a one-line reason (6 to 8 pool awards, like "Sniper: longest pot").
- **Ability effects** chunky and saturated like their auras, and a full ability bar shimmers with a moving rainbow.

The table below describes what's built today; the style pass rebuilds each piece on the kit and rewrites its row.

| Piece | Look |
| --- | --- |
| Cards | Cream (246, 239, 224) with ink (36, 28, 22) text, thin dark corner brackets set just inside each corner, and a faint dot texture. Corners nearly square (4 px) |
| Font | RobotoCondensed Bold, `Theme.Font`, set as `FontFace`: big and bold for names and numbers. Big moments use the display font (see Fonts) |
| Dark boxes | Near-black (32, 26, 22) with cream text: key boxes, the % readout, the power meter's track. Bigger ones, like the sunk-ball tray and later the timer, get cream corner brackets |
| Timer | A dark box at the top center, between the top bar's two cards |
| Control hints | Down the right side, stacked from the bottom: a slightly see-through cream label box, then a dark key box with the key or a short word, like "Lock aim" `Space` |
| Item slots | Players see items called "Abilities" everywhere on screen; code and docs keep "items". Each other player's 2 slots are small dark squares under their avatar on the top bar card, with their item bar under them. Your own card shows neither: your bar and slots are at the bottom (Ability squares) |
| Ability squares | Bottom center whenever you're at a table, in either view, sized for a 1080-pixel-high screen and scaled to the real one (`Theme.Abilities`): 2 squares of 100 px side by side, each with its key (`1` or `2`) in ink on a small cream tab half over its bottom edge. Empty, a square is just a thin cream outline; held, it's a dark tile with the ability's icon filling it. Under the squares, your item bar, a little wider than both, in 4 segments with a gap between them: dark tracks filling gold, with its "+4" pops and a gold glow while it's full with both slots taken. A thick gold outline round the square you're picking a target for, a dark veil over held squares while you can't use one, and a solid coral note with ink text just above the squares when a target is refused. Clicking a square does what its key does. Arranged like Illegal Soccer's item slots, drawn in our look |
| Lobby buttons and Abilities panel | While you're not at a table (exactly when the Leave button doesn't show), a centered row of gold accent buttons at the bottom center, each with its key letter in cream on a dark tag half over its top edge: Abilities (Z), Invite (X), Shop (C) and Settings (V), arranged like Illegal Soccer's lobby buttons and sized like the ability squares (`Theme.Abilities`). Abilities opens a cream card in the middle of the screen: "Abilities" at the top with a near-black Close button, two plain lines for 10-year-olds on earning and using them, then every ability in order, each its icon on a dark box beside its name and, in a softer ink, its one-line description. Close, Esc and joining a table close it |
| Buttons | A bright accent with ink text: sunny gold (255, 196, 46) for the main action, coral for leaving or undoing. A second choice beside a gold one, like Back to lobby beside Rematch, is a near-black button with cream text, so the gold one leads. Only the palette's colors; never neon |
| Text over the world | Always on a card or a dark box, never bare, so it reads on any background |

**Screen layout:**
- **Top center:** each side's card, yours on the left, with the timer between them. The side whose turn it is glows gold. Under the cards, the banner, and under the banner an item's name shown big, so the two never overlap.
- **Top right:** the coral Leave button while you're at a table, in both views. The spin control goes beside it later.
- **Left:** the power meter, with the phones' Lock button beside it.
- **Right:** the sunk-ball tray, with the control hints under it.
- **Bottom left:** the settings gear and, in test mode, the Test button.
- **Bottom center:** the lobby buttons while you're not at a table; at a table, in either view, your ability squares with your item bar under them. The top-down view shrinks the table a little to keep clear of them.

Touch targets stay at least 44 px, and everything fits a phone held sideways. Both are checked in the Mobile phase; until then the UI is built and tested on PC.

**Built so far:** cards, the font, dark boxes, control hints, accent buttons, the top bar's side cards, the banner, the timer and the gold "Turn" card over the shooter's head, with their name under "Turn". Placeholder item looks until the GUI pass: item icons drawn in code (an orange flame, a gold burst, an icy snowflake, a dark oil drop over a puddle edged in cream, a black pocket with a gold lid), shown on the other players' small slots on the cards and on your own ability squares bottom center (see Item slots and Ability squares above), the lobby buttons and the Abilities panel, and the item's name shown big at the top center under the banner: the name in Luckiest Guy with its one-line description under it in `Theme.Font`, on a dark box with its icon, popping in and fading out. Placeholder item effects on the table until Phase 4: an icy blue ring and tint on a frozen ball, a dark glossy oil patch edged in cream, and a gold lid across a blocked pocket. **Not built yet:** the ring at players' feet, and the final item effects (flame trail, blast burst, screen shake).

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
| UI motion (from Illegal Soccer) | Panels fade in 0.1 s and out 0.13 s, where they sit; what a panel covers cross-fades with it; tabs swap at once; hover glows show at once. A big moment is a 0.7 s sequence: 0.1 s line, 0.15 s flash in the side's color, 0.1 s settle, then the name typing on at about 0.03 s a letter. A full ability bar's rainbow scrolls about once a second |
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
- Glossy buttons, bevels, strong gradients, drop shadows on everything, or see-through "glass" panels. The only gradients are the soft pastel ones on second-rank buttons; the only see-through UI is a control you can't use right now.
- Neon glow and bloom on everything, lens flares, or sparkles and stars as decoration.
- Purple-and-blue "gamer" gradients, or random rainbow colors from outside the palette. The one rainbow is a full ability bar's shimmer.
- Emoji or stock icons in the UI. Icons are drawn in code, in this style.
- Text straight over the world without a card, a dark box or a dark edge, more than one font family, or rounded corners.
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
