#!/usr/bin/env sh
# tmux-ai-resurrect — install the Claude Code integration.
#
# Symlinks integrations/claude/plugin/ into Claude Code's plugin auto-load
# directory (~/.claude/skills/tmux-ai-resurrect/ by default). Claude picks
# up the hooks declared in hooks/hooks.json on next session start.
#
# No JSON editing, no jq, no python — just a symlink.

set -eu

DRY_RUN=0
FORCE=0
while [ $# -gt 0 ]; do
	case "$1" in
		--dry-run) DRY_RUN=1 ;;
		--force)   FORCE=1 ;;
		-h|--help)
			cat <<'EOF'
Usage: tmux-ai-resurrect install claude [--dry-run] [--force]

Symlinks the bundled Claude Code plugin into
~/.claude/skills/tmux-ai-resurrect/, so Claude auto-loads its hooks.

Environment:
  CLAUDE_PLUGINS_DIR   Override the target directory
                       (default: ~/.claude/skills).
EOF
			exit 0
			;;
		*) printf 'install-claude: unknown arg: %s\n' "$1" >&2; exit 2 ;;
	esac
	shift
done

: "${TMUX_AI_RESURRECT_ROOT:?call via 'tmux-ai-resurrect install claude'}"

src="$TMUX_AI_RESURRECT_ROOT/integrations/claude/plugin"
target_dir="${CLAUDE_PLUGINS_DIR:-$HOME/.claude/skills}"
target="$target_dir/tmux-ai-resurrect"

[ -d "$src" ] || { printf 'install-claude: plugin source missing: %s\n' "$src" >&2; exit 1; }

if [ -L "$target" ] && [ "$(readlink "$target")" = "$src" ]; then
	printf 'claude: already installed → %s\n' "$target"
	exit 0
fi

if [ -e "$target" ] && [ "$FORCE" -eq 0 ]; then
	printf 'claude: refusing to overwrite existing %s (use --force)\n' "$target" >&2
	exit 1
fi

if [ "$DRY_RUN" -eq 1 ]; then
	printf 'would: mkdir -p %s && ln -sfn %s %s\n' "$target_dir" "$src" "$target"
	exit 0
fi

mkdir -p "$target_dir"
# -n so ln doesn't dereference an existing symlink to $target and put the new
# link inside it. -f to replace a stale link cleanly.
ln -sfn "$src" "$target"
printf 'claude: installed → %s\n' "$target"
printf 'Restart Claude Code (or run /reload-plugins) to pick up the hooks.\n'
