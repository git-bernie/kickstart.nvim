# Noice Message Routing

## Overview

Noice intercepts all Neovim messages and routes them to different views based on filters. Understanding this routing is key to controlling where messages appear.

## How It Works

Messages flow through `routes` in order. The **first matching route wins**. Each route has:
- `filter` - Conditions to match (event, kind, find pattern, min_height, etc.)
- `view` - Where to display (`notify`, `split`, `mini`, `popup`, etc.)
- `opts` - Options like `{ skip = true }` to suppress entirely

## Key Concepts

- **event types:** `msg_show`, `msg_showmode`, `notify`, `lsp`
- **kind:** `shell_out`, `search_count`, `echo`, etc.
- **views:**
  - `notify` - nvim-notify popup (stores in history)
  - `split` - horizontal split (ephemeral, lost when closed)
  - `mini` - minimal bottom-right display
  - `popup` - centered popup

## Configuration

```lua
-- In noice.lua opts.routes
routes = {
  -- Route shell output to split (visible, but ephemeral)
  {
    view = 'split',
    filter = { event = 'msg_show', kind = 'shell_out' },
  },
  -- Skip vimgrep count messages
  {
    filter = { event = 'msg_show', find = '%(%d+ of %d+%)' },
    opts = { skip = true },
  },
  -- Long output goes to split
  {
    view = 'split',
    filter = { event = 'msg_show', min_height = 5 },
  },
}
```

## Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| `:!cmd` output invisible | Route with `skip = true` matching first | Change to `view = 'split'` |
| Output lost after closing split | Split is ephemeral buffer | Use `g<` to recall, or route to `notify` |
| Notifications too narrow | `max_width` setting in notify view | Increase `max_width` (default 80, try 120) |

## Important: `g<`

Vim's built-in `g<` command shows the last message output. This works even after closing a Noice split. We added a reminder autocmd:

```lua
vim.api.nvim_create_autocmd('ShellCmdPost', {
  callback = function()
    vim.defer_fn(function()
      vim.notify('Tip: g< to see output again', vim.log.levels.INFO)
    end, 100)
  end,
})
```

## Related

- `lua/custom/plugins/noice.lua` - Main configuration
- `:Noice history` - View message history
- `:Noice last` - Show last message
