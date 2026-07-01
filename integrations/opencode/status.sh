#!/usr/bin/env sh
# tmux-ai-resurrect — report install state for the opencode integration.
# Always exits 0; prints a one-line status.

set -eu

: "${TMUX_AI_RESURRECT_ROOT:?}"
src="$TMUX_AI_RESURRECT_ROOT/integrations/opencode/plugin.mjs"
target_dir="${OPENCODE_PLUGINS_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/opencode/plugins}"
target="$target_dir/tmux-ai-resurrect.mjs"

if [ -L "$target" ] && [ "$(readlink "$target")" = "$src" ]; then
	printf 'installed (symlink at %s)\n' "$target"
elif [ -e "$target" ]; then
	printf 'conflict: %s exists but does not point at our plugin\n' "$target"
elif command -v opencode >/dev/null 2>&1; then
	printf 'not installed (opencode found on PATH — run: tmux-ai-resurrect install opencode)\n'
else
	printf 'not installed (opencode not on PATH)\n'
fi
