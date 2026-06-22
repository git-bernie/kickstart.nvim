-- lazy.nvim (always latest stable release)
--
-- DISABLED 2026-06-22 pending evaluation. Two issues to resolve before enabling:
--   1. The plugin ships a malformed bundled `lazy.lua` (a bare `{ cmd = {...} }`
--      with no plugin name), which lazy.nvim rejects as "Invalid plugin spec" at
--      startup. A valid bundled spec names the plugin, e.g.
--      `{ { 'joryeugene/dadbod-grip.nvim', cmd = {...} } }` (cf. blink.compat).
--      `enabled = false` makes lazy skip the plugin entirely, silencing the error.
--   2. The placeholder below is wrong: the real commands are :Grip, :GripStart,
--      :GripTables, :GripQuery, … (22 total), NOT :DBGrip. Pick a real entry
--      command for the keymap when evaluating.
return {
  'joryeugene/dadbod-grip.nvim',
  enabled = false,
  version = '*',
  cmd = { 'DBGrip' }, -- replace with actual commands from the plugin's docs
  keys = {
    { '<leader>dg', '<cmd>DBGrip<cr>', desc = 'DBGrip' },
  },
}
