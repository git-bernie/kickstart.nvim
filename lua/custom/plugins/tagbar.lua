return {
  'preservim/tagbar',
  config = function()
    vim.keymap.set('n', '<leader>tt', '<cmd>TagbarToggle<CR>', { desc = '[T]agbar[[T]oggle', silent = true, noremap = true })
    vim.g.tagbar_left = true
    vim.g.tagbar_expand = true
  end,
}
