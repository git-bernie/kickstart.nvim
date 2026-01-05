-- Will need time to figure this one out
return {
  'stevearc/aerial.nvim',
  enabled = true,

  opts = {
    backends = { 'treesitter', 'lsp', 'markdown', 'asciidoc', 'man', 'php', 'vue' },
    filter_kind = false,
    -- filter_kind = {
    --   'Class',
    --   'Constructor',
    --   'Enum',
    --   'Function',
    --   'Interface',
    --   'Module',
    --   'Method',
    --   'Struct',
    -- },
    -- default_direction = 'prefer_left',
    default_direction = 'float',
    -- NB: not sure difference btw edge and window
    -- placement = 'window', -- edge, window
    placement = 'edge', -- edge, window
    close_on_select = false,
    -- close_on_select = true,
    --   window - aerial window will display symbols for the buffer in the window from which it was opened
    attach_mode = 'window',
    --   global - aerial window will display symbols for the current window
    -- attach_mode = 'global',
    close_automatic_events = {},
  },
  -- Optional dependencies
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    'nvim-tree/nvim-web-devicons',
  },
  -- vim.keymap.set('n', '<leader>tt', '<cmd>AerialToggle left<CR>', { desc = '[A]erial[T]oggle', silent = true, noremap = true }),
  vim.keymap.set('n', '<leader>ta', '<cmd>AerialToggle left<CR>', { desc = '[T]oggle[A]erial', silent = true, noremap = true }),
}
