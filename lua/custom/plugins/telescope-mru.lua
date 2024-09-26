return {
  'mikemcbride/telescope-mru.nvim',
  dependencies = { 'nvim-telescope/telescope.nvim', 'nvim-lua/plenary.nvim' },

  -- vim.keymap.set("n", "<space>sr", ":Telescope mru_files<CR>"),

  -- Alternatively, using lua API
  vim.keymap.set('n', '<space>su', function()
    require('telescope').extensions.mru_files.mru_files {
      prompt_title = '[S]earch Recently [U]sed Files',
    }
  end),
}
