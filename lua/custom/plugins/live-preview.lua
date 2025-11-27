return {
  'brianhuster/live-preview.nvim',
  enabled = false,
  dependencies = {
    -- You can choose one of the following pickers
    'nvim-telescope/telescope.nvim',
    'ibhagwan/fzf-lua',
    'echasnovski/mini.pick',
    'folke/snacks.nvim',
  },
  opts = {
    port = 5500,
    browser = 'default',
    dynamic_root = false,
    sync_scroll = true,
    picker = 'fzf-lua',
    address = '127.0.0.1',
  },
}
