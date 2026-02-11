return {
  'gbprod/yanky.nvim',
  dependencies = { 'nvim-telescope/telescope.nvim' },
  opts = {
    ring = {
      history_length = 100,
      storage = 'shada',
    },
    highlight = {
      on_put = true,
      on_yank = true,
      timer = 200,
    },
    preserve_cursor_position = {
      enabled = true,
    },
  },
  keys = {
    {
      '<leader>p',
      function()
        require('telescope').extensions.yank_history.yank_history {}
      end,
      mode = { 'n', 'x' },
      desc = 'Open Yank History',
    },
    { 'y', '<Plug>(YankyYank)', mode = { 'n', 'x' }, desc = 'Yank text' },
    { 'p', '<Plug>(YankyPutAfter)', mode = { 'n', 'x' }, desc = 'Put yanked text after cursor' },
    { 'P', '<Plug>(YankyPutBefore)', mode = { 'n', 'x' }, desc = 'Put yanked text before cursor' },
    { '[y', '<Plug>(YankyCycleForward)', desc = 'Cycle forward through yank history' },
    { ']y', '<Plug>(YankyCycleBackward)', desc = 'Cycle backward through yank history' },
  },
  config = function(_, opts)
    require('yanky').setup(opts)
    require('telescope').load_extension 'yank_history'
  end,
}
