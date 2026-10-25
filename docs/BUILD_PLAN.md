# Build plan

Launch Friday, Dec 11, 2026 with 1v1 and 2v2 pool and 5 items in a 30-player arena. The shot gets built first, features freeze Dec 4, and the last week is only for fixing. This assumes about 10 hours a week from me, with Claude writing most of the code and building the models. There's no commissioned modeler: the game is made entirely with AI.

This file started as a copy of my "Pool! Build Plan" doc and is now the working copy: Claude ticks tasks and keeps Status current here. The label after each task says who does it. A phase ends only when I say its "Done when" test passed.

## Status

- **Current phase:** Phase 2, 8-ball rules, 1v1 turns and earning items
- **In progress:** nothing being built. Rack and break, Groups and Turns are built and passed lint, tests and Claude's playtest; all three are waiting on my PC test, and Turns needs 2 players (Test → Clients and Servers). A game starts once both of Table1's platforms have a player (one in Studio solo), with no sign or countdown until Phase 3. Everyone in it switches to the top-down view on their own and goes back to the normal view when it ends; Claude checked that return only by sending the game-over message by hand, so the 2-player test checks it for real by having one player leave. The cue ball breaks from the middle of the head line with no ball in hand. The table stays open after the break, and the first legal pot sets the shooter's side's group. A legal pot of your own group (any ball on the break, any solid or stripe on an open table) keeps your turn; anything else passes it to the next seat. A temporary label under the name on your card reads like "Open table · Your turn" or "Solids · Their turn" until the top bar task replaces it. Until the Fouls task, a scratch gives the next player ball in hand, and a wrong first ball or nothing hit only passes the turn
- **Last session:** 2026-10-24. Claude built Turns with 8 new rule tests (64 pass). I changed the camera: players switch to the top-down view when their game starts and stay there until it ends, instead of pressing F (GAME_SPEC steps 2 and 10 updated). Each turn's message now carries the game's players, and the card got a temporary "Your turn" / "Their turn" label
- **Next up:** my PC test of rack and break, Groups and Turns, then Fouls. Phase 1's age check is still open: I'll do it when we first publish, before the friends playtest at the end of Phase 2
- **Known issues:**
  - Touch and the new HUD layout haven't been tried on a real phone yet, only in the emulator; it's covered by the Mobile phase
  - The existing touch code isn't tested or extended until the Mobile phase, so it will fall behind the PC features built before then. Ball in hand is mouse-only: on a phone the cue ball can't be moved yet
  - Lighting.Technology has to be set to Future by hand in Studio; scripts can't change it
  - In Studio solo, once a game starts on Table1 nothing ends it but stopping the playtest, and the test mode stays off until then
  - An ended game leaves the balls where they stopped; Phase 3's reset re-racks the table
  - Respawning mid-game drops you back to the normal view; press F to return
  - A player who joins mid-game hears nothing about the game until the next turn starts; Phase 3's spectating covers watchers
  - The Output warning about rbxassetid://203785492 ("Pop Close Sound") comes from a Studio plugin or Roblox, not the place: ignore it
  - The GUI needs tweaking. Leave it as it is until I say we'll get to it
  - Our break sinks about 2.0 balls with the 0.8 / 0.75 pockets (2.35 at 0.85 / 0.95) and the cue ball rebounds further than in 8 Ball Duels' break (0 sunk, cue ball near the middle); no RackGap or BreakPower setting fixed both. `tools/BreakStats.luau` compares
  - Not yet checked by me that a slider change reaches both the server and the shooter's screen (part 4 of my physics check). Claude's playtest confirmed it for the pocket sliders

## Rules that protect quality

1. **Riskiest first.** The shot is built and tuned before anything else, because every other system depends on it feeling good.
2. **Gates.** Each phase ends with something playable and a "Done when" test. Don't start the next phase until it passes.
3. **One config file.** Every tuning number lives there, so changing the feel never means rewriting code.
4. **Tested rules.** Physics and 8-ball rules are plain Luau modules with automatic tests, so a fix can't quietly break another rule.
5. **PC only until the Mobile phase.** I test every step and every "Done when" on PC. The touch code that's already there stays, but isn't tested or extended until Phase 5, the Mobile phase. Most Roblox players are on phones, so that phase makes everything work by touch before launch.
6. **Save often.** Commit to git every session, and save a place version before big changes.
7. **A Later list.** New ideas go on the Later list in GAME_SPEC.md, not into the current phase.
8. **Feature freeze Dec 4.** The last week is only for fixing.

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
- [ ] Complete the age check and the Maturity & Compliance Questionnaire, so friends can test from Phase 2 (Me)

