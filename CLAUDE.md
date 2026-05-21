# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a heavily customized fork of **kickstart.nvim** - a Neovim configuration. The main `init.lua` (~1,900 lines) is the heart of the config, with plugins organized in `lua/custom/plugins/` (100+ plugin files).

## Key Commands

```bash
# Format Lua code (required before commits)
stylua .

# Check formatting (CI runs this)
stylua --check .

# In Neovim - check plugin status
:Lazy

# In Neovim - validate dependencies
:checkhealth
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

## Formatting

Uses `.stylua.toml`: 160 char width, 2-space indent, single quotes preferred. GitHub Actions checks formatting on PRs.

## Branch Info

- Current branch: `jan-2026`
- Main branch for PRs: `master`
