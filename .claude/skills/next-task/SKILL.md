---
description: Pick up the next unchecked task in the current build phase, plan it, build it after my OK, test it, and tick it off.
argument-hint: "[a specific task, or leave empty for the next one]"
disable-model-invocation: true
---

1. Read the Status section and the current phase in docs/BUILD_PLAN.md. If I named a task ($ARGUMENTS), do that one. Otherwise take the first unchecked task in the current phase whose owner label mentions Claude. If none are left, list what's left for me (my tasks and the phase's "Done when" test) and stop.
2. Read the parts of GAME_SPEC.md and ARCHITECTURE.md the task touches, the rule files in .claude/rules/ for the folders you'll work in, and the existing code it affects.
3. Reply with a short plan: what you'll add or change (files and functions), how we'll know it works, anything I need to do in Studio, and any spec question that needs my answer. Then wait for my OK.
4. Build it in small steps, following CLAUDE.md.
5. Check it: `selene src` and the type check (the Stop hook runs both), then `lune run tests/run` if physics, rules or Config changed, then the playtest skill with what to look for. Fix what fails.
6. Tick the task's box in BUILD_PLAN.md and update Status. Then tell me in plain English what changed, what to try in Studio and what to look for, and anything I need to save or set.
