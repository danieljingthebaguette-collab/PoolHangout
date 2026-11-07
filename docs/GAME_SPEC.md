# Game spec

How the game works. Written 2026-10-11 from my design chats with Claude. Updated 2026-10-16 for the intense, item-based direction, 2026-10-24 for the full 8-ball rules, and 2026-11-03 for players, parties, progression and money.

Markers: no marker = decided by me. *(default)* = Claude's proposal I haven't confirmed; build it this way unless I say otherwise. Every number is a starting value in `Config.luau`, tuned by feel.

## The game

An intense, item-based pool game: 8-ball, 1v1 or 2v2, at tables in a big, warm wooden arena. Each player's item bar fills as they take turns and as balls drop, theirs or the other side's, and gives a gadget each time it's full. They use them before a shot. Items bend the physics but never the rules. Between turns players walk around and talk on voice chat. How it looks is in `docs/STYLE.md`, in the spirit of Illegal Soccer's style only. The heart of it is still the shot: a top-down view, the cue following your mouse (or your finger on phones), an aim lock, and a slingshot pull for power. Mechanics come first. 8-ball only, 1v1 and 2v2 only for now, and a game lasts 3–5 minutes. Progression comes after items (see Progression and money), and nothing is for sale. After launch, small updates every week.

## Audience and platform

- Players are 10–15, maybe a little older. Launch for 16+ first, and open it to all ages later (tentative).
- Chat: proximity voice chat, fading with distance so each table has its own conversation, and normal Roblox text chat. Roblox only offers voice chat to players 13 and over who pass its age check. Text chat also needs an age check, and only works between players in nearby age groups, so not every player can chat with every other.
- No alcohol anywhere: names, models, decals, menus. Showing alcohol makes a game Restricted (ID-verified 18+ only). The counter serves sodas, milkshakes and coffee.
- No guns or weapons: items are gadgets.
- PC and phones. Phones play in landscape, and every feature must work by touch.
- R6 avatars only: the game's avatar type is set to R6, so every character uses the same classic rig.

## The arena

- 24 players per server and 6 tables in one lodge room: 3 for 1v1 and 3 for 2v2 *(default split)*. Both kinds are the same size.
- One cozy lodge room, as `docs/STYLE.md` describes: timber beams, plank floors, plants, and lanterns throwing warm light over each table. Players arrive in the lobby: the room's spawn area *(default)*.
- A counter serving sodas, milkshakes and coffee, and places to sit.
- Upbeat music and punchy sounds: I pick them.
- Tables in green felt and painted warm wood: dark green cushions, slim rails with white diamonds, and black pockets.
- The game is made entirely with AI, models included; there's no modeler. Claude builds every model from parts with scripts, and writes prompts for Studio's AI model and texture tools for the shapes parts can't do well, like plants, which I run. `docs/MODELS.md` is the guide.

## Table and balls

- Playing surface 16 × 8 studs, 2:1 like a real table. With its cushions and slim wooden rails the whole table is about 18.2 × 10.2 studs: black plates over the corner pockets, the side pockets set into the rails, cushions angled at the pocket mouths, and white diamonds on the rails. The playing surface is about an avatar's hip height.
- 16 balls: the cue ball, solids 1–7, the 8, stripes 9–15. Stylized balls with icons (details coming).
- Balls and pockets in 8 Ball Duels' proportions, measured from recordings: balls 0.44 studs across, and 6 pockets, tighter than real, the corners about 1.55 ball widths across and the sides about 1.6.
- A full-power shot leaves at about 25 studs/s and rolls about 11 table lengths if nothing stops it. Balls slow at a steady rate at every speed.
- A ball loses about 27% of its speed when it bounces off a rail, and comes off at the same angle it hit.
- No follow: on a full straight hit the cue ball stops almost dead (it keeps about 3% of its speed), and on a cut it leaves along the tangent line, nudged only slightly forward, with no curve afterwards. The object ball takes about 97% of the speed along the line of centers.
- Feel: matched to 8 Ball Duels, measured frame by frame from a full match.

## Joining a table

