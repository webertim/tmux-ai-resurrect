#!/usr/bin/env sh
# tmux-ai-resurrect TPM entry point.
#
# Registers AI-harness commands with tmux-resurrect's @resurrect-processes
# so that panes running a supported harness are relaunched on restore via
# `tmux-ai-resurrect resume <harness>`, which threads through the pane's
# saved session id.

set -eu

CURRENT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
CLI="$CURRENT_DIR/bin/tmux-ai-resurrect"

add='"~opencode->'"$CLI"' resume opencode" "~claude->'"$CLI"' resume claude"'

existing=$(tmux show-option -gqv @resurrect-processes || true)
case "$existing" in
	*"$CLI resume"*) ;;  # already installed
	"")              tmux set-option -g @resurrect-processes "$add" ;;
	*)               tmux set-option -g @resurrect-processes "$existing $add" ;;
esac
