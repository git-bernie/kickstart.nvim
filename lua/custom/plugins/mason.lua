-- https://github.com/mason-org/mason-lspconfig.nvim
-- Recommended setup for `lazy.nvim`
return {
  'mason-org/mason-lspconfig.nvim',
  opts = {},
  dependencies = {
    { 'mason-org/mason.nvim', opts = {} },
    'neovim/nvim-lspconfig',
  },
}
