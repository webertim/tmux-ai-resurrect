#!/usr/bin/env sh
# tmux-ai-resurrect TPM entry point.
#
# Registers AI harness commands (opencode, claude, codex) with
# tmux-resurrect's @resurrect-processes so that on restore, panes running
# a supported harness are relaunched via `tmux-ai-resurrect resume <harness>`
# — which reads the pane's saved session ID and passes it as a resume arg.

set -eu

CURRENT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
CLI="$CURRENT_DIR/bin/tmux-ai-resurrect"

# Space-separated list of tmux-resurrect "~name->command" entries.
# The ~ prefix means "match this process even when launched with args"
# (uses pane_full_command). The right-hand side is the restore command
# that tmux-resurrect will send to the pane on restore.
add_processes='"~opencode->'"$CLI"' resume opencode" "~claude->'"$CLI"' resume claude" "~codex->'"$CLI"' resume codex"'

# Idempotently append to any existing @resurrect-processes value.
existing=$(tmux show-option -gqv @resurrect-processes || true)
case "$existing" in
	*"$CLI resume"*)
		# Already installed for this CLI path; nothing to do.
		;;
	"")
		tmux set-option -g @resurrect-processes "$add_processes"
		;;
	*)
		tmux set-option -g @resurrect-processes "$existing $add_processes"
		;;
esac
