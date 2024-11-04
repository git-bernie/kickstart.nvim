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
    close_if_last_window = true, -- misspelled in lua/kickstart/plugins/neo-tree.lua
    filesystem = {
      window = {
        mappings = {
          ['\\'] = 'close_window',
        },
      },
    },
  },
}
