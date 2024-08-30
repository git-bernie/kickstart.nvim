return {
  '0x00-ketsu/maximizer.nvim',
  config = function()
    require('maximizer').setup {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration
      -- vim.api.nvim_set_keymap('n', 'mt', '<cmd>lua require("maximizer").toggle()<CR>', {silent = true, noremap = true})
      -- vim.api.nvim_set_keymap('n', 'mm', '<cmd>lua require("maximizer").maximize()<CR>', {silent = true, noremap = true})
      -- vim.api.nvim_set_keymap('n', 'mr', '<cmd>lua require("maximizer").restore()<CR>', {silent = true, noremap = true}) section below
      vim.keymap.set('n', '<leader>z', '<cmd>lua require("maximizer").toggle()<CR>', { desc = 'Maximi[Z]er', silent = true, noremap = true }),
      -- vim.api.nvim_set_keymap('n', '<leader>z', '<cmd>lua require("maximizer").toggle()<CR>', { desc = 'Maximi[Z]er', silent = true, noremap = true }),
    }
  end,
}
