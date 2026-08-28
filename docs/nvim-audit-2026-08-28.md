# Neovim config audit — 2026-08-28

- **Neovim version:** 0.12.5 (upgraded from 0.12.2 earlier today)
- **Ecosystem research date:** 2026-08-28 (this run — no prior report existed)
- **Evidence:** `~/.cache/nvim-audit/2026-08-28/` (from `./bin/nvim-audit-evidence.sh`)
- **Prior art referenced:** `docs/search-keymaps-audit.md`
- **Caveats:** the evidence script produced no LSP-introspection warning, so tool liveness is complete for this run — both the Mason half and the `lsp:<name>` half. **However**, this run's `tools.json` was produced *before* the identifier-vs-binary fix to `bin/nvim-audit-evidence.sh`, so its `executable` field is unreliable for `conform`- and `lint`-sourced entries. See the correction in V4.

Findings are tiered by **how much they should be trusted**, not by topic. A measured fact and a reasoned opinion look identical on the page unless they are kept apart, and mixing them makes the measurements look like opinions too.

## Headline

The config is in good health and is genuinely *ahead* of kickstart upstream in one important respect (LSP wiring). It is not slow because of plugin count. It is slow because of one file. Nearly every real finding below is small, mechanical, and independent — there is no structural problem to unwind.

Startup is **200.9 ms median** (5 runs: 179.6 / 181.8 / 200.9 / 201.3 / 218.8). Of that, **72.6 ms — roughly 40% — is `init.lua` executing its own top-level code.** Every other single contributor is under 4.4 ms.

## Work profile vs. reality

`oldfiles-filetypes.txt` against the stated profile:

| Filetype | Count | Profile says |
|---|---|---|
| `md` | 33 | Markdown-heavy — **confirmed, dominant** |
| `php` + `ctp` | 17 + 8 | PHP/Laravel + CakePHP 2 — **confirmed** |
| `lua` | 3 | This config — consistent |
| `sh` | 2 | Under-counted by design; not evidence |
| `sql` | 1 | **Drift — see below** |
| `py` | 0 | **Drift — see below** |

Two mismatches worth naming rather than quietly tolerating:

**Python is in the profile and absent from the histogram.** Zero `.py` files in oldfiles, and `ruff` (from `nvim-lint`) and `isort` (from `conform`) are both *not executable*. The tooling for Python is half-installed and the work isn't happening. Either is fine on its own; together they mean nobody would notice if the Python setup were broken — and it partly is. Decide which way to resolve it: finish the install, or drop Python from the profile until the learning actually starts.

**SQL shows 1 file.** This is weaker evidence than it looks — dadbod work happens in scratch buffers and UI panes that never become oldfiles entries, much like the shell caveat. Treat the SQL profile entry as unverified by this instrument rather than contradicted. But note `sql_formatter` is also not executable (below), so it is worth an actual check.

---

# Verified

Backed by a measurement or a fetched source from this run. Evidence shown inline.

## V1 — `init.lua` is 40% of startup

```
72.630 self  sourcing /home/bernie/.config/nvim/init.lua
 4.326 self  sourcing .../lazy/cmp-dotenv/after/plugin/cmp-dotenv.lua
 2.830 self  require('vim.diagnostic')
```
*(`startup-1.txt`, total for that run 179.633 ms)*

`init.lua` is 2,165 lines and nearly all of it executes at top level on every launch. The gap between it and the #2 item is 17×. No plugin change will move startup meaningfully while this stands.

This is a finding, not yet a fix — carving it up is a real refactor and out of scope here. The measurement's value is in ruling *out* the usual suspects: it is not the 144 plugins, not the colorschemes, not lazy.nvim.

## V2 — `cmp-dotenv` loads eagerly to provide a source nothing queries

The #2 startup contributor, **4.326 ms**, is dead weight:

