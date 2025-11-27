return {
  'Wansmer/treesj',
  -- keys = { '<space>m', '<space>j', '<space>s' },
  -- keys = { ',m', ',j', ',s' },
  keys = {},
  dependencies = { 'nvim-treesitter/nvim-treesitter' }, -- if you install parsers with `nvim-treesitter`
  config = function()
    require('treesj').setup {--[[ your config ]]
      max_join_length = 300, -- default 120 I think the logic is so that it fits on one screen line
    }
  end,
}