- A "Join table" prompt floats above each table's centre: press E to join (phones: tap it). It shows how many have joined, like "1/2 joined". The first player takes side A, the next side B, and so on. A player who has joined sees "Waiting for players" there instead. The prompt only joins. To leave, press the Leave button at the top right, in either view: while waiting it takes you off the table, during the 3-second start it calls the start off, and during a game it asks first (see Leaving).
- A sign floats over each table: "0/2 players" or "0/4 players", counting the players who have joined, so open tables show from across the arena.
- 1v1 tables have 2 seats, one on each long side. 2v2 tables have 4, two on each long side. Your side is your team.
- When every seat is taken, everyone at the table sees a 3-second "Starting..." banner, and the prompt reads "Starting…" and can't be used. Then each player is moved once to their seat's spot beside the table, facing it, their normal camera turns to look at the table from behind them, and the game starts. Players walk freely before, during and after a game.
- If a player leaves during those 3 seconds, with the Leave button or by leaving the server, the start is called off, everyone at the table sees "Start called off: Player1 left.", and the others stay joined.
- While a game is on, the prompt reads "Table in use" and can't be used.
- A player joins one table at a time, and a player in a game can't join another table.
- No waiting line and no "winner stays on": whoever has joined when the last seat is taken plays.
- **Parties** (the first update after launch): when a party's leader joins a table, their partner joins too: as their teammate on a 2v2 table, or their opponent on a 1v1 table *(default)*. A player on their own can take an open seat on a 2v2 table and get a random partner.

## First join

- A simple tutorial, before launch: on-screen tips during a player's first match cover the basics as they come up: aiming, power, ball in hand, groups and the 8, and items *(default list)*.

## Starting a game

- Balls are racked in a triangle at the foot spot: the 8 in the middle, a solid and a stripe in the back corners, the rest random *(default)*.
- A random player breaks. The cue ball starts in the middle of the head line and can't be moved: there's no ball in hand on the break, and the server rejects any other spot. The break's full power is 2.5× a normal shot's, about 62.5 studs/s, like 8 Ball Duels.
- In 2v2 the breaker's side is team A, and turns go A1 → B1 → A2 → B2 with the breaker as A1 *(default)*.

## Taking a shot

