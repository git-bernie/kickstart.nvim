return {
  'srackham/digraph-picker.nvim',
  dependencies = {
    'nvim-telescope/telescope.nvim',
  },
  version = '*', -- Install latest tagged version
  keys = {
    {
      '<C-k><C-k>',
      function()
        require('digraph-picker').insert_digraph()
      end,
      mode = { 'i', 'n' },
      desc = 'Digraph picker',
    },
  },
  opts = {},
}
