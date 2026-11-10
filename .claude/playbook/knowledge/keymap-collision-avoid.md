# Keymap collision check: keys to avoid

## Overview

Before binding a new key in this config, check three layers: **built-in Vim/Neovim keys** (including defaults that arrive with Neovim upgrades), **this repo's maps**, and **plugin-added maps**. Plugin READMEs often suggest keys that clobber built-ins. bookmarks.nvim suggests `mm`/`mo`/`ma`, and `ma` would break setting mark `a`.

## Keys that look free but aren't

- **`m{a-z}` / `m{A-Z}`** set Vim marks. Any `m?` map with a letter steals a mark.
- **`]b` `[b` `]B` `[B`** are Neovim 0.11+ defaults for `:bnext` / `:bprev` / `:blast` / `:bfirst`. 0.11 also added `]q` `[q` (quickfix), `]l` `[l` (loclist), `]t` `[t` (tags), `]a` `[a` (args), `]<Space>` (add blank line), and `gr*` LSP maps (`grn` `gra` `grr` `gri` `grt`).
- **`<leader>bn` / `<leader>bp`** are buffer next/prev (`init.lua`). `<leader>b` is shared with bookmarks.nvim. Never add a bare `<leader>b`, which would make the prefix wait (see `lua/kickstart/plugins/debug.lua:58`).
- **Insert `<C-k>`** is native digraph entry, freed from blink on 2026-11-10. **Insert `<C-s>`** is blink signature help.

## How to check (measure, don't grep alone)

Grep finds repo maps but misses plugin defaults and buffer-local maps:

```bash
grep -rnE "<leader>X" --include=*.lua . | grep -v '^\S*:\s*--'
```

Runtime check of the real global table:

```lua
-- nvim --headless "+luafile check.lua" +qa
for _, mode in ipairs({ 'n', 'x', 'o', 'i' }) do
  local m = vim.fn.maparg(' bm', mode, false, true)  -- ' ' = <leader>
  print(mode, m.rhs or (m.callback and '<fn>') or 'free', m.desc or '')
end
```

- **Built-in defaults:** run `:h ]b`, or `nvim --clean` then `:nmap ]b`.
- **Buffer-local maps** (LSP `ca`, ftplugin `cv`) only appear in a buffer of that kind. A bare-startup count undercounts them.

## Common Issues

| Issue | Cause | Fix |
|-------|-------|-----|
| `<leader>x` waits | bare map + `xN` maps | drop the bare map |
| mark `a` broken | `ma` remapped | use a leader key |
| `]b` not buffer | plugin took it | use `<leader>bj/bk` |

## Related

- `CLAUDE.md`: leader group map counts
- `lua/custom/plugins/bookmarks.lua`: worked example
- `../runbooks/test-keymap-headlessly.md`: headless keymap testing
- `../runbooks/debug-keymap-conflict.md`: when two maps already fight
- `~/.claude/playbook/knowledge/neovim-keymap-api.md`: `vim.keymap.set` / `maparg` API
