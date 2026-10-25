# Game spec

How the game works. Written 2026-10-11 from my design chats with Claude. Updated 2026-10-16 for the intense, item-based direction, and 2026-10-24 for the full 8-ball rules.

Markers: no marker = decided by me. *(default)* = Claude's proposal I haven't confirmed; build it this way unless I say otherwise. Every number is a starting value in `Config.luau`, tuned by feel.

## The game

An intense, item-based pool game: 8-ball, 1v1 or 2v2, at tables in a big, warm wooden arena. Each player's item bar fills as they take turns and as balls drop, theirs or the other side's, and gives a gadget each time it's full. They use them before a shot. Items bend the physics but never the rules. Between turns players walk around and talk on voice chat. How it looks is in `docs/STYLE.md`, in the spirit of Illegal Soccer's style only. The heart of it is still the shot: a top-down view, the cue following your mouse (or your finger on phones), an aim lock, and a slingshot pull for power. Mechanics come first. The base build has no economy, cosmetics or ranked mode.

## Audience and platform

- For older players. Launch with the default 16+ audience; don't open it to under-16s.
- Voice chat is on. Voices fade with distance, so each table has its own conversation.
- No alcohol anywhere: names, models, decals, menus. Showing alcohol makes a game Restricted (ID-verified 18+ only). The counter serves sodas, milkshakes and coffee.
- No guns or weapons: items are gadgets.
- PC and phones. Phones play in landscape, and every feature must work by touch.

## The arena

- 30 players per server and 8 tables: 4 for 1v1 and 4 for 2v2. Both kinds are the same size.
- A big, warm wooden arena or lodge, as `docs/STYLE.md` describes: timber arches and beams, plank floors, plants, and lanterns throwing warm light over each table.
- A counter serving sodas, milkshakes and coffee, and places to sit.
- Upbeat music and punchy sounds: I pick them.
- Tables in green felt and painted warm wood: dark green cushions, slim rails with white diamonds, and black pockets.
- The game is made entirely with AI, models included; there's no modeler. Claude builds every model from parts with scripts, and writes prompts for Studio's AI model and texture tools for the shapes parts can't do well, like plants, which I run. `docs/MODELS.md` is the guide.

## Table and balls

- Playing surface 16 × 8 studs, 2:1 like a real table. With its cushions and slim wooden rails the whole table is about 18.2 × 10.2 studs: black plates over the corner pockets, the side pockets set into the rails, cushions angled at the pocket mouths, and white diamonds on the rails. The playing surface is about an avatar's hip height.
- 16 balls: the cue ball, solids 1–7, the 8, stripes 9–15.
- 6 pockets, tighter than real: the corners about 1.7 ball widths across, the sides about 1.6.
- A full-power shot leaves at about 25 studs/s and rolls about 11 table lengths if nothing stops it. Balls slow at a steady rate at every speed.
- A ball loses about 27% of its speed when it bounces off a rail, and comes off at the same angle it hit.
- No follow: on a full straight hit the cue ball stops almost dead (it keeps about 3% of its speed), and on a cut it leaves along the tangent line, nudged only slightly forward, with no curve afterwards. The object ball takes about 97% of the speed along the line of centers.
- Feel: matched to 8 Ball Duels, measured frame by frame from a full match.

## Joining a table

- A sign floats over each table: "0/2 players" or "0/4 players", counting the players standing on its platforms.
- 1v1 tables have 2 platforms, one on each long side. 2v2 tables have 4, two on each long side. Your side is your team.
- Stand on a platform to claim it. When every platform is filled, a 5-second countdown starts and shows on the sign ("Starting in 3…") *(default wording)*.
- If anyone steps off during the countdown, it resets and waits. When every platform is filled again, it starts over from 5.
- A player holds one platform at a time, and a player in a game can't claim another table's platform.
- No waiting line and no "winner stays on": whoever is on the platforms when the countdown ends plays.

## Starting a game

- Balls are racked in a triangle at the foot spot: the 8 in the middle, a solid and a stripe in the back corners, the rest random *(default)*.
- A random player breaks. The cue ball starts in the middle of the head line and can't be moved: there's no ball in hand on the break, and the server rejects any other spot. The break's full power is 3× a normal shot's, about 75 studs/s, like 8 Ball Duels.
- In 2v2 the breaker's side is team A, and turns go A1 → B1 → A2 → B2 with the breaker as A1 *(default)*.

## Taking a shot

