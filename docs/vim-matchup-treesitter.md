# vim-matchup × treesitter × Blade — debugging notes

Notes from a long debug session (2026-05-21) that traced a series of cascading errors
in `.blade.php` files back to a Lua truthiness bug in the matchup config. Captured
here so the next time something in this chain breaks, you don't have to redo the
investigation.

The complete fix lives in `lua/custom/plugins/vim-matchup.lua`. This document explains
*why* that file does what it does.

## Symptoms (any of these means read this doc)

- `Error detected while processing CursorMoved Autocommands for "*"` on every cursor move
- `E5108: Error executing lua .../treesitter/query.lua:373: Query error at X:Y. Invalid node type "..."`
- Stack trace through `vim-matchup/lua/treesitter-matchup/internal.lua:68` (`get_lang_matches`)
- `%` doesn't navigate `<button>` ↔ `</button>` in Blade files even though `b:match_words` is set
- `:Lazy check` fails with `You have local changes in .../vim-matchup` after you patched the queries
- `:checkhealth` fails with `E5009: Invalid $VIMRUNTIME` (unrelated but co-occurred — see Gotchas)

## Root cause chain

Five layers stacked. Each one masked the next.

| # | Layer | Detail |
|---|-------|--------|
| 1 | **Lua truthiness** | `vim.g.matchup_treesitter_enabled = 0` looks like "off" but in Lua `0` is truthy. matchup's `if enabled` check passes → TS engine treated as enabled despite the config. Must be `false`. |
| 2 | **Broken matchup queries** | matchup ships `after/queries/<lang>/matchup.scm` for `quote`, `html`, `vue`, `svelte`, `templ`. These reference node types (`"\""`, `(element)`) that exist in standalone parsers but **not** in the host parser's injected sub-grammar (e.g. blade-injected HTML) — so they fail to compile when matchup walks the language tree. |
| 3 | **`include_match_words` filtering** | With TS active (per #1), `g:matchup_treesitter_include_match_words = true` filters `b:match_words` down to only entries TS confirms as scopes. TS confirms nothing for the broken langs → HTML tag pattern silently removed from active match list. `%` finds nothing. |
| 4 | **`vim.treesitter.query.set` doesn't replace** | First-attempt fix tried `query.set(lang, 'matchup', '')`. nvim's `query.get` at `query.lua:322` **concatenates** the explicit query *after* file content (`read_query_files(query_files) .. explicit_queries[...]`). The broken file content is still parsed. Override is appended, not substituted. |
| 5 | **Plugin-dir patches dirty the git tree** | Second-attempt fix patched the `.scm` files directly in `~/.local/share/nvim/lazy/vim-matchup/after/queries/`. That works — but `:Lazy check`/`update` refuse to operate on a dirty tree. |

## The fix (what `vim-matchup.lua` does)

Two changes, both in `lua/custom/plugins/vim-matchup.lua`:

### 1. `init` hook wraps `vim.treesitter.query.get_files`

Runs at nvim startup *before* any plugin loads, so matchup's memoize cache never
fills with broken results.

```lua
vim.treesitter.query.get_files = function(lang, query_name, is_included)
  if query_name == 'matchup' and vim.list_contains(broken_matchup_langs, lang) then
    return {}
  end
  return orig_get_files(lang, query_name, is_included)
end
```

Returns `{}` for `(broken_lang, 'matchup')` pairs → `query.get` reads no files →
`query_string == ""` → returns `nil` → matchup's `if not query then return {} end`
short-circuits cleanly.

Wraps `get_files` (plain function) rather than `get` (memoize wrapper) because matchup
itself calls `vim.treesitter.query.get:clear()` at `matchup.vim:436` to invalidate its
cache on `matchup.scm` saves — replacing `get` with a plain function strips that
`:clear` method.

### 2. `config` uses `false`, not `0`

```lua
vim.g.matchup_treesitter_enabled = false  -- NOT 0
```

Genuinely disables matchup's TS engine, so:
- Broken queries are never invoked (the wrap above is defense-in-depth)
- `b:match_words` is not filtered → HTML tag pattern stays active → `%` works

## Adding a new broken language

If a *different* language starts firing `E5108` on `CursorMoved` with the same
`get_lang_matches → get_matches` stack trace:

1. Note the language from the error (look for `query.lua:373: ... at X:Y. Invalid node type "..."` — the lang is named earlier in the matchup files; cross-reference `grep -ln '<problem-node>' ~/.local/share/nvim/lazy/vim-matchup/after/queries/*/matchup.scm`).
2. Edit `lua/custom/plugins/vim-matchup.lua` line ~15: add the language name to `broken_matchup_langs`.
3. Restart nvim (or `:lua vim.g._matchup_query_get_files_patched = nil` then `:source %` then re-open the file).

Currently filtered: `quote`, `html`, `vue`, `svelte`, `templ`.

## Verification

After restart, on a `.blade.php` buffer:

```vim
:lua print(vim.g._matchup_query_get_files_patched)  " → true
:echo &filetype                                      " → blade
:echo exists('b:match_words')                        " → 1
" cursor on `<button` → press % → jumps to </button>
" cursor on `(` → press % → jumps to )
:Lazy check                                          " → no failures
```

## Gotchas / related findings

- **`vim.g.X = 0` vs `false`** — any matchup option (or other plugin) read from Lua needs `false`, not `0`. Vimscript reads them the same way; Lua doesn't. Anywhere you see `vim.g.foo_enabled = 0` in a Lua config file, audit whether the consuming code is vimscript (fine) or Lua (broken).
- **`vim.treesitter.query.set` semantics** — it appends, not replaces. To genuinely block a query, wrap `get_files` to return `{}`. Setting an empty explicit query just gets concatenated onto the file content.
- **`E5009: Invalid $VIMRUNTIME`** that co-occurred with the matchup errors was unrelated — caused by `/usr/local/share/nvim/` being owned by UID 1001 (`hl-l3290cdw`, the Brother printer driver user) instead of `root:root`. Reinstalled nvim from the official tarball as root and `:checkhealth` recovered. If this recurs, check `ls -ld /usr/local/share/nvim` and reinstall with proper ownership.
- **`:Lazy check` refuses dirty trees** — if you ever need to test query patches by editing files directly in `~/.local/share/nvim/lazy/`, remember to `git checkout -- .` in that plugin's dir before running `:Lazy check`/`update`.
- **vim-blade's ftplugin** at `~/.local/share/nvim/lazy/vim-blade/ftplugin/blade.vim` sources `ftplugin/html.vim` to inherit HTML's `b:match_words`, then appends Blade directives (`@if/@endif`, `{{--/--}}`, etc.). If `b:match_words` is missing in a Blade buffer, check that vim-blade is in rtp and `loaded_matchit` is set (matchit's flag, used by html.vim as a "set match_words" gate).

## When to revisit

- **Upgrading to nvim 0.12+**: nvim-treesitter migrates to its `main` branch, which restructures query loading. The `get_files` wrap likely still works, but verify the API hasn't been renamed (`pcall` already guards against this). Once `main` branch is stable and matchup updates its queries, the wrap may become unnecessary.
- **vim-matchup updates**: if the upstream `quote`/`html`/etc. `matchup.scm` files get fixed (referencing only nodes that exist in injected sub-grammars), the wrap is harmless overhead and can be removed. Test by temporarily commenting out `init = install_matchup_query_wrap` and opening a Blade file.
