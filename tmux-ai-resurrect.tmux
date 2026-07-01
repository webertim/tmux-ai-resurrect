#!/usr/bin/env sh
# tmux-ai-resurrect TPM entry point.
#
# Wires our post-save hook into tmux-resurrect. The hook rewrites each
# harness pane's `pane_full_command` in the save file to include the
# session ID from our cache, so resurrect's default restore (which types
# the full command into the pane) resumes the correct session.

set -eu

CURRENT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
HOOK="$CURRENT_DIR/scripts/post-save.sh"

existing=$(tmux show-option -gqv @resurrect-hook-post-save-all || true)
case "$existing" in
	"$HOOK") ;;                                # already installed
	"")      tmux set-option -g @resurrect-hook-post-save-all "$HOOK" ;;
	*)
		# Something else is wired up. Don't clobber; log where to look.
		tmux display-message -d 0 \
			"tmux-ai-resurrect: @resurrect-hook-post-save-all is set to another script; not overriding"
		;;
esac
