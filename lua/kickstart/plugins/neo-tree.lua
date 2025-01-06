-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim

return {
  'nvim-neo-tree/neo-tree.nvim',
  version = '*',
  dependencies = {
    '3rd/image.nvim', -- Optional image support in preview window: See `# Preview Mode` for more information
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
    'MunifTanjim/nui.nvim',
  },
  cmd = 'Neotree',
  keys = {
    { '\\', ':Neotree reveal<CR>', desc = 'NeoTree reveal', silent = true },
  },
  opts = {
    use_libuv_file_watcher = true,
    close_if_last_widnow = true,
    filesystem = {
      window = {
        mappings = {
          ['\\'] = 'close_window',
        },
      },
    },
    follow_current_file = true,
    buffers = {
      follow_current_file = {
        enabled = true,
      },
    },
  },
  filesystem = {
    follow_current_file = {
      enabled = true,
    },
  },
}
