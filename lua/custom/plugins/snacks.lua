---@diagnostic disable: undefined-global, undefined-field
return {
  'folke/snacks.nvim',
  priority = 1000,
  lazy = false,
  ---@class snacks.Config, snacks.lazygit.Config
  ---@type snacks.Config
  ---@class snacks.lazygit.Config
  ---@field lazygit? snacks.lazygit.Config
  opts = {
    -- your configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
    bigfile = { enabled = true },
    dashboard = { enabled = true },
    explorer = { enabled = false },
    indent = { enabled = true },
    input = { enabled = true },
    picker = { enabled = true },
    notifier = { enabled = true, timeout = 3000 },
    quickfile = { enabled = true },
    scope = { enabled = true },
    scroll = { enabled = false },
    statuscolumn = { enabled = true },
    words = { enabled = true },
    styles = {
      notification = {
        -- wo = {wrap = true } -- enable wrap for notifications
      },
    },
  },
  keys = {
    {
      '<leader>lg',
      function()
        Snacks.lazygit()
      end,
      desc = '[L]azy[G]it',
      silent = false,
    },
    {
      'gd',
      function()
        Snacks.picker.lsp_definitions()
        vim.cmd 'normal! zz'
      end,
      desc = '[G]o to [D]efinition (Snacks.picker.lsp_definitions)',
      silent = false,
    },
  },
}