- `lua/custom/plugins/cmp-dotenv.lua:1-3` is a bare spec with no `enabled`, no lazy trigger, no config — so it loads eagerly.
- It is an **nvim-cmp** source. This config uses **blink.cmp**.
- blink's source list (`init.lua:1670`) is `{ 'lsp', 'path', 'snippets', 'lazydev', 'buffer', 'copilot', 'sshconfig', 'emoji' }` — **`dotenv` is not in it**, nor in any per-filetype override.
- The only `dotenv` source config in the tree is **commented out** at `init.lua:2085-2096` (and contains a typo, `flase`).

`copilot-cmp.lua:6` is already `enabled = false` for exactly this reason. This is the same case, missed.

```diff
--- a/lua/custom/plugins/cmp-dotenv.lua
+++ b/lua/custom/plugins/cmp-dotenv.lua
 return {
   'SergioRibera/cmp-dotenv',
+  -- nvim-cmp source; this config uses blink.cmp and never lists `dotenv`
+  -- as a provider (init.lua:1670). Was loading eagerly for 4.3ms/startup.
+  enabled = false,
 }
```

## V3 — Two files pin a Mason URL that 301-redirects

`https://api.github.com/repos/williamboman/mason.nvim` → **`301 Moved Permanently`**; the repo is now `mason-org/mason.nvim` (`archived=false`, `pushed_at=2026-06-19`).

`init.lua:1181` already uses `mason-org/`. These two do not:

- `lua/custom/plugins/nvim-dap.lua:6`
- `lua/kickstart/plugins/debug.lua:21`

It works today because git follows the redirect and lazy keys on the directory name, but it means `lazy-plugins.json` reports the stale URL and a future redirect removal breaks the DAP stack specifically.

```diff
--- a/lua/custom/plugins/nvim-dap.lua
+++ b/lua/custom/plugins/nvim-dap.lua
-    'williamboman/mason.nvim',
+    'mason-org/mason.nvim',
```
```diff
--- a/lua/kickstart/plugins/debug.lua
+++ b/lua/kickstart/plugins/debug.lua
-    'williamboman/mason.nvim',
+    'mason-org/mason.nvim',
```

## V4 — Three referenced tools are missing (corrected)

> **Correction, same day.** This finding originally listed **four** tools including `sql_formatter`, and claimed the April 2026 conform/Mason issue was unresolved. That was wrong, and it was an artifact of the audit instrument rather than a fact about the config. Corrected below; the measurement bug is fixed in `bin/nvim-audit-evidence.sh`.

`sql_formatter` **works.** Proven end to end by formatting a real buffer through conform:

```sql
-- before
select a,b from t where x=1 and y=2;
-- after
select
  a,
  b
from
  t
where
  x = 1
  and y = 2;
```

`conform.get_formatter_info("sql_formatter")` returns `command=sql-formatter, available=true`, resolving to `~/.local/share/nvim/mason/bin/sql-formatter`.

**Why the audit got it wrong.** The evidence script collected names from `conform.formatters_by_ft` and called `executable()` on them directly. But `sql_formatter` is conform's *internal identifier*; the binary is `sql-formatter`. It tested the wrong string — while `sql-formatter` sat in the same `tools.json` marked executable, the same tool reported twice with opposite verdicts.

**A second effect, and the one that explains the April note.** The same check returns opposite answers depending on context: `available=true` with a `.sql` buffer open, `available=false` in a bare headless nvim. Mason prepends its bin directory to `vim.env.PATH` *when it loads*; with no relevant buffer, nothing triggers that, and every Mason tool looks missing. Mason appears **zero times** in the shell PATH — which is also why `stylua` needs its full path in `CLAUDE.md`.

The script now prepends Mason's bin explicitly and resolves identifiers to commands before probing, so it measures whether a tool *exists* rather than whether a plugin loaded first.

**The genuinely missing tools**, re-measured after the fix:

