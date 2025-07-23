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

  config = function()
    require('window-picker').setup {
      -- hint = 'statusline-winbar',
      hint = 'floating-big-letter',
      -- vim.api.nvim_set_keymap('n', '-', '<cmd>lua require("window-picker").pick_window()<cr>', { desc = '[-]ChooseWin', silent = true, noremap = true }),
    }
  end,
}
