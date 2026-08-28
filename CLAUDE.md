# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a heavily customized fork of **kickstart.nvim** - a Neovim configuration. The main `init.lua` (~1,900 lines) is the heart of the config, with plugins organized in `lua/custom/plugins/` (100+ plugin files).

## Key Commands

```bash
# Format Lua code (required before commits)
# NOTE: stylua is installed by Mason and is NOT on PATH. Use the full path,
# or add ~/.local/share/nvim/mason/bin to PATH in your shell profile.
~/.local/share/nvim/mason/bin/stylua .

# Check formatting (CI runs this)
~/.local/share/nvim/mason/bin/stylua --check .

# In Neovim - check plugin status
:Lazy

# In Neovim - validate dependencies
:checkhealth

# In Neovim - which-key popup not appearing on <leader>?
:WKDiag
:WKFix
```

## Architecture

### Plugin Organization

- **`init.lua`** - Main config: options, keymaps, autocmds, and lazy.nvim setup
- **`lua/kickstart/plugins/`** - Core kickstart plugins (debug, autopairs, gitsigns, etc.)
- **`lua/custom/plugins/`** - Custom plugins (one file per plugin, auto-imported by lazy.nvim)
- **`after/plugin/keymaps.lua`** - Extensive custom keymaps (~30KB)
- **`after/ftplugin/{filetype}.lua`** - Filetype-specific settings (php.lua, json.lua, markdown.lua, etc.)

### Adding a New Plugin

Create `lua/custom/plugins/{name}.lua` returning a plugin spec:
```lua
return {
  'owner/plugin-name',
  event = 'VimEnter',        -- lazy load trigger
  keys = { ... },            -- or lazy load on keypress
  opts = { ... },            -- configuration
}
```

Lazy.nvim auto-imports all files in `lua/custom/plugins/` via `{ import = 'custom.plugins' }` in init.lua.

### Key Mapping Conventions

- **Leader:** `<space>`
- **Leader groups:** `<leader>c` (code), `<leader>d` (document), `<leader>f` (file/fzf), `<leader>g` (git), `<leader>s` (search), `<leader>t` (toggle), `<leader>w` (workspace)
- **Window navigation:** `<C-hjkl>`

### Project-Local Config

Files named `.nvim.lua` or `.nvimrc` in project root are automatically sourced at startup for per-project settings.

### Vendored Tools

- **`bin/lc-codec.php`** — standalone LoanConnect ID encoder/decoder (V1 Rijndael-256 + V2 libsodium, auto-detect). Called by `lua/lc-cyber.lua` for `<leader>xd` / `<leader>xy` / `<leader>xe` keymaps. No external repo dependency. Full reference: [`docs/lc-codec.md`](docs/lc-codec.md).
- **`bin/lc-lookup.php`** — standalone PDO dumper for LoanConnect lookup tables (lenders, partners, products...). Reads a manifest of SQL queries and writes JSON to `~/.cache/lc-lookup/`. Called by `lua/lc-lookup.lua` for `<leader>xL` / `<leader>xll` / `<leader>xlp` / `<leader>xlr` picker keymaps and `:LcLookup` / `:LcLookupRefresh` / `:LcLookupCheck` commands. No Laravel dependency. Full reference: [`docs/lc-lookup.md`](docs/lc-lookup.md).
- **`bin/nvim-audit-evidence.sh`** — read-only measurement pass for the config health audit (startup timing, lazy stats, hot autocmds, keymap dump, tool liveness, health, oldfiles drift). Writes raw output to `~/.cache/nvim-audit/<date>` by default. Driven by the `/nvim-audit` slash command. Full reference: [`docs/nvim-audit.md`](docs/nvim-audit.md).
- **`bin/php-array-convert.php`** — converts a PHP array literal to JSON or YAML. Backs the `<leader>jp` / `<leader>jy` visual-mode keymaps, which replace the selection in place. Uses `eval`, but only after gating the snippet through an allowlist built on PHP's own lexer (`token_get_all`), so variables, function calls, constants and interpolation are rejected before evaluation — nothing executable can reach `eval`. Self-test: `./bin/php-array-convert.php --selftest`. Full reference: [`docs/php-array-convert.md`](docs/php-array-convert.md).

### Diagnostics

- **`after/plugin/which-key-diag.lua`** — `:WKDiag` / `:WKFix` plus a background watchdog for a which-key failure mode: the popup stops appearing on `<leader>` while the keymaps themselves keep working, until Neovim is restarted.

  **Why it happens:** which-key v3 doesn't hook the keypress stream. For each prefix it installs a real, *buffer-local*, `nowait` keymap whose `desc` is `which-key-trigger`; pressing the prefix invokes that mapping, which opens the popup. Your leader mappings are separate global mappings. Every time you execute a mapping, which-key calls `Triggers.suspend()` (`state.lua:222`), which **deletes** those trigger mappings — otherwise feeding the keys back through `nvim_feedkeys` would recurse forever — then re-installs them on a deferred timer (`triggers.lua:139`). If that re-install is ever skipped, the trigger stays gone: keymaps still work (untouched), but nothing opens the popup. which-key's own self-heal poll (`state.lua:157`) only checks whether the *Mode object* exists, **not** whether the trigger mappings do — so the broken state is permanent for that buffer.

  **Manual check** (`:verbose nmap <Space>` is useless here — it lists the entire leader tree):

  ```vim
  :lua =vim.fn.maparg(' ', 'n', false, true)
  ```

  Look for `desc = "which-key-trigger"`. Missing → run `:WKFix`.

  **Watchdog:** polls every 2s, repairs after ~4s of confirmed breakage, skips while the popup is open or a macro is recording. Each repair is logged to `~/.cache/nvim/which-key-watchdog.log` (survives restarts — this is the evidence trail for identifying *which* re-install path is being skipped). Disable with `vim.g.wk_watchdog = false`; silence notifications with `vim.g.wk_watchdog_notify = false`.

  **Status:** mitigation at a proven weak point, not a proven root-cause fix. The lost-trigger mechanism is confirmed; the specific code path that skips the re-install is not yet identified. Candidates: the macro defer at `triggers.lua:147`, the silent skip in `Triggers.add` when `is_mapped()` sees a competing mapping, or an error thrown inside the blocking `getcharstr` loop in `State.start`.

## Formatting

Uses `.stylua.toml`: 160 char width, 2-space indent, single quotes preferred. GitHub Actions checks formatting on PRs.

## Branch Info

- Current branch: `jan-2026`
- Main branch for PRs: `master`
