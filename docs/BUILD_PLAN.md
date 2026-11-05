# Build plan

Launch Friday, Dec 18, 2026, with 1v1 and 2v2 pool, 5 items and a simple tutorial, in one lodge room with 6 tables and 24-player servers. The shot came first, then normal tables, then items. Features freeze Dec 11, and the last week is only for fixing. This assumes about 10 hours a week from me, with Claude writing most of the code and building the models. There's no commissioned modeler: the game is made entirely with AI.

This file started as a copy of my "Pool! Build Plan" doc and is now the working copy: Claude ticks tasks and keeps Status current here. The label after each task says who does it. A step ends only when I say its "Done when" test passed.

## Status

- **Current step:** Phase 2, Normal tables
- **In progress:** the Claude docs and tools are set up and committed: the docs (BUILD_PLAN, GAME_SPEC, VISION, STYLE, references/), the art-director and style-builder subagents, and a hook that runs lint and tests after any turn that changed code. The join task (join with E, the Leave button, the automatic camera, and the camera turning to face the table from behind your seat) passed Claude's solo playtest on 2026-11-04 and is committed as a checkpoint; it waits for my 2-player test. Table1's seat markers are saved in the place, and the game is R6. On 2026-11-04 the physics was tuned from new 8 Ball Duels recordings: the break at 2.5× power, a nearly tight rack, a softest shot that still rolls about half the table, and 8 Ball Duels' ball and pocket sizes
- **Dates:** launch moved to Friday, Dec 18 when the plan was reordered. The phase dates are Claude's proposal for that launch
- **Last session:** 2026-11-03. New CLAUDE.md, R6 avatars only, and the plan reordered: normal tables, then items, then the lodge with a simple tutorial, Mobile and launch on Dec 18, with parties and progression as the first updates after launch and extras later. Then the Claude setup: the docs, two subagents for visual work and the lint-and-test hook
- **Next up:** my 2-player test of the join task, then Claude's health pass (type check, TableFlow module, whole-game tests, Hud and ShotController split, small known-issue fixes, items-readiness notes), then live aim for everyone at the table. Phase 1's age check is still open: I'll do it when we first publish, before the friends playtest in the Items step
- **Known issues:**
  - Touch and the new HUD layout haven't been tried on a real phone yet, only in the emulator; it's covered by the Mobile phase
  - The existing touch code isn't tested or extended until the Mobile phase, so it will fall behind the PC features built before then. Ball in hand is mouse-only: on a phone the cue ball can't be moved yet
  - Lighting.Technology has to be set to Future by hand in Studio; scripts can't change it
  - Leaving the server mid-game ends the game with no winner and leaves the balls where they stopped, until the arena step's takeover rules
  - In Studio solo you're always side A, so sinking the 8 early reads "Player1 loses: …" rather than naming a winner
  - In 2v2, two long names don't fit on one card and the second is cut to "…"; the avatars still show both
  - A card's ball icons change when the next turn starts, about a quarter second after the balls stop, not the moment a ball drops; the tray fills as they drop
  - Respawning mid-game drops you back to the normal view until your next turn starts
  - A player who joins mid-game hears nothing about the game until the next turn starts; spectating covers watchers
  - The Output warning about rbxassetid://203785492 ("Pop Close Sound") comes from a Studio plugin or Roblox, not the place: ignore it
  - The GUI needs tweaking. Leave it as it is until I say we'll get to it
  - Our break sinks about 1.8 balls (`tools/BreakStats.luau`), against 0.7 in the 3 full-power 8 Ball Duels breaks recorded so far. Since the 2026-11-04 tuning it spreads the rack and brings the cue ball back like theirs; more recorded breaks would show whether the count really differs
  - Not yet checked by me that a slider change reaches both the server and the shooter's screen (part 4 of my physics check). Claude's playtest confirmed it for the pocket sliders

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
- [ ] Complete the age check and the Maturity & Compliance Questionnaire, so friends can test in the Items step (Me)

**Done when:** I take 30 shots in a row on PC with no bugs, and sinking a ball feels satisfying. If it doesn't, keep tuning before Phase 2. **Passed 2026-10-17.**

## Phase 2, Nov 3–15: Normal tables (current)

**Goal:** a normal game of 8-ball works from joining to the end screen, in 1v1 and 2v2, and feels good, before any items.

