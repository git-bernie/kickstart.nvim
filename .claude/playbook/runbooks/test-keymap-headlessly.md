# Runbook: Test a Keymap Headlessly

## When to Use

When you've written or changed a keymap and want to prove it works against the
real config — not just that the file parses. Especially valuable for keymaps
that transform buffer text, where "it ran" and "it produced the right result"
are very different claims.

## Prerequisites

- The keymap is saved in `after/plugin/keymaps.lua` (or wherever it lives)
- A scratch directory outside the repo to hold throwaway fixtures

## ⚠️ Read this first: do NOT set NVIM_APPNAME

`~/.config/nvim` is a **symlink** to `./nvim-kickstart`. You launch this config
as plain `nvim`, and its data lives in the standard `~/.local/share/nvim`.

Setting `NVIM_APPNAME=nvim-kickstart` seems reasonable — the config directory
really is named that — but it makes Neovim derive a *whole separate* set of
data/state/cache paths:

```
~/.local/share/nvim-kickstart/    ← new, empty
~/.local/state/nvim-kickstart/    ← new, empty
~/.cache/nvim-kickstart/          ← new, empty
```

lazy.nvim finds no plugins there and **re-clones all ~144 of them**, quietly
producing about **1.2 GB** of duplicate checkouts and a confusing first run.
Nothing warns you; the clone messages scroll past as ordinary startup noise.

**Always use plain `nvim`.** The symlink resolves correctly on its own.

If you set it by accident, confirm the strays are yours before deleting —
birth timestamps are decisive:

```bash
stat -c 'birth:%w  %n' ~/.local/share/nvim-kickstart ~/.cache/nvim-kickstart \
                       ~/.local/state/nvim-kickstart
rm -rf ~/.local/share/nvim-kickstart ~/.cache/nvim-kickstart ~/.local/state/nvim-kickstart

# Verify the real data dir is untouched (should print your usual plugin count)
ls ~/.local/share/nvim/lazy | wc -l
```

## Steps

1. **Write a fixture** in a scratch directory, not in the repo:

   ```bash
   cd /tmp/scratch
   cat > fixture.php <<'EOF'
   <?php
   $config = [
       'name' => 'loanconnect',
       'debug' => true,
   ];
   EOF
   ```

2. **Write a driver script** that selects the target text, presses the keymap,
   and saves. Keep it in the same scratch directory:

   ```lua
   -- drive.lua
   vim.cmd('normal! 2ggV5gg')                    -- select lines 2-5
   vim.api.nvim_feedkeys(
     vim.api.nvim_replace_termcodes('<Space>jp', true, false, true),
     'x',                                        -- 'x' = execute immediately
     false
   )
   vim.cmd('silent write')
   vim.cmd('qa!')
   ```

   `<Space>` is the literal leader. The `'x'` mode flag matters — without it the
   keys queue but never run before `qa!` fires.

3. **Run it, deferred.** The delay lets lazy.nvim finish loading before the
   keys are fed; without it the keymap may not exist yet:

   ```bash
   nvim --headless fixture.php \
     -c 'lua vim.defer_fn(function() dofile("drive.lua") end, 1500)' \
     >/dev/null 2>&1
   ```

4. **Inspect the result:**

   ```bash
   cat fixture.php
   ```

5. **Test the failure path too.** Feed input the keymap should *reject* and
   confirm the buffer is unchanged. This is the case that actually bites users,
   and it is the one most likely to be broken.

   Beware format-on-save: `silent write` fires the `BufWritePost` formatter
   autocmds, so a rejected fixture may still differ by whitespace. Compare the
   region you selected, not the whole file.

## The stale-marks gotcha

Inside a visual-mode Lua callback, `'<` and `'>` still describe the
**previous** selection until visual mode ends. A keymap that reads them
directly will silently operate on whatever you selected last time.

Exit visual mode first, as the first line of the callback:

```lua
vim.cmd [[execute "normal! \<Esc>"]]
local first = vim.fn.line "'<"
local last = vim.fn.line "'>"
```

This bug is invisible in casual manual testing — the first invocation after a
fresh selection often looks right by coincidence.

## Verification

- The fixture file contains the expected transformed text
- The rejection fixture's selected region is unchanged
- `~/.local/share/nvim-kickstart` and friends do **not** exist
- `ls ~/.local/share/nvim/lazy | wc -l` still shows your real plugin count

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Plugins start cloning | You set `NVIM_APPNAME`. Kill it, clean up per above, use plain `nvim`. |
| Nothing happens | Missing `'x'` flag in `feedkeys`, or `defer_fn` delay too short. |
| Heredoc never ends, shell sits at `>` | You pasted the fixture block with its list indentation. `EOF` must be at column 0. |
| Wrong lines transformed | Stale `'<`/`'>` marks — add the `<Esc>` line. |
| `stylua: command not found` | Not on `PATH`. Use `~/.local/share/nvim/mason/bin/stylua`. |
| `stylua --check` fails oddly on a temp file | `.stylua.toml` only applies inside the repo. Copy the file into the repo before checking, or it silently uses tab/double-quote defaults. |

## Related

- [debug-keymap-conflict.md](debug-keymap-conflict.md) — when the key is mapped
  but the wrong thing runs
- [`docs/php-array-convert.md`](../../../docs/php-array-convert.md) — a keymap
  verified with exactly this procedure, including its rejection path
