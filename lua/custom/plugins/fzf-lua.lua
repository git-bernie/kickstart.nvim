return {
  'ibhagwan/fzf-lua',
  -- optional for icon support
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    -- calling `setup` is optional for customization
    -- require('fzf-lua').setup {}
    require('fzf-lua').setup {
      git = {
        branches = {
          sort_branches = '-committerdate',
        },
      },
    }
  end,
  opts = {},
}
