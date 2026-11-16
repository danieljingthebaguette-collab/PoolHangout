# Build plan

Launch Friday, Dec 18, 2026, with 1v1 and 2v2 pool, 5 items and a short tutorial with Coach, in one lodge room with 6 tables and 24-player servers. The shot came first, then normal tables, then items. Features freeze Dec 11, and the last week is only for fixing. This assumes about 10 hours a week from me, with Claude writing most of the code and building the models. There's no commissioned modeler: the game is made entirely with AI.

This file started as a copy of my "Pool! Build Plan" doc and is now the working copy: Claude ticks tasks and keeps Status current here. The label after each task says who does it. A step ends only when I say its "Done when" test passed.

## Status

- **Current step:** Phase 3, Items
- **In progress:** this week (Nov 11–15), before Phase 4: optimized code, mechanics that work perfectly and a style closer to Illegal Soccer, in my order: the ability squares and lobby buttons, helpers, the health fixes from the Nov 11 report, audits of Crazy 8 Ball and Illegal Soccer, then the features and style pass I pick from them, a mechanics check and my friends playtest. Every Claude task in Phase 3 is built. Players see "Abilities", never "items". The test panel, Give buttons and Coach stay owner-only on a published server. Left in Phase 3 is mine: the store page's name and description, the music and sound picks, the age check, publishing, then the friends playtest. After it: Phase 4, with the item balance pass and the tutorial's items step waiting for what my friends find. Phase 2's 2-player and 4-player checks are in the Phase 3 and Phase 4 friend playtests
- **Dates:** launch moved to Friday, Dec 18 when the plan was reordered. Phase 4 starts Monday, Nov 16. The phase dates are Claude's proposal for that launch
- **Last session:** 2026-11-12. This week's steps 1–6 and 8:
  - **Steps 1–3:** the ability squares and lobby row; helpers (a physics timer, contact sheets, a code-review subagent); five health fixes with before and after numbers.
  - **Steps 4–5:** both audits, with Illegal Soccer's measured spec in STYLE.md and `Theme.Kit`.
  - **Step 6:** the audit callouts, the clock pulse, the F reminder, the target preview, settings with saving, a mock shop, the camera check.
  - **Step 8:** the mechanics check (flow tests, full 1v1 and 2v2 games against Coach).
  - **Also:** native physics, twice as fast.
- **Next up:** step 7, the style pass on the UI kit, once interactions.mov is recorded. Then my Phase 3 jobs (store page, music and sounds, the age check, publishing the friends version) and the friends playtest
- **Known issues:**
  - Touch and the new HUD layout haven't been tried on a real phone yet, only in the emulator; it's covered by the Mobile phase
  - The existing touch code isn't tested or extended until the Mobile phase, so it will fall behind the PC features built before then. Ball in hand is mouse-only: on a phone the cue ball can't be moved yet
  - Lighting.Technology has to be set to Future by hand in Studio; scripts can't change it
  - Leaving the server mid-game ends the game with no winner (the table re-racks), until the arena step's takeover rules
  - In Studio solo you're always side A, so sinking the 8 early reads "Player1 loses: …" rather than naming a winner
  - In 2v2, two long names don't fit on one card and the second is cut to "…"; the avatars still show both
  - A card's ball icons change when the next turn starts, about a quarter second after the balls stop, not the moment a ball drops; the tray fills as they drop
  - The Output warning about rbxassetid://203785492 ("Pop Close Sound") comes from a Studio plugin or Roblox, not the place: ignore it
  - The GUI needs tweaking. Leave it as it is until I say we'll get to it
  - Coach's avatar on the top bar is an empty dark square, since a bot has no avatar picture
  - Our break sinks about 1.8 balls (`tools/BreakStats.luau`), against 0.7 in the 3 full-power 8 Ball Duels breaks recorded so far. Since the 2026-11-04 tuning it spreads the rack and brings the cue ball back like theirs; more recorded breaks would show whether the count really differs
  - Coach ignores items: it never uses one, and it still plays pots on frozen balls and doesn't allow for oil. It does avoid blocked pockets. Fine for testing; the tutorial's item step scripts its own
  - The item effects' looks (frozen ring, oil patch, lids), the item slots and the big name are placeholders: the effects get their final look in Phase 4's item-effects task, the UI in the GUI pass
  - Settings only save in a published game, or in Studio with Game Settings → Security → Enable Studio Access to API Services on. Without it they apply for the session and the page says so
  - The Screen shake setting has nothing to switch until screen shake is built in Phase 4
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

## Phase 3, Nov 8–15: Items (current)

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

## Phase 4, Nov 16–Dec 6: the lodge, every table, the tutorial, and polish

**Goal:** it looks, sounds and feels warm and punchy, every table runs itself even when people leave, and people want to stay.

