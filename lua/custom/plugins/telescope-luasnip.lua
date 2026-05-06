return {
  'benfowler/telescope-luasnip.nvim',
  dependencies = { 'nvim-telescope/telescope.nvim', 'L3MON4D3/LuaSnip' },
  keys = {
    {
      '<leader>fS',
      function()
        require('telescope').extensions.luasnip.luasnip {}
      end,
      desc = '[F]ind [S]nippets (LuaSnip)',
      mode = { 'n', 'i' },
    },
  },
  config = function()
    require('telescope').load_extension 'luasnip'
  end,
}