1. A "Turn" arrow appears over the shooter's head and their shot clock starts. The arrow is a small gold "Turn" card pointing down at the head; everyone sees it in the normal view, and the top-down view hides it, since the top bar's glow shows the turn there.
2. The shooter is already in the top-down view (step 10). F (phones: an on-screen button) switches between it and the normal view from anywhere. Where they stand doesn't matter.
3. The top-down view shows the whole table, fixed and horizontal on screen, the same for everyone *(default)*.
4. Ball in hand only comes after a foul, like a scratch, and lets the shooter place the cue ball anywhere on the table. The cue ball follows the mouse, stopping at the nearest spot it's allowed, with a faint white ring around it: never overlapping a ball or in a pocket's mouth. The hint reads "Place ball · Click". A click sets it down, then they aim and shoot as normal. Until they shoot, clicking on or near the cue ball (within 3 ball radii of its center) picks it up again. (Phones: the Mobile phase.)
5. Aim, on PC: only the mouse aims. The cue always points from the cue ball toward the cursor, even when the cue ball moves under a still mouse, like after a shot. No keys aim. On phones, dragging on the table turns the aim around the cue ball.
6. Aim lock (optional): Space locks the aim, and Space again unlocks it and goes back to aiming. On phones, a thumb-sized Lock button next to the power meter does the same. Space never shoots. Locking first lets you move the mouse freely before you pull. The aim indicator (step 7) shows the state: see-through white while aiming, solid white whenever the aim is locked, including during a pull. Control hints on the bottom right, each a label and its key, read "Lock aim · Space" and "Shoot · Hold + drag back" while aiming, and "Unlock · Space" and "Shoot · Drag back" while locked (phones: "Lock aim to pull from anywhere · Tap Lock" and "Shoot · Drag back from ball", then "Unlock · Tap Lock" and "Shoot · Drag back"). Each new shot starts unlocked.
6a. Power, like a slingshot and like 8 Ball Duels: on PC, hold the mouse button anywhere, best in front of the cue ball near where you're aiming, and drag back along the aim line toward the cue ball and the stick. The cursor moves freely the whole time. If the aim isn't locked, pressing locks it where it is. On phones, while unlocked a touch on or near the cue ball or the cue starts a pull and a touch anywhere else turns the aim; while locked, a pull can start anywhere, so tap Lock first to start the pull wherever there's room. Power is how far the pointer has moved from where you pressed, measured only along the line straight back toward the stick. Moving toward the ball lowers it, down to 0, and it stays at 0 however far you keep going; it only comes back once the pointer is behind where you pressed again. Sideways movement neither adds nor removes power. The first stretch back is a small cancel zone, about fingertip size on a phone, that isn't drawn. Power counts from its edge, with full power 6 studs past it: 6.6 studs of pull in all, about 41% of the table length (`FullPullDistance` in Config, with a slider on the test panel to tune it). Speed follows 8 Ball Duels' curve, measured from recordings: even the softest shot leaves at 21% of full speed, about 5 studs/s, enough to roll about half the table, and the rest of the speed rises with the square of the pull, so 50% on the meter gives about 41% of full speed and 76% about 67% (`SoftestShot` and `PowerCurve` in Config). The cue slides back as you pull, and the power meter on the left fills up, with the power as a % under it; the meter only shows power, you don't drag it. Let go to shoot.
6b. Cancelling: push back toward the ball into the cancel zone and the cue slides back to rest, the meter empties, the aim indicator turns see-through again and the hint says "Cancel · Let go"; let go there to cancel with no shot. Right-clicking, opening the Roblox menu (Esc) or a release the game misses also cancels. These put you back where you were before the pull: still locked if you'd pressed Space first, aiming again if not. Space or the Lock button mid-pull cancels and unlocks, and leaving the view cancels and resets.
7. Aim indicator, always on, like 8 Ball Duels: a white line from the cue ball to the center of a white circle where the cue ball will be when it first touches a ball, with a small dot at that center. From the dot, a short white line shows where the cue ball goes after the hit; from the hit ball's center, a yellow line shows where that ball goes. Both follow the physics' own hit rule, so the white line includes the cue ball's slight drift forward of the tangent line. Each line's length follows the share of the speed its ball gets: a full hit draws a long yellow line and a short white one, a thin cut the opposite, and neither gets shorter than a minimum. If the cue ball would hit a rail or drop in a pocket first, the line and circle stop there, with no bounce lines. Every line, the circle and the dot have a thin dark outline, so they stay readable over white and yellow balls. It uses the physics' own geometry, so it's exact. Anyone in the top-down view, not just the shooter, sees the shooter's cue and aim indicator move live: the aim line, the circle, both direction lines, the called-pocket ring, and the cue sliding back during a pull. The updates are display-only and smoothed, so a slow connection never affects the shot. The power meter stays the shooter's alone. It hides while balls roll. `Config.Aim.ShowAimLine` switches the line, circle and dot, `Config.Aim.ShowCueLine` the white line after the hit and `Config.Aim.ShowTargetLine` the yellow line; there's no player setting.
8. When shooting at the 8, the shooter calls a pocket. A gold ring marks the pocket the 8's yellow line points at, and follows the aim. Clicking near another pocket calls that one instead for the rest of the shot. A press that pulls back still starts a pull, so a pull can start over a pocket. At the start of the turn the ring is on the pocket nearest the 8, and it stays on the last one while the aim isn't on the 8. On the 8 the hint "Lock aim · Space" becomes "Call pocket · Click a pocket". Everyone in the top-down view sees the ring move live, like the aim indicator (step 7). (Phones: the Mobile phase.)
9. When they let go, the cue strikes forward and the shot fires the moment it touches the cue ball; the cue carries on a little and fades out. Everyone sees the balls roll.
10. Your turn starting switches you to the top-down view, even if you'd pressed F to leave it. When your turn ends (the balls stop and the turn passes), you go back to the normal third-person view to watch the opponent; a turn you keep leaves the view as it is. Only the shooter controls the cue; everyone else in the top-down view sees it move live. F switches the view any time. Players only waiting or watching aren't moved. When the game ends, the camera goes back to normal *(default)*.

