-- no longer necessary because of https://github.com/s1n7ax/nvim-window-picker
return {
  't9md/vim-choosewin',
  enabled = true,
  config = function()
    vim.api.nvim_set_keymap('n', '-', '<cmd>ChooseWin<CR>', { desc = '[-]ChooseWin', silent = true, noremap = true })
  end,
}
