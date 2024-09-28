return {
  'smjonas/inc-rename.nvim',
  enabled = false, -- too dangerous!!!!!
  -- vim.keymap.set("n", "<leader>rn", ":IncRename ")
  vim.keymap.set('n', '<leader>rn', function()
    return ':IncRename ' .. vim.fn.expand '<cword>'
  end, { expr = true }),
}
