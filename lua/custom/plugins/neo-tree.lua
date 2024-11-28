--[[
For awesome recipes @see https://github.com/nvim-neo-tree/neo-tree.nvim/wiki/Recipes#commands

## The `filesystem.follow_current_file` option is replaced with a table, please move to `filesystem.follow_current_file.enabled`.
sessionoptions blank,buffers,curdir,folds,help,tabpages,winsize,terminal
]]
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
    auto_restore_session_experimental = true,
    use_libuv_file_watcher = true,
    close_if_last_window = true, -- misspelled in lua/kickstart/plugins/neo-tree.lua
    filesystem = {
      follow_current_file = {
        enabled = true,
      },
      window = {
        mappings = {
          ['\\'] = 'close_window',
        },
      },
    },
    -- I like this setting, but I also like to see the tree in the state I left it.
    -- follow_current_file = true,
    buffers = {
      enabled = true,
      show_unloaded = true,
    },
  },
}
