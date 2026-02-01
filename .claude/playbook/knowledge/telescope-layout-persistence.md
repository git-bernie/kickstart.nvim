# Telescope Layout Persistence

## Overview

By default, Telescope resets to the configured `layout_strategy` each time a picker opens. This feature saves the user's layout choice (via `<M-l>` cycling) so it persists within the session and across Neovim restarts.

## How It Works

1. **File storage**: Layout preference saved to `~/.local/share/nvim/telescope_layout.txt`
2. **Session persistence**: When cycling, we update `telescope.config.values.layout_strategy` so future pickers use the new layout immediately
3. **Cross-session**: On startup, `get_saved_layout()` reads the file and sets the initial `layout_strategy`

## Key Concepts

- **`telescope.config.values`**: Runtime config that new pickers read from. Modifying this affects future pickers without re-running `setup()`
- **`action_state.get_current_picker()`**: Returns the picker object, which has `layout_strategy` property after cycling
- **`cycle_layout_list`**: Defines which layouts to cycle through (we include `flex`, `vertical`, `horizontal`)

## Configuration

```lua
local action_layout = require 'telescope.actions.layout'
local action_state = require 'telescope.actions.state'

-- Persist layout preference across sessions
local layout_file = vim.fn.stdpath 'data' .. '/telescope_layout.txt'
local function get_saved_layout()
  local f = io.open(layout_file, 'r')
  if f then
    local layout = f:read '*l'
    f:close()
    if layout and layout ~= '' then
      return layout
    end
  end
  return 'flex'
end

local function save_layout(layout)
  local f = io.open(layout_file, 'w')
  if f then
    f:write(layout)
    f:close()
  end
end

-- Custom cycle action that persists the choice
local function cycle_layout_and_save(prompt_bufnr)
  action_layout.cycle_layout_next(prompt_bufnr)
  local picker = action_state.get_current_picker(prompt_bufnr)
  if picker and picker.layout_strategy then
    -- Update default for future pickers in this session
    require('telescope.config').values.layout_strategy = picker.layout_strategy
    -- Save for next session
    save_layout(picker.layout_strategy)
  end
end

require('telescope').setup {
  defaults = {
    layout_strategy = get_saved_layout(),
    layout_config = {
      flex = { flip_columns = 100 }, -- only flex uses this
      horizontal = { preview_width = 0.5 },
      vertical = { preview_height = 0.4 },
    },
    cycle_layout_list = { 'flex', 'vertical', 'horizontal' },
    mappings = {
      i = {
        ['<M-l>'] = { cycle_layout_and_save, type = 'action', opts = { desc = 'Cycle layout (saves)' } },
      },
      n = {
        ['<M-l>'] = { cycle_layout_and_save, type = 'action', opts = { desc = 'Cycle layout (saves)' } },
      },
    },
  },
}
```

## Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| `flip_columns` warning | Option at top-level of `layout_config` | Nest under `flex = { flip_columns = 100 }` |
| Layout not persisting | File write permission | Check `~/.local/share/nvim/` is writable |
| Can't get back to flex | `flex` not in `cycle_layout_list` | Add `'flex'` to the list |

## Related

- `init.lua` line ~933 - Telescope setup with persistence
- Knowledge: [telescope-hidden-files](telescope-hidden-files.md)
- `:help telescope.layout`
