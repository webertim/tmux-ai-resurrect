#!/usr/bin/env sh
# tmux-ai-resurrect — uninstall the Claude Code integration.
#
# Removes any hook entry in ~/.claude/settings.json whose command matches our
# marker string. Also drops any resulting empty matcher-group and empty
# top-level event arrays, then removes the "hooks" object if it's now empty.

set -eu

DRY_RUN=0
while [ $# -gt 0 ]; do
	case "$1" in
		--dry-run) DRY_RUN=1 ;;
		-h|--help)
			cat <<'EOF'
Usage: tmux-ai-resurrect uninstall claude [--dry-run]

Environment:
  CLAUDE_SETTINGS_FILE   Override the settings file
                         (default: ~/.claude/settings.json).
EOF
			exit 0
			;;
		*) printf 'uninstall-claude: unknown arg: %s\n' "$1" >&2; exit 2 ;;
	esac
	shift
done

settings="${CLAUDE_SETTINGS_FILE:-$HOME/.claude/settings.json}"
marker='set --harness claude --from-stdin-json'

if [ ! -f "$settings" ]; then
	printf 'claude: not installed (%s does not exist)\n' "$settings"
	exit 0
fi

strip_with_jq() {
	jq --arg marker "$marker" '
		def strip_event(event; marker):
			if (.hooks // {}) | has(event) then
				.hooks[event] |= (
					map(.hooks |= map(select((.command // "") | test(marker; "l") | not))) |
					map(select((.hooks // []) | length > 0))
				) |
				if .hooks[event] == [] then del(.hooks[event]) else . end
			else . end;
		strip_event("SessionStart"; $marker) |
		strip_event("UserPromptSubmit"; $marker) |
		if (.hooks // {}) == {} then del(.hooks) else . end
	'
}

strip_with_python() {
	python3 - "$marker" <<'PY'
import json, sys
marker = sys.argv[1]
data = json.load(sys.stdin)
hooks = data.get("hooks") or {}
for event in ("SessionStart", "UserPromptSubmit"):
    groups = hooks.get(event)
    if not groups:
        continue
    new_groups = []
    for g in groups:
        inner = [h for h in (g.get("hooks") or []) if marker not in (h.get("command", "") or "")]
        if inner:
            g["hooks"] = inner
            new_groups.append(g)
    if new_groups:
        hooks[event] = new_groups
    else:
        hooks.pop(event, None)
if hooks:
    data["hooks"] = hooks
else:
    data.pop("hooks", None)
json.dump(data, sys.stdout, indent=2)
sys.stdout.write("\n")
PY
}

orig=$(cat "$settings")

if command -v jq >/dev/null 2>&1; then
	stripped=$(printf '%s' "$orig" | strip_with_jq)
elif command -v python3 >/dev/null 2>&1; then
	stripped=$(printf '%s' "$orig" | strip_with_python)
else
	printf 'uninstall-claude: neither jq nor python3 available — remove hooks entries manually\n' >&2
	exit 1
fi

if [ "$orig" = "$stripped" ]; then
	printf 'claude: not installed (no matching hooks in %s)\n' "$settings"
	exit 0
fi

if [ "$DRY_RUN" -eq 1 ]; then
	printf '=== would write to %s ===\n' "$settings"
	printf '%s\n' "$stripped"
	exit 0
fi

ts=$(date +%Y%m%d-%H%M%S)
cp -p "$settings" "$settings.bak.$ts"
printf '%s\n' "$stripped" >"$settings.tmp"
mv -f "$settings.tmp" "$settings"
printf 'claude: uninstalled (backup at %s.bak.%s)\n' "$settings" "$ts"
