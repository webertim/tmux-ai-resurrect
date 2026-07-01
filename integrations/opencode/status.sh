#!/usr/bin/env sh
# tmux-ai-resurrect — report install state for the opencode integration.
# Always exits 0; prints a one-line status.

set -eu

: "${TMUX_AI_RESURRECT_ROOT:?}"
target_dir="${OPENCODE_PLUGINS_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/opencode/plugins}"

check() {
	src="$1"; target="$2"
	[ -L "$target" ] && [ "$(readlink "$target")" = "$src" ]
}

srv_ok=1; check "$TMUX_AI_RESURRECT_ROOT/integrations/opencode/plugin.js" "$target_dir/tmux-ai-resurrect.js" || srv_ok=0
tui_ok=1; check "$TMUX_AI_RESURRECT_ROOT/integrations/opencode/tui.js"    "$target_dir/tmux-ai-resurrect-tui.js" || tui_ok=0

if [ "$srv_ok" -eq 1 ] && [ "$tui_ok" -eq 1 ]; then
	printf 'installed (server + tui in %s)\n' "$target_dir"
elif [ "$srv_ok" -eq 1 ] || [ "$tui_ok" -eq 1 ]; then
	missing=""
	[ "$srv_ok" -eq 0 ] && missing="server"
	[ "$tui_ok" -eq 0 ] && missing="${missing:+$missing, }tui"
	printf 'partial (missing: %s) — try: tmux-ai-resurrect install opencode --force\n' "$missing"
elif command -v opencode >/dev/null 2>&1; then
	printf 'not installed (opencode found on PATH — run: tmux-ai-resurrect install opencode)\n'
else
	printf 'not installed (opencode not on PATH)\n'
fi
