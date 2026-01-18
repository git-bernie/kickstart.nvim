return {
  'kelly-lin/ranger.nvim',
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
    vim.api.nvim_set_keymap('n', '<leader>ef', '', {
      desc = 'Open Ranger [E]xternal [F]ile manager(?)',
      noremap = true,
      callback = function()
        require('ranger-nvim').open(true)
      end,
    })
    vim.api.nvim_set_keymap('n', '<leader>rr', '', {
      desc = 'Open [R]ange[r]',
      noremap = true,
      callback = function()
        require('ranger-nvim').open(true)
      end,
    })
  end,
}
