# Runbook: Neovim Major-Version Upgrade

## When to Use

Upgrading the Neovim binary across a major version boundary (e.g. 0.11→0.12, 0.12→0.13). The hardest part is rarely the binary itself — it's the cascade of related ecosystems (treesitter, lazy-lock, runtime files) that all need to move together.

Derived from the 0.11.7→0.12.2 + nvim-treesitter master→main migration on 2026-05-25.

## Prerequisites

- A working baseline. Don't start mid-debugging-session.
- ~3 hours uninterrupted. The actual work is shorter, but the soak-test before cutover prevents pain.
- A backup branch state so `git checkout master` is always a clean rollback.

## Steps

### Phase 0 — Read the breakage matrix before touching anything

Check which plugins have known issues against the target version:

```bash
# Plugins with unusual branch pins (signs of holdback)
grep -E '"branch":' lazy-lock.json | grep -vE '"(master|main)"' | head
```

Examples of holdback signals from the 0.12 upgrade:
- `aerial.nvim` pinned to `branch = 'nvim-0.11'` → unpin for 0.12+
- `nvim-treesitter` pinned to `master @ <hash>` → migrate to `main` branch for 0.12+

Document each holdback's plan separately. Don't bundle unrelated migrations into one upgrade.

### Phase 1 — Bump tree-sitter CLI (if needed)

If migrating to nvim-treesitter main, install the CLI **via cargo, not npm** (upstream maintainer explicitly says so in the README):

```bash
sudo npm uninstall -g tree-sitter-cli   # if you have the npm version
cargo install tree-sitter-cli
which tree-sitter && tree-sitter --version  # expect ≥ 0.26.1
```

Cargo lands the binary at `~/.cargo/bin/tree-sitter`, user-local, ahead of `/usr/local/bin` on PATH.

### Phase 2 — Install the new Neovim in parallel (DON'T replace yet)

```bash
mkdir -p ~/.local/share/nvim-X.Y.Z
cd /tmp && curl -L -o nvim.tar.gz https://github.com/neovim/neovim/releases/download/vX.Y.Z/nvim-linux-x86_64.tar.gz
tar xzf nvim.tar.gz -C ~/.local/share/nvim-X.Y.Z --strip-components=1
~/.local/share/nvim-X.Y.Z/bin/nvim --version  # smoke test
```

**Tarball naming:** pre-0.12 it was `nvim-linux64.tar.gz`. From 0.12 onward it's `nvim-linux-x86_64.tar.gz`.

### Phase 3 — Branch a sandbox config

```bash
cp -a ~/.config/nvim-kickstart ~/.config/nvim-X.Y.Z-test
```

Test invocation (full isolation — separate state, lazy plugins, parsers):

```bash
NVIM_APPNAME=nvim-X.Y.Z-test ~/.local/share/nvim-X.Y.Z/bin/nvim
```

### Phase 4 — Apply migration edits in the sandbox

Edit `~/.config/nvim-X.Y.Z-test/init.lua` and relevant plugin specs. For the treesitter master→main migration, see commit `33e6a9a` and the `init.lua` block at the `nvim-treesitter` spec — the config function must call `TS.setup(opts)` (see Troubleshooting).

### Phase 5 — Force lazy-lock to use the new branches

After spec changes that include a `branch = '...'` swap, `:Lazy restore` alone will NOT switch branches — the lockfile pins a *commit hash*, which is on the old branch. Must explicitly update:

```vim
:Lazy update nvim-treesitter nvim-treesitter-textobjects aerial.nvim
```

Or nuclear: `rm ~/.config/nvim-X.Y.Z-test/lazy-lock.json` and `:Lazy sync` to re-resolve fully from spec.

### Phase 6 — Verify the sandbox headlessly

```bash
NVIM_APPNAME=nvim-X.Y.Z-test ~/.local/share/nvim-X.Y.Z/bin/nvim --headless \
  -c 'lua print("parsers:", #(require("nvim-treesitter").get_installed("parsers") or {}))' \
  -c 'edit ~/path/to/realfile.php' \
  -c 'lua print("highlighter:", vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()] ~= nil)' \
  -c 'qa!'
```

Expected: parsers > 0, highlighter true. Fix in sandbox before promoting.

### Phase 7 — Promote to live config

```bash
cd ~/.config/nvim-kickstart
git checkout -b feat/nvim-X.Y.Z-upgrade

cp ~/.config/nvim-X.Y.Z-test/init.lua init.lua
cp ~/.config/nvim-X.Y.Z-test/lua/custom/plugins/aerial.lua lua/custom/plugins/aerial.lua
cp ~/.config/nvim-X.Y.Z-test/lua/custom/plugins/nvim-treesitter-textobjects.lua lua/custom/plugins/nvim-treesitter-textobjects.lua
cp ~/.config/nvim-X.Y.Z-test/lazy-lock.json lazy-lock.json   # critical: brings verified commit pins

git diff --stat
git commit -am "feat: upgrade to Neovim X.Y.Z"
```