**Done when:** I take 30 shots in a row on PC with no bugs, and sinking a ball feels satisfying. If it doesn't, keep tuning before Phase 2. **Passed 2026-10-17.**

## Phase 2, Oct 26–Nov 8: 8-ball rules, 1v1 turns and earning items

**Goal:** two players can finish a full, fair game of 8-ball, earning items and using the first 2.

- [x] Rack and break: a random player breaks from the middle of the head line; no ball in hand on the break (Claude)
- [x] Groups: the table stays open after the break, and the first legal pot sets solids or stripes (Claude)
- [x] Turns: a legal pot keeps your turn; a miss passes it (Claude)
- [ ] Fouls (cue ball sunk, wrong ball hit first, nothing hit): the next player places the cue ball anywhere (Claude)
- [ ] The 8: call your pocket. Sinking it early, in the wrong pocket, or along with the cue ball loses (Claude)
- [ ] "Turn" arrow over the shooter, and a 45-second shot clock that stops while balls roll. Running out counts as a foul (Claude)
- [ ] Top bar for two: the other player's card, a highlight on whose turn it is, the shot-clock bar under the shooter's name, and each side's balls still left to sink (Claude)
- [ ] Your group's balls pulse white briefly when your turn starts (Claude)
- [ ] Automatic rule tests: 25+ scenarios, like sinking the cue ball on the 8, that rerun after every change (Claude)
- [ ] Earning items: one item bar per player that gives a random item at 12 points: +3 at the start of your turn, +4 for each of your balls you sink, +2 for each ball the other side sinks (in 2v2, all to the opponent who shoots next). When the bar fills with both slots full, it glows and the item arrives as soon as a slot frees. The bar sits under each card's 2 slots, with a small pop like "+4" for each fill. Test-panel buttons to give myself any item (Claude)
- [ ] Using items: press 1 or 2, on your own turn, one per shot, with the item's name shown big to everyone at the table. Slot icons drawn in code. Plain placeholder looks until Phase 4 (Claude)
- [ ] Power Shot (for the rest of the turn the meter keeps filling past 100%, up to 150% at 1.5× the full pull) and Blast Ball (one shot), with Lune tests for the blast. Check that a 150% pull fits on screen for a cue ball against a long rail shooting straight across, on a 1920×1080 PC; if it doesn't, make the extra 50% take less pull. The phone check is in the Mobile phase (Claude)
- [ ] Arena blockout: `tools/BuildArena.luau` builds the walls, floor, 8 table spots and the counter in plain parts (Claude builds it, I adjust)
- [ ] Playtest with 2 friends on a friends-only test version (Me)

**Done when:** every rule and item test passes, and 2 friends finish 3 full games on PC, items included, without me explaining anything.

## Phase 3, Nov 9–22: tables, joining, 2v2, leaving and the last 3 items

**Goal:** every table runs itself from joining to reset, in both modes, even when people leave, with all 5 items.

- [ ] All 8 tables: `tools/BuildTable.luau` builds 4 for 1v1 and 4 for 2v2, with their platforms, on the arena's table spots (Claude)
- [ ] Platforms and "0/2" or "0/4" signs above each table (Claude)
- [ ] A 5-second countdown once every platform is filled. It resets if anyone steps off and restarts at 5 when the spot is filled again (Claude)
- [ ] 2v2 on the same table: 2 platforms per side, your side is your team, and turns go A1 → B1 → A2 → B2 (Claude)
- [ ] Spectating: watch in 3D or switch to the top-down view (Claude)
- [ ] End screen with the winner, shot accuracy, balls sunk, best run and fouls. Then everyone is removed and the table resets (Claude)
- [ ] Save each player's lifetime stats, so ranked and levels have history later (Claude)
- [ ] Leaving: the empty platform lights up, and anyone who stands on it for 5 seconds takes over. After 15 seconds with nobody, the other player wins a 1v1, or the teammate plays on alone in 2v2. Disconnects count as leaving, and 2 timeouts in a row removes a player (Claude)
- [ ] Freeze, Oil Slick and Pocket Block: frozen balls and pocket lids bounce balls like rails, oil patches slow balls less, and the aim indicator knows about frozen balls and lids. The lock-out rules: no freezing the 8 or a side's last group ball, no Pocket Block against a side shooting at the 8, and no side targeting the same ball or pocket two turns running. With Lune tests (Claude)
- [ ] Playtest with 4 friends: 1v1 and 2v2, with people leaving mid-game on purpose and every item used (Me)

