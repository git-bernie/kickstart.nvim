# Neovim Search Keymaps Audit & Recommendations

## Current State (After Cleanup)

Search keymaps are now organized by **tool**:

| Prefix | Purpose | Tool |
|--------|---------|------|
| `<leader>s*` | Search operations | Telescope |
| `<leader>f*` | FzfLua operations | FzfLua |
| `<leader>//` | Buffer fuzzy find | Telescope (intuitive like vim `/`) |
| `<leader>T*` | Terminal operations | Native |
| `<leader>t*` | Toggle operations | Various |

---

## Changes Made (Jan 2026)

### 1. Fixed `<leader>fd` Conflict
- **Problem**: Both FzfLua diagnostics and Telescope file browser mapped to `fd`
- **Solution**: Moved Telescope file browser to `se`/`sE`

| Old | New | Action |
|-----|-----|--------|
| `<leader>ff` | `<leader>se` | Telescope file explorer (cwd) |
| `<leader>fd` | `<leader>sE` | Telescope file explorer (buffer dir) |
| `<leader>fd` | kept | FzfLua diagnostics (document) |

### 2. Moved Terminals to `<leader>T*`
- **Problem**: `st`/`sv` (terminals) under search prefix
- **Solution**: Moved to `T*` to separate from `t*` (toggle)

| Old | New | Action |
|-----|-----|--------|
| `<leader>st` | `<leader>Ts` | Terminal split |
| `<leader>sv` | `<leader>Tv` | Terminal vsplit |

### 3. Deleted `<leader>FF` Typo
- Was duplicate of `<leader>fF`

### 4. Fixed `<leader>fm` Wrong Prefix
- **Problem**: Telescope media files under `f*` (FzfLua prefix)
- **Solution**: Moved to `s*` (Telescope prefix)

| Old | New | Action |
|-----|-----|--------|
| `<leader>fm` | `<leader>sM` | Telescope media files |

### 5. Consolidated `<leader>/*` Prefix
- **Problem**: Mixed Telescope/FzfLua, duplicates
- **Solution**: Moved to appropriate prefixes, kept only `//`

| Old | New | Action | Tool |
|-----|-----|--------|------|
| `<leader>/s` | deleted | duplicate of `sg` | — |
| `<leader>/g` | `<leader>sa` | grep with args | Telescope |
| `<leader>/g` | `<leader>fg` | live grep | FzfLua |
| `<leader>/b` | `<leader>fB` | grep current buffer | FzfLua |
| `<leader>/f` | `<leader>fp` | grep project | FzfLua |
| `<leader>//` | kept | buffer fuzzy find | Telescope |

---

## Current Keymaps by Prefix

### `<leader>s*` — Telescope Search

| Key | Action | Notes |
|-----|--------|-------|
| `sf` | Find files | |
| `sg` | Live grep | |
| `sH` | Live grep (hidden) | |
| `sw` | Grep current word | |
| `sa` | Grep with args | `"word" -- *.php` syntax |
| `sr` | Resume last search | |
| `s.` | Recent files (cwd) | |
| `s:` | Command history | |
| `sh` | Help tags | |
| `sk` | Keymaps | |
| `sm` | Man pages | |
| `sM` | Media files | |
| `sO` | Vim options | |
| `so` | Grep open files | |
| `sn` | Neovim config files | |
| `sd` | Diagnostics | |
| `sx` | Workspace diagnostics | Custom |
| `sc` | Document symbols (LSP) | |
| `ss` | Telescope builtins | |
| `su` | MRU files | |
| `se` | File explorer (cwd) | Telescope file browser |
| `sE` | File explorer (buffer dir) | Telescope file browser |

### `<leader>f*` — FzfLua

| Key | Action | Notes |
|-----|--------|-------|
| `fF` | Files | |
| `fg` | Live grep | |
| `fh` | Live grep (hidden) | |
| `fw` | Grep current word | |
| `fB` | Grep current buffer | |
| `fp` | Grep project | |
| `fl` | Grep resume | |
| `fz` | FzfLua picker | See all methods |
| `fd` | Diagnostics (document) | |
| `fD` | Diagnostics (workspace) | |
| `fb` | Git branches | |
| `fs` | Git status | |
| `fc` | Git buffer commits | |
| `fC` | Git all commits | |

### `<leader>T*` — Terminal

| Key | Action |
|-----|--------|
| `Ts` | Terminal split |
| `Tv` | Terminal vsplit |

### `<leader>//` — Buffer Search

| Key | Action | Tool |
|-----|--------|------|
| `//` | Buffer fuzzy find | Telescope |

### Other Search Keymaps

| Key | Action | Tool |
|-----|--------|------|
| `<C-p>` | Find files | Telescope |
| `<A-p>` | Find files (hidden) | Telescope |
| `<leader>ds` | Document symbols | Telescope (LSP) |
| `<leader>ws` | Workspace symbols | Telescope (LSP) |

---

## Design Principles

1. **Tool Separation**: `s*` = Telescope, `f*` = FzfLua
2. **Case Convention**: lowercase = common, UPPERCASE = variant (e.g., `fd`/`fD`, `se`/`sE`)
3. **Intentional Duplicates**: `sw`/`fw` both grep word — lets you pick tool in the moment
4. **Intuitive Special Cases**: `//` mimics vim's `/` search

---

## Quick Reference Card

```
TELESCOPE (leader-s)        FZFLUA (leader-f)           OTHER
────────────────────        ─────────────────           ─────
sf  files                   fF  files                   //  buffer fuzzy
sg  grep                    fg  grep                    Ts  terminal split
sH  grep+hidden             fh  grep+hidden             Tv  terminal vsplit
sw  grep word               fw  grep word
sa  grep with args          fB  grep buffer
sr  resume                  fp  grep project
s.  recent files            fl  resume
s:  command history         fz  fzf picker
sh  help                    fd  diagnostics (buf)
sk  keymaps                 fD  diagnostics (all)
sm  man pages               fb  git branches
sM  media files             fs  git status
sO  vim options             fc  git commits (buf)
so  grep open files         fC  git commits (all)
sn  neovim files
sd  diagnostics
sx  workspace diag
sc  doc symbols
ss  telescope picker
su  MRU files
se  file explorer
sE  file explorer here
```

---

## Remaining Considerations

### Intentional Duplicates (kept)
- `sw` / `fw` — grep word (Telescope vs FzfLua)
- `sr` / `fl` — resume search (Telescope vs FzfLua)
- `sd` / `fd` — diagnostics (Telescope vs FzfLua)

These are **by design** — same action, different tool, user picks preference.

### Future Ideas
- Add which-key group labels for discoverability
- Consider `<leader>g*` for git operations (currently under `f*`)