- **Items:** before each shot, the shooter can use one item (see Items).
- **Top-down only:** you can only aim and shoot from the top-down view. The cue and the power meter only show there, and leaving the view in the middle of a pull cancels it with no shot.
- **Shot clock:** 45 seconds per shot (I said 30–60). It covers placing and aiming and stops when the shot fires, hiding while the balls roll. The next shot gets a fresh 45. Running out is a foul, so the next shooter gets ball in hand, and everyone at the table sees "Time's up. Player2 has ball in hand." On the break there's no ball in hand: the next player breaks instead *(default)*. 2 timeouts in a row remove the player, the same as leaving (Phase 4). The clock is a dark box in the middle of the top bar that always shows the seconds left, turning coral with bigger numbers for the last 10.
- **Between turns:** players can press F to leave the top-down view and walk around, sit or grab a drink.
- **No spin** in the base build. The top-right corner of the screen stays free for a spin control later.

## The screen

Laid out like 8 Ball Duels, in the look `docs/STYLE.md` describes: cream cards, dark boxes and bright accent buttons.

- **In the top-down view:**
  - a top bar with two cards: your side on the left and the other side on the right, with a gap in the middle for the shot clock. Anyone watching sees side A on the left. Each card shows the side's avatars and names (both teammates in 2v2), its group ("Solids", "Stripes" or "Open table") and small icons of that group's balls, greyed out once they're down, with the 8 added once all seven are. The side whose turn it is glows gold, and the shooter's avatar gets a gold ring. Every screen draws it from the server's turn message, so they all agree; the icons change when the next turn starts. With no game on, only your own card shows
  - the power meter on the left, with a % readout under it; on phones the Lock button sits next to it
  - a tray on the right where sunk balls collect, the first one sunk at the bottom
  - soft shadows under the balls (the normal view has Roblox's own shadows)
  - the shot clock in the middle of the top bar, between the two cards
  - a Leave button top right while you're at a table, in both views (see Leaving)
  - a settings button bottom-left with a sound volume slider. The volume lasts for the session and isn't saved *(default)*. It shows only in the top-down view, so it never covers the phones' thumbstick.
- **Coming next:**
  - your group's balls pulse white briefly when your turn starts (Normal tables)
  - item slots 1 and 2 at the bottom center (Items), with icons drawn in code, and every player's slots and item bar on their card

## 8-ball rules

Items never change these rules: what counts as a legal shot, a foul or a win is the same with or without them.

- **Break:** any break counts, so a scratch is its only foul: no first-ball or rail rule. Any ball in keeps the breaker shooting, unless the cue ball went in, which gives the other side ball in hand anywhere. If the 8 goes in on the break, it goes back on the foot spot, or the nearest free spot behind it toward the foot rail if that's taken, and play goes on: it's never a win or a loss.
- **Open table:** after the break the table is open, even if balls went in. On an open table you may hit any ball first except the 8.
- **Groups:** the first ball legally sunk on an open table gives the shooter's side that group, solids or stripes. If both kinds drop on that shot, the first to drop decides *(default)*.
- **Legal shot:** the cue ball first hits one of your group (any ball but the 8 on an open table, the 8 once your group is cleared), and the cue ball doesn't go in. After that first hit, a ball goes in or some ball touches a rail, the cue ball included.
- **Turns:** you keep shooting after legally sinking one of your balls, or any ball on the break or an open table. Anything else passes the turn.
- **Fouls:** the cue ball goes in, nothing is hit, the first ball hit isn't legal (the 8 on an open table; anything but the 8 when you're on it), no ball goes in or touches a rail after the first hit, or the clock runs out. After a foul the turn passes and the next shooter gets ball in hand anywhere. Balls that went in on a foul stay down. Everyone at the table sees a banner for 3 seconds naming the foul and who has ball in hand, like "Foul: wrong ball first. Player2 has ball in hand."
- **The other side's balls:** sinking one of theirs leaves it down; it counts for them.
- **Winning:** once your group is cleared, call a pocket and legally sink the 8 there.
- **Losing on the 8:** sinking it before your group is cleared (except on the break), including on the same shot as your last ball; in a pocket you didn't call; or on a shot that fouls (like the cue ball going in too).
- A foul while shooting at the 8 that doesn't sink it is just a foul.
- **When the 8 decides the game,** nobody's turn is on, and its players see the end screen at once, headed with who won and why, like "Player1 wins: 8 in the wrong pocket" (see End of a game). Anyone else near the table sees the same words as a banner for 5 seconds.

