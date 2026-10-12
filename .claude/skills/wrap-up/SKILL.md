---
description: End-of-session wrap-up. Updates the Status section of docs/BUILD_PLAN.md, records known issues and proposes a commit.
disable-model-invocation: true
---

1. Review what changed this session: run `git status` and `git diff --stat`, and look back over our conversation.
2. Rewrite the Status section at the top of docs/BUILD_PLAN.md:
   - **Current phase** (move to the next phase only after I've said this one's "Done when" test passed), and any task in progress with exactly where it stands
   - **Last session:** today's date and 1–3 lines on what got done
   - **Next up:** the next task
   - **Known issues:** bugs and loose ends, one line each. Remove the ones that are fixed.
3. Tick any finished tasks. If a game decision changed this session, make sure GAME_SPEC.md says so; if an architecture decision changed, update ARCHITECTURE.md.
4. If we learned something every future session needs (a gotcha, a convention), suggest a line for CLAUDE.md and add it only if I agree.
5. Propose a commit message (a one-line summary, then short bullets) and ask whether to commit. If anything was built or changed in the place, remind me to save it in Studio.
