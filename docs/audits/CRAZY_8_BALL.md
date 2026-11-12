# Crazy 8 Ball audit

From Daniel's two clips in `references/Crazy 8 Ball/Clips/`: Nov 7 (the "[9 BALL]" version, 6:13) and Nov 11 (the "[JUJUTSU]" update, 5:12). Read 2026-11-11 from contact sheets made with `tools/ContactSheet.sh`. Clip 1's middle (about 1:55–4:45) is mostly Daniel's desktop.

Reference only: ideas to weigh, never their art, layouts traced from them, or code. Anything on GAME_SPEC's "Decided against" list is marked **skip** and not re-proposed.

**Marks:** **fine** = ours already does this well enough. **better** = ours could be better here, for a small change. **worth it** = a bigger gap, worth building. **later** = a system for after launch, or a phase not started yet.

**Pick:** **take** = build it this week (step 6), **phase N** = build it in that phase, **later** = after launch, **skip** = don't build.

## 1. Before joining

| What they do | Ours | Mark | Pick |
| --- | --- | --- | --- |
| Game title carries the update's theme in brackets, "[9 BALL]" then "[JUJUTSU]", with a matching thumbnail | Store page not written yet | later | later: a bracket tag for each weekly update is free marketing |
| Own loading screen: game icon, name, "Waiting for an available server" | Roblox's default | better | later (Phase 6 polish) |
| Themed lobby, re-themed for an update (rooftop by the sea, then a Japanese temple with cherry trees) | Placeholder baseplate; the lodge is Phase 4 | worth it | phase 4, as planned; seasonal re-themes after launch |
| "Rewards ready!" card on joining: cash, a crate, a cue, the rank badge, a green Claim button | Nothing to claim | later | later (progression) |
| Daily rewards panel: days 1–7, Claim, Locked, "first week" | None | later | later (progression) |
| Quest line top center, "Now go win a match! 0/1, Reward:" and "Next: Wins 0/10" under the play button | None | later | later (missions are on the Later list) |
| Rank badge and progress top left ("Bronze", "2 wins to Bronze 3"), a rank icon beside every name, a "NEW RANK!" popup with a Continue button | None | later | later (ranked mode is on the Later list) |
| Cash counter bottom left with "Money Boost +0%" | None | later | later (progression) |
| A column of big icon buttons on the left: NEW SHOP, CUES, ABILITIES, FREE REWARD | A row at the bottom center, Illegal Soccer's layout: Abilities (Z), Invite (X) | fine | keep ours; Shop and Settings join the row (step 6) |
| "Players (N)" list top right | Roblox's own list (Tab) | fine | skip |
| Shop promo top right, "DIVINE CUE: ONE PER PLAYER" | None | later | later (no purchases) |
| A timed event, "Next Sky Lucky Block in 29:43" | None | later | later |
| Boards in the world: top countries, top streaks | None | later | later (stats are on the Later list) |
| An Emote button bottom right opening a grid of emotes | Roblox's own emote menu | better | later: one button to Roblox's emotes would be cheap, but it's another bottom button |
| "Play Global" matchmaking with "Don't want to wait?" | Walk up and join | skip | skip: it's a queue, close to the waiting line that's decided against |
| "NEW MODE!" and "SOLO MODE" signs | One mode | later | skip (8-ball only) |

## 2. Joining a table

| What they do | Ours | Mark | Pick |
| --- | --- | --- | --- |
| "Join a table!" over the spawn, with animated chevrons on the floor leading to a table | Nothing leads you | worth it | phase 4: part of the tutorial's last step (walk to a table), then shown to anyone who hasn't joined after 30 s *(proposal)* |
| Joining by standing in a yellow-outlined zone on the floor, painted with the mode ("1v1") and its state ("PLAYING", "FULL"); your zone glows green with sparkles | The "Join table" prompt (E); the sign comes in Phase 4 | better | phase 4: keep E (GAME_SPEC), and paint each table's floor with its mode and state like a court marking |
| A card floating over each table: "1v1 · Classic · 2/2 · PLAYING" with the players' avatars | Phase 4's "0/2 players" sign | better | phase 4: add the players' avatars to our sign |
| A rules panel while you wait: Classic, Difficult, Challenger, Abilities on | One rule set, abilities always on | skip | skip |
| "1/2 Waiting for opponent…" then "2/2 Starting in 3" as a pill at the bottom center | "Waiting for players" on the prompt, then a "Starting..." banner | better | take: count down 3, 2, 1 in our banner |
| "WHO BREAKS?" card with a spinning coin, then "BLURRED12 BREAKS" | A random breaker, shown only by the Turn card | worth it | take: a short "Who breaks?" card that lands on the breaker's name |

## 3. During a game

