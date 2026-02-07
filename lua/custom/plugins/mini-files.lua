return {
  'echasnovski/mini.files',
  version = '*',
  keys = {
    {
      '-',
      function()
        require('mini.files').open(vim.api.nvim_buf_get_name(0), true)
      end,
      desc = 'Mini Files (current file)',
    },
    {
      '<leader>-',
      function()
        require('mini.files').open(vim.uv.cwd(), true)
      end,
      desc = 'Mini Files (cwd)',
    },
  },
  opts = {
    mappings = {
      synchronize = '=',
      go_in_plus = '<CR>',
    },
    windows = {
      preview = true,
      width_preview = 40,
    },
  },
}
