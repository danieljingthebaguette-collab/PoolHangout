---
paths:
  - "src/Client/**"
  - "src/Shared/Theme.luau"
---

# Client code

- The client draws and asks. It never decides turns, fouls or where balls end up.
- Every control works with mouse and keyboard and with touch. Keep the touch version simple; phones play in landscape. Steps are checked on PC, and touch on a real phone at the end of each phase.
- In the top-down view, turn off character movement (the PlayerModule controls) so the character stays put while you aim and shoot, and hide the phone thumbstick and jump button so they don't fight the power meter. Turn both back on when leaving the view.
- Bind F with `ContextActionService` so phones get an on-screen button for it.
- Touch targets at least about 44 px. Size UI with Scale or `UIScale` so it fits every screen, and keep it clear of Roblox's top bar.
- For the top-down camera, set `CameraType` to `Scriptable`, and restore the previous camera type and subject afterwards.
- Show timers from the server's `clockEndsAt` using `workspace:GetServerTimeNow()`, not a local countdown.
- Disconnect everything a controller made when its game ends or the player respawns; never stack connections.
- Build UI in code, in the look `docs/STYLE.md` describes, with colors, fonts and sizes from `Theme.luau`. `Theme.Font` is a Font, so set it as `FontFace`, and use `Card.luau` for cards.