### Phase 8 — Install new binary AND runtime (both required)

```bash
sudo cp /usr/local/bin/nvim /usr/local/bin/nvim-OLD-backup
sudo mv /usr/local/share/nvim /usr/local/share/nvim-OLD-backup
sudo cp ~/.local/share/nvim-X.Y.Z/bin/nvim /usr/local/bin/nvim
sudo cp -r ~/.local/share/nvim-X.Y.Z/share/nvim /usr/local/share/

# Verify version match between binary and runtime
md5sum /usr/local/share/nvim/runtime/lua/vim/treesitter/languagetree.lua \
       ~/.local/share/nvim-X.Y.Z/share/nvim/runtime/lua/vim/treesitter/languagetree.lua
# Hashes MUST match — see Troubleshooting if they don't.
```

### Phase 9 — Sync live data dir against sandbox

If the live install's nvim-treesitter `install()` fails silently (no `.so` files appear despite "installed N/N languages" messages), copy parsers and queries from the sandbox where they verifiably work:

```bash
cp ~/.local/share/nvim-X.Y.Z-test/site/parser/*.so ~/.local/share/nvim/site/parser/
cp -a ~/.local/share/nvim-X.Y.Z-test/site/parser-info/. ~/.local/share/nvim/site/parser-info/
cp -a ~/.local/share/nvim-X.Y.Z-test/site/queries/. ~/.local/share/nvim/site/queries/
```

This bypasses the install machinery — parsers are just `.so` files that nvim auto-discovers from rtp.

### Phase 10 — Soak-test and merge

Use the new setup for real work for at least a few hours. If stable:

```bash
git checkout master && git merge --ff-only feat/nvim-X.Y.Z-upgrade && git push origin master
git branch -d feat/nvim-X.Y.Z-upgrade
```

Keep backup binary + runtime + sandbox config for at least a week before deleting.

## Verification

In the live nvim after cutover:

```vim
:checkhealth nvim-treesitter
:lua =vim.version()
:lua =vim.treesitter.highlighter.active[0] ~= nil   " in a code buffer
```

Open a representative real file (e.g. a 5000-line PHP file from work) and check:
- Syntax highlighting renders fully
- Folds work (`:set foldmethod?` should be `expr`)
- Indentation works (try `==` and `gg=G`)
- Textobjects keymaps respond (`]b`, `[b`, `%`)
- LSP attaches and intelephense responds
- Snacks dashboard / picker open without errors

## Troubleshooting

| Problem | Cause | Solution |
|---------|-------|----------|
| `attempt to call method 'set_timeout' (a nil value)` after replacing binary | Replaced `/usr/local/bin/nvim` but not `/usr/local/share/nvim/runtime/` — version mismatch between binary and runtime | Phase 8 step two: also copy the runtime |
| `:TSInstall <lang>` reports success but no `.so` files appear | `TS.setup(opts)` not called — plugin is half-initialized | Add `TS.setup(opts)` as first line of `config = function(_, opts)` in treesitter spec |
| `:Lazy restore` after branch swap leaves plugin on old branch | Lazy lock pins commit hash, not branch — checkout follows commit regardless of branch field | `:Lazy update <plugin>` to force-fetch latest of new branch; updates lockfile too |
| `dlopen: ... No such file or directory` for an existing parser | Either parser file deleted OR missing shared library dependency (misleading ENOENT) | Verify with `ls -la` first. If file exists, `ldd <parser>.so` shows real dependency |
| Parsers compile but install machinery fails silently | nvim-treesitter main install path has opaque failure modes | Manual fallback: clone parser repo, `tree-sitter generate`, `gcc -o X.so -shared -fPIC ...`, drop in `~/.local/share/nvim/site/parser/` |
| Sandbox works, live doesn't, configs look identical | `cp -a` brought lazy-lock to sandbox — lockfile commits diverged after `:Lazy update` in sandbox. Live still on old commits. | Phase 7 includes `cp ~/.config/nvim-X.Y.Z-test/lazy-lock.json lazy-lock.json` to bring verified pins |
| Phantom `pack/` directory in `~/.local/share/nvim/site/pack/` | Vestigial from packer.nvim era before switching to lazy.nvim | Safe to `rm -rf` — nothing in current config uses it |
| `[nvim-treesitter] warning: skipping unsupported language: norg` | `norg` removed from main-branch parser registry; install via Neorg plugin instead | Remove from `ensure_installed` |

## Related

- Knowledge: `lazy-nvim-performance.md` (lazy-loading patterns)
- Knowledge: `noice-cmdline-cursor-issue.md` (one specific 0.12 plugin issue)
- Commits: `33e6a9a feat: upgrade to Neovim 0.12.2 + nvim-treesitter main branch`, `228183c fix(treesitter): call TS.setup() in config; drop norg parser`
- External: [LazyVim's canonical treesitter spec](https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/plugins/treesitter.lua) — reference for main-branch patterns
