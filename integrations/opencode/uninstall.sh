#!/usr/bin/env sh
# tmux-ai-resurrect — uninstall the opencode integration.

set -eu

DRY_RUN=0
while [ $# -gt 0 ]; do
	case "$1" in
		--dry-run) DRY_RUN=1 ;;
		-h|--help)
			printf 'Usage: tmux-ai-resurrect uninstall opencode [--dry-run]\n'
			exit 0
			;;
		*) printf 'uninstall-opencode: unknown arg: %s\n' "$1" >&2; exit 2 ;;
	esac
	shift
done

: "${TMUX_AI_RESURRECT_ROOT:?}"
target_dir="${OPENCODE_PLUGINS_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/opencode/plugins}"

unlink_one() {
	src="$1"; target="$2"
	if [ ! -L "$target" ]; then
		printf 'opencode: %s not installed\n' "$target"
		return 0
	fi
	if [ "$(readlink "$target")" != "$src" ]; then
		printf 'opencode: %s is a symlink but does not point at our plugin — leaving it alone\n' "$target" >&2
		return 0
	fi
	if [ "$DRY_RUN" -eq 1 ]; then
		printf 'would: rm %s\n' "$target"
		return 0
	fi
	rm "$target"
	printf 'opencode: removed %s\n' "$target"
}

unlink_one "$TMUX_AI_RESURRECT_ROOT/integrations/opencode/plugin.js" \
           "$target_dir/tmux-ai-resurrect.js"
unlink_one "$TMUX_AI_RESURRECT_ROOT/integrations/opencode/tui.js" \
           "$target_dir/tmux-ai-resurrect-tui.js"
