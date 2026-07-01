# Integrations

Each subdirectory here is one harness integration. To add a new harness,
create `integrations/<harness>/` with these three scripts:

| File           | Called by                                | Purpose                                                                 |
|----------------|------------------------------------------|-------------------------------------------------------------------------|
| `install.sh`   | `tmux-ai-resurrect install <harness>`    | Wire this harness up so it writes session IDs into the pane cache.       |
| `uninstall.sh` | `tmux-ai-resurrect uninstall <harness>`  | Reverse of `install.sh`. Must be idempotent — safe to run when absent. |
| `status.sh`    | `tmux-ai-resurrect doctor [<harness>]`   | Print one line describing install state (installed / missing / broken).  |

## Environment your scripts receive

- `TMUX_AI_RESURRECT_CLI` — absolute path to the `tmux-ai-resurrect` CLI.
  Reference this in generated config so users can move the plugin dir
  without breaking their harness config.
- `TMUX_AI_RESURRECT_ROOT` — absolute path to the plugin repo root.
  Handy for finding sibling assets like `plugin.mjs` fragments.

## Contract

An integration's job is to make its harness call

```sh
"$TMUX_AI_RESURRECT_CLI" set --harness <name> --session-id <id>
```

whenever the harness's active session changes inside a tmux pane. The
mechanism differs per harness (config file, plugin file, wrapper
script). Everything else — the pane key, the cache, the resurrect hook
wiring — is handled by the core.

## Flags

All three scripts should accept (and forward) `--dry-run`, printing what
they would do rather than doing it. `install.sh` should also accept
`--force` to overwrite pre-existing state.
