#!/usr/bin/env sh
# tmux-ai-resurrect — install the opencode integration.
#
# Symlinks integrations/opencode/plugin.js into the opencode plugins
# directory. Idempotent: safe to run repeatedly. Refuses to clobber an
# existing non-symlink file at the target unless --force is given.

set -eu

DRY_RUN=0
FORCE=0
while [ $# -gt 0 ]; do
	case "$1" in
		--dry-run) DRY_RUN=1 ;;
		--force)   FORCE=1 ;;
		-h|--help)
			cat <<'EOF'
Usage: tmux-ai-resurrect install opencode [--dry-run] [--force]

Symlinks the opencode plugin into your opencode plugins directory.

Environment:
  OPENCODE_PLUGINS_DIR   Override the target dir
                         (default: $XDG_CONFIG_HOME/opencode/plugins
                                   or ~/.config/opencode/plugins).
EOF
			exit 0
			;;
		*) printf 'install-opencode: unknown arg: %s\n' "$1" >&2; exit 2 ;;
	esac
	shift
done

: "${TMUX_AI_RESURRECT_ROOT:?call via 'tmux-ai-resurrect install opencode' — TMUX_AI_RESURRECT_ROOT not set}"

src="$TMUX_AI_RESURRECT_ROOT/integrations/opencode/plugin.js"
target_dir="${OPENCODE_PLUGINS_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/opencode/plugins}"
target="$target_dir/tmux-ai-resurrect.js"

[ -f "$src" ] || { printf 'install-opencode: plugin source missing: %s\n' "$src" >&2; exit 1; }

if [ -L "$target" ] && [ "$(readlink "$target")" = "$src" ]; then
	printf 'opencode: already installed → %s\n' "$target"
	exit 0
fi

if [ -e "$target" ] && [ "$FORCE" -eq 0 ]; then
	printf 'opencode: refusing to overwrite existing %s (use --force)\n' "$target" >&2
	exit 1
fi

if [ "$DRY_RUN" -eq 1 ]; then
	printf 'would: mkdir -p %s && ln -sf %s %s\n' "$target_dir" "$src" "$target"
	exit 0
fi

mkdir -p "$target_dir"
ln -sf "$src" "$target"
printf 'opencode: installed → %s\n' "$target"
printf 'Restart opencode to pick up the plugin.\n'
