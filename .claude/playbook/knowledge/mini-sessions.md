# MiniSessions Per-Project Setup

## Overview

mini.sessions manages Neovim sessions (open buffers, window layout, etc.). We configure it for **per-project sessions** using explicit cwd paths.

## How It Works

With `directory = ''`, mini.sessions looks for local `Session.vim` files. However, `read('Session.vim')` looks for a **registered session by name**, not the file in cwd. This causes cross-project confusion.

**Solution:** Use explicit absolute paths in keymaps.

## Configuration

```lua
-- In init.lua
require('mini.sessions').setup {
  autoread = false,   -- Don't auto-load on startup
  autowrite = false,  -- Don't auto-save on exit
  directory = '',     -- No global session directory
  file = 'Session.vim',
  verbose = { read = true, write = true, delete = true },
}
```

## Keymaps (in after/plugin/keymaps.lua)

```lua
-- Save session to current directory
vim.keymap.set('n', '<leader>mk', function()
  local session_path = vim.fn.getcwd() .. '/Session.vim'
  require('mini.sessions').write(session_path, { force = true })
end, { desc = '[M]a[k]e Session (cwd/Session.vim)' })

-- Delete session from current directory
vim.keymap.set('n', '<leader>md', function()
  local session_path = vim.fn.getcwd() .. '/Session.vim'
  require('mini.sessions').delete(session_path, { force = true })
end, { desc = '[M]ake Session [D]elete' })

-- Read session from current directory (with warning if missing)
vim.keymap.set('n', '<leader>mR', function()
  local session_path = vim.fn.getcwd() .. '/Session.vim'
  if vim.fn.filereadable(session_path) == 1 then
    require('mini.sessions').read(session_path, { force = true })
  else
    vim.notify('No Session.vim in ' .. vim.fn.getcwd(), vim.log.levels.WARN)
  end
end, { desc = '[M]iniSessions [R]ead' })
```

## Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Loading wrong project's session | `read('Session.vim')` finds registered session | Use explicit `getcwd() .. '/Session.vim'` path |
| Session not found warning | No Session.vim in current directory | Use `<leader>mk` to create one first |

## Workflow

1. Open project: `cd ~/work/project && nvim`
2. Set up your windows/buffers
3. Save: `<leader>mk`
4. Later, restore: `<leader>mR`

## Related

- `init.lua` line ~1838 - mini.sessions setup
- `after/plugin/keymaps.lua` - Session keymaps
