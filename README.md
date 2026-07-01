# tmux-ai-resurrect

Persist and restore the *specific AI coding session* that was running in each
tmux pane across tmux server restarts, using
[tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect).

Works with multiple AI coding harnesses via small, per-harness integrations:

| Harness      | Status  | Install                                          |
|--------------|---------|--------------------------------------------------|
| opencode     | planned | `tmux-ai-resurrect install opencode`             |
| Claude Code  | planned | `tmux-ai-resurrect install claude`               |
| Codex CLI    | planned | `tmux-ai-resurrect install codex`                |

> This repo is under active early development. The CLI, layout, and
> contracts may still change.

## How it works

1. When your AI harness switches sessions inside a tmux pane, a tiny
   integration pushes the new session ID into a per-pane cache file.
2. tmux-resurrect saves and restores the pane layout as usual.
3. On restore, `tmux-ai-resurrect`'s hook re-launches the harness with
   the saved session ID, so you land back in the exact session you left.

The pane is identified by a *stable* key (`session/window/pane-index`),
not the volatile `%N` id, so restoration survives tmux server restarts.

## License

MIT — see [LICENSE](./LICENSE).
