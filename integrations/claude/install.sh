#!/usr/bin/env sh
# tmux-ai-resurrect — install the Claude Code integration.
#
# Merges two hook entries into ~/.claude/settings.json so that Claude's
# SessionStart and UserPromptSubmit hooks call our CLI, which reads the
# session_id from the hook's stdin JSON and writes it to the pane cache.
#
# Requires jq (with a python3 fallback). If neither is present the script
# prints the exact JSON fragment to paste in manually — so it degrades to
# copy/paste rather than hard-failing.

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

Adds SessionStart and UserPromptSubmit hooks to ~/.claude/settings.json.

Environment:
  CLAUDE_SETTINGS_FILE   Override the settings file
                         (default: ~/.claude/settings.json).
EOF
			exit 0
			;;
		*) printf 'install-claude: unknown arg: %s\n' "$1" >&2; exit 2 ;;
	esac
	shift
done

: "${TMUX_AI_RESURRECT_CLI:?call via 'tmux-ai-resurrect install claude'}"

settings="${CLAUDE_SETTINGS_FILE:-$HOME/.claude/settings.json}"
cmd="$TMUX_AI_RESURRECT_CLI set --harness claude --from-stdin-json"
marker='set --harness claude --from-stdin-json'

# --- JSON merge helpers -----------------------------------------------------

merge_with_jq() {
	# stdin: current settings JSON. stdout: merged JSON.
	jq --arg cmd "$cmd" --arg marker "$marker" '
		def install_hook(event; command; marker):
			.hooks //= {} |
			.hooks[event] //= [] |
			if (.hooks[event] | map(.hooks[]?.command // "") | map(test(marker; "l")) | any)
			then .
			else .hooks[event] += [{"hooks":[{"type":"command","command":command}]}]
			end;
		install_hook("SessionStart"; $cmd; $marker) |
		install_hook("UserPromptSubmit"; $cmd; $marker)
	'
}

merge_with_python() {
	# stdin: current settings JSON. stdout: merged JSON.
	python3 - "$cmd" "$marker" <<'PY'
import json, sys
cmd, marker = sys.argv[1], sys.argv[2]
data = json.load(sys.stdin)
hooks = data.setdefault("hooks", {})
for event in ("SessionStart", "UserPromptSubmit"):
    groups = hooks.setdefault(event, [])
    has_ours = any(
        marker in (h.get("command", "") or "")
        for g in groups
        for h in (g.get("hooks") or [])
    )
    if not has_ours:
        groups.append({"hooks": [{"type": "command", "command": cmd}]})
json.dump(data, sys.stdout, indent=2)
sys.stdout.write("\n")
PY
}

fallback_snippet() {
	cat <<EOF

Neither jq nor python3 is available — cannot safely edit
$settings.

Add the following block manually (merge into an existing "hooks" object
if you already have one):

{
  "hooks": {
    "SessionStart": [
      { "hooks": [ { "type": "command", "command": "$cmd" } ] }
    ],
    "UserPromptSubmit": [
      { "hooks": [ { "type": "command", "command": "$cmd" } ] }
    ]
  }
}
EOF
}

# --- Main -------------------------------------------------------------------

# Existing content (or {} if the file doesn't exist yet).
if [ -f "$settings" ]; then
	orig=$(cat "$settings")
else
	orig='{}'
fi

# Try jq, then python3, then fallback.
if command -v jq >/dev/null 2>&1; then
	merged=$(printf '%s' "$orig" | merge_with_jq)
elif command -v python3 >/dev/null 2>&1; then
	merged=$(printf '%s' "$orig" | merge_with_python)
else
	fallback_snippet
	exit 1
fi

# Idempotent — if nothing changed, exit cleanly.
if [ "$orig" = "$merged" ]; then
	printf 'claude: already installed → %s\n' "$settings"
	exit 0
fi

if [ "$DRY_RUN" -eq 1 ]; then
	printf '=== would write to %s ===\n' "$settings"
	printf '%s\n' "$merged"
	exit 0
fi

mkdir -p "$(dirname "$settings")"
if [ -f "$settings" ]; then
	ts=$(date +%Y%m%d-%H%M%S)
	cp -p "$settings" "$settings.bak.$ts"
	printf 'claude: backed up existing settings → %s.bak.%s\n' "$settings" "$ts"
fi

printf '%s\n' "$merged" >"$settings.tmp"
mv -f "$settings.tmp" "$settings"
printf 'claude: installed → %s\n' "$settings"
printf 'Restart claude to pick up the hooks.\n'
