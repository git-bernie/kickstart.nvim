# Telescope Hidden Files

## Overview

By default, Telescope's file pickers respect `.gitignore` and skip hidden files (dotfiles). Sometimes you need to search everything.

## How It Works

Telescope uses `fd` for `find_files` and `rg` for `live_grep`. Both respect ignore files by default.

**Options:**
- `hidden = true` - Include dotfiles (files starting with `.`)
- `no_ignore = true` - Ignore `.gitignore` rules

For grep pickers, use `additional_args`:
```lua
additional_args = { '--hidden', '--no-ignore' }
```

## Configuration

We use **uppercase variants** for hidden file searching:

| Normal | Hidden | Picker |
|--------|--------|--------|
| `<leader>sf` | `<leader>sF` | find_files |
| `<leader>sg` | `<leader>sG` | live_grep |
| `<leader>sw` | `<leader>s*` | grep_string (word under cursor) |

## Implementation

```lua
-- Find files with hidden
vim.keymap.set('n', '<leader>sF', function()
  builtin.find_files {
    hidden = true,
    no_ignore = true,
    prompt_title = 'Find Files (hidden, no_ignore)'
  }
end, { desc = '[S]earch [F]iles (hidden)' })

-- Live grep with hidden
vim.keymap.set('n', '<leader>sG', function()
  builtin.live_grep {
    additional_args = { '--hidden', '--no-ignore' },
    prompt_title = 'Live Grep (hidden, no_ignore)'
  }
end, { desc = '[S]earch by [G]rep (hidden)' })

-- Grep word with hidden (using * because W was taken)
vim.keymap.set('n', '<leader>s*', function()
  builtin.grep_string {
    additional_args = { '--hidden', '--no-ignore' },
    prompt_title = 'Grep Word (hidden, no_ignore)'
  }
end, { desc = '[S]earch current word [*] (hidden)' })
```

## Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Keymap conflict | Uppercase already used | Pick different key (we used `*` for grep_string) |
| Still missing files | Some files in nested .gitignore | Check `--no-ignore-vcs` flag |

## Related

- `init.lua` line ~975 - Telescope keymaps
- See also `<A-p>` for find_files with hidden (alternative binding)
- Runbook: [add-telescope-hidden-variant](../runbooks/add-telescope-hidden-variant.md)
