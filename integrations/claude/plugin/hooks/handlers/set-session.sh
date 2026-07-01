#!/usr/bin/env sh
# Claude Code hook handler: extract session_id from the hook's stdin JSON
# and hand it to the tmux-ai-resurrect CLI.
#
# `pwd -P` resolves the symlink Claude follows to reach this plugin, giving
# us the real repo path from which we can locate the CLI.

set -eu

session_id=$(sed -n \
	's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
	| head -1)
# Silent no-op if no id — hook callers must never be broken by us.
[ -n "$session_id" ] || exit 0

plugin_root=$(cd "$CLAUDE_PLUGIN_ROOT" && pwd -P)
exec "$plugin_root/../../../bin/tmux-ai-resurrect" \
	set --harness claude --session-id "$session_id"