- [x] Rack and break: a random player breaks from the middle of the head line; no ball in hand on the break (Claude)
- [x] Groups: the table stays open after the break, and the first legal pot sets solids or stripes (Claude)
- [x] Turns: a legal pot keeps your turn; a miss passes it (Claude)
- [x] Fouls (cue ball sunk, wrong ball hit first, nothing hit): the next player places the cue ball anywhere (Claude)
- [x] The 8: call your pocket. Sinking it early, in the wrong pocket, or along with the cue ball loses (Claude)
- [x] Top bar for two: the other player's card, a highlight on whose turn it is, and each side's balls still left to sink, with room in the middle for the shot clock (Claude)
- [x] Automatic rule tests: 25+ scenarios, like sinking the cue ball on the 8, that rerun after every change (Claude)
- [ ] Join Table1 with a "Join table" prompt instead of platforms: E only joins (side A, then B), a 3-second "Starting..." banner once every seat is taken, then each player is moved once to their seat facing the table, with their camera behind them, free to walk. "Table in use" during a game, and it opens again when the game ends. The table builder makes invisible seat markers where the platforms were. A coral Leave button top right in both views: off the table while waiting, calls off the 3-second start, and mid-game asks "Leave and lose this game?" (in 2v2 the teammate plays on). Camera: your turn switches you to the top-down view, and your turn passing switches you back to third person; F switches any time (Claude)
- [ ] Live aim for everyone at the table, after the health pass. Anyone in the top-down view, not just the shooter, sees the shooter's cue and aim indicator move live: the aim line, the circle, both direction lines, the called-pocket ring, and the cue sliding back during a pull. The updates are display-only and smoothed, so a slow connection never affects the shot. (Claude)
- [ ] 2v2 on one table: Table2, built as a 2v2 table with A1 and A2 on one long side and B1 and B2 on the other. Your side is your team, teammates share a group, and turns go A1 → B1 → A2 → B2 (Claude)
- [ ] "Turn" arrow over the shooter, and a 45-second shot clock in the middle of the top bar that stops while balls roll. Running out is a foul, with ball in hand for the next shooter (Claude)
- [ ] End screen: the winner and each player's stats, with Rematch and the other options in GAME_SPEC, then back to the lobby (Claude)
- [ ] Sounds and hit effects: hit, rail and pocket sounds, and small chunky sparks on hard hits, in `docs/STYLE.md`'s timings. The free placeholder sounds stay until I pick final ones (Claude; I pick the sounds)
- [ ] R6 shot pose: while you aim, your character moves around the table edge to stand behind the cue ball in a ready-to-shoot pose (Claude)
- [ ] Your group's balls pulse white briefly when your turn starts (Claude)
- [ ] 2-player test of the whole step: 1v1 on Table1 and 2v2 on Table2 (Me)

**Done when:**
1. Join with E, Leave and the automatic top-down camera pass a 2-player test.
2. 1v1 and 2v2 seats and turn order work.
3. A 45-second shot clock, where running out is a foul with ball in hand.
4. The end screen sends players to the lobby, with a Rematch button.
5. Hit and pocket sounds, small hit effects, and an R6 shot pose.
6. Everyone in the top-down view sees the shooter's cue and aim indicator move live.

## Phase 3, Nov 16–29: Items

**Goal:** players earn the 5 items during a game and use them, and games stay fair.

- [ ] Earning items: one item bar per player that gives a random item at 12 points: +3 at the start of your turn, +4 for each of your balls you sink, +2 for each ball the other side sinks (in 2v2, all to the opponent who shoots next). When the bar fills with both slots full, it glows and the item arrives as soon as a slot frees. The bar sits under each card's 2 slots, with a small pop like "+4" for each fill. Test-panel buttons to give myself any item (Claude)
- [ ] Using items: press 1 or 2, on your own turn, one per shot, with the item's name shown big to everyone at the table. Slot icons drawn in code. Plain placeholder looks until the arena step (Claude)
- [ ] Power Shot (for the rest of the turn the meter keeps filling past 100%, up to 150% at 1.5× the full pull) and Blast Ball (one shot), with Lune tests for the blast. Check that a 150% pull fits on screen for a cue ball against a long rail shooting straight across, on a 1920×1080 PC; if it doesn't, make the extra 50% take less pull. The phone check is in the Mobile phase (Claude)
- [ ] Freeze, Oil Slick and Pocket Block: frozen balls and pocket lids bounce balls like rails, oil patches slow balls less, and the aim indicator knows about frozen balls and lids. The lock-out rules: no freezing the 8 or a side's last group ball, no Pocket Block against a side shooting at the 8, and no side targeting the same ball or pocket two turns running. With Lune tests (Claude)
- [ ] Playtest with 2 friends on a friends-only test version (Me)

**Done when:** every rule and item test passes, and 2 friends finish 3 full games on PC, items included, without me explaining anything.

## Phase 4, Nov 30–Dec 6: the lodge, every table, a simple tutorial, and polish

**Goal:** it looks, sounds and feels warm and punchy, every table runs itself even when people leave, and people want to stay.

