# Runbook: Add Telescope Hidden Variant

## When to Use

When you want to add a "search hidden files" variant of an existing Telescope picker.

## Prerequisites

- Existing Telescope picker keymap to duplicate
- Know which picker function to use (`find_files`, `live_grep`, `grep_string`, etc.)

## Steps

1. **Identify the existing keymap** in `init.lua` (around line 975)

2. **Choose a key** - Convention is uppercase for hidden variants:
   - `<leader>sf` → `<leader>sF`
   - `<leader>sg` → `<leader>sG`
   - If uppercase is taken, use a symbol like `*`

3. **Add the variant** based on picker type:

   **For find_files:**
   ```lua
   vim.keymap.set('n', '<leader>sF', function()
     builtin.find_files {
       hidden = true,
       no_ignore = true,
       prompt_title = 'Find Files (hidden, no_ignore)'
     }
   end, { desc = '[S]earch [F]iles (hidden)' })
   ```

   **For live_grep/grep_string:**
   ```lua
   vim.keymap.set('n', '<leader>sG', function()
     builtin.live_grep {
       additional_args = { '--hidden', '--no-ignore' },
       prompt_title = 'Live Grep (hidden, no_ignore)'
     }
   end, { desc = '[S]earch by [G]rep (hidden)' })
   ```

4. **Check for conflicts** - Run `:Telescope keymaps` and search for your key

## Verification

1. Open Neovim in a project with hidden files (e.g., `.env`, `.gitignore`)
2. Use the normal variant - hidden files should NOT appear
3. Use the hidden variant - hidden files SHOULD appear

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Keymap doesn't work | Check for conflicts with `:verbose map <leader>sF` |
| Still missing files | Try adding `follow = true` for symlinks |
| LSP keymap overrides | LSP keymaps defined later win; check LSP on_attach |

## Related

- Knowledge: [telescope-hidden-files](../knowledge/telescope-hidden-files.md)
