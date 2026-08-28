# Mason Tool Resolution: Why "Missing" Tools Aren't

## Overview

"Is this formatter/linter actually installed?" has no single answer in this config. The same check returns different results depending on *what you ask* and *when you ask it*. Two independent mechanisms cause this, and together they have produced at least two wrong conclusions — an April 2026 session that concluded Mason formatters were unavailable to conform, and a false positive in the 2026-08-28 config audit.

Both mechanisms are benign. Nothing here is broken. But the diagnostics lie in a specific, repeatable way, and knowing how saves an hour each time.

## Mechanism 1 — the name is not the binary

`conform` and `nvim-lint` identify tools by an **internal name**, which is frequently not the executable:

- conform's `sql_formatter` runs the binary `sql-formatter`
- the identifier is what appears in `formatters_by_ft` / `linters_by_ft`

So `vim.fn.executable('sql_formatter')` returns **0** for a formatter that works perfectly. The tool is present, correctly installed, and formatting files — the probe just asked about a string that was never a command.

Ask the plugin, not the name:

```lua
require('conform').get_formatter_info('sql_formatter').command  --> "sql-formatter"
require('lint').linters.ruff.cmd                                --> "ruff"
```

## Mechanism 2 — Mason's PATH is load-order dependent

Mason installs into `~/.local/share/nvim/mason/bin`, which is **not on the shell `PATH`** (verified: zero entries). Mason prepends it to `vim.env.PATH` **when the plugin loads**.

The consequence: in a bare `nvim --headless` with no file open, nothing triggers Mason, the directory is never prepended, and *every* Mason-installed tool probes as missing. Open a `.sql` file first and the same check succeeds.

This is the same root cause as the `stylua` note in `CLAUDE.md` — Mason's binaries are invisible to any shell command, which is why the formatting step needs the full path:

```bash
~/.local/share/nvim/mason/bin/stylua .
```

## How to actually check

Ground truth, in increasing order of confidence:

1. **Filesystem** — unambiguous, no PATH involved:
   ```bash
   ls ~/.local/share/nvim/mason/bin/
   ```
2. **Resolved command** — with a relevant buffer open so Mason has loaded:
   ```vim
   :lua =require('conform').get_formatter_info('sql_formatter')
   ```
3. **Run it** — the only check that proves the whole pipeline:
   ```vim
   :lua require('conform').format({ bufnr = 0 })
   ```

The audit script (`bin/nvim-audit-evidence.sh`) now does 1 and 2 automatically: it prepends Mason's bin before probing, resolves identifiers to commands, and records both in `tools.json` as `name` and `command`.

## Common Issues

| Symptom | Cause | Check |
|---|---|---|
| `executable(name)` says 0, tool works | Probed the identifier, not the binary | `get_formatter_info(name).command` |
| Tool missing in headless, present interactively | Mason hadn't loaded, so PATH lacked its bin | Open a relevant file first |
| Mason tool invisible to a shell command | Mason's bin is never on the shell PATH | Use the full path |
| `tools.json` lists the same tool twice, disagreeing | Identifier and binary collected as separate entries | Compare `name` vs `command` |

## Related

- `bin/nvim-audit-evidence.sh` — the tool-liveness probe
- `docs/nvim-audit-2026-08-28.md` — finding V4, where this went wrong and was corrected
- `docs/nvim-audit.md` — the `jq` one-liner for listing genuinely-missing tools
- `CLAUDE.md` — the stylua full-path note, same root cause
