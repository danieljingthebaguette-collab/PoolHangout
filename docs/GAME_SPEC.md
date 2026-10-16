# Game spec

How the game works. Written 2026-10-11 from my design chats with Claude.

Markers: no marker = decided by me. *(default)* = Claude's proposal I haven't confirmed; build it this way unless I say otherwise. Every number is a starting value in `Config.luau`, tuned by feel.

## The game

A chill hangout game: a cozy, blocky Roblox bar where people talk on voice chat and play 8-ball at pool tables, 1v1 or 2v2. The heart of it is the shot: a top-down view, the cue following your mouse (or your finger on phones), an aim lock, and a slingshot pull for power. Mechanics come first. The base build has no economy, cosmetics or ranked mode.

## Audience and platform

- For older players. Launch with the default 16+ audience; don't open it to under-16s.
- Voice chat is on. Voices fade with distance, so each table has its own conversation.
- No alcohol anywhere: names, models, decals, menus. Showing alcohol makes a game Restricted (ID-verified 18+ only). The bar serves sodas, milkshakes and coffee.
- PC and phones. Phones play in landscape, and every feature must work by touch.

## The bar

- 30 players per server and 8 tables: 4 for 1v1 and 4 for 2v2. Both kinds are the same size.
- A counter serving sodas, milkshakes and coffee, places to sit, warm lamps over each table, and lo-fi music.
- Style: blocky Roblox look with a cozy, warm feel. Tables in classic green felt and warm wood: dark green cushions, slim warm brown rails with white diamonds, and black pockets.
- Every model is a placeholder: the table, platforms, cue, balls, the bar and the rest of the map. Nothing visual is final until a modeler I commission delivers it, built to the brief in `docs/MODELS.md`.

## Table and balls

- Playing surface 16 × 8 studs, 2:1 like a real table. With its cushions and slim wooden rails the whole table is about 18.2 × 10.2 studs: black plates over the corner pockets, the side pockets set into the rails, cushions angled at the pocket mouths, and white diamonds on the rails. The playing surface is about an avatar's hip height.
- 16 balls: the cue ball, solids 1–7, the 8, stripes 9–15.
- 6 pockets about real size: the corners about 2.1 ball widths across, the sides about 2.3.
- A full-power shot leaves at about 25 studs/s and rolls about 11 table lengths if nothing stops it. Balls slow at a steady rate at every speed.
- A ball loses about 30% of its speed when it bounces off a rail, and comes off at the same angle it hit.
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
- A random player breaks. Like GamePigeon, they place the cue ball anywhere behind the head line, then shoot. The break's full power is 3× a normal shot's, about 75 studs/s, like 8 Ball Duels.
- In 2v2 the breaker's side is team A, and turns go A1 → B1 → A2 → B2 with the breaker as A1 *(default)*.

## Taking a shot

1. A "Turn" arrow appears over the shooter's head and their shot clock starts.
2. The shooter presses F from anywhere (phones: an on-screen button) to switch to the top-down view. Where they stand doesn't matter. F again goes back to the normal view *(default)*.
3. The top-down view shows the whole table, fixed and horizontal on screen, the same for everyone *(default)*.
4. With ball in hand, they drag the cue ball to place it first: behind the head line on the break, anywhere after a foul. It can't overlap another ball.
5. Aim, on PC: only the mouse aims. The cue always points from the cue ball toward the cursor, even when the cue ball moves under a still mouse, like after a shot. No keys aim. On phones, dragging on the table turns the aim around the cue ball.
6. Aim lock (optional): Space locks the aim, and Space again unlocks it and goes back to aiming. On phones, a thumb-sized Lock button next to the power meter does the same. Space never shoots. Locking first lets you move the mouse freely before you pull. The aim indicator (step 7) shows the state: see-through white while aiming, solid white whenever the aim is locked, including during a pull. A small hint reads "Hold and drag to shoot · Space: lock aim" while aiming and "Drag to shoot · Space: unlock" while locked (phones: "Drag from the cue ball to shoot · Tap Lock to lock aim" and "Drag to shoot · Tap Lock to unlock"). Each new shot starts unlocked.
6a. Power, like a slingshot: on PC, hold the mouse button anywhere and drag. If the aim isn't locked, pressing locks it where it is. On phones, while unlocked a touch on or near the cue ball or the cue starts a pull and a touch anywhere else turns the aim; while locked, a pull can start anywhere. Around where you pressed is a small cancel zone, about fingertip size on a phone, that isn't drawn. Power counts from its edge, so soft shots still work, and the farther you drag, in any direction, the harder, with full power at a distance set in Config. Power rises on a curve (speed is pull^1.45, so 76% on the meter gives about 67% of full speed), so soft shots get more of the drag. Any direction counts, so a cue ball against a rail can still get full power. The cue slides back as you drag, and the power meter on the left fills up, with the power as a % under it; the meter only shows power, you don't drag it. Let go to shoot.
6b. Cancelling: drag back into the cancel zone and the cue slides back to rest, the meter empties, the aim indicator turns see-through again and the hint says "Let go to cancel"; let go there to cancel with no shot. Right-clicking, opening the Roblox menu (Esc) or a release the game misses also cancels. These put you back where you were before the pull: still locked if you'd pressed Space first, aiming again if not. Space or the Lock button mid-pull cancels and unlocks, and leaving the view cancels and resets.
7. Aim indicator, always on: a white line from the cue ball to a white circle where the cue ball will be when it first touches a ball, and a short white line from that ball showing which way it will go. If the cue ball would hit a rail or drop in a pocket first, the line and circle stop there, with no bounce lines. It uses the physics' own geometry, so it's exact. Only the shooter sees it, and it hides while balls roll. `Config.Aim.ShowAimLine` switches the line and circle and `Config.Aim.ShowTargetLine` the target ball's line; there's no player setting.
8. When shooting at the 8, the shooter clicks or taps the pocket they're calling before they can shoot *(default)*.
9. When they let go, the cue strikes forward and the shot fires the moment it touches the cue ball; the cue carries on a little and fades out. Everyone sees the balls roll.
10. The shooter stays in the top-down view while it's still their turn. The camera goes back to normal when their turn ends *(default)*.

