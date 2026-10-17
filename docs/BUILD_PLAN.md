# Build plan

Launch Friday, Dec 11, 2026 with 1v1 and 2v2 pool and 5 items in a 30-player arena. The shot gets built first, features freeze Dec 4, and the last week is only for fixing. This assumes about 10 hours a week from me, with Claude writing most of the code and building the models. There's no commissioned modeler: the game is made entirely with AI.

This file started as a copy of my "Pool! Build Plan" doc and is now the working copy: Claude ticks tasks and keeps Status current here. The label after each task says who does it. A phase ends only when I say its "Done when" test passed.

## Status

- **Current phase:** Phase 1, the shot on one table
- **In progress:** nothing being built. The item design and the switch to models Claude builds are in the docs and committed. Waiting on my PC test: the 8 Ball Duels physics with a 3× break, the new art direction (`docs/STYLE.md`) on the lighting, test table, floor and HUD, the 8 Ball Duels aim indicator (center dot, white and yellow lines, dark outlines), and the 8 Ball Duels pull (free cursor, power straight back from where I pressed, full power 6 studs past the cancel zone, with a slider). STYLE.md's timer and item slots come in Phase 2; its effects, player ring and lodge in Phase 4.
- **Last session:** 2026-10-16. Matched the physics to my 8 Ball Duels measurements (FullPowerSpeed 25, BreakPower 3, RollingSlowdown 1.84, RailBounce 0.73, BallBounce 0.94, Follow 0, PowerCurve 1.45, sub-steps for fast balls, optional SpeedDrag). Moved to the new art direction in `docs/STYLE.md`: warm golden lighting, a matte painted table on a plank floor, a cream-card HUD. Rebuilt the aim indicator and the pull to work like 8 Ball Duels. Wrote the item design (with my lock-out rules) and the switch to models Claude builds into every doc, ARCHITECTURE.md included. On 2026-10-17, replaced item boxes with earned items, then the earning rules with one item bar per player, in every doc.
- **Next up:** my PC test of the Phase 1 work (restart the playtest first, so it runs the new code), then Phase 1's age check (answering the questionnaire for the item version) and phone check
- **Known issues:**
  - Touch and the new HUD layout haven't been tried on a real phone yet, only in the emulator; it's covered by Phase 1's phone check
  - Lighting.Technology has to be set to Future by hand in Studio; scripts can't change it
  - Three code comments still mention commissioned models (`Config.luau`, `BuildTable.luau`, `PhysicsTest.luau`); fix them the next time those files change
  - The GUI needs tweaking. Leave it as it is until I say we'll get to it
  - Our break sinks about 2.5 balls and the cue ball rebounds further than in 8 Ball Duels' break (0 sunk, cue ball near the middle); no RackGap or BreakPower setting fixed both. `tools/BreakStats.luau` compares
  - Not yet checked that a slider change reaches both the server and the shooter's screen (part 4 of my physics check)

## Rules that protect quality

1. **Riskiest first.** The shot is built and tuned before anything else, because every other system depends on it feeling good.
2. **Gates.** Each phase ends with something playable and a "Done when" test. Don't start the next phase until it passes.
3. **One config file.** Every tuning number lives there, so changing the feel never means rewriting code.
4. **Tested rules.** Physics and 8-ball rules are plain Luau modules with automatic tests, so a fix can't quietly break another rule.
5. **PC every step, my phone every phase.** I test each step on PC. Most Roblox players are on phones, so every feature works by touch as it's built, kept simple, and I test on my real phone once at the end of each phase.
6. **Save often.** Commit to git every session, and save a place version before big changes.
7. **A Later list.** New ideas go on the Later list in GAME_SPEC.md, not into the current phase.
8. **Feature freeze Dec 4.** The last week is only for fixing.

## Phase 1, Oct 12–25: the shot on one table

**Goal:** one table where sinking a ball feels great on PC and on my phone.

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
- [ ] End-of-phase check on my real phone: everything built this phase works by touch (Me)

**Done when:** I take 30 shots in a row on PC and on my phone with no bugs, and sinking a ball feels satisfying. If it doesn't, keep tuning before Phase 2.

## Phase 2, Oct 26–Nov 8: 8-ball rules, 1v1 turns and earning items

**Goal:** two players can finish a full, fair game of 8-ball, earning items and using the first 2.

