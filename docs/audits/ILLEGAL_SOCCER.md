# Illegal Soccer audit: the measured style spec

From Daniel's references in `references/illegal-soccer/`:
- the two screenshots;
- `clips/illegal-soccer-1.mov` up to 4:10 and `clips/illegal-soccer-2.mov` up to 2:18 (after those, the desktop);
- the 12 key frames in `clips/frames/key/`, sampled at full size;
- the contact sheets in `clips/frames/`;
- 10 interaction bursts at 15 frames a second.

Measured 2026-11-12. `interactions.mov` isn't recorded yet; section 5 lists what it should cover.

**The rule:** we match their tone, texture, shape and interactions almost one for one, and draw everything ourselves in code. We never use or trace their images, icons, logos or item art; our icons are our own, in the same flat style.

**How it was measured:**
- **Screen:** every key frame is 2940 × 1912, with Roblox's view 1847 px tall under a black bar. Sizes are a share of that height, then converted to pixels on a 1080-pixel-high screen, the size our UI is designed at and scaled from (`UIScale`).
- **Colours:** the median of a small patch at full size. JPEG noise is about ±3 per channel.
- **Times:** from frames 1/15 s apart, so about ±0.07 s.

## 1. What makes their look work

1. **One cream, one ink, few accents.**
   - Warm cream cards and near-black ink carry everything.
   - Mint means "go", red and blue mean the two sides, and gold is only for progress.
   - Nothing else competes.
