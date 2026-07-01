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
src="$TMUX_AI_RESURRECT_ROOT/integrations/opencode/plugin.mjs"
target_dir="${OPENCODE_PLUGINS_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/opencode/plugins}"
target="$target_dir/tmux-ai-resurrect.mjs"

if [ ! -L "$target" ]; then
	printf 'opencode: not installed (no symlink at %s)\n' "$target"
	exit 0
fi

if [ "$(readlink "$target")" != "$src" ]; then
	printf 'opencode: %s is a symlink but does not point at our plugin — leaving it alone\n' "$target" >&2
	exit 0
fi

if [ "$DRY_RUN" -eq 1 ]; then
	printf 'would: rm %s\n' "$target"
	exit 0
fi

rm "$target"
printf 'opencode: uninstalled (%s removed)\n' "$target"
