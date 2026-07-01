#!/usr/bin/env sh
# tmux-ai-resurrect — report install state for the Claude Code integration.
# Always exits 0; prints a one-line status.

set -eu

: "${TMUX_AI_RESURRECT_ROOT:?}"
src="$TMUX_AI_RESURRECT_ROOT/integrations/claude/plugin"
target_dir="${CLAUDE_PLUGINS_DIR:-$HOME/.claude/skills}"
target="$target_dir/tmux-ai-resurrect"

if [ -L "$target" ] && [ "$(readlink "$target")" = "$src" ]; then
	printf 'installed (symlink at %s)\n' "$target"
elif [ -e "$target" ]; then
	printf 'conflict: %s exists but does not point at our plugin\n' "$target"
elif command -v claude >/dev/null 2>&1; then
	printf 'not installed (claude found on PATH — run: tmux-ai-resurrect install claude)\n'
else
	printf 'not installed (claude not on PATH)\n'
fi