- [ ] Lodge blockout: `tools/BuildArena.luau` builds the room, the floor, the table spots, the lobby spawn and the counter in plain parts (Claude builds it, I adjust)
- [ ] The lodge in the `docs/STYLE.md` look: timber beams, a plank floor, lanterns over each table, seating, and a counter serving sodas, milkshakes and coffee (Claude)
- [ ] Plants and other organic props: Claude writes prompts for Studio's AI model and texture tools, I run them, and the arena builder places the results (Me + Claude)
- [ ] All 6 tables: `tools/BuildTable.luau` builds 3 for 1v1 and 3 for 2v2, with their seat markers, on the lodge's table spots (Claude)
- [ ] Simple tutorial: on-screen tips during a player's first match, covering aiming, power, ball in hand, groups and the 8, and items as each first comes up (Claude)
- [ ] "0/2" or "0/4" signs above each table, counting the players who have joined (Claude)
- [ ] Spectating: watch in 3D or switch to the top-down view (Claude)
- [ ] Leaving: the leaver's seat opens on the prompt as "Take seat", and the first player to press E takes over. After 15 seconds with nobody, the other player wins a 1v1, or the teammate plays on alone in 2v2. Disconnects count as leaving, and 2 timeouts in a row removes a player (Claude)
- [ ] Final looks for the table, cue and the stylized balls with icons, in the `docs/STYLE.md` look, every size still from Config (Claude)
- [ ] Item effects in the `docs/STYLE.md` look: flame trail, blast burst and ring, icy frozen balls, oil patch, pocket lids, screen shake on big hits, and the ring at players' feet (Claude)
- [ ] Server size 24 and voice chat turned on (Me)
- [ ] Upbeat music and final sounds: ball clicks, rail thuds, pocket drops and a sound for each item (I pick them, Claude wires them in)
- [ ] Item balance pass: the item bar's points, blast strength, oil, item odds, all in Config. Aim for about one item every 2 turns per player. Try raising `OpponentBallPoints` to 3 for a stronger comeback, and `SinkItemsWaitForTurnEnd` if item runs get out of hand (Me + Claude)
- [ ] Analytics: joined → first game started → first game finished → second game (Claude)
- [ ] Store page: name, icon, 3–5 thumbnails, and a description (Me)
- [ ] Playtest with 4 friends: 1v1 and 2v2, with people leaving mid-game on purpose and every item used (Me)
- [ ] Big playtest with as many friends as I can get, on PC (Me)

**Done when:** 4 friends play on PC for 30 minutes straight, including leaving mid-game, every item gets used and no table ever gets stuck, and big-playtest testers stay 20+ minutes without being asked, leaving me a written bug and balance list.

## Phase 5, Dec 7–11: Mobile

**Goal:** everything built so far works by touch on my phone, held sideways.

- [ ] Touch controls: bring the existing touch code (drag to aim, a touch near the cue ball to pull, the Lock button, the F button) up to date with everything built since Phase 1, and make the first-match tips name the touch controls on phones (Claude)
- [ ] Touch for items: tap a slot to use an item, and tap a ball, a spot on the felt or a pocket to pick a target, choosing the nearest one within a finger's reach (Claude)
- [ ] Phone HUD layout: the power meter with the Lock button beside it, the item slots, the cards with their item bars, the hints and the top bar all fit a phone held sideways, with touch targets of at least 44 px (Claude)
- [ ] Power Shot near-rail check on a phone: a 150% pull fits on screen for a cue ball against a long rail shooting straight across; if it doesn't, make the extra 50% take less pull (Claude)
- [ ] Phone pass: button sizes, readable text, 30+ fps on a mid-range phone (I test, Claude fixes)
- [ ] Check on my real phone: everything works by touch (Me)

**Done when:** on my real phone I take 30 shots in a row and finish a full game with items, with no bugs, at 30+ fps.

**Feature freeze Dec 11:** nothing new gets added after this date, items included.

## Phase 6, Dec 12–17: fix and launch prep

**Goal:** launch Friday, Dec 18 with no known game-breaking bugs.

- [ ] Fix the bug list, worst first, including item balance (Config numbers only, no new items) (Me + Claude)
- [ ] Turn off `Config.Debug.PhysicsTestLive` before launch, so the test mode can't run in public servers (Claude)
- [ ] Final test with friends on PC and phones (Me)
- [ ] Edit 6 short videos from playtest clips (Me)
- [ ] Launch day: set the audience to Public for 16+, post the first videos, and share the link (Me)

**If a step runs long,** don't cut the fix week.

## After launch

Small updates every week, starting with fixes from launch week. Then these steps, in this order, each with its own tasks and "Done when" once we plan it:

1. **Parties:** a party joins a table together, and a player on their own can take an open seat with a random partner
2. **Progression:** XP that levels you up, coins, and loot crates bought with coins that give cosmetics and unlock new items; save each player's lifetime stats. No purchases: monetization is still open
3. **Extras** like streaks, later

Then new items and the rest of the Later list in GAME_SPEC.md.
