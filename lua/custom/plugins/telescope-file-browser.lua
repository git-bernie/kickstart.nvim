--https://github.com/nvim-telescope/telescope-file-browser.nvim
return {
  'nvim-telescope/telescope-file-browser.nvim',
  -- keys = {
  --[[ {
      '<leader>zf',
      '<cmd>Telescope file_browser follow_symlinks=true<cr>',
      desc = '[F]ile [B]rowser',
      silent = true,
    }, ]]
  -- Don't totally understand this one because I had to add <cr> to make work without waiting for a keystroke, or something.
  --[[ {
      '<leader>fd',
      '<cmd>Telescope file_browser path=%:p:h follow_symlinks=true<cr>',
      desc = '[F]ile Browser to this [D]ir',
      silent = true,
    }, ]]
  -- },
  config = function()
    vim.keymap.set('n', '<leader>ff', '<cmd>Telescope file_browser follow_symlinks=true<cr>', { desc = '[F]ile [F]ind', silent = true })
    vim.keymap.set('n', '<leader>fd', '<cmd>Telescope file_browser path=%:p:h follow_symlinks=true<cr>', { desc = '[F]ile Browser to this [D]ir' })
  end,
}
