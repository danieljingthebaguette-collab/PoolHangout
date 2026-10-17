---
paths:
  - "src/Client/**"
  - "src/Shared/Theme.luau"
---

# Client code

- The client draws and asks. It never decides turns, fouls or where balls end up.
- PC only for now: build every control for mouse and keyboard. Leave the existing touch code in place, but don't test or extend it, or add touch versions of new controls, until the Mobile phase in BUILD_PLAN.md. From then on every control works by touch too, kept simple, with phones in landscape.
- In the top-down view, turn off character movement (the PlayerModule controls) so the character stays put while you aim and shoot, and hide the phone thumbstick and jump button so they don't fight the power meter. Turn both back on when leaving the view.
- Bind F with `ContextActionService` so phones get an on-screen button for it.
- Size UI with Scale or `UIScale` so it fits every screen, and keep it clear of Roblox's top bar. Touch targets of at least about 44 px come with the Mobile phase.
- For the top-down camera, set `CameraType` to `Scriptable`, and restore the previous camera type and subject afterwards.
- Show timers from the server's `clockEndsAt` using `workspace:GetServerTimeNow()`, not a local countdown.
- Disconnect everything a controller made when its game ends or the player respawns; never stack connections.
- Build UI in code, in the look `docs/STYLE.md` describes, with colors, fonts and sizes from `Theme.luau`. `Theme.Font` is a Font, so set it as `FontFace`, and use `Card.luau` for cards.