- **Top-down only:** you can only aim and shoot from the top-down view. The cue and the power meter only show there, and leaving the view in the middle of a pull cancels it with no shot.
- **Shot clock:** 45 seconds per shot (I said 30–60). It covers placing and aiming, shows a countdown for the last 10 seconds, and stops when the shot fires. The next shot gets a fresh 45. Running out is a foul, and 2 timeouts in a row remove the player, the same as leaving.
- **Between turns:** players can walk around, sit or grab a drink.
- **No spin** in the base build. The top-right corner of the screen stays free for a spin control later.

## The screen

Laid out like 8 Ball Duels.

- **In the top-down view:**
  - a top bar with your player card (name and avatar)
  - the power meter on the left, with a % readout under it; on phones the Lock button sits next to it
  - a tray on the right where sunk balls collect, the first one sunk at the bottom
  - soft shadows under the balls (the normal view has Roblox's own shadows)
  - a settings button bottom-left with a sound volume slider. The volume lasts for the session and isn't saved *(default)*. It shows only in the top-down view, so it never covers the phones' thumbstick.
- **Colors:** every panel, button and the meter in warm browns, matching the table's wood.
- **Phase 2:**
  - the other player's card in the top bar
  - a highlight on whose turn it is
  - the shot-clock bar under the shooter's name
  - each side's balls still left to sink
  - your group's balls pulse white briefly when your turn starts

## 8-ball rules

- **Break:** any break counts. Sinking the cue ball on the break is a foul. If the 8 goes in on the break, it goes back on the foot spot and the breaker keeps shooting, unless the cue ball also went in, which is a foul *(default)*.
- **Open table:** after the break the table is open, even if balls went in. On an open table you may hit any ball first except the 8.
- **Groups:** the first ball legally sunk on an open table gives the shooter's side that group, solids or stripes. If both kinds drop on that shot, the first to drop decides *(default)*.
- **Legal shot:** the cue ball first hits one of your group (any ball but the 8 on an open table, the 8 once your group is cleared), and the cue ball doesn't go in. No rail is required after contact *(default)*.
- **Turns:** you keep shooting after legally sinking one of your balls, or any ball on the break or an open table. Anything else passes the turn.
- **Fouls:** the cue ball goes in, the first ball hit isn't legal, nothing is hit, or the clock runs out. After a foul, the other side gets ball in hand anywhere. Balls that went in on a foul stay down *(default)*.
- **The other side's balls:** sinking one of theirs leaves it down; it counts for them.
- **Winning:** once your group is cleared, call a pocket and legally sink the 8 there.
- **Losing on the 8:** sinking it before your group is cleared (except on the break), in a pocket you didn't call, or on a shot that fouls (like the cue ball going in too).
- A foul while shooting at the 8 that doesn't sink it is just a foul.

## 2v2

- Same table, 2 platforms per long side. Your side is your team, and teammates share a group.
- Turns go A1 → B1 → A2 → B2. Sinking a ball keeps the turn with the same player; the next time the team is up, the teammate shoots.

## Watching and hanging out

- In a real game, the other players and anyone watching see the shooter's cue move live while they aim (Phase 3).
- Anyone can watch a game in 3D from where they stand, or switch to the same top-down view *(default: a "Watch from above" button when you're near a table with a game on)*.
- When a shot fires, the shooter's avatar is placed at the rail behind the cue ball and leans over with the cue, so 3D watchers see it (Phase 4) *(default)*.
- Emotes, quick phrases (like "Nice shot!" and "GG"), text chat and voice chat.
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

1. Spin: GamePigeon's red dot on a cue-ball icon in the top-right corner. Top and back spin first, side spin later.
2. Levels, plus lifetime stats on each player's profile.
3. Cosmetics: cues, cloth colors, ball sets. The economy comes with this, along with missions and a coin pot for matches.
4. Ranked mode, alongside casual.
5. A back room with extra tables that opens once a server passes 15 players.

## Decided against (don't re-propose)

- Bots or computer opponents.
- A waiting line or "winner stays on". Every game ends with the table reset.
- Locking tables in public servers.
- Where you stand changing your aim, or walking to a spot to shoot or to place the cue ball.
- W/S controls, or holding Space to shoot.
- A/D or arrow-key aiming.
- Alcohol.
- Shooting from the normal view.
- My fading aim line (shown only near the end of a forward stroke): the slingshot pull has no forward stroke.
- An economy, cosmetics or ranked mode before the mechanics are done.

## Raised but not decided (don't build)

- A practice table for a player who's alone, since new players leave empty servers fast.
- A daily trick-shot challenge with a leaderboard.
