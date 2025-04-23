-- Will need time to figure this one out
return {
  'stevearc/aerial.nvim',
  enabled = true,

  opts = {
    backends = { 'treesitter', 'lsp', 'markdown', 'asciidoc', 'man', 'php' },
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
    placement = 'window', -- edge, window
    close_on_select = false,
  },
  -- Optional dependencies
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    'nvim-tree/nvim-web-devicons',
  },
  vim.keymap.set('n', '<leader>tt', '<cmd>AerialToggle left<CR>', { desc = '[A]erial[T]oggle', silent = true, noremap = true }),
  vim.keymap.set('n', '<leader>ta', '<cmd>AerialToggle left<CR>', { desc = '[T]oggle[A]erial', silent = true, noremap = true }),
}
