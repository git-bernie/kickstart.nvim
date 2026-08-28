# Runbook: Debug Keymap Conflict

## When to Use

When a keymap isn't working as expected, or two features are fighting for the same key.

There are **two different conflicts** here, and only one of them errors:

- **Duplicate** — two mappings on the identical key. One silently wins. See the `<leader>sW` example.
- **Prefix shadowing** — a bare `<leader>x` map coexisting with a `<leader>x*` group. Nothing wins, nothing errors, everything just gets slower. See the `<leader>b` example.

## Prerequisites

- Know the key sequence in question (e.g., `<leader>sW`)

## Steps

1. **Check what's mapped** using verbose:
   ```vim
   :verbose map <leader>sW
   :verbose nmap <leader>sW
   ```
   This shows the mapping AND where it was defined.

2. **Search all keymaps** with Telescope:
   ```vim
   :Telescope keymaps
   ```
   Then type the key you're looking for.

3. **Check which-key** if installed:
   ```vim
   :WhichKey <leader>s
   ```

4. **Common conflict sources:**
   - `init.lua` - Main keymaps (~line 975)
   - `after/plugin/keymaps.lua` - Custom keymaps
   - LSP `on_attach` - Buffer-local keymaps (override globals)
   - Plugin defaults - Some plugins set their own keymaps

5. **Check for prefix shadowing** — a bare prefix map sitting on top of a group.
   `:verbose map` will NOT flag this; both mappings are legitimate and neither
   overrides the other. Enumerate instead:
   ```vim
   :lua for _, m in ipairs(vim.api.nvim_get_keymap('n')) do if m.lhs:match('^ b') then print(m.lhs, m.desc) end end
   ```
   If the output contains both a bare prefix (` b`) and longer maps under it
   (` bn`, ` bp`), that is the shadowing case.

6. **Resolution strategies:**
   - Change one keymap to a different key
   - Use buffer-local vs global scoping intentionally
   - Disable plugin's default keymaps in its config

## Example: `<leader>sW` Conflict

We had `<leader>sW` mapped to both:
- `grep_string` (hidden) - in init.lua
- `lsp_dynamic_workspace_symbols` - in LSP on_attach

**Solution:** Changed grep_string to `<leader>s*`

## Example: `<leader>b` Prefix Shadowing

Found by the 2026-08-28 config audit — the only real collision in 482 mappings.

Three normal-mode maps coexisted:

| Mapping | Source |
|---|---|
| `<leader>b` | kickstart `debug.lua` — toggle breakpoint |
| `<leader>bn` | next buffer |
| `<leader>bp` | previous buffer |

**Why this is a real problem, not a style nit.** When both `<leader>b` and `<leader>b{n,p}` exist, Neovim cannot know at the moment you press `b` whether you are finished typing. So it waits out `timeoutlen` on **every** press: the bare map is delayed waiting to see if a longer one follows, and the longer maps are delayed behind the same ambiguity. Both sides get slower. Nothing errors. Nothing is logged.

That silence is why it survived years in a heavily-tuned config. A collision that throws an error gets fixed in the first week; one that just makes two keys feel sluggish reads as "vim being vim".

**Solution:** moved the breakpoint keys to `<F4>` / `<F6>` rather than deleting them — the debugger was unused, but stepping keys with no way to set a breakpoint would be worse than either keeping or removing the stack.

**The general rule:** a prefix is either a leaf or a group, never both. If you want a bare `<leader>x` *and* `<leader>x*` maps, you have to accept the timeout on both.

## Verification

After fixing:
```vim
:verbose nmap <the_key>
```
Should show only one mapping from the expected location.

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Mapping shows "Last set from ..." unexpected file | That file is overriding; edit it or load order |
| No mapping found but key does something | Could be a plugin's `<Plug>` mapping |
| Works in some buffers, not others | Buffer-local mapping (check LSP on_attach) |
| Key works but feels sluggish; no error anywhere | Bare prefix map shadowing a group — see the `<leader>b` example |
| `:verbose map` shows one clean mapping, still feels slow | `verbose` cannot show shadowing; enumerate with `nvim_get_keymap` instead |

## Related

- `:help map-listing`
- `:help map-verbose`
