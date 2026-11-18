# Build plan

Launch Friday, Dec 18, 2026, with 1v1 and 2v2 pool, 5 items and a short tutorial with Coach, in one lodge room with 6 tables and 24-player servers. The shot came first, then normal tables, then items. Features freeze Dec 11, and the last week is only for fixing. This assumes about 10 hours a week from me, with Claude writing most of the code and building the models. There's no commissioned modeler: the game is made entirely with AI.

This file started as a copy of my "Pool! Build Plan" doc and is now the working copy: Claude ticks tasks and keeps Status current here. The label after each task says who does it. A step ends only when I say its "Done when" test passed.

## Status

- **Current step:** the Fable pass, Part 2, step 2b (its section is below, after Phase 3). The Fable window ended on Nov 17 at 2:59 AM with Part 1 and step 2e done; the pass's steps carry on in the same order as Phase 4 work
- **In progress:** the Fable pass, which replaces this week's step 7: polish Pool! as far as we can before the Fable window ends on Tuesday, Nov 17 at 2:59 AM Eastern. One part per session, and every step is one commit. Part 1, the audit and the plan, is done. Every Claude task in Phase 3 is built. Players see "Abilities", never "items". The test panel, Give buttons and Coach stay owner-only on a published server. Left in Phase 3 is mine: the store page's name and description, the music and sound picks, the age check, publishing, then the friends playtest. After the pass: the rest of Phase 4, with the item balance pass and the tutorial's items step waiting for what my friends find. Phase 2's 2-player and 4-player checks are in the Phase 3 and Phase 4 friend playtests
- **Dates:** launch moved to Friday, Dec 18 when the plan was reordered. Phase 4 starts Monday, Nov 16; the Fable pass (Nov 14–17) does some of its tasks early. The phase dates are Claude's proposal for that launch
- **Last session:** 2026-11-18. Step 2a: each ball is one sphere mesh (`Theme.BallMesh`, imported from `tools/BallTextures.py`'s sphere.obj) wearing one texture that script makes from Theme's colors: solids in full color, stripes cream with a band 70% of the ball's width, a lighter violet for 4 and 12, brick brown for 7 and 15, two cream number circles on opposite sides that roll with the ball, and a cream cue ball with two tan dots. A fresh rack turns one number up on each ball, and each screen draws a camera-facing ink edge. The uploaded images' IDs are in Theme. The art director's two ball notes that need code (matte balls, a pixel minimum for the edge) are at the top of 4a. Then a fix: the aim indicator and the ink edges are drawn after the camera's ease each frame, so the aim line stays on the cue ball while the view glides in. And a second: in the top-down view your own character is hidden whole from the instant the view opens until it closes, and anyone else whole while they stand on a table, never part by part. Last, the Studio Assistant's code review, checked point by point: its real points went into 2b, the tutorial rooms task, the phone pass and the Progression step
- **Before that:** 2026-11-17, step 2e (bodies over a table hidden in the top-down view, shooters at least 2 studs clear of the table's edge) and two fixes: the server sends each shot's starting speed in `ShotStarted`, and NativeCheck covers item shots (fingerprint 1579840315). From 2e's art director: step 2d should space the tables at least 6 studs apart end to end, since a stepped-off Coach ends up about 1 stud from Table2's rail. Earlier, 2026-11-14 to 16, Part 1 of the pass: four games against Coach with 47 "before" screenshots in `references/before-fable/`, the art director's top 10 (in the Fable pass section), and my decisions: the balls get numbers, the room is the lodge blockout's first cut, bodies on the table are hidden from above, and steps 2c and 3b wait until after Part 4
- **Next up:** 2b, then 2d. Then 3a and Part 4. After the pass: my Phase 3 jobs (store page, music and sounds, the age check, publishing the friends version) and the friends playtest
- **Known issues:**
  - Touch and the new HUD layout haven't been tried on a real phone yet, only in the emulator; it's covered by the Mobile phase
  - The existing touch code isn't tested or extended until the Mobile phase, so it will fall behind the PC features built before then. Ball in hand is mouse-only: on a phone the cue ball can't be moved yet
  - Lighting.Technology has to be set to Future by hand in Studio; scripts can't change it
  - Leaving the server mid-game ends the game with no winner (the table re-racks), until the arena step's takeover rules
  - In Studio solo you're always side A, so sinking the 8 early reads "Player1 loses: …" rather than naming a winner
  - In 2v2, two long names don't fit on one card and the second is cut to "…"; the avatars still show both
  - A card's ball icons change when the next turn starts, about a quarter second after the balls stop, not the moment a ball drops; the tray fills as they drop
  - The Output warning about rbxassetid://203785492 ("Pop Close Sound") comes from a Studio plugin or Roblox, not the place: ignore it
  - The GUI needs tweaking: the Fable pass's Parts 3, 4 and 6 redo it on the UI kit
  - Coach's avatar on the top bar is an empty dark square, since a bot has no avatar picture
  - Our break sinks about 1.8 balls (`tools/BreakStats.luau`), against 0.7 in the 3 full-power 8 Ball Duels breaks recorded so far. Since the 2026-11-04 tuning it spreads the rack and brings the cue ball back like theirs; more recorded breaks would show whether the count really differs
  - Coach ignores items: it never uses one, and it still plays pots on frozen balls and doesn't allow for oil. It does avoid blocked pockets. Fine for testing; the tutorial's item step scripts its own
  - The item effects' looks (frozen ring, oil patch, lids), the item slots and the big name are placeholders: the effects get their final look in Phase 4's item-effects task, the UI in the Fable pass's steps 4b and 4c
  - Settings only save in a published game, or in Studio with Game Settings → Security → Enable Studio Access to API Services on. Without it they apply for the session and the page says so
  - The Screen shake setting has nothing to switch until screen shake is built in Phase 4
  - Not yet checked by me that a slider change reaches both the server and the shooter's screen (part 4 of my physics check). Claude's playtest confirmed it for the pocket sliders
  - Seen once, on 2026-11-14: when my shot clock ran out in the middle of a pull, two aim lines (the white one after the hit and the yellow one) stayed on screen near a pocket while Coach aimed. Cause not found; the Fable pass's step 4d finds and fixes it
  - The sunk-ball tray may not fit the 15th ball in a small window: the art director's count from a 1100 × 580 capture, not checked. Step 4a checks it when it redraws the tray

## Rules that protect quality

1. **Riskiest first.** The shot is built and tuned before anything else, because every other system depends on it feeling good.
2. **Gates.** Each step ends with something playable and a "Done when" test. Don't start the next step until it passes.
3. **One config file.** Every tuning number lives there, so changing the feel never means rewriting code.
4. **Tested rules.** Physics and 8-ball rules are plain Luau modules with automatic tests, so a fix can't quietly break another rule.
5. **PC only until the Mobile phase.** I test every step and every "Done when" on PC. The touch code that's already there stays, but isn't tested or extended until Phase 5, the Mobile phase. Most Roblox players are on phones, so that phase makes everything work by touch before launch.
6. **Save often.** Commit to git every session, and save a place version before big changes.
7. **A Later list.** New ideas go on the Later list in GAME_SPEC.md, not into the current step.
8. **Feature freeze Dec 11.** The last week is only for fixing.

## Phase 1, Oct 12–25: the shot on one table

**Goal:** one table where sinking a ball feels great on PC.

- [x] Set up Studio's MCP connection, Script Sync, git and this kit (Me)
- [x] One config file for every tuning number: table size, pocket size, friction, rail bounce, max power, shot clock (Claude)
- [x] Greybox table: 16 × 8 studs of playing surface, 16 balls, and 6 pockets about real size (Claude builds it, I adjust)
- [x] Ball physics: our own simulation on the server for rolling, ball-to-ball hits, rail bounces and pockets, played back smoothly on every screen (Claude)
- [x] Press F to switch to the top-down view, and F again to go back (Claude)
- [x] Aim: on PC only the mouse aims (the cue follows it). On phones, drag on the table. Space (phones: a Lock button) locks and unlocks the aim; the aim indicator is see-through while aiming and solid while locked, with a hint (Claude)
- [x] Power, like a slingshot: hold the mouse button and drag (it locks the aim where it is), or press Space first to lock. Phones: while unlocked, a touch near the cue ball pulls; while locked, anywhere. Power is how far the pointer has moved from where you pressed, straight back toward the stick, counted from the edge of a small cancel zone; pushing toward the ball lowers it to 0 and sideways does nothing, like 8 Ball Duels. The cue slides back and a display-only meter fills. Let go to shoot; let go back inside the cancel zone (the indicator turns see-through and the hint says "Cancel · Let go"), right-click, Esc or a missed release cancels back to how you were; Space or Lock mid-pull cancels and unlocks. You can only aim and shoot from the top-down view: the cue and the meter only show there, and leaving the view mid-pull cancels the shot (Claude)
- [x] Aim indicator, always on, like 8 Ball Duels: a line from the cue ball to the center of a circle where it first touches a ball (stopping at a rail or pocket), with a dot there; a white line showing where the cue ball goes after the hit and a yellow line where the hit ball goes, each sized by its share of the speed; thin dark outlines on everything. Three Config switches, no player setting (Claude)
- [x] Tune the feel together: friction, power, rail bounce, pocket size (Me + Claude)
- [x] Restyle the table (slim rails with diamonds, real-size pockets, classic green and warm wood) and add a HUD laid out like 8 Ball Duels: power meter with %, sunk-ball tray, ball shadows, my player card, settings with sound volume, a collapsible test panel (Claude)
- [x] Decide the final table size, since `docs/MODELS.md` needs it (Me)
- [ ] The age check and questionnaire: moved to Phase 3, next to the friends playtest that needs them

**Done when:** I take 30 shots in a row on PC with no bugs, and sinking a ball feels satisfying. If it doesn't, keep tuning before Phase 2. **Passed 2026-10-17.**

## Phase 2, Nov 3–15: Normal tables

**Goal:** a normal game of 8-ball works from joining to the end screen, in 1v1 and 2v2, and feels good, before any items.

- [x] Rack and break: a random player breaks from the middle of the head line; no ball in hand on the break (Claude)
- [x] Groups: the table stays open after the break, and the first legal pot sets solids or stripes (Claude)
- [x] Turns: a legal pot keeps your turn; a miss passes it (Claude)
- [x] Fouls (cue ball sunk, wrong ball hit first, nothing hit): the next player places the cue ball anywhere (Claude)
- [x] The 8: call your pocket. Sinking it early, in the wrong pocket, or along with the cue ball loses (Claude)
- [x] Top bar for two: the other player's card, a highlight on whose turn it is, and each side's balls still left to sink, with room in the middle for the shot clock (Claude)
- [x] Automatic rule tests: 25+ scenarios, like sinking the cue ball on the 8, that rerun after every change (Claude)
- [x] Join Table1 with a "Join table" prompt instead of platforms: E only joins (side A, then B), a 3-second "Starting..." banner once every seat is taken, then each player is moved once to their seat facing the table, with their camera behind them, free to walk. "Table in use" during a game, and it opens again when the game ends. The table builder makes invisible seat markers where the platforms were. A coral Leave button top right in both views: off the table while waiting, calls off the 3-second start, and mid-game asks "Leave and lose this game?" (in 2v2 the teammate plays on). Camera: your turn switches you to the top-down view, and your turn passing switches you back to third person; F switches any time (Claude) **Passed my 2-player test 2026-11-04.**
- [x] "Turn" arrow over the shooter, and a 45-second shot clock in the middle of the top bar that stops while balls roll. Running out is a foul, with ball in hand for the next shooter (Claude)
- [x] End screen: the winner and each player's stats, with Rematch and the other options in GAME_SPEC, then back to the lobby (Claude)
- [x] Live aim for everyone at the table. Anyone in the top-down view, not just the shooter, sees the shooter's cue and aim indicator move live: the aim line, the circle, both direction lines, the called-pocket ring, and the cue sliding back during a pull. The updates are display-only and smoothed, so a slow connection never affects the shot. (Claude)
- [x] Sounds and hit effects: hit, rail and pocket sounds, and small chunky sparks on hard hits, in `docs/STYLE.md`'s timings. The free placeholder sounds stay until I pick final ones (Claude; I pick the sounds)
- [x] Coach, a bot opponent for testing, in Studio or for me alone in a published server: when I'm alone in the server and join a 1v1 table, Coach takes the other seat and plays simple, sensible shots, built on the whole-game test bots' shot logic, so I can play the whole loop alone. It becomes the tutorial's bot in Phase 4, and never plays in normal matches (Claude)
- [x] 2v2 on one table: Table2, built as a 2v2 table with A1 and A2 on one long side and B1 and B2 on the other. Your side is your team, teammates share a group, and turns go A1 → B1 → A2 → B2 (Claude)
- [x] R6 shot pose: while you aim, your character glides to stand straight behind the cue ball, always facing it, on top of the table when needed (see-through there), in a ready-to-shoot pose, and steps off after the turn. The camera eases between views, and while it isn't your turn the top-down view sits a little farther out (Claude)
- [x] Your balls pulse once over 2 seconds when your turn starts (Claude)
- [x] Test of the whole step: 1v1 on Table1 and 2v2 on Table2 (Me) **Passed solo 2026-11-08:** 1v1 against Coach, and 2v2 against three Coaches. Server & Clients wouldn't run, so the 2-player 1v1 check moved to Phase 3's friends playtest and the 4-player 2v2 check to Phase 4's 4-friend playtest

**Done when:**
1. Join with E, Leave and the automatic top-down camera pass a 2-player test. **Passed 2026-11-04.**
2. 1v1 and 2v2 seats and turn order work.
3. A 45-second shot clock, where running out is a foul with ball in hand.
4. The end screen sends players to the lobby, with a Rematch button.
5. Hit and pocket sounds, small hit effects, and an R6 shot pose.
6. Everyone in the top-down view sees the shooter's cue and aim indicator move live.

**Passed 2026-11-08** in solo tests against Coach; the multiplayer checks moved to Phases 3 and 4 (above).

## Phase 3, Nov 8–15: Items

**Goal:** players earn the 5 items during a game and use them, and games stay fair.

- [x] Earning items: one item bar per player that gives a random item at 12 points: +3 at the start of your turn, +4 for each of your balls you sink, +2 for each ball the other side sinks (in 2v2, all to the opponent who shoots next). When the bar fills with both slots full, it glows and the item arrives as soon as a slot frees. The bar sits under each card's 2 slots, with a small pop like "+4" for each fill. Test-panel buttons to give myself any item (Claude)
- [x] Using items: press 1 or 2, on your own turn, one per shot, with the item's name shown big to everyone at the table. Slot icons drawn in code. Plain placeholder looks until the arena step (Claude)
- [x] Power Shot (for the rest of the turn the meter keeps filling past 100%, up to 150% at 1.5× the full pull) and Blast Ball (one shot), with Lune tests for the blast. Check that a 150% pull fits on screen for a cue ball against a long rail shooting straight across, on a 1920×1080 PC; if it doesn't, make the extra 50% take less pull. The phone check is in the Mobile phase (Claude) **The 150% check:** it fits at 1920×1080, but only just: with the cue ball against a long rail shooting straight across, the pull (9.55 studs) has to start on the far cushion or rail, a band about 160 px tall above the cards
- [x] Freeze, Oil Slick and Pocket Block: frozen balls and pocket lids bounce balls like rails, oil patches slow balls less, and the aim indicator knows about frozen balls and lids. The lock-out rules: no freezing the 8 or a side's last group ball, no Pocket Block against a side shooting at the 8, and no side targeting the same ball or pocket two turns running. With Lune tests (Claude)
- [ ] Store page name and description, moved from Phase 4 to spread my hours (Me)
- [ ] Pick the music and final sounds: ball clicks, rail thuds, pocket drops and a sound for each item. Claude wires them in during Phase 4 (Me)
- [ ] Complete the age check and the Maturity & Compliance Questionnaire, so friends can test. At that first publish, also check that a player who joins a server mid-game sees the game (Studio can't add a player mid-test) (Me)
- [ ] Playtest with 2 friends on a friends-only test version. Include Phase 2's 2-player check: 1v1 on Table1, each sees the other's shot pose in 3D and the live aim with F, and Leave → Yes gives the other player the win (Me)

**Done when:** every rule and item test passes, and 2 friends finish 3 full games on PC, items included, without me explaining anything.

## Fable pass, Nov 14–17: the look, the HUD and the table systems (current)

**Goal:** fix what a player notices most, as far as we get before the Fable window ends on Tuesday, Nov 17 at 2:59 AM Eastern. It replaces this week's step 7 and does some of Phase 4 early: the final looks, the GUI pass, the table signs, floor markings, floor arrows, the cue in players' hands, the lanterns, the ring at players' feet and the first cut of the lodge blockout.

**How it runs:**
- One part per session, in the order below. Every step is one commit: Claude plans it and waits for my OK, builds only that step and refactors nothing outside it, I playtest, and then it's committed. Other ideas go at the end of the report.
- Steps stay small enough to commit before a usage limit hits. If a limit cuts a step off, Claude stops at a clean point and lists what's left.
- References are for tone, size and timing only: never copy or trace their art, icons, models, layouts or code. Ask before uploading anything or inserting Creator Store models.
- Visual work goes to the style-builder, and the art director reviews the after screenshots beside the closest reference frame: at most about 18 screenshots a review, shrunk, so it finishes inside a usage limit. Its top 3 fixes go in the report.
- Every number lives in Config or Theme. Lint, the type check and all tests pass. Each step updates the doc that owns its change (STYLE.md, MODELS.md, GAME_SPEC, this file's Status).
- Not in this pass: daily rewards, ranks, coins, crates, quests, streaks and real purchases.

**The art director's top 10** on 2026-11-16, worst first, and the steps that fix each:
1. The world is a baseplate under the default sky, with the stock spawn decal: 2d
2. Bodies lie on the felt and show under the HUD in the top-down view: 2e
3. The table is a flat green rectangle that melts into the floor, with black blocks for corners and no light: 2b, 2d
4. The balls are beads, and a stripe seen end-on passes for the cue ball: 2a
5. One yellow for everything, rounded corners everywhere, no side colors: 3a, 4a
6. The aim line is the faintest thing on the felt: 4d
7. The abilities UI is the thinnest thing on screen: 4c
8. Big moments are flat, and the ability's name lands on the table in a second font: 4b
9. The lobby has no main action and points nowhere: 6a, 7a, 7c
10. The panels and the end screen are forms: 6b, 6c, 6d

- [x] **Part 1, audit and plan:** four games against Coach through the Studio MCP, 47 "before" screenshots in `references/before-fable/` (our own screens, not style references; git ignores them like the other reference images), the art director's top 10, the ball look and this plan (Claude) **Done 2026-11-16.**

**Part 2: table, balls and lights** (Phase 4's final-looks task, moved up)
- [x] **2e** Bodies in the top-down view: any part of a character inside the table's outer edge is hidden completely in the top-down view, where the cue shows who's shooting; the normal view keeps 40%. Step-off and seat spots stay off the corners and at least 2 studs outside the rail, and the cue passes the shooter's hand, not their head. Update GAME_SPEC (Claude) **Done 2026-11-17.**
- [x] **2a** Balls, with numbers: solids in full color; stripes cream with one band 70% of the ball's width, so a stripe never passes for a solid from the side or for the cue ball end-on; a thin ink edge; no white dots; a purple clearly lighter than the 8, and 7 and 15 in brick brown; a plain cream cue ball with two dark tan roll dots. Each ball is one sphere with its paint in one texture made in code (`tools/BallTextures.py`) and uploaded: two cream number circles on opposite sides, half the ball wide with a thin ink ring and the number as big as fits, rolling with the ball like a real pool ball, at every size, and a fresh rack turns one number on each ball straight up; only the ink edge faces the camera. Sizes from Config; update STYLE.md and MODELS.md (Claude) **Done 2026-11-18.**
- [ ] **2b** Table: rails in two or three painted plank tones with dark seams, wooden corner blocks no wider than 1.6 pocket mouths with only the hole black, the felt in the palette's green with a head line and a foot spot a little lighter, an apron and legs with more shape, a soft shadow underneath, and break sparks about 10 px across at 1080p. Every size still from Config. Rebuild with `tools/BuildTable.luau`, then Claude reminds me to save the place. Also, from the Studio Assistant's review on 2026-11-18: wrap each of TableBuilder's CSG cuts in pcall and remove its cutter parts if one fails, so a failed cut warns instead of leaving parts in Workspace and a half-built table; and cut each piece once and copy it to every table, instead of about a dozen cuts per table, ready for Phase 4's 6 tables (Claude)
- [ ] **2d** Lantern, light and the room: a lantern over each table that throws a warm pool of light, so the felt's center is the brightest thing on screen; it's hidden on your own screen in the top-down view. The room is the first cut of Phase 4's lodge blockout in `tools/BuildArena.luau`, so it grows into the lodge: dark plank walls, a roof, the floor out to the walls and the spawn pad repainted, sized for the 6 tables Phase 4 adds. Update STYLE.md's lighting table if the light changes, and Claude reminds me to save the place (Claude)

**Part 3: the UI kit** (step 7a)
- [ ] **3a** Contact sheets of `interactions-1.mov` and `interactions-2.mov` at 15 fps (`tools/ContactSheet.sh`), ILLEGAL_SOCCER.md section 4's "Not seen yet" filled in, and the values in `Theme.Kit`; if a moment isn't in the clips, build from the measured spec and list what's still unmeasured. One client module with the kit pieces the table HUD needs (card, buttons, key tab, badge, timer box, controls-column row, big-moment card, dark label), each with hover, press, selected and can't-use states, scaled by the UI scale setting, with the dot texture kept to a few objects per card (Claude)

**Part 4: the table HUD on the kit** (step 7b), with a coin flip for who breaks
- [ ] **4a** First, two ball fixes from the 2a art-director review that need code: matte balls without the sun's highlight, which is the loudest mark on every ball (try a texture built into Roblox as a roughness map first, and ask me before uploading one); and a minimum width for the balls' ink edge, about 1.5 px on screen, so it stays a solid line on small balls. Then the top bar and timer: red and blue side squares, the tan timer, the clock pulse in side red, and the cards' ball icons and the tray drawn like the new balls. Check the tray fits 15 balls in a small window (Claude)
- [ ] **4b** Big-moment cards in the goal timing: a big "FOUL!" over the reason, the result, and today's callouts. The ability's name in Roboto Condensed Bold on a compact card under the top bar, clear of the felt (at most about 420 × 72 px at 1080p), with the user's avatar. Reword the result line so it names who sank the 8, and update GAME_SPEC (Claude)
- [ ] **4c** Ability squares and bar as STYLE.md describes: a bar about 16 px tall at 1080p, mint, with the rainbow when it's full; the refusal as a badge; other players' slots inside their card; the Oil Slick and Pocket Block icons redrawn (Claude)
- [ ] **4d** One controls column on the right replacing the hints and the F reminder; a heavier aim line (about 3 px at 1080p, cream with an ink outline) drawn above the oil patch and the rings; the meter's colors and a flash at full power. Find and fix the two aim lines that stayed on screen after my clock ran out mid-pull (Claude)
- [ ] **4e** "Who breaks?" as a coin flip on a big-moment card: our own coin drawn in code, each face in a side's color with its players' avatars, spinning about 1.5 s and landing on the breaker, then their name. The server still picks the breaker; the coin only shows it. And the ring at each player's feet (Claude)

**Part 5: physics, small adjustments only** (after Prompt A's fix is committed)
- [ ] **5** Measure breaks and rail shots in `references/8ball duels/clips` and my playtest clips, and compare them with `tools/BreakStats.luau`: today our break sinks about 1.8 balls against their 0.7. Propose up to 3 Config changes of 10% or less, each with before and after numbers, and change nothing until I pick. Then rerun the tests and NativeCheck and update its fingerprint (Claude)

**Part 6: lobby, panels and end screen** (steps 7c and 7d)
- [ ] **6a** Lobby row: pastel buttons with cream key tabs (Abilities Z, Invite X, Shop C, Settings V), hidden under an open panel and the end screen (Claude)
- [ ] **6b** The Abilities and Settings panels on the kit; needs 3b (Claude)
- [ ] **6c** The Shop panel on the kit, with a small code-drawn preview on each tile; needs 3b (Claude)
- [ ] **6d** End screen: a crown on the winner, a rematch score that counts up, and 6 to 8 award ribbons from a tested Rules module (Claude)

**Part 7: systems from my Crazy 8 Ball recordings** (the audit's "phase 4" picks)
- [ ] **7a** Signs above each table: "0/2" or "0/4", counting the players who have joined, with their avatars. And our own "Join table" prompt on the kit, in place of Roblox's stock one (Claude)
- [ ] **7b** Floor markings at each table, painted like a court: its mode ("1v1", "2v2") and its state ("Open", "Playing", "Full") (Claude)
- [ ] **7c** Floor chevrons that lead to the nearest open table, for anyone who hasn't joined a table after 30 seconds *(default)*. The tutorial's last step uses them once Phase 4 builds it (Claude)
- [ ] **7d** A cue in the hands of every seated player in 3D (Claude)

**Skipped for now,** since nothing in Part 4 needs them; do them after it:
- [ ] **2c** Cue: tapered and two-tone, with a cream ferrule and a dark tip, every size still from Config (Claude)
- [ ] **3b** The kit's panel pieces (panel, tab row, toggle, slider, tooltip, ribbon) and an owner-only kit sheet; Part 6's panels need them (Claude)

**Open questions from the art director,** each for its step's plan:
- 4a: keep the timer box in place while balls roll, with its digits hidden (a head shows through the gap today), and show the timer, the turn label and the F row in both views?
- 4c: empty ability squares as opaque dark tiles with a cream border, where STYLE.md says a thin outline?
- 4d: the meter's fill in mint, with one orange only for Power Shot's extra 50%?
- 7a: is "Join table" the lobby's one mint action?
- Phase 4's item effects: a cream pocket lid with an ink edge instead of gold, since gold means the called pocket?

**Earlier art-director notes,** from the GUI pass task this replaces, that these steps also cover:
- 4b: the big name fades when a pull starts.
- 4c: an opaque empty slot, a thicker picking outline with an ink ring, the bar in a dark box, something on the card showing Power Shot is still on, and Coach's blank avatar and empty squares, which read as broken images.
- 6b: a narrower Abilities panel with a bigger title, and lines of 40 characters or fewer.
- 6d: the result headline bigger, with smaller column headers, so the result reads first.

**Done when:** I've OK'd the playtest of every step we reach. Whatever the window doesn't reach stays here as Phase 4 work.

## Phase 4, Nov 16–Dec 6: the lodge, every table, the tutorial, and polish

**Goal:** it looks, sounds and feels warm and punchy, every table runs itself even when people leave, and people want to stay.

Moved up into the Fable pass, above: the final looks for the table, cue and balls, the GUI pass, the table signs, the floor markings, the floor arrows, the cue in players' hands, the lanterns and the ring at players' feet.

- [ ] Lodge blockout: `tools/BuildArena.luau` builds the room, the floor, the table spots, the lobby spawn and the counter in plain parts. The Fable pass's step 2d builds its first cut: the room, the floor and the spawn pad (Claude builds it, I adjust)
- [ ] The lodge in the `docs/STYLE.md` look: timber beams, a plank floor, seating, and a counter serving sodas, milkshakes and coffee (Claude)
- [ ] Plants and other organic props: Claude writes prompts for Studio's AI model and texture tools, I run them, and the arena builder places the results. The first thing cut if Phase 4 runs tight (Me + Claude)
- [ ] All 6 tables: `tools/BuildTable.luau` builds 3 for 1v1 and 3 for 2v2, with their seat markers, on the lodge's table spots (Claude)
- [ ] Tutorial rooms: each new player gets a private room in the same server, out of sight, with one table and Coach, that nobody else can get into; several can run at once. Skip or finishing puts them straight into the lodge and removes the room, and finishing or skipping is saved (needs my OK on saving data). Rooms make and remove tables while the server runs, so everything kept per table is cleared when its table goes: Balls' parts and resting balls, TableService's lobby and prompt, TableView's spins, ShotPose's shooter (from the Studio Assistant's review; today's fixed tables never need it). All testable in Studio (Claude)
- [ ] Tutorial steps with Coach: aiming, power, ball in hand, groups, calling the 8 and items, each with a tip card and the table set up for it, and a Skip button. Its last step follows the floor arrows to the nearest open table (Claude)
- [ ] Leaving: the leaver's seat opens on the prompt as "Take seat", and the first player to press E takes over. After 15 seconds with nobody, the other player wins a 1v1, or the teammate plays on alone in 2v2. Disconnects count as leaving, and 2 timeouts in a row removes a player (Claude)
- [ ] Item effects in the `docs/STYLE.md` look: flame trail, blast burst and ring, icy frozen balls, oil patch, pocket lids and screen shake on big hits. From the art director on 2026-11-16: the lid is a small wedge that doesn't cover the pocket and reads as an arrow, the oil patch reads as a burn hole, and ball in hand, the target preview and the frozen ball all use the same thin pale ring (Claude)
- [ ] Server size 24 and voice chat turned on (Me)
- [ ] Wire in the music and final sounds I picked in Phase 3 (Claude)
- [ ] Item balance pass: the item bar's points, blast strength, oil, item odds, all in Config. Aim for about one item every 2 turns per player. Try raising `OpponentBallPoints` to 3 for a stronger comeback, and `SinkItemsWaitForTurnEnd` if item runs get out of hand (Me + Claude)
- [ ] Analytics: joined → each tutorial step finished (or skipped) → first game started → first game finished → second game, so I can see where new players quit (Claude)
- [ ] Playtest with 4 friends: 1v1 and 2v2, with people leaving mid-game on purpose and every item used. Include Phase 2's 4-player check: 2v2 on Table2, turns go A1 → B1 → A2 → B2, and when one player leaves their teammate plays on alone (Me)
- [ ] Big playtest with as many friends as I can get, on PC (Me)

**Done when:** 4 friends play on PC for 30 minutes straight, including leaving mid-game, every item gets used and no table ever gets stuck, and big-playtest testers stay 20+ minutes without being asked, leaving me a written bug and balance list.

## Phase 5, Dec 7–11: Mobile

**Goal:** everything built so far works by touch on my phone, held sideways.

- [ ] Touch controls: bring the existing touch code (drag to aim, a touch near the cue ball to pull, the Lock button, the F button) up to date with everything built since Phase 1, and make the tutorial's tips name the touch controls on phones (Claude)
- [ ] Touch for items: tap a slot to use an item, and tap a ball, a spot on the felt or a pocket to pick a target, choosing the nearest one within a finger's reach (Claude)
- [ ] Phone HUD layout: the power meter with the Lock button beside it, the item slots, the cards with their item bars, the hints and the top bar all fit a phone held sideways, with touch targets of at least 44 px (Claude)
- [ ] Power Shot near-rail check on a phone: a 150% pull fits on screen for a cue ball against a long rail shooting straight across; if it doesn't, make the extra 50% take less pull. Recheck the 1920×1080 PC case too: it fits only just today (Claude)
- [ ] Phone pass: button sizes, readable text, 30+ fps on a mid-range phone. Part of it, from the Studio Assistant's review on 2026-11-18: build the table's `Geometry` layout once per set of table params and reuse it, instead of on every call (the aim indicator rebuilds it every frame), rebuilding when the test panel's sliders change the params (I test, Claude fixes)
- [ ] Check on my real phone: everything works by touch (Me)

**Done when:** on my real phone I take 30 shots in a row and finish a full game with items, with no bugs, at 30+ fps.

**Feature freeze Dec 11:** nothing new gets added after this date, items included.

## Phase 6, Dec 12–17: fix and launch prep

**Goal:** launch Friday, Dec 18 with no known game-breaking bugs.

- [ ] Fix the bug list, worst first, including item balance (Config numbers only, no new items) (Me + Claude)
- [ ] Turn off `Config.Debug.PhysicsTestLive` before launch, so the test mode can't run in public servers (Claude)
- [ ] Final test with friends on PC and phones (Me)
- [ ] Store page icon and 3–5 thumbnails, now that the look is frozen (Me)
- [ ] Edit 6 short videos from playtest clips (Me)
- [ ] Launch day: set the audience to Public for 16+, post the first videos, and share the link (Me)

**If a step runs long,** don't cut the fix week.

## After launch

Small updates every week, starting with fixes from launch week, and in the first week a "Watch from above" button near a table with a game on (Spectating, moved from Phase 4: until then F does it). Then these steps, in this order, each with its own tasks and "Done when" once we plan it:

1. **Parties:** a party joins a table together, and a player on their own can take an open seat with a random partner
2. **Progression:** XP that levels you up, coins, and loot crates bought with coins that give cosmetics and unlock new items; save each player's lifetime stats, and add session locking to PlayerData before any coins or XP are saved (today's save has none, a documented shortcut that's fine while it only holds settings). No purchases: monetization is still open
3. **Extras** like streaks, later

Then new items and the rest of the Later list in GAME_SPEC.md.

From the Illegal Soccer audit (`docs/audits/ILLEGAL_SOCCER.md`), for when progression and parties are planned:
- Daily rewards: a 7-day calendar with coins each day and an item on day 7, confetti on claiming, and a small toast
- A stats board in the lobby: career stats with round icons, and weekly and all-time leaderboards
- Level and coins in the top-right corner: a level card with an XP bar over a coin card
- Party slots: the lobby row shrinks to its icons and adds your avatar and "+" slots to invite into (with Parties)
- Shop odds and guaranteed drops, and bundles with guarantees, only if I decide on paid rolls (see GAME_SPEC's "Raised but not decided")
- Passes: perk tiles under colored category bars and one promo card
- Inventory: tabs per kind, an equipped preview, and the owned grid with small tags
- Redeem codes, keybinds in Settings, and an event popup with Notify me
