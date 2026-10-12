# Game spec

How the game works. Written 2026-10-11 from my design chats with Claude.

Markers: no marker = decided by me. *(default)* = Claude's proposal I haven't confirmed; build it this way unless I say otherwise. Every number is a starting value in `Config.luau`, tuned by feel.

## The game

A chill hangout game: a cozy, blocky Roblox bar where people talk on voice chat and play 8-ball at pool tables, 1v1 or 2v2. The heart of it is the shot: a top-down view, A/D to aim, and a power meter you pull back and push forward like a real cue. Mechanics come first. The base build has no economy, cosmetics or ranked mode.

## Audience and platform

- For older players. Launch with the default 16+ audience; don't open it to under-16s.
- Voice chat is on. Voices fade with distance, so each table has its own conversation.
- No alcohol anywhere: names, models, decals, menus. Showing alcohol makes a game Restricted (ID-verified 18+ only). The bar serves sodas, milkshakes and coffee.
- PC and phones. Phones play in landscape, and every feature must work by touch.

## The bar

- 30 players per server and 8 tables: 4 for 1v1 and 4 for 2v2. Both kinds are the same size.
- A counter serving sodas, milkshakes and coffee, places to sit, warm lamps over each table, and lo-fi music.
- Style: blocky Roblox look with a cozy, warm feel. Tables in classic green felt and warm wood *(default)*.
- Every model is a placeholder: the table, platforms, cue, balls, the bar and the rest of the map. Nothing visual is final until a modeler I commission delivers it, built to the brief in `docs/MODELS.md`.

## Table and balls

- Playing surface 10 × 5 studs, about 1.5× a real bar table *(default)*.
- 16 balls: the cue ball, solids 1–7, the 8, stripes 9–15.
- 6 pockets about 20% wider than real ones, so it's forgiving.
- A full-power shot rolls about 13 table lengths if nothing stops it.
- A ball loses about 20% of its speed when it bounces off a rail, and comes off at the same angle it hit.
- A rolling ball that hits another keeps some forward roll, like natural roll in real pool: about 29% of its speed on a straight hit, and it bends slightly forward after a cut.
- Feel: between GamePigeon's lively rolls and a heavy, controlled table *(default)*.

## Joining a table

- A sign floats over each table: "0/2 players" or "0/4 players", counting the players standing on its platforms.
- 1v1 tables have 2 platforms, one on each long side. 2v2 tables have 4, two on each long side. Your side is your team.
- Stand on a platform to claim it. When every platform is filled, a 5-second countdown starts and shows on the sign ("Starting in 3…") *(default wording)*.
- If anyone steps off during the countdown, it resets and waits. When every platform is filled again, it starts over from 5.
- A player holds one platform at a time, and a player in a game can't claim another table's platform.
- No waiting line and no "winner stays on": whoever is on the platforms when the countdown ends plays.

## Starting a game

- Balls are racked in a triangle at the foot spot: the 8 in the middle, a solid and a stripe in the back corners, the rest random *(default)*.
- A random player breaks. Like GamePigeon, they place the cue ball anywhere behind the head line, then shoot.
- In 2v2 the breaker's side is team A, and turns go A1 → B1 → A2 → B2 with the breaker as A1 *(default)*.

## Taking a shot

1. A "Turn" arrow appears over the shooter's head and their shot clock starts.
2. The shooter presses F from anywhere (phones: an on-screen button) to switch to the top-down view. Where they stand doesn't matter. F again goes back to the normal view *(default)*.
3. The top-down view shows the whole table, fixed and horizontal on screen, the same for everyone *(default)*.
4. With ball in hand, they drag the cue ball to place it first: behind the head line on the break, anywhere after a foul. It can't overlap another ball.
5. Aim: A/D or the left/right arrow keys turn the cue around the cue ball, a full 360°. Tap for a tiny nudge; hold to turn faster the longer you hold. W and S do nothing. On phones, drag on the table to turn the aim *(default)*.
6. Power: a vertical meter in the bottom-right of the screen with a ball icon on it. Drag the icon back (down) to load power, then push it all the way forward (up) to shoot. Power is how far back the icon was when the final push began. Let go before the end and the icon springs back with no shot, so practice strokes are free. Mouse and touch work the same way.
7. Aim line: a plain line from the cue ball to the first ball it would hit, switched with `Config.Aim.ShowAimLine`. It's a testing aid in the base build; the real aim help is on the Later list.
8. When shooting at the 8, the shooter clicks or taps the pocket they're calling before they can shoot *(default)*.
9. The shot fires when the icon reaches the end, and everyone sees the balls roll.
10. The shooter stays in the top-down view while it's still their turn. The camera goes back to normal when their turn ends *(default)*.

- **Shot clock:** 45 seconds per shot (I said 30–60). It covers placing and aiming, shows a countdown for the last 10 seconds, and stops when the shot fires. The next shot gets a fresh 45. Running out is a foul, and 2 timeouts in a row remove the player, the same as leaving.
- **Between turns:** players can walk around, sit or grab a drink.
- **No spin** in the base build. Leave room on the screen for a spin control later.

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

1. Aim help, my fading-line idea: the aim line shows only near the end of the forward stroke, while the icon is moving, so practice strokes reveal where you'll shoot.
2. Spin: GamePigeon's red dot on a cue-ball icon. Top and back spin first, side spin later.
3. Levels, plus lifetime stats on each player's profile.
4. Cosmetics: cues, cloth colors, ball sets. The economy comes with this.
5. Ranked mode, alongside casual.
6. A back room with extra tables that opens once a server passes 15 players.

## Decided against (don't re-propose)

- Bots or computer opponents.
- A waiting line or "winner stays on". Every game ends with the table reset.
- Locking tables in public servers.
- Where you stand changing your aim, or walking to a spot to shoot or to place the cue ball.
- W/S controls, or holding Space to shoot.
- Alcohol.
- An economy, cosmetics or ranked mode before the mechanics are done.

## Raised but not decided (don't build)

- A practice table for a player who's alone, since new players leave empty servers fast.
- A daily trick-shot challenge with a leaderboard.
