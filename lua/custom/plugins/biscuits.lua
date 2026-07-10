return {
  'code-biscuits/nvim-biscuits',
  enabled = true,
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
  },
  opts = {
    cursor_line_only = true,
    -- Recompute only when the cursor rests (CursorHold), not on every
    -- CursorMoved. Without an explicit on_events, cursor_line_only binds
    -- biscuits to CursorMoved/CursorMovedI (see nvim-biscuits init.lua:309),
    -- which re-walks the whole treesitter tree on every line move — pegs a
    -- core on large files (e.g. 6K-line CakePHP controllers). CursorHold
    -- fires after `updatetime` ms of no movement, so movement stays smooth.
    on_events = { 'CursorHold', 'CursorHoldI' },
    -- Config goes here
  },
}
