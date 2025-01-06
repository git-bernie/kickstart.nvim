-- Will need time to figure this one out
return {
  'stevearc/aerial.nvim',
  enabled = true,

  opts = {
    backends = { 'treesitter', 'lsp', 'markdown', 'asciidoc', 'man' },
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
    default_direction = 'prefer_left',
    placement = 'window', -- edge, window
  },
  -- Optional dependencies
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    'nvim-tree/nvim-web-devicons',
  },
  vim.keymap.set('n', '<leader>tt', '<cmd>AerialToggle left<CR>', { desc = '[A]erial[[T]oggle', silent = true, noremap = true }),
}
