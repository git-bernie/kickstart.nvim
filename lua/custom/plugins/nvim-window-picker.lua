-- https://github.com/s1n7ax/nvim-window-picker
-- https://www.lunarvim.org/docs/configuration/plugins/example-configurations
return {
  's1n7ax/nvim-window-picker',
  enabled = true,
  name = 'window-picker',
  event = 'VeryLazy',
  version = '2.*',
  --[[ opts = {
    hint = 'floating-big-letter',
  }, ]]

  keys = {
    {
      '-',
      function()
        local picked = require('window-picker').pick_window { include_current_win = true }
          or vim.api.nvim_get_current_win()
        vim.api.nvim_set_current_win(picked)
      end,
      desc = 'Pick a window',
    },
    {
      ',w',
      function()
        local picked = require('window-picker').pick_window { include_current_win = true }
          or vim.api.nvim_get_current_win()
        vim.api.nvim_set_current_win(picked)
      end,
      desc = '[,] Pick a [w]indow',
    },
  },
  config = function()
    require('window-picker').setup {
      hint = 'floating-big-letter',
      filter_rules = {
        include_current_win = false,
        autoselect_one = true,
        bo = {
          filetype = { 'neo-tree', 'neo-tree-popup', 'notify' },
          buftype = { 'terminal', 'quickfix' },
        },
      },
    }
  end,
}
