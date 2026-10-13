# Build plan

Launch Friday, Dec 11, 2026 with 1v1 and 2v2 pool in a 30-player bar. The shot gets built first, features freeze Dec 4, and the last week is only for fixing. This assumes about 10 hours a week from me, with Claude writing most of the code.

This file started as a copy of my "Pool! Build Plan" doc and is now the working copy: Claude ticks tasks and keeps Status current here. The label after each task says who does it. A phase ends only when I say its "Done when" test passed.

## Status

- **Current phase:** Phase 1, the shot on one table
- **In progress:** nothing. Owner-only physics test mode in the published game (`Config.Debug.PhysicsTestLive`, `Shared/PhysicsTestAccess.luau`) is built and passed lint, tests and a Studio playtest; I'll publish privately and try it in Phase 1's phone check. All shot controls are done and checked on PC and in the phone emulator.
- **Last session:** 2026-10-12. Tuned physics: RollingSlowdown 5 → 1.5 (full power now rolls about 13 table lengths), BallBounce 0.95 → 0.9, Follow 0.29 → 0.25. Built shot controls step 1 in `Client/ShotController.luau`: F toggles a high, narrow (20°) top-down camera that keeps room for the test panel and the meter, and turns off walking. Removed the test panel's C key and Top view button. Built step 2: a cue stick only you see, A/D and arrows (0.25° tap, hold turns after 0.25 s, 15 → 120°/s), and drag-to-rotate around the cue ball by mouse or touch. In the top view, clicks aim instead of shooting. Built a first step 3 (drag a meter icon back, push it forward to shoot), then replaced it with a slingshot design. Removed click-to-shoot and the Power slider. Added the placeholder-models rule and `docs/MODELS.md`, the modeler's brief.
- **Next up:** tuning the feel together on PC, then Phase 1's phone check
- **Known issues:**
  - None

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
- [x] Greybox table: 10 × 5 studs of playing surface, 16 balls, and 6 pockets about 20% wider than real (Claude builds it, I adjust)
- [x] Ball physics: our own simulation on the server for rolling, ball-to-ball hits, rail bounces and pockets, played back smoothly on every screen (Claude)
- [x] Press F to switch to the top-down view, and F again to go back (Claude)
- [x] Aim: on PC only the mouse aims (the cue follows it). On phones, drag on the table. Space (phones: a Lock button) locks and unlocks the aim; the aim indicator is see-through while aiming and solid while locked, with a hint (Claude)
- [x] Power, like a slingshot: hold the mouse button and drag (it locks the aim where it is), or press Space first to lock. Phones: while unlocked, a touch near the cue ball pulls; while locked, anywhere. Power counts from the edge of a small cancel zone around where you pressed, in any direction. The cue slides back and a display-only meter fills. Let go to shoot; let go back inside the cancel zone (the indicator turns see-through and the hint says "Let go to cancel"), right-click, Esc or a missed release cancels back to how you were; Space or Lock mid-pull cancels and unlocks. You can only aim and shoot from the top-down view: the cue and the meter only show there, and leaving the view mid-pull cancels the shot (Claude)
- [x] Aim indicator, always on: a line from the cue ball to a circle where it first touches a ball (stopping at a rail or pocket), and a short line showing where that ball goes. Two Config switches, no player setting (Claude)
- [ ] Tune the feel together: friction, power, rail bounce, pocket size (Me + Claude)
- [ ] Decide the final table size, since the modeler's brief (`docs/MODELS.md`) needs it (Me)
- [ ] Complete the age check and the Maturity & Compliance Questionnaire, so friends can test from Phase 2 (Me)
- [ ] End-of-phase check on my real phone: everything built this phase works by touch (Me)

**Done when:** I take 30 shots in a row on PC and on my phone with no bugs, and sinking a ball feels satisfying. If it doesn't, keep tuning before Phase 2.

## Phase 2, Oct 26–Nov 8: 8-ball rules and 1v1 turns

**Goal:** two players can finish a full, fair game of 8-ball.

