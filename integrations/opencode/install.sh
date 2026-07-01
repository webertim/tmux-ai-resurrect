#!/usr/bin/env sh
# tmux-ai-resurrect — install the opencode integration.
#
# Symlinks integrations/opencode/plugin.js (server hooks) and
# integrations/opencode/tui.js (TUI hooks + route poll) into the
# opencode plugins directory. Idempotent.

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

Symlinks two opencode plugin files (server + TUI) into your opencode
plugins directory.

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

: "${TMUX_AI_RESURRECT_ROOT:?call via 'tmux-ai-resurrect install opencode'}"

target_dir="${OPENCODE_PLUGINS_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/opencode/plugins}"

link_one() {
	src="$1"; target="$2"
	[ -f "$src" ] || { printf 'install-opencode: plugin source missing: %s\n' "$src" >&2; return 1; }

	if [ -L "$target" ] && [ "$(readlink "$target")" = "$src" ]; then
		printf 'opencode: already installed → %s\n' "$target"
		return 0
	fi

	if [ -e "$target" ] && [ "$FORCE" -eq 0 ]; then
		printf 'opencode: refusing to overwrite existing %s (use --force)\n' "$target" >&2
		return 1
	fi

	if [ "$DRY_RUN" -eq 1 ]; then
		printf 'would: mkdir -p %s && ln -sf %s %s\n' "$target_dir" "$src" "$target"
		return 0
	fi

	mkdir -p "$target_dir"
	ln -sf "$src" "$target"
	printf 'opencode: installed → %s\n' "$target"
}

# Server plugin only. opencode's plugins-dir loader instantiates EVERY
# exported function in a module as a plugin, so plugin.js must export just
# its factory (helpers are module-internal).
link_one "$TMUX_AI_RESURRECT_ROOT/integrations/opencode/plugin.js" \
         "$target_dir/tmux-ai-resurrect.js"

# NOTE: tui.js is intentionally NOT installed. opencode's server process
# loads every plugins-dir file with kind="server" and throws on a tui-only
# module ("must default export an object with server()"), which cascades and
# breaks provider config. There is no supported way to drop a standalone TUI
# plugin into the plugins dir in current opencode, so the companion is
# disabled until a supported delivery path exists.

[ "$DRY_RUN" -eq 1 ] || printf 'Restart opencode to pick up the plugins.\n'