## 2v2

- Same table, 2 seats per long side. Your side is your team, and teammates share a group.
- Turns go A1 → B1 → A2 → B2. Sinking a ball keeps the turn with the same player; the next time the team is up, the teammate shoots.
- After a foul, ball in hand goes to the next shooter.

## Items

Items are gadgets that change how balls move, never the rules. Here a **turn** means one player's visit to the table: every shot they take until the turn passes.

### Earning items

Each player has one item bar. At 12 points it gives an item, and leftover points carry over.

| Points | When |
| --- | --- |
| +3 | At the start of each of your turns. The break counts as the breaker's first turn |
| +4 | For each of your own group's balls you sink, when the balls stop. On an open table, any legal pot counts |
| +2 | For each ball the other side sinks that earns them +4, when the balls stop. In 2v2 it all goes to the opponent who shoots next |

- Break pots, foul pots and the 8 give no points to anyone. Neither does a ball from the other side's group that you sink.
- Each item is random from the 5, each equally likely. Nobody starts with one.
- Each player holds up to 2 items, in slots 1 and 2. A new item goes in the first empty slot. If the bar fills while both slots are full, it stops at full and glows, and the item arrives as soon as you use one. Points past full are lost.
- `Config.Items.SinkItemsWaitForTurnEnd` (off by default): when it's on, an item that your own sink fills arrives when your turn ends, not right away.
- Every player's card shows their 2 slots with the item bar under them, for everyone to see. Each fill shows a small pop on the bar, like "+4", so players learn what fills it. The exact look waits for the GUI pass.
- In 2v2, each player has their own slots and bar, and balls sunk count for the shooter.

### Using items

- On your own turn, before a shot, press 1 or 2 (phones: tap the slot). One item per shot. Like shooting, it works only in the top-down view.
- Power Shot and Blast Ball take effect at once. Freeze, Oil Slick and Pocket Block then ask for a target: click or tap a ball, a spot on the felt or a pocket. Pressing the same key or tapping the slot again backs out without using it. Items can't be used mid-pull.
- An item is spent the moment you use it, even if you then foul or the clock runs out. The shot clock keeps running while you pick a target.
- Everyone at the table, players and watchers, sees the item's name big in the middle of the screen for about 1.5 seconds, and its effect stays visible on the table while it lasts. Every player's held items show on their card, for everyone to see.
- **How long they last:** Power Shot lasts your whole turn: every shot until you miss or foul. Blast Ball lasts one shot. Freeze, Oil Slick and Pocket Block last from when you use them until the end of the other side's next turn, so they also affect your own shots this turn. In 2v2, the other side's next turn is the next turn the other team takes.
- A second Power Shot can't be used while one is on, since it would do nothing.
- Combos are allowed: Power Shot on one shot, then Blast Ball on a later shot in the same turn, since each uses its own slot.
- Effects from both sides can be on the table at once. A ball that's already frozen or a pocket that's already blocked can't be picked again.
- **No lock-outs:** Freeze can't pick the 8, or the last ball left in either side's group. Pocket Block can't be used once the other side has cleared their group and is shooting at the 8. A lid that's already down stays for its full time, even if the other side clears their group while it's there, and they can't call that pocket until it lifts. A side can't target the same ball or pocket on two of its turns in a row.
- Items and bars are cleared at the end of a game. A player who takes over a leaver's spot gets their items and bar.