| What they do | Ours | Mark | Pick |
| --- | --- | --- | --- |
| Aiming from a low 3D camera behind the cue, scroll to zoom out, with a "Scroll to zoom out and see the angle better!" hint | The top-down view only | fine | skip (shooting from the normal view is decided against) |
| Walking anywhere during the other side's turn, camera behind you | Same | fine | skip |
| Top bar: each side's avatar, name and all 7 of its group's balls (sunk ones greyed), "OPEN TABLE" before groups, the shot clock as a number in a circle between them | Same layout, from 8 Ball Duels | fine | skip |
| "YOUR TURN" / "OPPONENT'S TURN" written under the top bar | Only the gold glow on the shooter's card | better | take: a one-line label under the clock |
| "YOU ARE SOLIDS" / "YOU ARE STRIPES" as groups are set | The card's group label changes | better | take: a short banner |
| "STREAK x3" under the top bar for pots in a row | None | later | later: CLAUDE.md holds streaks until the plan says so |
| "NICE SHOT!" floating up from a pot, and "+$100" pops | None | better | take, small: "Nice shot!" over a long pot or a bank *(proposal: one that crossed half the table)* |
| "FOUL!" big in red with the reason under it ("Scratched the white ball"), and "INVALID FIRST TARGET" in small red by the shooter | A banner: "Foul: wrong ball first. Player2 has ball in hand." | better | take in the style pass: a big "FOUL!" headline over our reason line |
| Ball in hand: "Ball in hand! Drag the white ball anywhere." with a hand cursor, and a pill at the bottom | The "Place ball · Click" hint and the ring | fine | skip |
| Coaching tips in a real match for new players: "Try a combo! Hit this ball into that one!", "Now pull the power bar to shoot!", "Press Q to use your ability!" | Coach's tutorial (Phase 4) | fine | phase 4, as planned |
| A vertical power bar on the right with a cue drawn in it; it turns into a rainbow at 100% | Our meter on the left with its %, the slingshot pull | better | take in the style pass: a flash of color when the pull reaches 100% |
| A spin picker: a cue ball with a red dot, left of center | No spin yet | later | later (on the Later list) |
| A white aim line with the cue ball's ghost and both directions; Eagle's Eye makes it much longer | The same, from 8 Ball Duels | fine | skip |
| On the 8: "PICK ANY POCKET FOR THE 8!" with every pocket marked | A gold ring on the pocket and the "Call pocket" hint | better | take: a one-line "Call your pocket" banner when your 8 turn starts |
| One ability per match: a meter at the bottom center fills with %, Q uses it, and a banner slides across with the player's avatar and the ability's name ("ABILITY · Fire Shot", "Eagle's Eye"); Fire Shot sets the ball alight | Our item bar, 2 squares, 5 random items, the big name at the top | fine | take one detail: the user's avatar on our big name card |
| Choosing your ability before the match (an ABILITIES button in the lobby) | Random items from the bar | skip | skip (our design) |
| Cosmetic cues with effects (a flaming cue) | None | later | later (cosmetics come with progression) |
| Every player holds a cue in 3D while at a table | No cue in 3D | better | phase 4 polish: a cue in the hands of everyone seated |
| Rank icon and country flag by every name | Names hidden at tables, the Turn card names the shooter | later | later |
| Bright cyan felt | Green felt (GAME_SPEC) | fine | skip |

## 4. End of a game and after

| What they do | Ours | Mark | Pick |
| --- | --- | --- | --- |
| "WINNER" with a crown over the winner's avatar, the score between the two avatars ("1-0", then "2-0" after a rematch) | The winner in the headline and each player's stats | better | take in the style pass: avatars, a crown on the winner, and a score that counts up over rematches |
| A rewards card: balls pocketed, nice shots, streak bonus, win bonus, rank reward, total, and a rank XP bar | Our 4 stats, no rewards | later | later (progression) |
| Rematch (green) and Leave (red) | Rematch and Back to lobby, a 10 s countdown | fine | skip |
| "Badge Awarded" toasts | None | later | later |
| Back in the lobby, the quest ticks to 1/1 and "Have fun!" | Back in the lobby, the table re-racks | later | later (missions) |

## 5. Their systems, in one list

Global matchmaking ("Play Global"), modes (Classic, Difficult, Challenger, Solo), a chosen ability, cash with boosts, ranks with XP and rank rewards, daily rewards, quests, a cue shop with effects, timed lucky blocks, boards in the world, Roblox badges and an emote panel. All **later** except matchmaking and modes, which are **skip**.

## What I'd take this week

Small, cheap, and each makes the game clearer or more fun:

1. A "Who breaks?" card before the break
2. "Your turn" / "Opponent's turn" under the clock
3. "You're Solids" / "You're Stripes" when groups are set
4. "Call your pocket" when your 8 turn starts
5. The countdown as 3, 2, 1 in the starting banner
6. "Nice shot!" over a long pot or a bank
7. In the style pass: a big "FOUL!" headline, a full-power flash on the meter, the user's avatar on the big ability name, and a crown and a rematch score on the end screen

Phase 4: chevrons to a table for new players, floor markings with each table's mode and state, avatars on the table signs, and a cue in the hands of everyone seated.
