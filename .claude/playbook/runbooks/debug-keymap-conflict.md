# Runbook: Debug Keymap Conflict

## When to Use

When a keymap isn't working as expected, or two features are fighting for the same key.

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

5. **Resolution strategies:**
   - Change one keymap to a different key
   - Use buffer-local vs global scoping intentionally
   - Disable plugin's default keymaps in its config

## Example: `<leader>sW` Conflict

We had `<leader>sW` mapped to both:
- `grep_string` (hidden) - in init.lua
- `lsp_dynamic_workspace_symbols` - in LSP on_attach

**Solution:** Changed grep_string to `<leader>s*`

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

## Related

- `:help map-listing`
- `:help map-verbose`