- [ ] Rack and break: a random player places the cue ball behind the head line and breaks (Claude)
- [ ] Groups: the table stays open after the break, and the first legal pot sets solids or stripes (Claude)
- [ ] Turns: a legal pot keeps your turn; a miss passes it (Claude)
- [ ] Fouls (cue ball sunk, wrong ball hit first, nothing hit): the next player places the cue ball anywhere (Claude)
- [ ] The 8: call your pocket. Sinking it early, in the wrong pocket, or along with the cue ball loses (Claude)
- [ ] "Turn" arrow over the shooter, and a 45-second shot clock that stops while balls roll. Running out counts as a foul (Claude)
- [ ] Top bar for two: the other player's card, a highlight on whose turn it is, the shot-clock bar under the shooter's name, and each side's balls still left to sink (Claude)
- [ ] Your group's balls pulse white briefly when your turn starts (Claude)
- [ ] Automatic rule tests: 25+ scenarios, like sinking the cue ball on the 8, that rerun after every change (Claude)
- [ ] Earning items: one item bar per player that gives a random item at 12 points: +3 at the start of your turn, +4 for each of your balls you sink, +2 for each ball the other side sinks (split +1 each in 2v2). When the bar fills with both slots full, it glows and the item arrives as soon as a slot frees. The bar sits under each card's 2 slots, with a small pop like "+4" for each fill. Test-panel buttons to give myself any item (Claude)
- [ ] Using items: press 1 or 2 (phones: tap the slot), on your own turn, one per shot, with the item's name shown big to everyone at the table. Slot icons drawn in code. Plain placeholder looks until Phase 4 (Claude)
- [ ] Power Shot (lasts the whole turn) and Blast Ball (one shot), with Lune tests for the blast (Claude)
- [ ] Arena blockout: `tools/BuildArena.luau` builds the walls, floor, 8 table spots and the counter in plain parts (Claude builds it, I adjust)
- [ ] Playtest with 2 friends on a friends-only test version (Me)
- [ ] End-of-phase check on my real phone: everything built this phase works by touch (Me)

**Done when:** every rule and item test passes, and 2 friends finish 3 full games, items included, without me explaining anything.

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
- [ ] Freeze, Oil Slick and Pocket Block: frozen balls and pocket lids bounce balls like rails, oil patches slow balls less, and the aim indicator knows about frozen balls and lids. The lock-out rules: no freezing the 8, no Pocket Block against a side shooting at the 8, and no side targeting the same ball or pocket two turns running. With Lune tests (Claude)
- [ ] Playtest with 4 friends: 1v1 and 2v2, with people leaving mid-game on purpose and every item used (Me)
- [ ] End-of-phase check on my real phone: everything built this phase works by touch (Me)

**Done when:** 4 friends play for 30 minutes straight, including leaving mid-game, every item gets used, and no table ever gets stuck.

## Phase 4, Nov 23–Dec 4: the arena, effects and polish

**Goal:** it looks, sounds and feels big and punchy, and people want to stay.

- [ ] The arena in the `docs/STYLE.md` look, built by `tools/BuildArena.luau`: timber arches and beams, a plank floor, lanterns over each table, seating, and a counter serving sodas, milkshakes and coffee (Claude)
- [ ] Plants and other organic props: Claude writes prompts for Studio's AI model and texture tools, I run them, and the arena builder places the results (Me + Claude)
- [ ] Final looks for the table, platforms, cue and balls in the `docs/STYLE.md` look, every size still from Config (Claude)
- [ ] Item effects in the `docs/STYLE.md` look: flame trail, blast burst and ring, icy frozen balls, oil patch, pocket lids, screen shake on big hits, and the ring at players' feet (Claude)
- [ ] Server size 30 and voice chat turned on (Me)
- [ ] Upbeat music and sounds: ball clicks, rail thuds, pocket drops and a sound for each item (I pick them, Claude wires them in)
- [ ] Item balance pass: the item bar's points, blast strength, oil, item odds, all in Config. Try raising `OpponentBallPoints` to 3 for a stronger comeback (Me + Claude)
- [ ] Phone pass: button sizes, readable text, 30+ fps on a mid-range phone (I test, Claude fixes)
- [ ] Analytics: joined → first game started → first game finished → second game (Claude)
- [ ] Store page: name, icon, 3–5 thumbnails, and a description (Me)
- [ ] Big playtest over Thanksgiving weekend, Nov 26–29, with as many friends as I can get (Me)
- [ ] End-of-phase check on my real phone: everything built this phase works by touch (Me)

**Done when:** Thanksgiving testers stay 20+ minutes without being asked, and I have a written bug and balance list.

**Feature freeze Dec 4:** nothing new gets added after this date, items included.

## Phase 5, Dec 5–10: fix and launch prep

**Goal:** launch Friday, Dec 11 with no known game-breaking bugs.

- [ ] Fix the bug list, worst first, including item balance (Config numbers only, no new items) (Me + Claude)
- [ ] Turn off `Config.Debug.PhysicsTestLive` before launch, so the test mode can't run in public servers (Claude)
- [ ] Final test with friends on PC and phones (Me)
- [ ] Edit 6 short videos from playtest clips (Me)
- [ ] End-of-phase check on my real phone: everything built this phase works by touch (Me)
- [ ] Launch day: set the audience to Public, post the first videos, and share the link (Me)

**If my Nov 1 application eats late October, or the items run long,** slide Phases 2–5 back one week and launch Dec 18. Don't cut the fix week.

## After launch

Ship one themed update every Friday, starting with fixes from launch week, then new items and the rest of the Later list in GAME_SPEC.md.