1. A "Turn" arrow appears over the shooter's head and their shot clock starts.
2. The shooter is already in the top-down view (step 10). F (phones: an on-screen button) switches between it and the normal view from anywhere. Where they stand doesn't matter.
3. The top-down view shows the whole table, fixed and horizontal on screen, the same for everyone *(default)*.
4. Ball in hand only comes after a foul, like a scratch, and lets the shooter place the cue ball anywhere on the table. The cue ball follows the mouse, stopping at the nearest spot it's allowed, with a faint white ring around it: never overlapping a ball or in a pocket's mouth. The hint reads "Place ball · Click". A click sets it down, then they aim and shoot as normal. Until they shoot, clicking on or near the cue ball (within 3 ball radii of its center) picks it up again. (Phones: the Mobile phase.)
5. Aim, on PC: only the mouse aims. The cue always points from the cue ball toward the cursor, even when the cue ball moves under a still mouse, like after a shot. No keys aim. On phones, dragging on the table turns the aim around the cue ball.
6. Aim lock (optional): Space locks the aim, and Space again unlocks it and goes back to aiming. On phones, a thumb-sized Lock button next to the power meter does the same. Space never shoots. Locking first lets you move the mouse freely before you pull. The aim indicator (step 7) shows the state: see-through white while aiming, solid white whenever the aim is locked, including during a pull. Control hints on the bottom right, each a label and its key, read "Lock aim · Space" and "Shoot · Hold + drag back" while aiming, and "Unlock · Space" and "Shoot · Drag back" while locked (phones: "Lock aim to pull from anywhere · Tap Lock" and "Shoot · Drag back from ball", then "Unlock · Tap Lock" and "Shoot · Drag back"). Each new shot starts unlocked.
6a. Power, like a slingshot and like 8 Ball Duels: on PC, hold the mouse button anywhere, best in front of the cue ball near where you're aiming, and drag back along the aim line toward the cue ball and the stick. The cursor moves freely the whole time. If the aim isn't locked, pressing locks it where it is. On phones, while unlocked a touch on or near the cue ball or the cue starts a pull and a touch anywhere else turns the aim; while locked, a pull can start anywhere, so tap Lock first to start the pull wherever there's room. Power is how far the pointer has moved from where you pressed, measured only along the line straight back toward the stick. Moving toward the ball lowers it, down to 0, and it stays at 0 however far you keep going; it only comes back once the pointer is behind where you pressed again. Sideways movement neither adds nor removes power. The first stretch back is a small cancel zone, about fingertip size on a phone, that isn't drawn. Power counts from its edge, so soft shots still work, with full power 6 studs past it: 6.6 studs of pull in all, about 41% of the table length (`FullPullDistance` in Config, with a slider on the test panel to tune it). Power rises on a curve (speed is pull^1.45, so 76% on the meter gives about 67% of full speed), so soft shots get more of the drag. The cue slides back as you pull, and the power meter on the left fills up, with the power as a % under it; the meter only shows power, you don't drag it. Let go to shoot.
6b. Cancelling: push back toward the ball into the cancel zone and the cue slides back to rest, the meter empties, the aim indicator turns see-through again and the hint says "Cancel · Let go"; let go there to cancel with no shot. Right-clicking, opening the Roblox menu (Esc) or a release the game misses also cancels. These put you back where you were before the pull: still locked if you'd pressed Space first, aiming again if not. Space or the Lock button mid-pull cancels and unlocks, and leaving the view cancels and resets.
7. Aim indicator, always on, like 8 Ball Duels: a white line from the cue ball to the center of a white circle where the cue ball will be when it first touches a ball, with a small dot at that center. From the dot, a short white line shows where the cue ball goes after the hit; from the hit ball's center, a yellow line shows where that ball goes. Both follow the physics' own hit rule, so the white line includes the cue ball's slight drift forward of the tangent line. Each line's length follows the share of the speed its ball gets: a full hit draws a long yellow line and a short white one, a thin cut the opposite, and neither gets shorter than a minimum. If the cue ball would hit a rail or drop in a pocket first, the line and circle stop there, with no bounce lines. Every line, the circle and the dot have a thin dark outline, so they stay readable over white and yellow balls. It uses the physics' own geometry, so it's exact. Only the shooter sees it, and it hides while balls roll. `Config.Aim.ShowAimLine` switches the line, circle and dot, `Config.Aim.ShowCueLine` the white line after the hit and `Config.Aim.ShowTargetLine` the yellow line; there's no player setting.
8. When shooting at the 8, the shooter calls a pocket. A gold ring marks the pocket the 8's yellow line points at, and follows the aim. Clicking near another pocket calls that one instead for the rest of the shot. A press that pulls back still starts a pull, so a pull can start over a pocket. At the start of the turn the ring is on the pocket nearest the 8, and it stays on the last one while the aim isn't on the 8. On the 8 the hint "Lock aim · Space" becomes "Call pocket · Click a pocket". Only the shooter sees the ring until watchers see the shooter's aim live (Phase 3). (Phones: the Mobile phase.)
9. When they let go, the cue strikes forward and the shot fires the moment it touches the cue ball; the cue carries on a little and fades out. Everyone sees the balls roll.
10. When a game starts, every player in it switches to the top-down view automatically and stays there the whole game. Only the shooter gets the cue; the others watch. F still toggles the view for anyone who wants. When the game ends, the camera goes back to normal *(default)*.