- [ ] Lodge blockout: `tools/BuildArena.luau` builds the room, the floor, the table spots, the lobby spawn and the counter in plain parts (Claude builds it, I adjust)
- [ ] The lodge in the `docs/STYLE.md` look: timber beams, a plank floor, lanterns over each table, seating, and a counter serving sodas, milkshakes and coffee (Claude)
- [ ] Plants and other organic props: Claude writes prompts for Studio's AI model and texture tools, I run them, and the arena builder places the results. The first thing cut if Phase 4 runs tight (Me + Claude)
- [ ] All 6 tables: `tools/BuildTable.luau` builds 3 for 1v1 and 3 for 2v2, with their seat markers, on the lodge's table spots (Claude)
- [ ] Tutorial rooms: each new player gets a private room in the same server, out of sight, with one table and Coach, that nobody else can get into; several can run at once. Skip or finishing puts them straight into the lodge and removes the room, and finishing or skipping is saved (needs my OK on saving data). All testable in Studio (Claude)
- [ ] Tutorial steps with Coach: aiming, power, ball in hand, groups, calling the 8 and items, each with a tip card and the table set up for it, and a Skip button (Claude)
- [ ] "0/2" or "0/4" signs above each table, counting the players who have joined, with the avatars of the players at it (Claude)
- [ ] Floor markings at each table, painted like a court: its mode ("1v1", "2v2") and its state ("Open", "Playing", "Full") (Claude)
- [ ] Floor arrows that lead a new player to the nearest open table: the tutorial's last step, then anyone who hasn't joined a table after 30 seconds *(default)* (Claude)
- [ ] A cue in the hands of every seated player in 3D (Claude)
- [ ] Leaving: the leaver's seat opens on the prompt as "Take seat", and the first player to press E takes over. After 15 seconds with nobody, the other player wins a 1v1, or the teammate plays on alone in 2v2. Disconnects count as leaving, and 2 timeouts in a row removes a player (Claude)
- [ ] Final looks for the table, cue and the stylized balls with icons, in the `docs/STYLE.md` look, every size still from Config (Claude)
- [ ] Item effects in the `docs/STYLE.md` look: flame trail, blast burst and ring, icy frozen balls, oil patch, pocket lids, screen shake on big hits, and the ring at players' feet (Claude)
- [ ] Server size 24 and voice chat turned on (Me)
- [ ] Wire in the music and final sounds I picked in Phase 3 (Claude)
- [ ] Item balance pass: the item bar's points, blast strength, oil, item odds, all in Config. Aim for about one item every 2 turns per player. Try raising `OpponentBallPoints` to 3 for a stronger comeback, and `SinkItemsWaitForTurnEnd` if item runs get out of hand (Me + Claude)
- [ ] Analytics: joined → each tutorial step finished (or skipped) → first game started → first game finished → second game, so I can see where new players quit (Claude)
- [ ] GUI pass, as I direct it: this week's step 7 style pass does it on the UI kit (`docs/STYLE.md`), and also adds a big "FOUL!" headline over the foul's reason, a flash when the meter reaches full power, the user's avatar on the big ability name, and a crown on the winner with a running rematch score on the end screen. Starting with the art director's end-screen fix: the headline in the display font and bigger, with smaller column headers, so the result reads first. Its item-UI notes from 2026-11-08 wait here too: a Pocket Block icon that doesn't read as a "no entry" sign, an Oil Slick icon that shows on a dark slot, the big item name off the felt (top center), the card strips inside the card's empty end, and an opaque empty slot. And from the 2026-11-08 Abilities review: the big name smaller and right under the top bar, fading when a pull starts; a thicker picking outline with an ink ring on bigger slot squares; the Abilities button in full gold with a gap above it, a narrower panel and a bigger title; and something on the card showing Power Shot is still on. And from the ability-rows review: each card's slots and bar on a dark tab joined to the card's bottom edge, with a taller bar; the rows a fixed width with shorter lines, centered; and Coach's blank avatar and empty squares, which read as broken images. And from the always-on rows review: other players' slots and bar inside their card rather than hanging below it, a taller bar in a dark box, lines of 40 characters or fewer, and maybe a thin cream outline on an empty slot (Claude)
- [ ] Playtest with 4 friends: 1v1 and 2v2, with people leaving mid-game on purpose and every item used. Include Phase 2's 4-player check: 2v2 on Table2, turns go A1 → B1 → A2 → B2, and when one player leaves their teammate plays on alone (Me)
- [ ] Big playtest with as many friends as I can get, on PC (Me)

**Done when:** 4 friends play on PC for 30 minutes straight, including leaving mid-game, every item gets used and no table ever gets stuck, and big-playtest testers stay 20+ minutes without being asked, leaving me a written bug and balance list.

## Phase 5, Dec 7–11: Mobile

**Goal:** everything built so far works by touch on my phone, held sideways.

- [ ] Touch controls: bring the existing touch code (drag to aim, a touch near the cue ball to pull, the Lock button, the F button) up to date with everything built since Phase 1, and make the tutorial's tips name the touch controls on phones (Claude)
- [ ] Touch for items: tap a slot to use an item, and tap a ball, a spot on the felt or a pocket to pick a target, choosing the nearest one within a finger's reach (Claude)
- [ ] Phone HUD layout: the power meter with the Lock button beside it, the item slots, the cards with their item bars, the hints and the top bar all fit a phone held sideways, with touch targets of at least 44 px (Claude)
- [ ] Power Shot near-rail check on a phone: a 150% pull fits on screen for a cue ball against a long rail shooting straight across; if it doesn't, make the extra 50% take less pull. Recheck the 1920×1080 PC case too: it fits only just today (Claude)
- [ ] Phone pass: button sizes, readable text, 30+ fps on a mid-range phone (I test, Claude fixes)
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
2. **Progression:** XP that levels you up, coins, and loot crates bought with coins that give cosmetics and unlock new items; save each player's lifetime stats. No purchases: monetization is still open
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
