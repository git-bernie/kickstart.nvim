return {
  'numToStr/Comment.nvim',
  opts = {
    extra = { above = 'gcO', below = 'gco', eol = 'gcA' },
  },
  keys = {
    {
      '<leader>c<space>',
      function()
        return vim.v.count == 0 and '<Plug>(comment_toggle_linewise_current)' or '<Plug>(comment_toggle_linewise_count)'
      end,
      expr = true,
      desc = 'Toggle [C]omment current [L]ine or with count',
    },
  },
}