### The 5 items

| Item | What it does | Numbers |
| --- | --- | --- |
| **Power Shot** | For every shot in the rest of your turn, the meter can go past 100%. Up to 100% it works as normal. Pulling further keeps filling it at the same rate, up to 150% at 1.5× `FullPullDistance` (9 studs past the cancel zone today). Past 100%, speed rises in step with the meter, so 125% is 1.25× full speed *(default)*. Past 100% the meter's fill turns orange and fills again from the bottom, with the % reading up to 150% (a placeholder until the GUI pass). A flame trail follows the cue ball. The server only accepts power above 100% while the shooter's Power Shot is on | `Config.Items.PowerShotMax` 1.5: 150% sends the cue ball at 1.5× full speed, 37.5 studs/s today |
| **Blast Ball** | On this shot, the first ball the cue ball hits sends out a blast that pushes nearby balls away from it. The cue ball, the hit ball and frozen balls aren't pushed. If the cue ball hits nothing, nothing happens. The aim indicator shows the blast's reach as a ring around the ball it's going to hit | Reaches about 3 ball widths from the hit ball's center. A ball right next to it is pushed at about 40% of normal full speed, fading to nothing at the edge |
| **Freeze** | Pick any ball except the cue ball (freezing it would leave nothing to shoot), the 8, and the last ball left in either side's group (it couldn't drop, so that side couldn't finish their group). Until the end of the other side's next turn it can't move or drop, and balls bounce off it like a wall. It still counts as a ball for the rules, so hitting it first is legal when it's yours to hit. It glows icy blue | Balls bounce off it like a rail, keeping about 73% of their speed |
| **Oil Slick** | Place a round patch anywhere on the felt, even under balls. Balls on it slow down much less. It lasts until the end of the other side's next turn. Patches don't stack | About 5 ball widths across. Balls on it slow at a quarter of the normal rate |
| **Pocket Block** | Pick a pocket. A lid covers its mouth until the end of the other side's next turn, and balls bounce off it like a rail. Can't be used while the other side is shooting at the 8, but a lid already down stays for its full time. Nobody can call a blocked pocket for the 8, and the cue ball can't scratch there either. The lid is built in code | Balls keep about 73% of their speed off the lid, like a rail |

### Feedback

- Chunky, stylized effects as `docs/STYLE.md` describes: a flame trail for Power Shot, a burst and a ring for the blast, an icy glow on a frozen ball, a glossy patch for oil and a lid over a blocked pocket.
- Screen shake on big hits: the blast, and any hit or rail bounce faster than about 60% of normal full speed, so the break and Power Shots shake too. It's short and small, so the table stays readable.
- The item's name shown big when it's used (above).
- More items come in the Friday updates after launch.

## Watching and hanging out

