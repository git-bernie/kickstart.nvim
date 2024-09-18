--https://github.com/nvim-telescope/telescope-file-browser.nvim
return {
  'nvim-telescope/telescope-file-browser.nvim',
  keys = {
    { '<leader>ff', '<cmd>Telescope file_browser<cr>', desc = '[F]ile [B]rowser', silent = true },
    -- Don't totally understand this one because I had to add <cr> to make work without waiting for a keystroke, or something.
    { '<leader>fd', ':Telescope file_browser path=%:p:h<cr>', desc = '[F]ile Browser to this [D]ir', silent = true },
  },
}
