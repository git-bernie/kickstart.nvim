return {
  'mikemcbride/telescope-mru.nvim',
  dependencies = { 'nvim-telescope/telescope.nvim', 'nvim-lua/plenary.nvim' },
  keys = {
    {
      '<space>su',
      function()
        require('telescope').extensions.mru_files.mru_files {
          prompt_title = '[S]earch Recently [U]sed Files',
        }
      end,
      desc = '[S]earch Recently [U]sed Files',
    },
  },
}
