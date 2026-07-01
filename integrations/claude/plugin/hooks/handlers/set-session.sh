#!/usr/bin/env sh
# Claude Code hook handler: forward the hook's stdin JSON to the
# tmux-ai-resurrect CLI, which extracts .session_id and records it for the
# current pane.
#
# This script lives inside a Claude Code plugin. Claude sets
# CLAUDE_PLUGIN_ROOT to the plugin's directory when invoking the hook.
# The plugin dir is a symlink into the tmux-ai-resurrect repo, so we walk
# up three levels from the real plugin dir to reach the repo root, then
# down into bin/.

set -eu

plugin_root="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
# Resolve any symlink so relative navigation lands in the actual repo.
if command -v realpath >/dev/null 2>&1; then
	plugin_root=$(realpath "$plugin_root")
fi

repo_root="$plugin_root/../../.."
cli="$repo_root/bin/tmux-ai-resurrect"

# Never break Claude if the CLI is missing — just no-op.
[ -x "$cli" ] || exit 0

exec "$cli" set --harness claude --from-stdin-json