**Done when:** 4 friends play on PC for 30 minutes straight, including leaving mid-game, every item gets used, and no table ever gets stuck.

## Phase 4, Nov 23–29: the arena, effects and polish

**Goal:** it looks, sounds and feels big and punchy, and people want to stay.

- [ ] The arena in the `docs/STYLE.md` look, built by `tools/BuildArena.luau`: timber arches and beams, a plank floor, lanterns over each table, seating, and a counter serving sodas, milkshakes and coffee (Claude)
- [ ] Plants and other organic props: Claude writes prompts for Studio's AI model and texture tools, I run them, and the arena builder places the results (Me + Claude)
- [ ] Final looks for the table, platforms, cue and balls in the `docs/STYLE.md` look, every size still from Config (Claude)
- [ ] Item effects in the `docs/STYLE.md` look: flame trail, blast burst and ring, icy frozen balls, oil patch, pocket lids, screen shake on big hits, and the ring at players' feet (Claude)
- [ ] Server size 30 and voice chat turned on (Me)
- [ ] Upbeat music and sounds: ball clicks, rail thuds, pocket drops and a sound for each item (I pick them, Claude wires them in)
- [ ] Item balance pass: the item bar's points, blast strength, oil, item odds, all in Config. Aim for about one item every 2 turns per player. Try raising `OpponentBallPoints` to 3 for a stronger comeback, and `SinkItemsWaitForTurnEnd` if item runs get out of hand (Me + Claude)
- [ ] Analytics: joined → first game started → first game finished → second game (Claude)
- [ ] Store page: name, icon, 3–5 thumbnails, and a description (Me)
- [ ] Big playtest over Thanksgiving weekend, Nov 26–29, with as many friends as I can get, on PC (Me)

**Done when:** Thanksgiving testers on PC stay 20+ minutes without being asked, and I have a written bug and balance list.

## Phase 5, Nov 30–Dec 4: Mobile

**Goal:** everything built so far works by touch on my phone, held sideways.

- [ ] Touch controls: bring the existing touch code (drag to aim, a touch near the cue ball to pull, the Lock button, the F button) up to date with everything built since Phase 1 (Claude)
- [ ] Touch for items: tap a slot to use an item, and tap a ball, a spot on the felt or a pocket to pick a target, choosing the nearest one within a finger's reach (Claude)
- [ ] Phone HUD layout: the power meter with the Lock button beside it, the item slots, the cards with their item bars, the hints and the top bar all fit a phone held sideways, with touch targets of at least 44 px (Claude)
- [ ] Power Shot near-rail check on a phone: a 150% pull fits on screen for a cue ball against a long rail shooting straight across; if it doesn't, make the extra 50% take less pull (Claude)
- [ ] Phone pass: button sizes, readable text, 30+ fps on a mid-range phone (I test, Claude fixes)
- [ ] Check on my real phone: everything works by touch (Me)

**Done when:** on my real phone I take 30 shots in a row and finish a full game with items, with no bugs, at 30+ fps.

**Feature freeze Dec 4:** nothing new gets added after this date, items included.

## Phase 6, Dec 5–10: fix and launch prep

**Goal:** launch Friday, Dec 11 with no known game-breaking bugs.

- [ ] Fix the bug list, worst first, including item balance (Config numbers only, no new items) (Me + Claude)
- [ ] Turn off `Config.Debug.PhysicsTestLive` before launch, so the test mode can't run in public servers (Claude)
- [ ] Final test with friends on PC and phones (Me)
- [ ] Edit 6 short videos from playtest clips (Me)
- [ ] Launch day: set the audience to Public, post the first videos, and share the link (Me)

**If my Nov 1 application eats late October, or the items run long,** slide Phases 2–6 back one week and launch Dec 18. Don't cut the fix week.

## After launch

Ship one themed update every Friday, starting with fixes from launch week, then new items and the rest of the Later list in GAME_SPEC.md.
