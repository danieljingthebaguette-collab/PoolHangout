# Style guide

How Pool! looks. Every task that adds or changes something players see follows this file. Written 2026-10-16, when the art direction moved from a chill bar to an intense, item-based look in the spirit of the Roblox game Illegal Soccer.

- **A guide, not a source.** Screenshots of Illegal Soccer show the style we're after. Never copy their models, textures, images, UI art or effects. Everything in Pool! is made by us: in code, in Studio, or with Studio's AI tools from our own prompts, which never name another game.
- **Spec vs style.** Where GAME_SPEC.md and this file disagree about how things look, this file wins. For how the game plays, GAME_SPEC.md wins.
- **Placeholders.** The table and floor in the place are early versions in this style until Phase 4's final-look pass. `docs/MODELS.md` covers how models are built.

## In one line

Warm, golden and readable at a glance: chunky shapes and flat painted colors in a soft, glowing world, with bold UI that pops on top.

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

A big, warm wooden arena or lodge: timber arches and beams, plank floors, plants, and lanterns that throw warm pools of light. Mostly warm reds, oranges and browns, some green from the plants, and the pool felt as the strongest color in the middle of each table.

## Characters

Normal Roblox avatars, unchanged. Each player has a soft ring at their feet: a thin cream circle with a faint glow, a little wider than the avatar. The ring isn't built yet.

## UI

Every value lives in `src/Shared/Theme.luau`, and UI is built in code. `src/Client/Card.luau` draws the card look.

| Piece | Look |
| --- | --- |
| Cards | Cream (246, 239, 224) with ink (36, 28, 22) text, thin dark corner brackets set just inside each corner, and a faint dot texture. Corners nearly square (4 px) |
| Font | RobotoCondensed Bold everywhere: `Theme.Font`, set as `FontFace`. Big and bold for names and numbers |
| Dark boxes | Near-black (32, 26, 22) with cream text: key boxes, the % readout, the power meter's track. Bigger ones, like the sunk-ball tray and later the timer, get cream corner brackets |
| Timer | A dark box at the top center, between the top bar's two cards |
| Control hints | Down the right side, stacked from the bottom: a slightly see-through cream label box, then a dark key box with the key or a short word, like "Lock aim" `Space` |
| Item slots | Bottom center: square dark slots with bright corner brackets, a small number tag on each, and a dashed outline for an empty slot |
| Buttons | A bright accent with ink text. The main accent is sunny gold (255, 196, 46). Other bright, slightly pastel accents like mint, sky blue or coral can mark other kinds of buttons; never neon |
| Text over the world | Always on a card or a dark box, never bare, so it reads on any background |

**Screen layout:**
- **Top center:** each side's card, yours on the left, with the timer between them. The side whose turn it is glows gold.
- **Top right:** kept free for the spin control.
- **Left:** the power meter, with the phones' Lock button beside it.
- **Right:** the sunk-ball tray, with the control hints under it.
- **Bottom left:** the settings gear and, in test mode, the Test button.
- **Bottom center:** the item slots.

Touch targets stay at least 44 px, and everything fits a phone held sideways. Both are checked in the Mobile phase; until then the UI is built and tested on PC.

**Built so far:** cards, the font, dark boxes, control hints and accent buttons. **Not built yet:** the timer, item slots and the ring at players' feet.

## Effects

Stylized and chunky, never realistic:
- **Auras:** flame and energy auras made of a few big, soft particles in flat colors with a bright core.
- **Trails:** dashed trails behind fast-moving things.
- **Sparks:** small, short bursts of chunky sparks on impact.

Keep them short so the game stays readable, and keep particle counts low for phones. Custom particle and trail textures are assets, so ask before uploading any.

## Performance

Hold 30+ fps on a mid-range phone:
- Future lighting scales itself down on weaker devices.
- Merge static decoration where you can.
- Keep only a few lights casting shadows.
- Keep particle counts low.
