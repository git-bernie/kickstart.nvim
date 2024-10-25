return {
  'hrsh7th/cmp-omni',
  enabled = true,
  sources = {
    {
      name = 'omni',
      option = {
        disable_omnifuncs = { 'v:lua.vim.lsp.omnifunc' },
      },
    },
  },
}