2. **Square printed cards.** Every card is square-cornered, with thin tan corner brackets and a faint halftone dot texture, so the UI reads like stickers and trading cards, not app buttons. No rounded corners, and no drop shadows.
3. **Big, tight condensed type.**
   - Bold condensed for names, numbers and labels, with plain ink-on-cream contrast.
   - The secondary line is the same family, regular weight, in warm grey.
   - Numbers are huge (the score is 5.6% of the screen's height).
4. **Every control teaches its key.**
   - A cream label with a black key box, down the right edge.
   - Keys sit on small cream tags on the bottom buttons and on the item slots.
   - A dark label takes a white key box, the same pair inverted.
5. **See-through means "not now".** A control you can't use keeps its ink text and black key box, but its cream label goes about 30% opaque and lets the world show through.
6. **Calm UI, loud world.**
   - The HUD is flat and quiet.
   - Abilities are saturated, chunky auras (purple flames, blue swirls, fire), and a charged bar is a moving rainbow.
   - The contrast makes the big moments land.
7. **Fast UI, short sequences.**
   - Panels fade in and out in about 0.1 s, and tabs swap instantly.
   - A goal is a 0.7 s sequence: a line, a flash in the team colour, then the name typing on.
8. **Pastel tints for second-rank buttons.** The lobby's Shop, Inventory and Friends are soft vertical gradients from near-cream to blue, beige or lilac, with a thin cream border and the dot texture. The one main action (PLAY) is solid mint.

## 2. Palette (sampled)

| Name | Hex | Where they use it | Ours, in step 7 |
| --- | --- | --- | --- |
| Cream | `#FEFAEA` | Cards, labels, panels' bodies, tooltips | Every card and label (ours today: `#F6EFE0`, slightly greyer) |
| Cream-white | `#FFFEED` | Key tabs on slots and buttons, the close button | Key tabs and tags |
| Ink | `#15130F` | All text on cream, key boxes | All text on cream (ours today: `#241C16`, browner) |
| Dark box | `#171513` | Timer box, panel header bar, key boxes, dark labels | Same |
| Warm grey | `#807B6F` | Subtitles, the "285/1625", reasons on award ribbons | Second lines everywhere |
| Section band | `#EBE7DB` | Section headers inside panels ("Gameplay") | Same |
| Tan | `#C2927B` | Corner brackets, the score's dash, timer digits, the info pill's title | Brackets and the timer (ours today: ink brackets) |
| Mint | `#38FFA5` | Main buttons (PLAY `#44FFAB`), toggles that are on, slider fill, full bar segments, the "GOAL!" tag, slot brackets | Main buttons, on toggles, sliders, full bars, the big-moment tag (ours today: gold) |
| Mint edge | `#D4EED5` | The thin light border round mint buttons and segments | Same |
| Side red | `#ED105D` | Red team square, the "YOU" tag, badges' "!" and warnings | Side A, warnings, badges (replaces coral `#FF8A76`) |
| Side blue | `#3384FA` | Blue team square | Side B |
| Gold | `#F8D734` | The level bar's fill, the coin (`#EAC836`) | Only the turn and the called pocket |
| Pastel blue | `#DBDEDB` → `#BDCDE0` | Shop button, top to bottom | Shop |
| Pastel beige | `#E7DDD1` → `#E1D0C1` | Inventory button | A second lobby button |
| Pastel lilac | `#E5D1DA` → `#D6AFDE` | Friends button | Invite |
| Toggle track | `#E2DED2` → `#D2CEC3` | The off half of a toggle, left to right | Same |
| Rainbow | `#F35CE8` → `#F6B379` → `#99FF7A` → `#4FB8FF` | A full ability bar, each segment, scrolling | A full ability bar (Daniel's step 7) |
| World text | `#F0EEF6` with a dark edge | Player names, the assist's name | Names over the world |

**Their translucency:**
- the dim control label is cream at about 30% over the world;
- the info pill is `#161412` at about 85%;
- a held slot's tile is near-black (`#171314`), or dark green with a teal glow for some items.

## 3. Shapes and type (measured)

Share of the screen's height, then pixels at 1080 high. All corners are square.

| Piece | Measured | At 1080 |
| --- | --- | --- |
| Screen margins (top, sides, bottom) | 1.6–1.7% | 17–18 px |
| Corner brackets | arm 1.2%, line 0.22%, inset 0.87% from the card's edge | arm 13, line 2, inset 9 |
| Dot texture | dots 0.16% across, every 0.51%, tan at about 15%, stronger toward one side | dot 2, every 5.5 |
| Borders on mint and pastel buttons, bar segments | 0.16% cream | 2 px |
| Score card | 7.6% tall, 20.7% wide; numerals 5.6%; side squares 1.75% | 82 × 223; numerals 60; squares 19 |
| Timer box | 3.7% tall, 9.5% wide, 0.7% under the score card; digits 2.5% in tan | 40 × 103, 13 below; digits 27 |
| Level card, coin card | 6.4% tall × 23.5% wide; 3.8% × 8.4% | 69 × 253; 41 × 90 |
| Controls column (right edge) | label 3.9% tall, one every 4.8%; key box 2.7%; text 2.0%; a 1.8% × 0.16% white bar between groups | 42 tall, every 52; key box 29; text 21; divider 19 × 2 |
| Main button (PLAY) | 7.7% tall, 21.6% wide; text 4.1%; hover glow 1.1% | 83 × 234; text 45; glow 12 |
| Tooltip | 2.6% tall, text 1.8%, pointer 0.8% | 28 tall, text 19, pointer 9 |
| Bottom buttons (Shop, Inventory, Friends) | 5.3% tall, 18.7% wide, 1.2% apart; text 2.7%; key tag 2.4% half over the top edge | 58 × 202, 13 apart; text 29; tag 26 (letter 18) |
| Badge on a button ("! 21h") | 3.2% tall dark box, red square 1.4% | 34 tall, square 15 |
| Item slots | 7.9% square, 1.1% apart; key tab 2.6% about two-thirds inside the bottom edge; empty = cream dashes 0.16% thick with a thin "+" | 85, 12 apart; tab 28; dashes 2 thick, 6 long, 4 apart |
| Thin bar over the slots | 0.6% tall, 8% wide, pale gradient | 7 × 86 |
| Ability bar | 4 segments 1.8% tall, 7.8% wide, 0.55% apart: 32.7% in all, 1.7% under the slots | 20 × 84, 6 apart, 353 in all, 18 under |
| Panel (Settings, Shop) | black header bar 5.6% with the title at 2.9%; square cream close button 3.3%; body width 47% | header 60, title 31, close 36, width 507 |
| Panel rows | 5.6% tall; title 2.1% bold; second line 1.6% regular grey; side padding 2.4% | 61 tall; 23 / 17; padding 26 |
| Section band | 3.0% tall, text 1.6% grey | 33, text 17 |
| Toggle | 6.4% × 3.2%; square knob 2.5%: mint on the right when on, ink on the left when off | 69 × 34, knob 27 |
| Slider | 15.8% × 2.8%, 10 square segments 0.3% apart: mint up to the value, ink after | 170 × 30, 3 apart |
| Big-moment card (goal) | 8.9% tall, 35% wide; name 5.6%; mint tag 3.7% over its top edge, text 2.0% | 96 × 378; name 60; tag 40 tall, text 22 |
| Award ribbon | 7.6% tall, 23–28% wide; title 2.7% bold; reason 1.8% regular grey; cut tails 2.8% each side; pointer down | 82 × 250–300; 29 / 19; tails 30 |
| Dark label with a key ("Stats TAB") | 3.6% tall, ink box with a cream key box | 39 tall |
| Info pill | 3.9% tall, dark at 85%; tan bold title, light text | 42 tall |

**Type:**
- **Their faces:** a bold condensed sans (Roboto Condensed Bold, or one very close to it) and its regular weight.
- **What Roblox ships:** Roboto Condensed in Light, Regular and Bold only. Bold (700) is the heaviest, so it's the big text too (Daniel's call in place of Luckiest Guy).
- **Text over the world:** cream with a 1–2 px dark edge.

## 4. Interactions (timed)

| Moment | What happens | Time |
| --- | --- | --- |
| A panel opens (Settings, Shop) | Fades in where it sits, no slide or scale; the lobby's PLAY and bottom buttons fade out together | 0.1 s |
| A panel closes | Fades out; what it covered fades back | 0.13 s |
| Panel to panel (PLAY to team pick) | A cross-fade | 0.1 s |
| Hover on a main button | A soft cream glow round it, about 1.1% of the screen's height, at once | 1 frame |
| Hover on the close button | The hand cursor; the button stays cream | — |
| Tab switch | The hovered tab lights up; the click swaps the content at once; the selected tab gets a cream outline | 0.07 s |
| Big moment: a goal | The score card fades as a mint line wipes out from the middle; the card flashes in the scorer's team colour with a bright glow; brackets and the side square settle in; the name types on letter by letter, each fading from light to ink; the assist's name shows under the card in white | 0.1 + 0.15 + 0.1 + 0.35 s (about 0.03 s a letter) |
| A full ability bar | Every segment fills with a rainbow gradient that keeps scrolling sideways | about one cycle a second |
| A control can't be used | Its label snaps between solid cream and about 30% cream | at once |
| A key held | Its key box inverts: cream with an ink edge ("Sprint SHIFT" while sprinting) | at once |
| Daily reward | Confetti of coloured ovals falls over the screen; a dark tooltip with a date shows on hovering a day | — |

**Not seen yet:**
- a toggle flipping and a slider dragging;
- a button's pressed state, and hover on the bottom buttons;
- a tooltip appearing;
- number pops (coins) and a badge appearing.

These need `interactions.mov` (section 5).

## 5. What to record next (`interactions.mov`)

Move slowly and pause about 2 seconds on each:
1. Hover each bottom button (Shop, Inventory, Friends), then off.
2. Press and hold PLAY (or a bottom button) for a second before letting go.
3. In Settings, flip one toggle on and off, drag a slider all the way left and right, and hover a row.
4. In the Shop, hover a tab, click through every tab, and hover an item and its price button.
5. Hover something with a tooltip, like a day in Daily Reward or an item in Inventory.
6. Anything that adds coins or XP (the end of a match), and a badge appearing.
7. The ring at your feet while you run, from behind.

## 6. What moves closer in our UI (my picks)

All **take** in step 7, since Daniel decided to match the look. Each row names the STYLE.md rule it changes.

| Ours today | Moves to | STYLE.md |
| --- | --- | --- |
| Cards with 4 px corners, ink brackets, a faint texture | Square corners, tan brackets (13 px arms, 2 px lines, 9 px in), the measured dot grid | Palette, UI: Cards |
| Cream `#F6EFE0`, ink `#241C16` | `#FEFAEA` and `#15130F` | Palette |
| Gold as the main accent (buttons, meter, bars) | Mint for main buttons, on toggles and full bars; gold only for the turn and the called pocket | Palette, Buttons |
| Coral for warnings and leaving | Their red-pink `#ED105D` for warnings and badges | Palette |
| Sides told apart only by the turn glow | Red and blue: a square by each name, a ring at each player's feet, name tags underlined | Characters, top bar |
| Luckiest Guy for the item's big name | Roboto Condensed Bold, big | Fonts |
| Two hints bottom right | One controls column on the right: cream label, black key box, dimmed to 30% when you can't use it (Lock aim, Shoot, Watch from above F, Abilities 1 and 2, Join E) | Control hints |
| Gold lobby buttons with dark key tags | Pastel gradient buttons with a cream border, the dot texture, cream key tags; mint for the one main action | Lobby buttons |
| Ability squares with a cream outline, gold bar | Dashed cream outline and a "+" when empty, a dark tile with mint brackets when held, cream tabs; mint segments, a rainbow scroll when full; a thin bar over the slots | Ability squares |
| A plain settings card | A panel with a black header bar and a square close button, section bands, rows with a second line, square toggles and 10-segment sliders | (new) Panels |
| Banners for fouls and the winner | A cream card with a short mint (or red-pink) tag over its top edge, the goal sequence's timing, award ribbons at the end | Big moments |
| Our 0.25 s fades | 0.1 s fades for panels; instant tab swaps | Timings |

## 7. Settings other games offer

From Illegal Soccer's Settings, in their order. Crazy 8 Ball shows no settings in the clips.

| Group | Settings | For Pool! |
| --- | --- | --- |
| Codes | Redeem a code (a text box and a go button) | later, with progression |
| Graphics | Performance mode; hide large accessories | later; we already hide the shooter's accessories on the table |
| Gameplay | Assisted passes; automatic item use; invert curve | skip (soccer only) |
| Camera | Free camera | skip |
| Privacy | Friend invites only; allow club invites | later, with parties |
| Interface | Show controls; show hints; show stats (frame rate and ping); show own name tag; UI scale (10 steps) | **take** show controls (Daniel's "control hints on/off"), show stats and UI scale. Skip the name tag, which is hidden at tables |
| Sensitivity | Curve sensitivity (10 steps) | skip |
| Audio | Sliders | **take**: music and sound, as planned |
| Keybinds | Every action and every UI key, each with a reset and a second key | later: worth it after launch, too big this week |

Daniel's own list for step 6: music, sound, camera glide, screen shake and control hints. My pick adds **UI scale** and **show stats** from theirs.

## 8. Their systems, for later (not built this week)

- **Daily rewards:** a 7-day calendar ("1/7 Days", coins each day, a free item on day 7), confetti when you claim, a small "Daily Reward 100" toast, and a "Join Event" popup with Notify Me.
- **Stats board in the lobby:**
  - Career and Feats tabs with round stat icons: goals, assists, saves, tackles, item hits, MVPs, level, daily streak.
  - Clubs and Players leaderboards, weekly and all time, plus a "Top Elo" board.
- **Level and coins in the corner:** a cream level card (badge, "Level 55", "285/1625", a gold XP bar) over a coin card.
- **Party slots:** the bottom row shrinks to its icons and adds your avatar and "+" slots to invite into.
- **Shop odds and guaranteed drops:**
  - Rarity sections with "6% of rolls · 1/3 owned".
  - Pity bars ("Guaranteed Epic in 5 rolls").
  - Bundles with guarantees, prices struck through, duplicates turning into dust.
- **Passes:** coloured category bars (VIP kit, emotes, club, chat, deals) and a dark "Own the pitch" card with one big price button.
- **Inventory:** tabs per kind, an "Equipped" preview with brackets, an owned grid with small black tags ("Equipped", "VIP", "In shop now").
- **Match flow:** an Intermission header with its timer, a team pick card (Red, Blue, spots left, mint Join buttons), and award ribbons over players at the end.

## 9. The mock shop, from their structure

Only the structure: tabs for **Daily Shop**, **Bundles** and **Passes**, with no rolls tab until Daniel decides on gacha.

- **Daily Shop:** a "Today" row of 5 items, each priced, with "Leaves in 20h 59m"; a big Featured card beside it.
- **Bundles:** cards of 3–4 items with a struck-through total.
- **Passes:** a few perk tiles under coloured category bars, and one dark promo card.
- **Our items:** cue skins, ball sets, felt colours, pocket effects.
- **Buying:** "Coming soon", and no real purchase anywhere.
