---
paths:
  - "src/Client/**"
  - "src/Shared/Theme.luau"
---

# Client code

- The client draws and asks. It never decides turns, fouls or where balls end up.
- Every control works with mouse and keyboard and with touch. Test with Studio's device emulator; phones play in landscape.
- In the top-down view, turn off character movement (the PlayerModule controls) so A/D only aim, and hide the phone thumbstick and jump button so they don't fight the power meter. Turn both back on when leaving the view.
- Bind F with `ContextActionService` so phones get an on-screen button for it.
- Touch targets at least about 44 px. Size UI with Scale or `UIScale` so it fits every screen, and keep it clear of Roblox's top bar.
- For the top-down camera, set `CameraType` to `Scriptable`, and restore the previous camera type and subject afterwards.
- Show timers from the server's `clockEndsAt` using `workspace:GetServerTimeNow()`, not a local countdown.
- Disconnect everything a controller made when its game ends or the player respawns; never stack connections.
- Build UI in code with colors, fonts and sizes from `Theme.luau`.