| Tool | Expected by | Resolved command |
|---|---|---|
| `ruff` | `lint` | `ruff` |
| `isort` | `conform` | `isort` |
| `caddy` | `conform` | `caddy` |

Absent from Mason's bin directory *and* the system PATH. `ruff` and `isort` are the Python pair — the same profile drift noted above: Python is in the profile, zero `.py` files in oldfiles, tooling half-installed. `caddy` matters only if Caddyfiles get edited in nvim.

## V5 — Snacks is configured but two integrations are unwired

From `checkhealth.txt:290,301`:

```
Snacks.input ~
- ❌ ERROR `vim.ui.input` is not set to `Snacks.input`
Snacks.picker ~
- ❌ ERROR `vim.ui.select` is not set to `Snacks.picker.select`
```

Both modules report `setup {enabled}` — so they are turned on but something later reassigns `vim.ui.input`/`vim.ui.select`. `telescope-ui-select.nvim` is installed and loaded, which is the likely claimant. Not a bug so much as two plugins configured to do the same job, with the loser silently reporting an error.

Also at `checkhealth.txt:257`: `Snacks.dashboard ~ ❌ ERROR setup did not run`.

## V6 — image.nvim cannot render in this terminal

```
checkhealth.txt:285  ❌ ERROR your terminal does not support the kitty graphics protocol
                     supported terminals: `kitty`, `wezterm`, `ghostty`
checkhealth.txt:103  ❌ ERROR {lua5.1} or {lua} or {lua-5.1} version `5.1` not installed
                     (luarocks 3.8.0 present, but system Lua is 5.2.4)
```

Two independent blockers. Meanwhile image.nvim registers **five `BufEnter` autocmds on `*`** — for `typst`, `neorg`, `asciidoc`, `syslang`, and `markdown` (`hot-autocmds.json`, sampled while `run-tests.php` was open). Four of those five filetypes appear nowhere in the work profile or in oldfiles.

The `norg` treesitter parser is also reported missing (`checkhealth.txt:277`) — for a filetype that isn't used.

## V7 — `<leader>b` prefix collision (resolved same day)

> **Resolved 2026-08-28.** The breakpoint keys moved to `<F4>` / `<F6>` in `lua/kickstart/plugins/debug.lua`, rather than being deleted — the debugger is unused here, but stepping keys with no way to set a breakpoint would be worse than either keeping or removing the stack. Verified in a live session: bare `<leader>b` no longer exists, `<leader>bn` / `<leader>bp` are intact.

From `keymaps.json`, all normal mode, all global:

| Mapping | Description |
|---|---|
| `<leader>b` | Debug: Toggle Breakpoint |
| `<leader>bn` | Next buffer |
| `<leader>bp` | Previous buffer |

A bare `<leader>b` and a populated `<leader>b*` group cannot coexist cleanly: `<leader>bn` costs a full `timeoutlen` wait, and so does `<leader>b` itself. This is the only genuine collision in 482 keymaps.

`<leader>T` looks like the same problem but is not — the bare map is `v`/`x` mode, the `<leader>Ts`/`<leader>Tv` maps are `n`. No collision. `<leader>?` is which-key's own buffer-local map, by design.

## V8 — Five leader maps are invisible to which-key

The only leader maps lacking a `desc` are table-mode's `<Plug>` bindings — `<leader>tt` (n/x/o) and `<leader>T` (v/x). They work; they just never appear in the popup, so they are undiscoverable.

## V9 — `colorscheme.lua` has three duplication bugs

`lua/custom/plugins/colorscheme.lua`, 12 specs:

- **tokyonight declared twice** — line 4 (bare) and line 14 (`lazy=false, priority=1000`).
- **Two different `gruvbox.nvim` repos** — `ellisonleao/` (line 3) and `npxbr/` (line 10). Same plugin name, different sources; one silently wins.
- **catppuccin installs as a directory literally named `nvim`** (line 8, `catppuccin/nvim`). This is why `lazy-plugins.json` contains a mysterious entry called `nvim`.

