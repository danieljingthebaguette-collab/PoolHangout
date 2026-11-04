#!/bin/bash
# Stop hook: if any .luau file in src/ or tests/ changed since the last check, run selene, the Luau type check and the
# Lune tests. Quiet on pass. On a failure it exits 2, so Claude sees the errors and keeps working on them.
cd "$CLAUDE_PROJECT_DIR" || exit 0
stamp="${TMPDIR:-/tmp}/poolhangout-checked"
now=$(find src tests -name '*.luau' -type f -print0 | sort -z | xargs -0 shasum | shasum)
[ "$now" = "$(cat "$stamp" 2>/dev/null)" ] && exit 0
echo "$now" >"$stamp"
out=$(selene src 2>&1) || { printf 'selene src failed:\n%s\n' "$out" >&2; exit 2; }

# The type check needs Roblox's type definitions for this luau-lsp version (downloaded once, not in git) and a
# sourcemap of the scripts (tools/Sourcemap.luau). Offline with no definitions yet, it's skipped.
version=$(luau-lsp --version)
defs=".luau-lsp/globalTypes-$version.d.luau"
[ -f "$defs" ] || curl -fsSL --create-dirs -o "$defs" \
	"https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/$version/scripts/globalTypes.d.luau"
if [ -f "$defs" ]; then
	out=$(lune run tools/Sourcemap 2>&1 && luau-lsp analyze --sourcemap sourcemap.json --definitions "@roblox=$defs" src 2>&1) ||
		{ printf 'luau-lsp type check failed:\n%s\n' "$(grep -v '^\[' <<<"$out" | awk '!seen[$0]++')" >&2; exit 2; }
fi

out=$(lune run tests/run 2>&1) || { printf 'lune run tests/run failed:\n%s\n' "$out" >&2; exit 2; }
exit 0
