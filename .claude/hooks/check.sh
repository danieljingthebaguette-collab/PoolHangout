#!/bin/bash
# Stop hook: if any .luau file in src/ or tests/ changed since the last check, run selene and the Lune tests.
# Quiet on pass. On a failure it exits 2, so Claude sees the errors and keeps working on them.
cd "$CLAUDE_PROJECT_DIR" || exit 0
stamp="${TMPDIR:-/tmp}/poolhangout-checked"
now=$(find src tests -name '*.luau' -type f -print0 | sort -z | xargs -0 shasum | shasum)
[ "$now" = "$(cat "$stamp" 2>/dev/null)" ] && exit 0
echo "$now" >"$stamp"
out=$(selene src 2>&1) || { printf 'selene src failed:\n%s\n' "$out" >&2; exit 2; }
out=$(lune run tests/run 2>&1) || { printf 'lune run tests/run failed:\n%s\n' "$out" >&2; exit 2; }
exit 0