- In a real game, the other players and anyone watching from the top-down view see the shooter's cue and aim indicator move live while they aim (Taking a shot, step 7).
- Anyone can watch a game in 3D from where they stand, or switch to the same top-down view *(default: a "Watch from above" button when you're near a table with a game on)*.
- While the shooter aims, their character moves around the table edge to stand behind the cue ball in a ready-to-shoot pose, so 3D watchers see it (a planned Phase 2 task).
- Roblox's own emotes, text chat and voice chat. Quick phrases (like "Nice shot!" and "GG") are on the Later list.
- Public servers have no way to lock a table.

## Progression and money

- Progression is one of the first updates after launch (see BUILD_PLAN): XP levels you up, and coins buy loot crates. Crates give cosmetics, like cues, cloth colors and ball sets, and unlock new items, which then show up in matches the normal way, through the item bar. What earns XP and coins, what's in each crate and how unlocks work stay open until we design progression.
- Free private servers. No paid boosters. $0 budget: free tools and assets only.
- Nothing is for sale. Don't build any purchases; see "Raised but not decided".

## End of a game

- When a side wins, an end screen shows the winner and each player's stats *(default definitions)*:
  - **Shot accuracy:** the share of your shots that kept your turn or won the game
  - **Balls sunk:** balls you sank on shots that weren't fouls
  - **Best run:** the most balls you sank in one turn
  - **Fouls:** your fouls, timeouts included
- The end screen opens at once when the game is decided, for its players only, headed with who won and why. The winners' lines are highlighted. It offers Rematch and Back to lobby *(default)*, and stays up 10 seconds *(default)*, counting down. It shows in both views.
- **Rematch:** if every player at the table presses it before the end screen closes, the table re-racks and the same players are moved to their seats and play again, with a random breaker *(default)*. It's a replay for the same players, not "winner stays on". Each player's screen says who has pressed it, like "Player2 wants a rematch". There's no Rematch once someone has pressed Leave.
- **Back to lobby** closes your end screen and rules out the rematch; the others see "Player1 went back to the lobby". Nobody is moved: the room is the lobby.
- When the end screen closes without a rematch, the balls are re-racked, the prompt opens again and the sign goes back to "0/2 players" or "0/4 players". Joining again starts a new game.
- Each player's lifetime stats are saved for future levels and ranked mode, but not shown anywhere yet.

## Leaving

Leaving means leaving the server, disconnecting, or 2 timeouts in a row. Walking away from the table doesn't count. The Leave button is a choice to give up, below the table.

| Situation | What happens |
| --- | --- |
| Someone leaves the server during the 3-second start | The start is called off, and the others stay joined |
| A player leaves mid-game | Their seat opens: the prompt reads "Take seat", and the first player to press E takes over their spot: team, group and turn *(default)* |
| Nobody takes over within 15 seconds, 1v1 | The other player wins |
| Nobody takes over within 15 seconds, 2v2 | The teammate plays on alone and shoots every time the team is up |
| A whole 2v2 team is gone for 15 seconds | The other team wins |
| It was the leaver's turn | The game waits for a takeover, up to 15 seconds *(default)* |
| They leave while balls are rolling | The shot counts, then the rows above apply |
| Everyone leaves | The table resets |

- **The Leave button mid-game** asks "Leave and lose this game?" (Yes / No). Yes in 1v1 means the other side wins at once, shown like a win on the 8: "Player2 wins: Player1 left". In 2v2 it asks "Leave? Your teammate plays on alone.": Yes leaves the teammate to play on alone, shooting every time the team is up, and the other team wins once both have left.
- Until Phase 4 builds the rows above, leaving the server mid-game just ends the game, with no winner.

## Later list (after launch, roughly in this order)

The planned updates after launch, parties and progression first and extras like streaks later, are in BUILD_PLAN. These ideas come after or between them.

1. More items, a few at a time in the weekly updates.
2. Spin: GamePigeon's red dot on a cue-ball icon in the top-right corner. Top and back spin first, side spin later.
3. Lifetime stats on each player's profile, beside their level.
4. Missions and a coin pot for matches.
5. Ranked mode, alongside casual.
6. A back room with extra tables, for when servers fill up.
7. Quick phrases like "Nice shot!" and "GG" (moved from Phase 4 to make room for items).

## Decided against (don't re-propose)

- Bots or computer opponents.
- A waiting line or "winner stays on". Every game ends with the table reset.
- Locking tables in public servers.
- Where you stand changing your aim, or walking to a spot to shoot or to place the cue ball.
- W/S controls, or holding Space to shoot.
- A/D or arrow-key aiming.
- Alcohol.
- Guns or weapon items.
- Items that change what counts as a foul or a win.
- Item boxes on the felt: players earn items instead.
- Shooting from the normal view.
- My fading aim line (shown only near the end of a forward stroke): the slingshot pull has no forward stroke.
- An economy, cosmetics or ranked mode before the mechanics are done.

## Raised but not decided (don't build)

- A practice table for a player who's alone, since new players leave empty servers fast.
- A daily trick-shot challenge with a leaderboard.
- Catch-up help for the player who's behind: decide with playtesters. Today the only help is the item bar's +2 for each of the other side's pots.
- Paid gacha rolls, and whether Robux can buy items or coins. Don't build any purchases. Roblox requires paid random items to show their odds.
