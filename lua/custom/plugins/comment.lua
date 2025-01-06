return {
  'numToStr/Comment.nvim',
  enabled = true,
  opts = {
    -- add any options here
    -- Toggle current line or with count
    vim.keymap.set('n', '<leader>c<space>', function()
      return vim.v.count == 0 and '<Plug>(comment_toggle_linewise_current)' or '<Plug>(comment_toggle_linewise_count)'
    end, { expr = true, desc = 'Toggle [C]omment current [L]ine or with count' }),

    --[[ vim.keymap.set('n', '<C-_>', function()
      return vim.v.count == 0 and '<Plug>(comment_toggle_linewise_current)' or '<Plug>(comment_toggle_linewise_count)'
    end, { expr = true, desc = 'Toggle [C]omment current [L]ine or with count' }), ]]

    --[[ vim.keymap.set('n', '<leader>cb', function()
      return vim.v.count == 0 and '<Plug>(comment_toggle_blockwise_current)' or '<Plug>(comment_toggle_blockwise_count)'
    end, { expr = true, desc = 'Toggle [C]omment current [B]lock or with count' }), ]]

    --[[ vim.keymap.set('x', '<leader>cb', function()
      return vim.v.count == 0 and '<Plug>(comment_toggle_blockwise_current)' or '<Plug>(comment_toggle_blockwise_count)'
    end, { expr = true, desc = 'Toggle [C]omment current [B]lock or with count' }), ]]
  },
}
