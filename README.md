# tmux-ai-resurrect

Persist and restore the *specific AI coding session* that was running in each
tmux pane across tmux server restarts, via
[tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect).

When you close and reopen tmux (reboot, crash, `killall tmux`), you don't
just get your panes and shells back — you get back into the exact
opencode / Claude Code / Codex CLI session each pane was on.

## Supported harnesses

| Harness      | Mechanism                                                                 | Install command                           |
|--------------|---------------------------------------------------------------------------|-------------------------------------------|
| opencode     | opencode plugin (auto-loaded from `~/.config/opencode/plugins/`)          | `tmux-ai-resurrect install opencode`      |
| Claude Code  | `SessionStart` + `UserPromptSubmit` hooks in `~/.claude/settings.json`    | `tmux-ai-resurrect install claude`        |
| Codex CLI    | (planned)                                                                 | —                                         |

Adding a harness is small: three shell scripts under `integrations/<name>/`.
See [integrations/README.md](./integrations/README.md).

## Install

Install as a [TPM](https://github.com/tmux-plugins/tpm) plugin. Add to
`~/.tmux.conf`:

```tmux
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'webertim/tmux-ai-resurrect'
```

Reload tmux config and fetch plugins: `prefix + I`.

Then put the CLI on your PATH (choose one):

```sh
# Option 1: add the plugin's bin/ dir to PATH in your shell rc
export PATH="$HOME/.tmux/plugins/tmux-ai-resurrect/bin:$PATH"

# Option 2: symlink into an existing bin dir on PATH
ln -sf "$HOME/.tmux/plugins/tmux-ai-resurrect/bin/tmux-ai-resurrect" \
       "$HOME/.local/bin/tmux-ai-resurrect"
```

Finally, install the per-harness integrations you use:

```sh
tmux-ai-resurrect install --all         # everything we can detect
# or, individually:
tmux-ai-resurrect install opencode
tmux-ai-resurrect install claude
```

Verify:

```sh
tmux-ai-resurrect doctor
```

## How it works

1. Each per-harness integration listens for session changes inside its
   harness and calls
   `tmux-ai-resurrect set --harness <name> --session-id <id>`, which writes
   a small record to `~/.cache/tmux-ai-resurrect/pane-<key>.tsv`.
2. The record is keyed by a **stable pane key**
   (`<session>--<window_idx>--<pane_idx>`) rather than tmux's volatile
   `%N` id — so the mapping survives tmux server restarts.
3. tmux-resurrect saves and restores the pane layout as usual.
4. On restore, the TPM entry `tmux-ai-resurrect.tmux` has registered
   opencode/claude/codex in `@resurrect-processes` with a resume wrapper:

   ```
   ~opencode->tmux-ai-resurrect resume opencode
   ~claude  ->tmux-ai-resurrect resume claude
   ~codex   ->tmux-ai-resurrect resume codex
   ```

   The wrapper looks up the pane's saved session id and execs the harness
   with the appropriate resume flag
   (`opencode --session ID`, `claude --resume ID`, `codex resume ID`).

## Dependencies

Deliberately minimal:

- **Required** for anyone: `tmux`, `tmux-resurrect`, POSIX `sh` + coreutils.
- **Claude install only**: `jq` (with a `python3` fallback, or a
  copy/paste snippet if neither is present).
- **opencode install**: nothing beyond `ln`. Opencode brings its own Bun.

Nothing is compiled, no Node runtime is bundled, no npm publish.

## Configuration

| Environment variable                | Purpose                                                                    |
|-------------------------------------|----------------------------------------------------------------------------|
| `TMUX_AI_RESURRECT_CACHE_DIR`       | Override cache dir (default: `$XDG_CACHE_HOME/tmux-ai-resurrect`).         |
| `TMUX_AI_RESURRECT_CLI`             | Set inside integrations to point at the CLI binary. Rarely needed manually.|
| `OPENCODE_PLUGINS_DIR`              | Override opencode install target (default: `~/.config/opencode/plugins/`). |
| `CLAUDE_SETTINGS_FILE`              | Override Claude settings path (default: `~/.claude/settings.json`).        |

## Extending

To add a new harness, create `integrations/<name>/` with `install.sh`,
`uninstall.sh`, and `status.sh`. See
[integrations/README.md](./integrations/README.md) for the exact
contract. The dispatcher picks it up automatically.

## License

MIT — see [LICENSE](./LICENSE).
