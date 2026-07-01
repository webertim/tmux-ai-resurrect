#!/usr/bin/env sh
# tmux-ai-resurrect — report install state for the Claude Code integration.
# Always exits 0; prints a one-line status.

set -eu

settings="${CLAUDE_SETTINGS_FILE:-$HOME/.claude/settings.json}"
marker='set --harness claude --from-stdin-json'

if [ ! -f "$settings" ]; then
	if command -v claude >/dev/null 2>&1; then
		printf 'not installed (claude found on PATH — run: tmux-ai-resurrect install claude)\n'
	else
		printf 'not installed (claude not on PATH)\n'
	fi
	exit 0
fi

if grep -q "$marker" "$settings" 2>/dev/null; then
	printf 'installed (hook present in %s)\n' "$settings"
else
	printf 'not installed (hook not present in %s)\n' "$settings"
fi
