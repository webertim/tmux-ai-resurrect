#!/usr/bin/env sh
# tmux-ai-resurrect — uninstall the Claude Code integration.

set -eu

DRY_RUN=0
while [ $# -gt 0 ]; do
	case "$1" in
		--dry-run) DRY_RUN=1 ;;
		-h|--help)
			printf 'Usage: tmux-ai-resurrect uninstall claude [--dry-run]\n'
			exit 0
			;;
		*) printf 'uninstall-claude: unknown arg: %s\n' "$1" >&2; exit 2 ;;
	esac
	shift
done

: "${TMUX_AI_RESURRECT_ROOT:?}"
src="$TMUX_AI_RESURRECT_ROOT/integrations/claude/plugin"
target_dir="${CLAUDE_PLUGINS_DIR:-$HOME/.claude/skills}"
target="$target_dir/tmux-ai-resurrect"

if [ ! -L "$target" ]; then
	printf 'claude: not installed (no symlink at %s)\n' "$target"
	exit 0
fi

if [ "$(readlink "$target")" != "$src" ]; then
	printf 'claude: %s is a symlink but does not point at our plugin — leaving it alone\n' "$target" >&2
	exit 0
fi

if [ "$DRY_RUN" -eq 1 ]; then
	printf 'would: rm %s\n' "$target"
	exit 0
fi

rm "$target"
printf 'claude: uninstalled (%s removed)\n' "$target"
