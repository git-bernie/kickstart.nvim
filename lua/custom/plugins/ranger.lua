return {
  'kelly-lin/ranger.nvim',
  keys = {
    {
      '<leader>ef',
      function()
        require('ranger-nvim').open(true)
      end,
      desc = 'Open Ranger [E]xternal [F]ile manager(?)',
    },
    {
      '<leader>rr',
      function()
        require('ranger-nvim').open(true)
      end,
      desc = 'Open [R]ange[r]',
    },
  },
  config = function()
    require('ranger-nvim').setup {
      enable_cmds = false,
      replace_netrw = false,
      keybinds = {
        ['ov'] = require('ranger-nvim').OPEN_MODE.vsplit,
        ['oh'] = require('ranger-nvim').OPEN_MODE.split,
        ['ot'] = require('ranger-nvim').OPEN_MODE.tabedit,
        ['or'] = require('ranger-nvim').OPEN_MODE.rifle,
      },
      ui = {
        border = 'none',
        height = 1,
        width = 1,
        x = 0.5,
        y = 0.5,
      },
    }
  end,
}