**Cost of all 11 eager colorschemes: 2.783 ms.** I expected this to be a startup problem and measured it instead of asserting it — lazy.nvim registers the runtime paths but only sources `colors/` for the *active* scheme. So this is a hygiene finding, not a performance one. Worth fixing for legibility; not worth fixing for speed.

## V10 — netrw is still enabled alongside four file explorers

```
startup-1.txt:  1.048 self  sourcing /usr/local/share/nvim/runtime/plugin/netrwPlugin.vim
                0.280 self  sourcing .../pack/dist/opt/netrw/plugin/netrwPlugin.vim
hot-autocmds.json:  group=FileExplorer  event=BufEnter  pattern=*
                    command=sil call s:LocalBrowse(expand("<amatch>"))
```

No `loaded_netrw` guard exists anywhere in the config. neo-tree, mini.files, ranger.nvim and snacks.explorer are all installed. ~1.3 ms and a `BufEnter *` handler for a plugin that is structurally redundant.

```diff
--- a/init.lua
+++ b/init.lua
+-- Disable netrw: neo-tree / mini.files / ranger.nvim / snacks.explorer all cover it.
+vim.g.loaded_netrw = 1
+vim.g.loaded_netrwPlugin = 1
```
*(must run before plugins load)*

## V11 — Ecosystem currency: clean

**Neovim itself.** 0.12.5 is the current stable release (`https://api.github.com/repos/neovim/neovim/releases/latest` → `tag_name: v0.12.5`, checked 2026-08-28).

**Deprecations.** `checkhealth vim.deprecated` → `✅ OK No deprecated functions detected`. Checked against the 0.12 breaking changes in `/usr/local/share/nvim/runtime/doc/news.txt:14-96` — diagnostic sign config, `vim.diagnostic.disable()`, `vim.diff`→`vim.text.diff`, LSP `vim.NIL` handling, `semantic_tokens.start()`→`enable()`. This config trips none of them.

**Load-bearing plugin health** (GitHub API, `archived` + `pushed_at` only):

| Plugin | Last push |
|---|---|
| nvim-lspconfig | 2026-08-28 |
| blink.cmp · nvim-lint | 2026-08-25 |
| nvim-treesitter | 2026-08-23 |
| image.nvim | 2026-08-19 |
| telescope.nvim | 2026-08-17 |
| markview.nvim | 2026-08-14 |
| fzf-lua | 2026-08-13 |
| conform.nvim · gitsigns.nvim | 2026-08-11 |
| lazy.nvim | 2026-06-29 |
| mason.nvim (mason-org) | 2026-06-19 |
| snacks.nvim | 2026-05-25 |
| **which-key.nvim** | **2025-10-28** |

**None archived.** which-key is the outlier at 10 months quiet — which bears directly on the trigger-loss bug that `after/plugin/which-key-diag.lua` was written to mitigate today. That watchdog should be treated as **permanent**, not a stopgap awaiting an upstream fix.

## V12 — LSP wiring is ahead of upstream (credit, not a finding)

`init.lua:1450` records that mason-lspconfig was deliberately removed, and `init.lua:1470-1471` uses `vim.lsp.config(name, server)` + `vim.lsp.enable(name)` directly — the 0.11+ native path. Most kickstart forks still carry the mason-lspconfig translation layer. Nothing to do; noted so a future audit doesn't "helpfully" reintroduce it.