- **Items:** before each shot, the shooter can use one item (see Items).
- **Top-down only:** you can only aim and shoot from the top-down view. The cue and the power meter only show there, and leaving the view in the middle of a pull cancels it with no shot.
- **Shot clock:** 45 seconds per shot (I said 30–60). It covers placing and aiming, shows a countdown for the last 10 seconds, and stops when the shot fires. The next shot gets a fresh 45. Running out is a foul, and 2 timeouts in a row remove the player, the same as leaving.
- **Between turns:** players can press F to leave the top-down view and walk around, sit or grab a drink.
- **No spin** in the base build. The top-right corner of the screen stays free for a spin control later.

## The screen

Laid out like 8 Ball Duels, in the look `docs/STYLE.md` describes: cream cards, dark boxes and bright accent buttons.

- **In the top-down view:**
  - a top bar with two cards: your side on the left and the other side on the right, with a gap in the middle for the shot clock. Anyone watching sees side A on the left. Each card shows the side's avatars and names (both teammates in 2v2), its group ("Solids", "Stripes" or "Open table") and small icons of that group's balls, greyed out once they're down, with the 8 added once all seven are. The side whose turn it is glows gold, and the shooter's avatar gets a gold ring. Every screen draws it from the server's turn message, so they all agree; the icons change when the next turn starts. With no game on, only your own card shows
  - the power meter on the left, with a % readout under it; on phones the Lock button sits next to it
  - a tray on the right where sunk balls collect, the first one sunk at the bottom
  - soft shadows under the balls (the normal view has Roblox's own shadows)
  - a settings button bottom-left with a sound volume slider. The volume lasts for the session and isn't saved *(default)*. It shows only in the top-down view, so it never covers the phones' thumbstick.
- **Phase 2:**
  - the shot clock in the middle of the top bar, between the two cards
  - your group's balls pulse white briefly when your turn starts
  - item slots 1 and 2 at the bottom center, with icons drawn in code, and every player's slots and item bar on their card

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
- **Until the end screen (Phase 3):** when the 8 decides the game, everyone at the table sees who won and why, like "Player1 wins: 8 in the wrong pocket", for 5 seconds, with nobody's turn. Then the game ends and the table re-racks. Players still on the platforms start a new game right away.

## 2v2

- Same table, 2 platforms per long side. Your side is your team, and teammates share a group.
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

- In a real game, the other players and anyone watching see the shooter's cue move live while they aim (Phase 3).
- Anyone can watch a game in 3D from where they stand, or switch to the same top-down view *(default: a "Watch from above" button when you're near a table with a game on)*.
- When a shot fires, the shooter's avatar is placed at the rail behind the cue ball and leans over with the cue, so 3D watchers see it (Later list) *(default)*.
- Roblox's own emotes, text chat and voice chat. Quick phrases (like "Nice shot!" and "GG") are on the Later list.
- Private servers are free. Public servers have no way to lock a table.

## End of a game

- When a side wins, an end screen shows the winner and each player's stats *(default definitions)*:
  - **Shot accuracy:** the share of your shots that kept your turn or won the game
  - **Balls sunk:** balls you sank on shots that weren't fouls
  - **Best run:** the most balls you sank in one turn
  - **Fouls:** your fouls, timeouts included
- The end screen stays up 10 seconds *(default)*. Then everyone is moved just off their platform, the balls are re-racked, and the sign goes back to "0/2 players" or "0/4 players". Stepping back on starts a new game.
- Each player's lifetime stats are saved for future levels and ranked mode, but not shown anywhere yet.

## Leaving

Leaving means leaving the server, disconnecting, pressing a Leave button in the game UI *(default)*, or 2 timeouts in a row. Walking away from the table doesn't count.

| Situation | What happens |
| --- | --- |
| Someone steps off during the countdown | The countdown resets and waits |
| A player leaves mid-game | Their platform lights up. Anyone who stands on it for 5 seconds takes over their spot: team, group and turn |
| Nobody takes over within 15 seconds, 1v1 | The other player wins |
| Nobody takes over within 15 seconds, 2v2 | The teammate plays on alone and shoots every time the team is up |
| A whole 2v2 team is gone for 15 seconds | The other team wins |
| It was the leaver's turn | The game waits for a takeover, up to 15 seconds *(default)* |
| They leave while balls are rolling | The shot counts, then the rows above apply |
| Everyone leaves | The table resets |

## Later list (after launch, roughly in this order)

1. More items, a few at a time in the Friday updates.
2. Spin: GamePigeon's red dot on a cue-ball icon in the top-right corner. Top and back spin first, side spin later.
3. Levels, plus lifetime stats on each player's profile.
4. Cosmetics: cues, cloth colors, ball sets. The economy comes with this, along with missions and a coin pot for matches.
5. Ranked mode, alongside casual.
6. A back room with extra tables that opens once a server passes 15 players.
7. The shooter's avatar leaning over the table with the cue, for 3D watchers (moved from Phase 4 to make room for items).
8. Quick phrases like "Nice shot!" and "GG" (moved from Phase 4 to make room for items).

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
