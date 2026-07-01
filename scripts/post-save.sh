#!/usr/bin/env sh
# tmux-ai-resurrect post-save hook.
#
# Runs after tmux-resurrect writes its save file. For each pane running a
# supported AI harness, injects the current session ID from our pane cache
# into the pane's full-command field, so that resurrect's default restore
# (which types the full command back into the pane) resumes the correct
# session.
#
# We prefer the cache over any session ID that may already be in argv,
# because the cache reflects the harness's live state (session switches,
# /new, etc.), whereas argv only reflects how the harness was launched.

set -eu

RESURRECT_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect"
CACHE_DIR="${TMUX_AI_RESURRECT_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/tmux-ai-resurrect}"

state_file=$(readlink -f "$RESURRECT_DIR/last" 2>/dev/null || true)
[ -n "$state_file" ] && [ -f "$state_file" ] || exit 0
[ -d "$CACHE_DIR" ] || exit 0

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

# resurrect pane line format (tab-separated):
#   pane <sess> <win> <pane> :* <active> <win_name> :<cwd> <active2> <cmd> <full_cmd>
# field 10 is <cmd>, field 11 is <full_cmd> (prefixed with ':' when set).
while IFS= read -r line; do
	case "$line" in
		pane*)
			sess=$(printf '%s' "$line" | cut -f2)
			win=$(printf '%s' "$line" | cut -f3)
			pi=$(printf '%s' "$line" | cut -f4)
			cmd=$(printf '%s' "$line" | cut -f10)
			case "$cmd" in
				opencode|claude)
					safe=$(printf '%s' "${sess}--${win}--${pi}" | tr '/' '_')
					cache="$CACHE_DIR/${safe}-${cmd}.session"
					if [ -f "$cache" ]; then
						sid=$(cat "$cache")
						case "$cmd" in
							opencode) new=":$cmd --session $sid" ;;
							claude)   new=":$cmd --resume $sid" ;;
						esac
						prefix=$(printf '%s' "$line" | cut -f1-10)
						# Rebuild with a literal tab between prefix and new field 11.
						line=$(printf '%s\t%s' "$prefix" "$new")
					fi
					;;
			esac
			;;
	esac
	printf '%s\n' "$line"
done <"$state_file" >"$tmp"

cp "$tmp" "$state_file"