`vim.pack` (0.12's built-in plugin manager) appears nowhere in the config, correctly — it does not cover this config's actual usage of lazy.nvim (144 specs, lockfile, per-plugin lazy triggers). A built-in existing is not an argument for switching.

---

# Judgment calls

Reasoned from the config, not measured. Weigh accordingly.

## J1 — Three picker stacks are installed and two load at startup

telescope (+ 4 extensions), fzf-lua, and snacks.picker are all present. `lazy-plugins.json` shows telescope, its extensions, **and** fzf-lua all loaded at startup; `startup-slowest.txt` shows `require('fzf-lua')` at 3.123 ms and `telescope.config` at 2.711 ms in the same run.

Per-item cost is small, so this is not a performance argument. It is a coherence argument: `<leader>s*` is 30 maps of near-perfect mnemonic discipline, and it is worth knowing whether all 30 route to the same picker or whether the group silently spans three engines with three different UIs. `docs/search-keymaps-audit.md` is the right place to settle it.

## J2 — image.nvim earns nothing in this terminal

Given V6 — no kitty graphics protocol, no Lua 5.1 for luarocks — image.nvim cannot render. It still costs five `BufEnter *` autocmds and pulls a missing `norg` parser warning into checkhealth. The June work on neo-tree image previews suggests it mattered once; the current terminal cannot support it. Either move to a supporting terminal deliberately, or disable it and reclaim the health output.

The cost of leaving it is not speed. It is that `checkhealth` currently has 20 issues, most of them expected, which is precisely how a real one goes unnoticed.

## J3 — `catppuccin/nvim` should be renamed or removed

A plugin whose directory is literally `nvim` will keep producing confusing output in every future audit, lockfile diff, and `:Lazy` listing. If it is wanted, give it `name = 'catppuccin'`. If not, drop it — nothing references it.

---

# Experimental

Frequency-weighted ergonomics, inferred from leader-group population, the work profile, and git history. **There is no keylogging here** — this is proxy reasoning and should be treated as the weakest tier. No prior report exists, so there are no previously-declined suggestions to drop.

## X1 — Documented leader groups have drifted from real ones

`CLAUDE.md` documents seven groups: `c d f g s t w`. Measured reality:

| Group | Documented | Actual maps |
|---|---|---|
| `<leader>d` | document | **0** |
| `<leader>w` | workspace | 1 |
| `<leader>y` | — | **16** |
| `<leader>x` | — | **14** |
| `<leader>m` | — | **10** |
| `<leader>j` | — | 7 |

`<leader>d` is documented and empty; `<leader>y`, `<leader>x`, `<leader>m` and `<leader>j` are populated and undocumented. Someone reading `CLAUDE.md` to find a keymap gets a map of a config that doesn't exist. This is the cheapest fix in the report — it is a documentation edit, not a keymap change.

## X2 — Markdown is the most-edited filetype and does not have the cheapest keys

`md` is 33 of ~90 oldfiles entries — nearly double PHP. Markdown operations live under `<leader>m` (10 maps), while `<leader>d` sits empty. If the muscle memory is already trained, leave it; the observation is only that prime single-letter real estate is unused while the dominant filetype sits one tier down.

## X3 — `<leader>s` is the model the other groups should copy

30 maps, every one meaning search, every one with a bracketed mnemonic (`[S]earch [F]iles`). It is the best-organised part of the keymap surface by a wide margin. Where other groups need reorganising, this is the pattern to copy — noted so it doesn't get "cleaned up" into inconsistency.

---

# Suggested order of work

Roughly by value-per-minute. All diffs above are **unapplied**.

1. **V2** — disable `cmp-dotenv`. One line, 4.3 ms, zero risk.
2. **X1** — fix the leader groups in `CLAUDE.md`. Documentation only.
3. **V3** — two Mason URL updates.
4. **V10** — disable netrw.
5. **V4** — nothing to fix for SQL. Decide whether `ruff`/`isort`/`caddy` are wanted.
6. **V7 / V8** — resolve `<leader>b`; add `desc` to the five table-mode maps.
7. **V9 / J3** — clean up `colorscheme.lua`.
8. **V5 / V6 / J2** — decide on snacks vs telescope-ui-select, and on image.nvim.
9. **V1** — the `init.lua` refactor, when there is appetite for it. Highest impact, highest cost, needs its own plan.
