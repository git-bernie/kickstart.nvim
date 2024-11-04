-- disabled: let's use mini.surround instead.
return {
  'kylechui/nvim-surround',
  enabled = false, -- Enable this plugin
  version = '*', -- Use for stability; omit to use `main` branch for the latest features
  event = 'VeryLazy',
  config = function()
    require('nvim-surround').setup {
      -- Configuration here, or leave empty to use defaults
    }
  end,
}
