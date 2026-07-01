#!/usr/bin/env sh
# Claude Code hook handler: forward the hook's stdin JSON to the
# tmux-ai-resurrect CLI, which extracts .session_id and records it for the
# current pane.
#
# `pwd -P` resolves the symlink Claude follows to reach this plugin, giving
# us the real repo path from which we can locate the CLI.

set -eu

plugin_root=$(cd "$CLAUDE_PLUGIN_ROOT" && pwd -P)
exec "$plugin_root/../../../bin/tmux-ai-resurrect" \
	set --harness claude --from-stdin-json
