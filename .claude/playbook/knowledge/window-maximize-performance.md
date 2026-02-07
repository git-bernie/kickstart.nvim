# Window Maximize Performance

## Problem

Window maximize/restore (`<leader>z`) felt sluggish and "crawly" — not the snappy toggle expected.

## Root Cause

Two layers were adding animation overhead:

1. **`mini.animate` resize** — animates window resize frame-by-frame, making maximize visually slow
2. **`maximizer.nvim` plugin** — added unnecessary abstraction over simple native operations

`smear-cursor.nvim` was initially suspected but is innocent — it only animates cursor movement, not window resizes.

## Solution

### 1. Disable mini.animate resize (keep other animations)

```lua
require('mini.animate').setup {
  resize = { enable = false },
}
```

This keeps cursor and scroll animations but makes window resizes instant.

### 2. Replace maximizer.nvim with built-in toggle

```lua
local saved_layout = nil

local function toggle_maximize()
  if saved_layout then
    vim.cmd(saved_layout)
    saved_layout = nil
  else
    saved_layout = vim.fn.winrestcmd()
    vim.cmd 'wincmd _ | wincmd |'
  end
end
```

- `winrestcmd()` saves exact split sizes before maximizing
- `wincmd _ | wincmd |` maximizes height + width (native, zero overhead)
- Restore replays the saved command — pixel-perfect

## Key Insight

When debugging perceived slowness, check animation layers first: `mini.animate`, `smear-cursor`, `neoscroll`. They stack and the real culprit may not be the plugin you suspect.
