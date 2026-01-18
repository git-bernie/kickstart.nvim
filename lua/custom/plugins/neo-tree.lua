--[[
For awesome recipes @see https://github.com/nvim-neo-tree/neo-tree.nvim/wiki/Recipes#commands

## The `filesystem.follow_current_file` option is replaced with a table, please move to `filesystem.follow_current_file.enabled`.
sessionoptions blank,buffers,curdir,folds,help,tabpages,winsize,terminal

BUG: for "f" to filter you have to press "R" to refresh to see the results. Or open and close again.
Remember that C-x is for clearing the filter.

]]
return {
  'nvim-neo-tree/neo-tree.nvim',
  enabled = true,
  branch = 'v3.x',
  -- version = '*',
  dependencies = {
    '3rd/image.nvim', -- Optional image support in preview window: See `# Preview Mode` for more information
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
    'MunifTanjim/nui.nvim',
  },
  cmd = 'Neotree',
  keys = {
    { '\\', ':Neotree reveal<CR>', desc = 'NeoTree reveal', silent = true },
    { '<leader>tl', ':Neotree position=left<CR>', desc = 'Neo[T]ree position=[L]eft', silent = true },
    { '<leader>tf', ':Neotree float<CR>', desc = 'Neo[T]ree [F]loat', silent = true },
    { '<leader>tc', ':Neotree current<CR>', desc = 'Neo[T]ree [C]urrent', silent = true },
  },
  window = {
    mappings = {
      ['P'] = { 'toggle_preview', config = { use_float = true, use_image_nvim = true } },
    },
  },
  opts = {
    auto_restore_session_experimental = true,
    use_libuv_file_watcher = true,
    close_if_last_window = true, -- misspelled in lua/kickstart/plugins/neo-tree.lua
    filesystem = {
      hijack_netrw_behavior = 'open_default',
      -- "open_current",
      -- "disabled",
      window = {
        mappings = {
          ['\\'] = 'close_window',
          ['P'] = { 'toggle_preview', config = { use_float = true, use_image_nvim = true } },
        },
      },
      follow_current_file = {
        enabled = true,
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