- [ ] Rack and break: a random player places the cue ball behind the head line and breaks (Claude)
- [ ] Groups: the table stays open after the break, and the first legal pot sets solids or stripes (Claude)
- [ ] Turns: a legal pot keeps your turn; a miss passes it (Claude)
- [ ] Fouls (cue ball sunk, wrong ball hit first, nothing hit): the next player places the cue ball anywhere (Claude)
- [ ] The 8: call your pocket. Sinking it early, in the wrong pocket, or along with the cue ball loses (Claude)
- [ ] "Turn" arrow over the shooter, and a 45-second shot clock that stops while balls roll. Running out counts as a foul (Claude)
- [ ] Automatic rule tests: 25+ scenarios, like sinking the cue ball on the 8, that rerun after every change (Claude)
- [ ] Block out the bar in plain parts: walls, 8 table spots, the counter (Me)
- [ ] Find a modeler and send them `docs/MODELS.md` and my bar blockout by Nov 8, with everything due Nov 22 (Me)
- [ ] Playtest with 2 friends on a friends-only test version (Me)
- [ ] End-of-phase check on my real phone: everything built this phase works by touch (Me)

**Done when:** every rule test passes, and 2 friends finish 3 full games without me explaining anything.

## Phase 3, Nov 9–22: tables, joining, 2v2 and leaving

**Goal:** every table runs itself from joining to reset, in both modes, even when people leave.

- [ ] Platforms and "0/2" or "0/4" signs above each table (Claude)
- [ ] A 5-second countdown once every platform is filled. It resets if anyone steps off and restarts at 5 when the spot is filled again (Claude)
- [ ] 2v2 on the same table: 2 platforms per side, your side is your team, and turns go A1 → B1 → A2 → B2 (Claude)
- [ ] Spectating: watch in 3D or switch to the top-down view (Claude)
- [ ] End screen with the winner, shot accuracy, balls sunk, best run and fouls. Then everyone is removed and the table resets (Claude)
- [ ] Save each player's lifetime stats, so ranked and levels have history later (Claude)
- [ ] Leaving: the empty platform lights up, and anyone who stands on it for 5 seconds takes over. After 15 seconds with nobody, the other player wins a 1v1, or the teammate plays on alone in 2v2. Disconnects count as leaving, and 2 timeouts in a row removes a player (Claude)
- [ ] Swap in the commissioned table, platforms and cue (Claude)
- [ ] Playtest with 4 friends: 1v1 and 2v2, with people leaving mid-game on purpose (Me)
- [ ] End-of-phase check on my real phone: everything built this phase works by touch (Me)

**Done when:** 4 friends play for 30 minutes straight, including leaving mid-game, and no table ever gets stuck.

## Phase 4, Nov 23–Dec 4: the bar, social features and polish

**Goal:** it looks, sounds and feels like a cozy bar people want to stay in.

- [ ] Swap in the commissioned bar: 8 tables (4 for 1v1, 4 for 2v2), a counter serving sodas, milkshakes and coffee, seating, and warm lighting (Claude)
- [ ] Server size 30 and voice chat turned on (Me)
- [ ] Lo-fi music and sounds: ball clicks, rail thuds, pocket drops (I pick them, Claude wires them in)
- [ ] Emotes and quick phrases (Claude)
- [ ] The shooter's avatar leans over the table with the cue, so people watching in 3D see the shot (Claude)
- [ ] Phone pass: button sizes, readable text, 30+ fps on a mid-range phone (I test, Claude fixes)
- [ ] Analytics: joined → first game started → first game finished → second game (Claude)
- [ ] Store page: name, icon, 3–5 thumbnails, and a description (Me)
- [ ] Big playtest over Thanksgiving weekend, Nov 26–29, with as many friends as I can get (Me)
- [ ] End-of-phase check on my real phone: everything built this phase works by touch (Me)

**Done when:** Thanksgiving testers stay 20+ minutes without being asked, and I have a written bug list.

**Feature freeze Dec 4:** nothing new gets added after this date.

## Phase 5, Dec 5–10: fix and launch prep

**Goal:** launch Friday, Dec 11 with no known game-breaking bugs.

- [ ] Fix the bug list, worst first (Me + Claude)
- [ ] Turn off `Config.Debug.PhysicsTestLive` before launch, so the test mode can't run in public servers (Claude)
- [ ] Final test with friends on PC and phones (Me)
- [ ] Edit 6 short videos from playtest clips (Me)
- [ ] End-of-phase check on my real phone: everything built this phase works by touch (Me)
- [ ] Launch day: set the audience to Public, post the first videos, and share the link (Me)

**If my Nov 1 application eats late October,** slide Phases 2–5 back one week and launch Dec 18. Don't cut the fix week.

## After launch

Ship one themed update every Friday, starting with fixes from launch week, then work down the Later list in GAME_SPEC.md.
