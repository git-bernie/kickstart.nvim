return {
  'ibhagwan/fzf-lua',
  -- optional for icon support
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function(_, opts)
    -- Clear FZF_DEFAULT_OPTS to prevent conflicts with fzf-lua settings
    vim.env.FZF_DEFAULT_OPTS = nil

    require('fzf-lua').setup(opts)
  end,
  opts = {
    -- F1:help  F4:preview  F5:layout
    winopts = {
      preview = {
        layout = 'flex',
        flip_columns = 100,
      },
    },
    keymap = {
      builtin = {},
      fzf = {},
    },
    git = {
      branches = {
        sort_branches = '-committerdate',
      },
    },
  },
}
