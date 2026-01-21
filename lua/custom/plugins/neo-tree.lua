--[[
For awesome recipes @see https://github.com/nvim-neo-tree/neo-tree.nvim/wiki/Recipes#commands

## The `filesystem.follow_current_file` option is replaced with a table, please move to `filesystem.follow_current_file.enabled`.
sessionoptions blank,buffers,curdir,folds,help,tabpages,winsize,terminal

FIX: Custom 'filter_and_refresh' command auto-refreshes after filtering (was: had to press "R" manually).
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
    commands = {
      -- Custom filter command that auto-refreshes after filtering
      filter_and_refresh = function(state)
        local fs_commands = require('neo-tree.sources.filesystem.commands')
        fs_commands.filter_on_submit(state)
        -- Poll until filter popup closes, then call refresh directly
        local timer = vim.uv.new_timer()
        if not timer then
          return
        end
        timer:start(100, 100, vim.schedule_wrap(function()
          if vim.fn.mode() == 'n' then
            timer:stop()
            timer:close()
            fs_commands.refresh(state)
          end
        end))
      end,
    },
    filesystem = {
      hijack_netrw_behavior = 'open_default',
      -- "open_current",
      -- "disabled",
      window = {
        mappings = {
          ['\\'] = 'close_window',
          ['P'] = { 'toggle_preview', config = { use_float = true, use_image_nvim = true } },
          ['f'] = 'filter_and_refresh', -- Use custom command instead of default filter
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
